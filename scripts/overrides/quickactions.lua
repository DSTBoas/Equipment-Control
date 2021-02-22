local InventoryFunctions = require "util/inventoryfunctions"
local ItemFunctions = require "util/itemfunctions"

-- 
-- Config
-- 

local PREFERRED_CAMPFIRE_FUEL = GetModConfigData("PREFERRED_CAMPFIRE_FUEL", MOD_EQUIPMENT_CONTROL.MODNAME)

-- 
-- Events
-- 

local function OnGetBirdEvent(inst, data, target)
    if data and data.item:HasTag("bird") then
        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, ACTIONS.STORE.code, data.item, target)
    end

    inst.components.eventtracker:DetachEvent("OnGetBirdEvent")
end

local function OnTrapActiveItem(inst, modaction, data, trap, pos)
    if data and data.item and data.item == trap then
        local act = BufferedAction(inst, nil, ACTIONS.DROP, trap, pos)

        if inst.components.locomotor == nil then
            if InventoryFunctions:HasFreeSlot() then
                SendRPCToServer(RPC.LeftClick, ACTIONS.DROP.code, pos.x, pos.z, nil, nil, nil, nil, nil, nil, false)
            else
                inst:DoTaskInTime(FRAMES * 3, function()
                    SendRPCToServer(RPC.LeftClick, ACTIONS.DROP.code, pos.x, pos.z, nil, nil, nil, nil, nil, nil, false)
                end)
            end
        else
            act.preview_cb = function()
                SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, nil, true, nil, nil, nil, nil, false)
            end
        end

        inst.components.playercontroller:DoAction(act)        
    end

    inst.components.eventtracker:DetachEvent(modaction)
end

local function GetContainerFromSlot(slot, item, ...)
    for _, container in ipairs({...}) do
        if container:GetItemInSlot(slot) == item then
            return container
        end
    end

    return nil
end

local function TrapToActiveItem(inst, slot, trap)
    local container = GetContainerFromSlot(slot, trap, InventoryFunctions:GetInventory(), InventoryFunctions:GetBackpack())

    if container then
        if TheWorld.ismastersim then
            container:TakeActiveItemFromAllOfSlot(slot)
        else
            SendRPCToServer(RPC.TakeActiveItemFromAllOfSlot, slot, container ~= inst.replica.inventory and container.inst)
        end
    end
end

local function OnGetTrapEvent(inst, data, trap)
    if data and data.item and data.item == trap then
        if TheWorld.ismastersim then
            inst:DoTaskInTime(FRAMES, function()
                TrapToActiveItem(inst, data.slot, trap)
            end)
        else
            TrapToActiveItem(inst, data.slot, trap)
        end

        inst.components.eventtracker:DetachEvent("OnGetTrapEvent")
    end
end

local function OnBuildFossil(inst, data, target)
    if data and data.item and data.item.prefab == "fossil_piece" and target:HasTag("workrepairable") then
        local act = BufferedAction(inst, target, ACTIONS.REPAIR, data.item)

        if inst.components.locomotor == nil then
            SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
        else
            act.preview_cb = function()
                SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
            end
        end

        inst.components.playercontroller:DoAction(act)
    else
        inst.components.eventtracker:DetachEvent("OnBuildFossil")
    end
end

local TrackTimeOut = FRAMES * 90

local function GetTrack()
    local time = GetTime()
    
    local track
    while GetTime() - time < TrackTimeOut do
        track = GetClosestInstWithTag("dirtpile", ThePlayer, 60)

        if track then
            break
        end

        Sleep(FRAMES)
    end

    return track
end

local function DoTracking()
    ThePlayer.components.eventtracker:DetachEvent("DoTracking")
    StartThread(function()
        local track = GetTrack()

        if not track then
            return
        end

        ThePlayer.components.eventtracker:AddEvent(
            "onremove",
            "DoTracking",
            DoTracking,
            track
        )

        local act = BufferedAction(ThePlayer, track, ACTIONS.ACTIVATE)
        local position = track:GetPosition()

        if ThePlayer.components.locomotor == nil then
            SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, track)
        else
            act.preview_cb = function()
                SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, track)
            end
        end

        ThePlayer.components.playercontroller:DoAction(act)
    end, "TrackingThread")
