local InventoryFunctions = require "util/inventoryfunctions"
local ItemFunctions = require "util/itemfunctions"

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
        if InventoryFunctions:HasFreeSlot() then
            SendRPCToServer(RPC.LeftClick, ACTIONS.DROP.code, pos.x, pos.z)
        else
            inst:DoTaskInTime(FRAMES * 3, function()
                SendRPCToServer(RPC.LeftClick, ACTIONS.DROP.code, pos.x, pos.z)
            end)
        end
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

local function OnGetTrapEvent(inst, data, trap)
    if data and data.item == trap then
        local container = GetContainerFromSlot(data.slot, trap, InventoryFunctions:GetInventory(), InventoryFunctions:GetBackpack())

        if container then
            SendRPCToServer(RPC.TakeActiveItemFromAllOfSlot, data.slot, container ~= inst.replica.inventory and container.inst)
        end
    end

    inst.components.eventtracker:DetachEvent("OnGetTrapEvent")
end


local function OnBuildFossil(inst, data, target)
    if data and data.item and data.item.prefab == "fossil_piece" and target:HasTag("workrepairable") then
        local act = BufferedAction(inst, target, ACTIONS.REPAIR, data.item)

        if ThePlayer.components.locomotor == nil then
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

-- 
--  QuickActions Logic
-- 

local QuickActions = {}

local function GetQuickAction(self, target)
    local action = nil
    for i = 1, #QuickActions do
        if QuickActions[i].triggerfn(target) then
            action = QuickActions[i].actionfn(self, target)
            if action then
                return action
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

--
-- AddQuickAction
--

