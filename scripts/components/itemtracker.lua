local InventoryFunctions = require "util/inventoryfunctions"
local ItemFunctions = require "util/itemfunctions"
local Say = require "util/say"

-- 
-- Config
-- 

local AUTO_RE_EQUIP_WEAPON = GetModConfigData("AUTO_RE_EQUIP_WEAPON", MOD_EQUIPMENT_CONTROL.MODNAME)
local BUTTON_SHOW = GetModConfigData("BUTTON_SHOW", MOD_EQUIPMENT_CONTROL.MODNAME)

local Trackers = {}
local TrackerFunctions = {}

-- 
-- Event functions
-- 

local AutoEquipEnum =
{
    BEST = 2,
    SAME = 1,
}

local function GetItemFromCategory(category)
    return ThePlayer
       and ThePlayer.components.actioncontroller
       and ThePlayer.components.actioncontroller:GetItemFromCategory(category)
end

local function AutoReEquip(item)
    if AUTO_RE_EQUIP_WEAPON == AutoEquipEnum.BEST and ItemFunctions:IsMeleeWeapon(item) then
        item = GetItemFromCategory("WEAPON")

        if item then
            SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, item)
        end
    else
        for _, invItem in pairs(InventoryFunctions:GetPlayerInventory(true)) do
            if invItem.prefab == item.prefab then
                SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, invItem)
                break
            end
        end
    end
end

local function GetArmorCategory(item)
    return Categories.ARMORHAT.fn(item) and "ARMORHAT"
        or "ARMORBODY"
end

local function AutoReEquipArmor(item)
    if InventoryFunctions:Has(item.prefab, 1) then
        return
    end

    local category = GetArmorCategory(item)

    item = GetItemFromCategory(category)
    if item then
        item:DoTaskInTime(FRAMES * 10, function()
            SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, item)
        end)
    end
end

local AutoUnequipTasks = {}
local AutoUnequipTimeOut = FRAMES * 35

local function TaskTimeout(item)
    local elapsedTime = GetTime() - AutoUnequipTasks[item].start
    local timeout = elapsedTime > AutoUnequipTimeOut

    if timeout then
        AutoUnequipTasks[item].message = MOD_EQUIPMENT_CONTROL.STRINGS.AUTO_UNEQUIP_ITEM.FAIL
    end

    return timeout
end

local function StopTask(item)
    Say(
        string.format(
            AutoUnequipTasks[item].message,
            item.name
        )
    )
    AutoUnequipTasks[item].task:Cancel()
    AutoUnequipTasks[item] = nil
end

local function IsEquipped(item, eslot)
    return ThePlayer.replica.inventory:GetEquippedItem(eslot) == item
end

local function PlayerCanPerformAction()
    return not InventoryFunctions:IsBusyClassified()
       and ThePlayer
       and not ThePlayer:HasTag("busy")
       and not (ThePlayer.sg ~= nil and ThePlayer.sg:HasStateTag("busy"))
       and ThePlayer.components.playeractionpicker ~= nil
       and ThePlayer.components.playercontroller ~= nil
end

local function AutoUnequipPeriodicTask(item, eslot)
    if not IsEquipped(item, eslot) or TaskTimeout(item) then
        StopTask(item)
        return
    end

    if not PlayerCanPerformAction() then
        return
    end

    local activeItem = InventoryFunctions:GetActiveItem()
    if activeItem then
        if activeItem ~= item then
            if InventoryFunctions:HasFreeSlot() then
                SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.UNEQUIP.code, item)
                StopTask(item)
                return
            else
                AutoUnequipTasks[item].message = MOD_EQUIPMENT_CONTROL.STRINGS.AUTO_UNEQUIP_ITEM.DROP
                InventoryFunctions:ReturnActiveItem()
            end
        end
    else
        if not InventoryFunctions:HasFreeSlot() then
            InventoryFunctions:TakeActiveItemFromEquipSlot(eslot)
        else
            InventoryFunctions:UseItemFromInvTile(item)
            StopTask(item)
            return
        end
    end
end

local function StartAutoUnequipTask(item)
    if not AutoUnequipTasks[item] then
        AutoUnequipTasks[item] =
        {
            start = GetTime(),
            message = MOD_EQUIPMENT_CONTROL.STRINGS.AUTO_UNEQUIP_ITEM.UNEQUIP,
            task = item:DoPeriodicTask(FRAMES, AutoUnequipPeriodicTask, 0, ItemFunctions:GetEquipSlot(item)),
        }
    end
end