end

-- 
-- Helpers @TODO Refactor helpers
-- 

local function GetItemFromInventory(prefab)
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item.prefab == prefab then
            return item
        end
    end

    return nil
end

local function IsSleeping(target)
    return target.AnimState:IsCurrentAnimation("sleep_pre")
        or target.AnimState:IsCurrentAnimation("sleep_loop")
        or target.AnimState:IsCurrentAnimation("sleep_pst")
end

local function GetBestGoldValueItem()
    local ret = {}

    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if ItemFunctions:GetGoldValue(item) > 0 then
            ret[#ret + 1] =
            {
                item = item,
                priority = ItemFunctions:GetGoldValue(item)
            }
        end
    end

    table.sort(ret, function(a, b)
        return a.priority > b.priority
    end)

    return ret[1] and ret[1].item
end

local function GetEggPriority(item)
    local priority = 0

    if item:HasTag("spoiled") then
        priority = 4 - (ItemFunctions:GetHunger(item) * .01)
    elseif item:HasTag("monstermeat") then
        priority = 3
    elseif item:HasTag("badfood") then
        priority = 2.5
    elseif item:HasTag("preparedfood") then
        priority = item:HasTag("stale") and 1 or .5
    elseif item:HasTag("stale") then
        priority = 1.5
    elseif item.prefab == "bird_egg_cooked" then
        priority = 1.6
    end

    return priority
end

local invalid_foods =
{
    "bird_egg",
    "rottenegg",
    "monstermeat",
    -- "cookedmonstermeat",
    -- "monstermeat_dried",
}

local function GetBirdFood()
    local t = {}

    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if not table.contains(invalid_foods, item.prefab) and item:HasTag("edible_MEAT") then
            t[#t + 1] =
            {
                item = item,
                priority = GetEggPriority(item)
            }
        end
    end

    table.sort(t, function(a, b)
        return a.priority > b.priority
    end)

    return t[1] and t[1].item
end

local function GetKlausSackKey()
    local ret = {}

    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag("klaussackkey") then
            ret[#ret + 1] = item
            if item.prefab =="klaussackkey" then
                return item
            end
        end
    end

    return ret[1]
end

local function GetDisplayName(item)
    local str = ""

    local adjective = item:GetAdjective()
    if adjective then
        str = adjective .. " "
    end

    return str .. item:GetDisplayName()
end

local function GetBird()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag("bird") then
            return item
        end
    end

    return nil
end

local function GetWallElement(target)
    local element = target.prefab:find("_")

    if element then
        element = target.prefab:sub(element + 1)
        if element == "ruins" then
            element = "thulecite"
        end
    end

    return element 
end

local function GetElementPriority(item, prefab)
    local priority = 0

    prefab = "REPAIR_" .. item.prefab:upper() .. "_HEALTH"
    if TUNING[prefab] then
        priority = TUNING[prefab]
    end

    return priority
end

local function GetRepairItem(target)
    local t = {}

    local element = GetWallElement(target)
    if element then
        for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
            if item:HasTag("repairer") and item:HasTag("health_" .. element) then
                t[#t + 1] =
                {
                    item = item,
                    priority = GetElementPriority(item)
                }
            end
        end
    end

    table.sort(t, function(a, b)
        return a.priority > b.priority
    end)

    return t[1] and t[1].item
end

local function IsExtinguishable(target)
    return not target:HasTag("campfire")
       and (target:HasTag("fire") or target:HasTag("smolder"))
end

local IgnoredFuels =
{
    blueprint = true,
    livinglog = true,
    waxwelljournal = true,
    boatpatch = true,
}

local function IsCompatibleFuel(target, item)
    return item:HasTag("BURNABLE_fuel")
       and not IgnoredFuels[item.prefab]
       and not item:HasTag("_equippable")
       and not (item:HasTag("deployable") and item.prefab ~= "pinecone")
        or target:HasTag("blueflame")
       and item:HasTag("CHEMICAL_fuel")
end

local function GetFuelItem(target)
    local ret = {}

    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if IsCompatibleFuel(target, item) then
            ret[#ret + 1] = item
            if item.prefab == PREFERRED_CAMPFIRE_FUEL then
                return item
            end
        end
    end

    return ret[1]
end

local function IsHighFire(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fire = (TheSim:FindEntities(x, y, z, .5, {"HASHEATER", "fx"}))[1]

    return fire
       and fire.AnimState
       and fire.AnimState:IsCurrentAnimation("level4")
end

local function GetToolFromInventory(action)
    local tag = action.id .. "_tool"

    if InventoryFunctions:EquipHasTag(tag) then
        return nil
    end

    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag(tag) then
            return item
        end
    end

    return nil
end

local function GetIgniteItem()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag("lighter") or item:HasTag("rangedlighter") then
            return item
        end
    end

    return nil
end

local function IsExtinguishItem(item)
    return item.prefab == "waterballoon"
        or item:HasTag("extinguisher")
        or (item:HasTag("repairer") and item:HasTag("frozen"))
end

local function GetExtinguishItem()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory(true)) do
        if IsExtinguishItem(item) then
            return item
        end
    end

    return nil
end

local QuickAction = Class(function(self, data)
    if data == nil then
        data = {}
    end

    self.toolaction = data.toolaction
    self.modaction = data.modaction
    self.itemfn = data.itemfn
    self.item = data.item
    self.rmb = data.rmb or false
    self.fn = function() return false end
    self.stringfn = data.stringfn
end)

-- @TODO Implement a priority system
local QuickActions =
{
    QUICK_ACTION_REPAIR_BOAT = QuickAction({item = "boatpatch", modaction = "SceneUse"}),
    QUICK_ACTION_WALLS = QuickAction({rmb = true, itemfn = GetRepairItem, modaction = "SceneUse"}),
    QUICK_ACTION_CAMPFIRE = QuickAction({itemfn = GetFuelItem, modaction = "SceneUse"}),
    QUICK_ACTION_BEEFALO = QuickAction({item = "razor", modaction = "SceneUse"}),
    QUICK_ACTION_PIG_KING = QuickAction({itemfn = GetBestGoldValueItem, modaction = "SceneUse"}),
    QUICK_ACTION_FEED_BIRD = QuickAction({itemfn = GetBirdFood, modaction = "SceneUse"}),
    QUICK_ACTION_IMPRISON_BIRD = QuickAction({itemfn = GetBird, modaction = "SceneUse"}),
    QUICK_ACTION_ATRIUM_GATE = QuickAction({item = "atrium_key", modaction = "SceneUse"}),
    QUICK_ACTION_KLAUS_SACK = QuickAction({itemfn = GetKlausSackKey, modaction = "SceneUse"}),
    QUICK_ACTION_EXTINGUISH = QuickAction({itemfn = GetExtinguishItem, modaction = "Extinguish"}),
    QUICK_ACTION_WAKEUP_BIRD = QuickAction({modaction = "WakeUp"}),
    QUICK_ACTION_TRAP = QuickAction({modaction = "Reset"}),
    QUICK_ACTION_DIRTPILE = QuickAction({modaction = "Track"}),
    QUICK_ACTION_BUILD_FOSSIL = QuickAction({rmb = true, item = "fossil_piece", modaction = "BuildFossil"}),
    QUICK_ACTION_DIG = QuickAction({rmb = true, toolaction = ACTIONS.DIG, modaction = "ToolAction"}),
    QUICK_ACTION_HAMMER = QuickAction({rmb = true, toolaction = ACTIONS.HAMMER, modaction = "ToolAction"}),
    QUICK_ACTION_NET = QuickAction({toolaction = ACTIONS.NET, modaction = "ToolAction"}),
    QUICK_ACTION_SLURTLEHOLE = QuickAction({itemfn = GetIgniteItem, modaction = "Ignite"}),
}

QuickActions.QUICK_ACTION_REPAIR_BOAT.fn = function(target)
    return target:HasTag("boat_leak")
end

QuickActions.QUICK_ACTION_WALLS.fn = function(target)
    return target:HasTag("wall")
       and not (target.AnimState:IsCurrentAnimation("fullA")
             or target.AnimState:IsCurrentAnimation("fullB")
             or target.AnimState:IsCurrentAnimation("fullC")
             or IsExtinguishable(target))
end

QuickActions.QUICK_ACTION_WALLS.stringfn = function(item)
    return "Repair (" .. item.name .. ")"
end

QuickActions.QUICK_ACTION_CAMPFIRE.fn = function(target)
    return target:HasTag("campfire")
       and not IsHighFire(target)
end

QuickActions.QUICK_ACTION_CAMPFIRE.stringfn = function(item)
    return "Add Fuel (" .. item.name .. ")"
end

QuickActions.QUICK_ACTION_BEEFALO.fn = function(target)
    return target:HasTag("beefalo")
       and IsSleeping(target)
       and target.AnimState:GetBuild() ~= "beefalo_shaved_build"
end

QuickActions.QUICK_ACTION_PIG_KING.fn = function(target)
    return target.prefab == "pigking"
       and target:HasTag("trader")
end

QuickActions.QUICK_ACTION_PIG_KING.stringfn = function(item)
    return "Trade " .. item.name .. " (" .. ItemFunctions:GetGoldValue(item) .. ")"
end

QuickActions.QUICK_ACTION_FEED_BIRD.fn = function(target)
    return target.prefab == "birdcage"
       and target:HasTag("trader")
       and not IsSleeping(target)
end

QuickActions.QUICK_ACTION_FEED_BIRD.stringfn = function(item)
    return "Feed (" .. GetDisplayName(item) .. ")"
end

QuickActions.QUICK_ACTION_IMPRISON_BIRD.fn = function(target)
    return target.prefab == "birdcage"
       and not target:HasTag("trader")
end

QuickActions.QUICK_ACTION_IMPRISON_BIRD.stringfn = function(item)
    return "Imprison (" .. item.name .. ")"
end

QuickActions.QUICK_ACTION_KLAUS_SACK.fn = function(target)
    return target:HasTag("klaussacklock")
end

QuickActions.QUICK_ACTION_ATRIUM_GATE.fn = function(target)
    return target.prefab == "atrium_gate"
end

QuickActions.QUICK_ACTION_WAKEUP_BIRD.fn = function(target)
    return target.prefab == "birdcage"
       and target:HasTag("trader")
       and IsSleeping(target)
end

QuickActions.QUICK_ACTION_WAKEUP_BIRD.stringfn = function()
    return "Wakeup"
end

if GetModConfigData("QUICK_ACTION_TRAP", MOD_EQUIPMENT_CONTROL.MODNAME) == 2 then
    QuickActions.QUICK_ACTION_TRAP.fn = function(target)
        return target:HasTag("trap")
    end
else
    QuickActions.QUICK_ACTION_TRAP.fn = function(target)
        return target:HasTag("trapsprung")
    end
end

QuickActions.QUICK_ACTION_TRAP.stringfn = function()
    return "Reset"
end

QuickActions.QUICK_ACTION_DIRTPILE.fn = function(target)
    return target:HasTag("dirtpile")
end

QuickActions.QUICK_ACTION_DIRTPILE.stringfn = function()
    return "Track Animal"
end

QuickActions.QUICK_ACTION_BUILD_FOSSIL.fn = function(target)
    return target.prefab == "fossil_stalker"
       and target:HasTag("workrepairable")
end

QuickActions.QUICK_ACTION_BUILD_FOSSIL.stringfn = function()
    return "Build"
end

QuickActions.QUICK_ACTION_DIG.fn = function(target)
    return target:HasTag(ACTIONS.DIG.id .. "_workable")
end

QuickActions.QUICK_ACTION_HAMMER.fn = function(target)
    return target:HasTag(ACTIONS.HAMMER.id .. "_workable")
       and not IsExtinguishable(target)
       and not target:HasTag("campfire")
       and target.prefab ~= "birdcage"
end

QuickActions.QUICK_ACTION_NET.fn = function(target)
    return target:HasTag(ACTIONS.NET.id .. "_workable")
end

QuickActions.QUICK_ACTION_SLURTLEHOLE.fn = function(target)
    return target.prefab == "slurtlehole"
end

QuickActions.QUICK_ACTION_SLURTLEHOLE.stringfn = function(item)
    return "Light (" .. item.name .. ")"
end

QuickActions.QUICK_ACTION_EXTINGUISH.fn = IsExtinguishable

QuickActions.QUICK_ACTION_EXTINGUISH.stringfn = function(item)
    return "Extinguish (" .. item.name .. ")"
end

-- @TODO Move this logic
for config in pairs(QuickActions) do
    if not GetModConfigData(config, MOD_EQUIPMENT_CONTROL.MODNAME) then
        QuickActions[config] = nil
    end
end

local function QuickActionFactory(self, target, quickAction)
    local item

    if quickAction.item then
        item = GetItemFromInventory(quickAction.item)

        if not item then
            return nil
        end
    elseif quickAction.itemfn then
        item = quickAction.itemfn(target)

        if not item then
            return nil
        end
    elseif quickAction.toolaction then
        item = GetToolFromInventory(quickAction.toolaction)

        if not item then
            return nil
        end
    end

    local act

    if item then
        if item:HasTag("_equippable") then
            act = self:GetEquippedItemActions(target, item, quickAction.rmb or item.prefab == "waterballoon")[1]
        else
            act = self:GetUseItemActions(target, item, quickAction.rmb)[1]
        end
    else
        act = self:GetSceneActions(target)[1]
    end

    if not act then
        return nil
    end

    local buffAction = BufferedAction(self.inst, target, act.action, item)
    
    if quickAction.stringfn then
        buffAction.GetActionString = function()
            return quickAction.stringfn(item)
        end
    end

    buffAction.modaction = quickAction.modaction

    return buffAction
end

local function GetQuickAction(self, target)
    local ret

    for _, quickAction in pairs(QuickActions) do
        if quickAction.fn(target) then
            ret = QuickActionFactory(self, target, quickAction)

            if ret then
                return ret
            end
        end
    end

    return nil
end

local function GetRMBOverride(self, position, target)
    if InventoryFunctions:IsHeavyLifting() then
        return nil
    end

    local isaoetargeting = false
    local wantsaoetargeting = false

    if position == nil and not self.inst.replica.inventory:GetActiveItem() then
        isaoetargeting = self.inst.components.playercontroller:IsAOETargeting()
        wantsaoetargeting = not isaoetargeting and self.inst.components.playercontroller:HasAOETargeting()

        if target == nil and not isaoetargeting then
            target = TheInput:GetWorldEntityUnderMouse()
        end
        position = isaoetargeting and self.inst.components.playercontroller:GetAOETargetingPos() or TheInput:GetWorldPosition()

        local cansee
        if target == nil then
            local x, y, z = position:Get()
            cansee = CanEntitySeePoint(self.inst, x, y, z)
        else
            cansee = target == self.inst or CanEntitySeeTarget(self.inst, target)
        end

        if cansee and target then
            local rmb_override = GetQuickAction(self, target)

            if rmb_override then
                return rmb_override
            end
        end
    end

    return nil
end

local ModActions = {}

function ModActions.SceneUse(self, act)
    if self.locomotor == nil then
        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
    else
        act.preview_cb = function()
            SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
        end
    end

    self:DoAction(act)
end

function ModActions.Reset(self, act)
    local position = TheInput:GetWorldPosition()

    if self.locomotor == nil then
        SendRPCToServer(
            RPC.LeftClick,
            act.action.code,
            position.x,
            position.z,
            act.target
        )
    else
        act.preview_cb = function()
            SendRPCToServer(
                RPC.LeftClick,
                act.action.code,
                position.x,
                position.z,
                act.target
            )
        end
    end

    local function callback(inst, data)
        OnGetTrapEvent(inst, data, act.target)
    end

    local pos = act.target:GetPosition()
    local function callback2(inst, data)
        OnTrapActiveItem(inst, act.modaction, data, act.target, pos)
    end

    self.inst.components.eventtracker:AddEvent(
        "gotnewitem",
        "OnGetTrapEvent",
        callback
    )

    self.inst.components.eventtracker:AddEvent(
        "newactiveitem",
        act.modaction,
        callback2
    )

    self:DoAction(act)
end

function ModActions.WakeUp(self, act)
    local position = TheInput:GetWorldPosition()

    if self.locomotor == nil then
        SendRPCToServer(
            RPC.LeftClick,
            act.action.code,
            position.x,
            position.z,
            act.target
        )
    else
        act.preview_cb = function()
            SendRPCToServer(
                RPC.LeftClick,
                act.action.code,
                position.x,
                position.z,
                act.target
            )
        end
    end

    local function callback(inst, data)
        OnGetBirdEvent(inst, data, act.target)
    end

    self.inst.components.eventtracker:AddEvent(
        "gotnewitem",
        "OnGetBirdEvent",
        callback
    )

    self:DoAction(act)
end

local function IsWalkButtonDown()
    return TheInput:IsControlPressed(CONTROL_MOVE_UP)
        or TheInput:IsControlPressed(CONTROL_MOVE_DOWN)
        or TheInput:IsControlPressed(CONTROL_MOVE_LEFT)
        or TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)
end

function ModActions.Track(self, act)
    if IsWalkButtonDown() then
        return
    end

    KillThreadsWithID("TrackingThread")
    DoTracking()
end

function ModActions.ToolAction(self, act)
    if not InventoryFunctions:EquipHasTag(act.action.id .. "_tool") then
        InventoryFunctions:Equip(act.invobject)
    end

    local rpc = act.action.rmb and RPC.RightClick or RPC.LeftClick
    local position = TheInput:GetWorldPosition()

    if self.locomotor == nil then
        SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, nil, nil, act.action.canforce)
    else
        act.preview_cb = function()
            SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target)
        end
    end

    self:DoAction(act)
end

function ModActions.Ignite(self, act)
    if self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= act.invobject then
        InventoryFunctions:Equip(act.invobject)
    end

    if act.invobject:HasTag("rangedlighter") then
        act.action = ACTIONS.ATTACK
    end

    local position = TheInput:GetWorldPosition()

    self.inst:DoTaskInTime(FRAMES * 4, function()
        if self.locomotor == nil then
            SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, act.target)
        else
            act.preview_cb = function()
                SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, act.target)
            end
        end

        self:DoAction(act)
    end)