local function AddQuickAction(config, triggerfn, actionfn)
    if GetModConfigData(config, MOD_EQUIPMENT_CONTROL.MODNAME) then
        QuickActions[#QuickActions + 1] =
        {
            triggerfn = triggerfn,
            actionfn = actionfn,
        }
    end
end

--
-- QuickActions Helpers
--

local IgnoredFuels =
{
    blueprint = true,
    waxwelljournal = true,
}

local function IsCompatibleFuel(target, item)
    return item:HasTag("BURNABLE_fuel")
       and not IgnoredFuels[item.prefab]
       and not item:HasTag("_equippable")
       and not item:HasTag("repairer")
       and not (item:HasTag("deployable") and item.prefab ~= "pinecone")
        or target:HasTag("blueflame")
       and item:HasTag("CHEMICAL_fuel")
end

local function GetActionFromFuel(item)
    return item:GetIsWet() and ACTIONS.ADDWETFUEL
        or ACTIONS.ADDFUEL
end

local function GetFuelAndAction(target)
    local ret = {}

    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if IsCompatibleFuel(target, item) then
            ret[#ret + 1] = item
            if item.prefab == PREFERRED_CAMPFIRE_FUEL then
                return item, GetActionFromFuel(item)
            end
        end
    end

    if ret[1] then
        return ret[1], GetActionFromFuel(ret[1])
    end

    return nil
end

local function GetRazor()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item.prefab == "razor" then
            return item
        end
    end

    return nil
end

local invalid_foods =
{
    "bird_egg",
    "rottenegg",
    "monstermeat",
    -- "cookedmonstermeat",
    -- "monstermeat_dried",
}

local function GetEggPriority(item)
    local priority = 0

    if item:HasTag("spoiled") then
        priority = 4 - (ItemFunctions:GetHunger(item) * 0.01)
    elseif item:HasTag("monstermeat") then
        priority = 3
    elseif item:HasTag("badfood") then
        priority = 2.5
    elseif item:HasTag("preparedfood") then
        priority = item:HasTag("stale") and 1
                   or .5
    elseif item:HasTag("stale") then
        priority = 1.5
    elseif item.prefab == "bird_egg_cooked" then
        priority = 1.6
    end

    return priority
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

local function GetIgniteItem()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory(true)) do
        if item:HasTag("lighter") or item:HasTag("rangedlighter") then
            return item
        end
    end

    return nil
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

local function GetAtriumKey()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item.prefab == "atrium_key" then
            return item
        end
    end

    return nil
end

local function GetFossilPiece()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag("work_fossil") then
            return item
        end
    end

    return nil
end

local function GetBoatPatch()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag("boat_patch") then
            return item
        end
    end

    return nil
end

-- 
-- QuickActions Triggers
-- 

local function IsDigWorkable(target)
    return target:HasTag(ACTIONS.DIG.id .. "_workable")
end

local function IsHammerWorkable(target)
    return target:HasTag(ACTIONS.HAMMER.id .. "_workable")
       and not target:HasTag("campfire")
       and not target.prefab == "birdcage"
end

local function IsNetWorkable(target)
    return target:HasTag(ACTIONS.NET.id .. "_workable")
end

local function IsHighFire(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fire = (TheSim:FindEntities(x, y, z, .5, {"HASHEATER", "fx"}))[1]

    return fire
       and fire.AnimState
       and fire.AnimState:IsCurrentAnimation("level4")
end

local function IsCampfire(target)
    return target:HasTag("campfire")
       and not IsHighFire(target)
end

local function IsSnurtleMound(target)
    return target.prefab == "slurtlehole"
end

local function IsExtinguishable(target)
    return not target:HasTag("campfire")
       and (target:HasTag("fire") or target:HasTag("smolder"))
end

local function IsRepairableWall(target)
    return target:HasTag("wall")
       and not (target.AnimState:IsCurrentAnimation("fullA")
                or target.AnimState:IsCurrentAnimation("fullB")
                or target.AnimState:IsCurrentAnimation("fullC")
                or IsExtinguishable(target))
end

local function IsTrapSprung(target)
    return target:HasTag("trapsprung")
end

local function IsSleeping(target)
    return target.AnimState:IsCurrentAnimation("sleep_pre")
        or target.AnimState:IsCurrentAnimation("sleep_loop")
        or target.AnimState:IsCurrentAnimation("sleep_pst")
end

local function HasHair(target)
    return target:HasTag("beefalo")
       and IsSleeping(target)
       and target.AnimState:GetBuild() ~= "beefalo_shaved_build"
end

local function IsValidBirdcage(target)
    return target.prefab == "birdcage"
       and target:HasTag("trader")
end

local function BirdTraderValid(target)
    return IsValidBirdcage(target)
       and not IsSleeping(target)
end

local function IsBirdcageEmpty(target)
    return target.prefab == "birdcage"
       and not target:HasTag("trader")
end

local function IsBirdcageSleeping(target)
    return IsValidBirdcage(target)
       and IsSleeping(target)
end

local function IsKlausSack(target)
    return target:HasTag("klaussacklock")
end

local function IsFossilStructure(target)
    return target.prefab == "fossil_stalker"
       and target:HasTag("workrepairable")
end

local function IsAtriumGate(target)
    return target.prefab == "atrium_gate"
end

local function IsBoatLeak(target)
    return target:HasTag("boat_leak")
end

-- 
-- QuickActions
--

local function CatchQuickAction(self, target)
    local tool = GetToolFromInventory(ACTIONS.NET)

    if tool then
        local action = BufferedAction(self.inst, target, ACTIONS.NET, tool)

        action.modlmb = true
        action.modaction = "toolaction"

        return action
    end

    return nil
end

local function DigQuickAction(self, target)
    local tool = GetToolFromInventory(ACTIONS.DIG)

    if tool then
        local action = BufferedAction(self.inst, target, ACTIONS.DIG, tool)

        action.modaction = "toolaction"

        return action
    end

    return nil
end

local function HammerQuickAction(self, target)
    local tool = GetToolFromInventory(ACTIONS.HAMMER)

    if tool then
        local action = BufferedAction(self.inst, target, ACTIONS.HAMMER, tool)

        action.modaction = "toolaction"

        return action
    end

    return nil
end

local function RepairBoatQuickAction(self, target)
    local patch = GetBoatPatch()

    if patch then
        local action = BufferedAction(self.inst, target, ACTIONS.REPAIR_LEAK, patch)

        action.modaction = "sceneuse"

        return action
    end

    return nil
end

local function CampfireQuickAction(self, target)
    local fuel, fuelAct = GetFuelAndAction(target)

    if fuel then
        local action = BufferedAction(self.inst, target, fuelAct, fuel)

        action.GetActionString = function()
            return "Add Fuel (" .. fuel.name .. ")"
        end

        action.modaction = "sceneuse"

        return action
    end

    return nil
end

local function ResetTrapQuickAction(self, target)
    local action = BufferedAction(self.inst, target, ACTIONS.CHECKTRAP)

    action.GetActionString = function()
        return "Reset"
    end

    action.modaction = "reset"

    return action
end

local function BeefaloQuickAction(self, target)
    local razor = GetRazor()

    if razor then
        local action = BufferedAction(self.inst, target, ACTIONS.SHAVE, razor)

        action.modaction = "sceneuse"

        return action
    end

    return nil
end

local function SocketKeyQuickAction(self, target)
    local key = GetAtriumKey()

    if key then
        local action = BufferedAction(self.inst, target, ACTIONS.GIVE, key)

        action.modaction = "sceneuse"

        return action
    end

    return nil
end

local function KlausSackQuickAction(self, target)
    local key = GetKlausSackKey()

    if key then
        local action = BufferedAction(self.inst, target, ACTIONS.USEKLAUSSACKKEY, key)

        action.modaction = "sceneuse"

        return action
    end

    return nil
end

local function BuildFossilQuickAction(self, target)
    local fossil_piece = GetFossilPiece()

    if fossil_piece then
        local action = BufferedAction(self.inst, target, ACTIONS.REPAIR, fossil_piece)

        action.GetActionString = function()
            return "Build"
        end

        action.modaction = "fossil_build"

        return action
    end

    return nil
end

local function FeedBirdcageQuickAction(self, target)
    local food = GetBirdFood()

    if food then
        local action = BufferedAction(self.inst, target, ACTIONS.GIVE, food)

        action.GetActionString = function()
            return "Feed (" .. GetDisplayName(food) .. ")"
        end

        action.modaction = "sceneuse"

        return action
    end

    return nil
end

local function ImprisonQuickAction(self, target)
    local bird = GetBird()

    if bird then
        local action = BufferedAction(self.inst, target, ACTIONS.STORE, bird)

        action.GetActionString = function()
            return "Imprison (" .. bird.name .. ")"
        end

        action.modaction = "sceneuse"

        return action
    end

    return nil
end

local function RepairWallQuickAction(self, target)
    local repairItem = GetRepairItem(target)

    if repairItem then
        local action = BufferedAction(self.inst, target, ACTIONS.REPAIR, repairItem)

        action.GetActionString = function()
            return "Repair (" .. repairItem.name .. ")"
        end

        action.modaction = "sceneuse"

        return action
    end

    return nil
end

local function ExtinguishQuickAction(self, target)
    local extinguishItem = GetExtinguishItem()

    if extinguishItem then
        local action = BufferedAction(self.inst, target, ACTIONS.MANUALEXTINGUISH, extinguishItem)

        action.GetActionString = function()
            return "Extinguish (" .. extinguishItem.name .. ")"
        end

        action.modaction = "extinguish"

        return action
    end

    return nil
end

local function LightQuickAction(self, target)
    local igniteItem = GetIgniteItem()

    if igniteItem then
        local action = BufferedAction(self.inst, target, ACTIONS.LIGHT, igniteItem)

        action.GetActionString = function()
            return "Light (" .. igniteItem.name .. ")"
        end

        action.modaction = "ignite"

        return action
    end

    return nil
end

local function WakeupQuickAction(self, target)
    local action = BufferedAction(self.inst, target, ACTIONS.HARVEST)

    action.GetActionString = function()
        return "Wakeup"
    end

    action.modaction = "wakeup"

    return action
end

-- 
-- Add QuickActions
-- 

AddQuickAction("QUICK_ACTION_CAMPFIRE", IsCampfire, CampfireQuickAction)
AddQuickAction("QUICK_ACTION_TRAP", IsTrapSprung, ResetTrapQuickAction)
AddQuickAction("QUICK_ACTION_BEEFALO", HasHair, BeefaloQuickAction)
AddQuickAction("QUICK_ACTION_WALLS", IsRepairableWall, RepairWallQuickAction)
AddQuickAction("QUICK_ACTION_EXTINGUISH", IsExtinguishable, ExtinguishQuickAction)
AddQuickAction("QUICK_ACTION_SLURTLEHOLE", IsSnurtleMound, LightQuickAction)
AddQuickAction("QUICK_ACTION_FEED_BIRD", BirdTraderValid, FeedBirdcageQuickAction)
AddQuickAction("QUICK_ACTION_WAKEUP_BIRD", IsBirdcageSleeping, WakeupQuickAction)
AddQuickAction("QUICK_ACTION_IMPRISON_BIRD", IsBirdcageEmpty, ImprisonQuickAction)
AddQuickAction("QUICK_ACTION_BUILD_FOSSIL", IsFossilStructure, BuildFossilQuickAction)
AddQuickAction("QUICK_ACTION_DIG", IsDigWorkable, DigQuickAction)
AddQuickAction("QUICK_ACTION_HAMMER", IsHammerWorkable, HammerQuickAction)
AddQuickAction("QUICK_ACTION_NET", IsNetWorkable, CatchQuickAction)
AddQuickAction("QUICK_ACTION_KLAUS_SACK", IsKlausSack, KlausSackQuickAction)
AddQuickAction("QUICK_ACTION_ATRIUM_GATE", IsAtriumGate, SocketKeyQuickAction)
AddQuickAction("QUICK_ACTION_REPAIR_BOAT", IsBoatLeak, RepairBoatQuickAction)

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller
    local PlayerActionPicker = ThePlayer and ThePlayer.components.playeractionpicker

    if not PlayerController or not PlayerActionPicker then
        return
    end

    local OldOnRightClick = PlayerController.OnRightClick
    function PlayerController:OnRightClick(down)
        if not (self:UsingMouse() and down) then
            OldOnRightClick(self, down)
            return
        end

        local act = self:GetRightMouseAction()
        if act and act.modaction then
            if act.modaction == "fossil_build" then
                if ThePlayer.components.locomotor == nil then
                    SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                else
                    act.preview_cb = function()
                        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                    end
                end

                local function callback(inst, data)
                    OnBuildFossil(inst, data, act.target)
                end

                ThePlayer.components.eventtracker:AddEvent(
                    "stacksizechange",
                    "OnBuildFossil",
                    callback
                )

                self:DoAction(act)
                return
            elseif act.modaction == "toolaction" then
                if not InventoryFunctions:EquipHasTag(act.action.id .. "_tool") then
                    InventoryFunctions:Equip(act.invobject)
                end

                local position = TheInput:GetWorldPosition()
                local rpc = act.modlmb and RPC.LeftClick or RPC.RightClick

                if ThePlayer.components.locomotor == nil then
                    SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, nil, nil, rpc == RPC.LeftClick, nil, nil, false)
                else
                    act.preview_cb = function()
                        SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, nil, nil, rpc == RPC.LeftClick, nil, nil, false)
                    end
                end

                self:DoAction(act)
                return
            elseif act.modaction == "sceneuse" then
                if ThePlayer.components.locomotor == nil then
                    SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                else
                    act.preview_cb = function()
                        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                    end
                end
                self:DoAction(act)
                return
            elseif act.modaction == "ignite" and act.invobject and act.target then
                if self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= act.invobject then
                    InventoryFunctions:Equip(act.invobject)
                end

                if act.invobject:HasTag("rangedlighter") then
                    act.action = ACTIONS.ATTACK
                end

                local position = TheInput:GetWorldPosition()

                self.inst:DoTaskInTime(FRAMES * 4, function()
                    if ThePlayer.components.locomotor == nil then
                        SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, act.target)
                    else
                        act.preview_cb = function()
                            SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, act.target)
                        end
                    end

                    self:DoAction(act)
                    return
                end)
                return
            elseif act.modaction == "extinguish" and act.invobject and act.target then
                if act.invobject:HasTag("_equippable") then
                    if self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= act.invobject then
                        InventoryFunctions:Equip(act.invobject)
                    end

                    local position = TheInput:GetWorldPosition()
                    local rpc = RPC.LeftClick
                    local attack = nil

                    if act.invobject.prefab == "waterballoon" then
                        rpc = RPC.RightClick
                        act = BufferedAction(self.inst, act.target, ACTIONS.TOSS, nil, position)
                    else
                        attack = true
                        act = BufferedAction(self.inst, act.target, ACTIONS.ATTACK, nil, position)
                    end

                    self.inst:DoTaskInTime(FRAMES * 4, function()
                        if ThePlayer.components.locomotor == nil then
                            SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, nil, nil, attack, nil, nil, false)
                            SendRPCToServer(RPC.StopControl, CONTROL_PRIMARY)
                        else
                            -- Some predict walking jazz
                            act.preview_cb = function()
                                SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target)
                            end
                        end

                        self:DoAction(act)
                        return
                    end)
                    return
                else
                    act.action = act.target:HasTag("fire") and ACTIONS.MANUALEXTINGUISH or ACTIONS.SMOTHER
                    if ThePlayer.components.locomotor == nil then
                        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                    else
                        act.preview_cb = function()
                            SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                        end 
                    end
                end
                self:DoAction(act)
                return
            elseif act.modaction == "wakeup" then
                local position = TheInput:GetWorldPosition()

                if ThePlayer.components.locomotor == nil then
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

                ThePlayer.components.eventtracker:AddEvent(
                    "gotnewitem",
                    "OnGetBirdEvent",
                    callback
                )

                self:DoAction(act)
                return
            elseif act.modaction == "reset" then
                local position = TheInput:GetWorldPosition()

                if ThePlayer.components.locomotor == nil then
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

                ThePlayer.components.eventtracker:AddEvent(
                    "gotnewitem",
                    "OnGetTrapEvent",
                    callback
                )

                ThePlayer.components.eventtracker:AddEvent(
                    "newactiveitem",
                    act.modaction,
                    callback2
                )

                self:DoAction(act)
                return
            end
        end

        OldOnRightClick(self, down)
    end

    -- 
    -- PlayerActionPicker Overrides
    -- 

    local CanOverride =
    {
        [ACTIONS.LOOKAT] = true,
        [ACTIONS.WALKTO] = true,
    }

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