local function AutoUnEquip(item)
    item = item.entity:GetParent()

    if ItemFunctions:GetPercentUsed(item) <= ItemFunctions:GetFiniteUses(item) then
        StartAutoUnequipTask(item)
    end
end

local function AutoSwitchSkeletonArmor(item)
    item = item.entity:GetParent()
    item.LAST_USED = GetTime()

    local armors = {}
    for _, invItem in pairs(InventoryFunctions:GetPlayerInventory(true)) do
        if invItem.prefab == item.prefab and not invItem:HasTag("fueldepleted") then
            armors[#armors + 1] = invItem
        end
    end

    local function GetDelta(armor)
        return GetTime() - armor.LAST_USED
    end

    local bestArmor = nil
    for _, armor in pairs(armors) do
        if armor.LAST_USED then
            if not bestArmor or (GetDelta(armor) > GetDelta(bestArmor)) then
                bestArmor = armor
            end
        else
            bestArmor = armor
            break
        end
    end

    if bestArmor then
        SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, bestArmor)
    end
end

local function GetFuels(item)
    local fuels = {}

    for _, tag in pairs(FUELTYPE) do
        if item:HasTag(tag .. "_fueled") then
            fuels[#fuels + 1] = tag
        end
    end

    return fuels
end

local function IsWalkButtonDown()
    return TheInput:IsControlPressed(CONTROL_MOVE_UP)
        or TheInput:IsControlPressed(CONTROL_MOVE_DOWN)
        or TheInput:IsControlPressed(CONTROL_MOVE_LEFT)
        or TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)
end

local function AddFuel(invItem, item)
    local newRequest = false

    if IsWalkButtonDown() and not ThePlayer.sg then
        SendRPCToServer(RPC.StopWalking)
        newRequest = true
    end

    local action = invItem:GetIsWet() and ACTIONS.ADDWETFUEL
                   or ACTIONS.ADDFUEL
    local buffaction = BufferedAction(ThePlayer, nil, action)
    ThePlayer.components.playercontroller:RemoteControllerUseItemOnItemFromInvTile(buffaction, item, invItem)

    if newRequest then
        ThePlayer:DoTaskInTime(FRAMES * 8, function()
            if IsWalkButtonDown() then
                SendRPCToServer(
                    RPC.DirectWalking,
                    ThePlayer.components.playercontroller.remote_vector.x,
                    ThePlayer.components.playercontroller.remote_vector.z
                )
            end
        end)
    end
end

local function AutoRefuel(item)
    item = item.entity:GetParent()

    if ItemFunctions:GetPercentUsed(item) < 50 then
        local fuels = GetFuels(item)

        for _, invItem in pairs(InventoryFunctions:GetPlayerInventory(true)) do
            for _, fuel in pairs(fuels) do
                if invItem:HasTag(fuel .. "_fuel") then
                    AddFuel(invItem, item)
                    return
                end
            end
        end
    end
end

local function RefreshButtons()
    if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls.buttons then
        ThePlayer.HUD.controls.buttons:Refresh()
    end
end

local function OnFuelDepleted(item)
    item = item.entity:GetParent()
    if item:HasTag("fueldepleted") then
        RefreshButtons()
    end
end

-- 
-- Triggers
-- 

local function IsHambat(item)
    return item.prefab == "hambat"
end

local function IsArmor(item)
    return ItemFunctions:IsArmor(item)
end

local function IsWeapon(item)
    return item:HasTag("weapon")
end

local function IsSlingshot(item)
    return item:HasTag("slingshot")
end

local function IsBoneArmor(item)
    return item.prefab == "armorskeleton"
end

local function IsFuelable(item)
    return item.prefab == "yellowamulet"
        or item:HasTag(FUELTYPE.CAVE .. "_fueled")
        or item:HasTag(FUELTYPE.WORMLIGHT .. "_fueled")
end

local function IsRepairable(item)
    return ItemFunctions:IsRepairable(item)
end

--- 
--- Tracker system
--- 