end

function ModActions.BuildFossil(self, act)
    if self.locomotor == nil then
        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
    else
        act.preview_cb = function()
            SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
        end
    end

    local function callback(inst, data)
        OnBuildFossil(inst, data, act.target)
    end

    self.inst.components.eventtracker:AddEvent(
        "stacksizechange",
        "OnBuildFossil",
        callback
    )

    self:DoAction(act)
end

function ModActions.Extinguish(self, act)
    if not act.invobject:HasTag("_equippable") then
        if self.locomotor == nil then
            SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
        else
            act.preview_cb = function()
                SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
            end
        end

        self:DoAction(act)
        return
    end

    if self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= act.invobject then
        InventoryFunctions:Equip(act.invobject)
    end

    local rpc = act.action.rmb and RPC.RightClick or RPC.LeftClick
    local position = TheInput:GetWorldPosition()

    self.inst:DoTaskInTime(FRAMES * 4, function()
        if self.locomotor == nil then
            SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, nil, nil, act.action.canforce)
        else
            act.preview_cb = function()
                SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, rpc == RPC.LeftClick)
            end
        end
        self:DoAction(act)
    end)
end

local CanOverride =
{
    [ACTIONS.LOOKAT] = true,
    [ACTIONS.WALKTO] = true,
}

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller
    local PlayerActionPicker = ThePlayer and ThePlayer.components.playeractionpicker

    if not PlayerController or not PlayerActionPicker then
        return
    end

    local OldOnRightClick = PlayerController.OnRightClick
    function PlayerController:OnRightClick(down)
        if not down then
            OldOnRightClick(self, down)
            return
        end

        local act = self:GetRightMouseAction()
        if act then
            local modAction = ModActions[act.modaction]

            if modAction then
                modAction(self, act)
                return
            end
        end

        OldOnRightClick(self, down)
    end

    -- 
    -- PlayerActionPicker Overrides
    -- 

    local OldDoGetMouseActions = PlayerActionPicker.DoGetMouseActions
    function PlayerActionPicker:DoGetMouseActions(...)
        local lmb, rmb = OldDoGetMouseActions(self, ...)

        if not rmb or CanOverride[rmb.action] then
            local rmb_override = GetRMBOverride(self, ...)

            if rmb_override then
                return lmb, rmb_override
            end
        end

        return lmb, rmb
    end
end

return Init