local function AddTracker(triggerFn, event, eventFn, classified, initFn)
    TrackerFunctions[#TrackerFunctions + 1] =
    {
        trigger = triggerFn,
        event = event,
        eventFn = eventFn,
        classified = classified,
        initFn = initFn,
    }
end

local function DetachTrackers(eslot)
    if Trackers[eslot] then
        for i = 1, #Trackers[eslot] do
            Trackers[eslot][i].eventLocation:RemoveEventCallback(
                Trackers[eslot][i].tracker.event,
                Trackers[eslot][i].tracker.eventFn
            )
            Trackers[eslot][i] = nil
        end
    end
end

local function AttachTrackers(item)
    local eslot = item.replica.equippable:EquipSlot()

    if Trackers[eslot] then
        DetachTrackers(eslot)
    else
        Trackers[eslot] = {}
    end

    for i = 1, #TrackerFunctions do
        if TrackerFunctions[i].trigger(item) then
            local location = TrackerFunctions[i].classified and item.replica.inventoryitem.classified 
                             or item

            location:ListenForEvent(
                TrackerFunctions[i].event,
                TrackerFunctions[i].eventFn
            )

            Trackers[eslot][#Trackers[eslot] + 1] =
            {
                item = item,
                eventLocation = location,
                tracker = TrackerFunctions[i],
            }

            if TrackerFunctions[i].initFn then
                TrackerFunctions[i].initFn(location)
            end
        end
    end
end

local HookedBackpack = {}
local BackpackEvents = { "itemlose" }

local function HookBackpack(item)
    if item:HasTag("backpack") then
        for _, event in pairs(BackpackEvents) do
            item:ListenForEvent(event, RefreshButtons)
        end
        local eslot = item.replica.equippable:EquipSlot()
        HookedBackpack[eslot] = item
    end
end

local function UnhookBackpack(eslot)
    if HookedBackpack[eslot] then
        for _, event in pairs(BackpackEvents) do
            HookedBackpack[eslot]:RemoveEventCallback(event, RefreshButtons)
        end
        HookedBackpack[eslot] = nil
    end
end

local RunOnEquip = { AttachTrackers }
local RunOnUnequip = { DetachTrackers }

if BUTTON_SHOW then
    RunOnEquip[#RunOnEquip + 1] = HookBackpack
    RunOnUnequip[#RunOnUnequip + 1] = UnhookBackpack

    if TheWorld.ismastersim then
        BackpackEvents[#BackpackEvents + 1] = "itemget"
        RunOnEquip[#RunOnEquip + 1] = RefreshButtons
        RunOnUnequip[#RunOnUnequip + 1] = RefreshButtons
    end
end

local function OnDeactivateWorld()
    for _, eslot in pairs(Trackers) do
        DetachTrackers(eslot)
    end
end

local ItemTracker = Class(function(self, inst)
    self.inst = inst

    self.inst:ListenForEvent("equip", function(_, data)
        for _, fn in pairs(RunOnEquip) do
            fn(data.item)
        end
    end)

    self.inst:ListenForEvent("unequip", function(_, data)
        for _, fn in pairs(RunOnUnequip) do
            fn(data.eslot)
        end
    end)

    self.inst.player_classified:ListenForEvent("isghostmodedirty", function()
        for _, eslot in pairs(Trackers) do
            for _, fn in pairs(RunOnUnequip) do
                fn(eslot)
            end
        end
    end)

    self.inst:ListenForEvent("deactivateworld", OnDeactivateWorld, TheWorld)

    if AUTO_RE_EQUIP_WEAPON then
        AddTracker(IsWeapon, "onremove", AutoReEquip)
    end

    if GetModConfigData("AUTO_RE_EQUIP_ARMOR", MOD_EQUIPMENT_CONTROL.MODNAME) then
        AddTracker(IsArmor, "onremove", AutoReEquipArmor)
    end

    if GetModConfigData("AUTO_REFUEL_LIGHT_SOURCES", MOD_EQUIPMENT_CONTROL.MODNAME) then
        AddTracker(IsFuelable, "percentuseddirty", AutoRefuel, true)
    end

    if GetModConfigData("AUTO_UNEQUIP_REPAIRABLES", MOD_EQUIPMENT_CONTROL.MODNAME) then
        AddTracker(IsRepairable, "percentuseddirty", AutoUnEquip, true, AutoUnEquip)
    end

    if GetModConfigData("AUTO_SWITCH_BONE_ARMOR", MOD_EQUIPMENT_CONTROL.MODNAME) then
        AddTracker(IsBoneArmor, "percentuseddirty", AutoSwitchSkeletonArmor, true)
    end

    if BUTTON_SHOW then
        AddTracker(IsFuelable, "percentuseddirty", OnFuelDepleted, true)
        AddTracker(IsHambat, "perishdirty", RefreshButtons, true)
    end

    for _, item in pairs(InventoryFunctions:GetEquips()) do
        for _, fn in pairs(RunOnEquip) do
            fn(item)
        end
    end
end)

return ItemTracker
