local InventoryFunctions = require "util/inventoryfunctions"
local ItemFunctions = require "util/itemfunctions"

local Events = {}

local function AddEvent(self, event, n, callback)
    self.inst:ListenForEvent(event, callback)

    if not Events[n] then
        Events[n] = {}
    end

    Events[n][#Events[n] + 1] =
    {
        event = event,
        eventfn = callback
    }
end

local function DetachEvent(self, n)
    if Events[n] then
        for _, eventData in pairs(Events[n]) do
            self.inst:RemoveEventCallback(
                eventData.event,
                eventData.eventfn
            )
        end
        Events[n] = nil
    end
end

-- 
-- Events
-- 

local function OnGetBirdEvent(self, modaction, item, target)
    if item:HasTag("bird") then
        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, ACTIONS.STORE.code, item, target)
        DetachEvent(self, modaction)
    end
end

local function IsValidData(data, trap)
    return data
       and data.src_pos
       and data.slot
       and data.item == trap
end

local function GetContainerFromSlot(slot, item, ...)
    for _, container in ipairs({...}) do
        if container:GetItemInSlot(slot) == item then
            return container
        end
    end

    return nil
end

local function OnTrapActiveItem(self, modaction, data, trap, pos)
    if data and data.item and data.item == trap then
        if InventoryFunctions:HasFreeSlot() then
            SendRPCToServer(RPC.LeftClick, ACTIONS.DROP.code, pos.x, pos.z)
        else
            self.inst:DoTaskInTime(FRAMES * 3, function()
                SendRPCToServer(RPC.LeftClick, ACTIONS.DROP.code, pos.x, pos.z)
            end)
        end

        DetachEvent(self, modaction)
    end
end

local function OnGetTrapEvent(self, modaction, data, trap)
    if IsValidData(data, trap) then
        local container = GetContainerFromSlot(data.slot, trap, InventoryFunctions:GetInventory(), InventoryFunctions:GetBackpack())

        if container then
            SendRPCToServer(RPC.TakeActiveItemFromAllOfSlot, data.slot, container ~= self.inst.replica.inventory and container.inst)
        end
    end
end

-- 
--  QuickActions Logic
-- 

local QuickActions = {}

local function GetQuickAction(self, target)
    for i = 1, #QuickActions do
        if QuickActions[i].triggerfn(target) then
            return QuickActions[i].actionfn(self, target)
        end
    end

    return nil
end

local CannotOverrideActions =
{
    [ACTIONS.HAMMER] = true;
}

local function ModDoGetMouseActions(self, position, target)
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
            local rmb = not wantsaoetargeting and self:GetRightClickActions(position, target)[1] or nil

            if rmb and not CannotOverrideActions[rmb.action] then
                local rmb_override = GetQuickAction(self, target)

                if rmb_override then
                    local lmb = not isaoetargeting and self:GetLeftClickActions(position, target)[1] or nil
                    return lmb, rmb_override
                end
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

local function IsCompatibleFuel(target, item)
    return item:HasTag("BURNABLE_fuel")
       and not (item:HasTag("deployedplant") and item.prefab ~= "pinecone")
        or target:HasTag("blueflame")
       and item:HasTag("CHEMICAL_fuel")
end

local function GetFuelAction(target)
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if IsCompatibleFuel(target, item) then
            return item, item:GetIsWet() and ACTIONS.ADDWETFUEL
                or ACTIONS.ADDFUEL
        end
    end
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
        priority = 4 - (ItemFunctions:GetHungerValue() * 0.01)
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

local function GetExtinguishItem()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory(true)) do
        if item:HasTag("repairer") and item:HasTag("frozen") or item:HasTag("extinguisher") or item.prefab == "waterballoon" then
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

-- 
-- QuickActions Triggers
-- 

local function IsDigWorkable(target)
    return target:HasTag(ACTIONS.DIG.id .. "_workable")
end

local function IsHammerWorkable(target)
    return target:HasTag(ACTIONS.HAMMER.id .. "_workable")
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

local function IsValidBirdcage(target)
    return target.prefab == "birdcage"
       and target:HasTag("trader")
end

local function BirdTraderValid(target)
    return IsValidBirdcage(target)
       and not IsSleeping(target)
end

local function IsBirdcageSleeping(target)
    return IsValidBirdcage(target)
       and IsSleeping(target)
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

local function CampfireQuickAction(self, target)
    local fuel, fuelAction = GetFuelAction(target)

    if fuel then
        local action = BufferedAction(self.inst, target, fuelAction, fuel)

        action.GetActionString = function()
            return "Add Fuel (" .. fuel.name .. ")"
        end

        action.modaction = "scenegive"

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

local function FeedBirdcageQuickAction(self, target)
    local food = GetBirdFood()

    if food then
        local action = BufferedAction(self.inst, target, ACTIONS.GIVE, food)

        action.GetActionString = function()
            return "Feed (" .. GetDisplayName(food) .. ")"
        end

        action.modaction = "scenegive"

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

        action.modaction = "scenegive"

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
AddQuickAction("QUICK_ACTION_BIRD_CAGE", BirdTraderValid, FeedBirdcageQuickAction)
AddQuickAction("QUICK_ACTION_WALLS", IsRepairableWall, RepairWallQuickAction)
AddQuickAction("QUICK_ACTION_EXTINGUISH", IsExtinguishable, ExtinguishQuickAction)
AddQuickAction("QUICK_ACTION_SLURTLEHOLE", IsSnurtleMound, LightQuickAction)
AddQuickAction("QUICK_ACTION_WAKEUP_BIRD", IsBirdcageSleeping, WakeupQuickAction)
AddQuickAction("QUICK_ACTION_DIG", IsDigWorkable, DigQuickAction)
AddQuickAction("QUICK_ACTION_HAMMER", IsHammerWorkable, HammerQuickAction)
AddQuickAction("QUICK_ACTION_NET", IsNetWorkable, CatchQuickAction)

local IsCancelControl =
{
    [CONTROL_PRIMARY] = true,
    [CONTROL_SECONDARY] = true,
    [CONTROL_ATTACK] = true,
    [CONTROL_ACTION] = true,

    [CONTROL_MOVE_UP] = true,
    [CONTROL_MOVE_DOWN] = true,
    [CONTROL_MOVE_LEFT] = true,
    [CONTROL_MOVE_RIGHT] = true,
}

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller
    local PlayerActionPicker = ThePlayer and ThePlayer.components.playeractionpicker

    if not PlayerController or not PlayerActionPicker then
        return
    end

    local PlayerControllerOnControl = PlayerController.OnControl
    function PlayerController:OnControl(control, down)
        if down and IsCancelControl[control] then
            for modevent in pairs(Events) do
                DetachEvent(self, modevent)
            end
        end
        PlayerControllerOnControl(self, control, down)
    end

    local OldOnRightClick = PlayerController.OnRightClick
    function PlayerController:OnRightClick(down)
        if not (self:UsingMouse() and down) then
            OldOnRightClick(self, down)
            return
        end

        local act = self:GetRightMouseAction()
        if act and act.modaction then
            if act.modaction == "toolaction" then
                if not InventoryFunctions:EquipHasTag(act.action.id .. "_tool") then
                    SendRPCToServer(RPC.EquipActionItem, act.invobject)
                end

                local position = TheInput:GetWorldPosition()
                local rpc = act.modlmb and RPC.LeftClick or RPC.RightClick

                if self:CanLocomote() then
                    act.preview_cb = function()
                        SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, nil, nil, rpc == RPC.LeftClick, nil, nil, false)
                    end
                else
                    SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, nil, nil, rpc == RPC.LeftClick, nil, nil, false)
                end

                self:DoAction(act)
                return
            elseif act.modaction == "scenegive" then
                if self:CanLocomote() then
                    act.preview_cb = function()
                        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                    end
                else
                    SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                end
                self:DoAction(act)
                return
            elseif act.modaction == "ignite" and act.invobject and act.target then
                if self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= act.invobject then
                    SendRPCToServer(RPC.EquipActionItem, act.invobject)
                end

                if act.invobject:HasTag("rangedlighter") then
                    act.action = ACTIONS.ATTACK
                end

                local position = TheInput:GetWorldPosition()

                self.inst:DoTaskInTime(FRAMES * 4, function()
                    if self:CanLocomote() then
                        act.preview_cb = function()
                            SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, act.target)
                        end
                    else
                        SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, act.target)
                    end

                    self:DoAction(act)
                    return
                end)
                return
            elseif act.modaction == "extinguish" and act.invobject and act.target then
                if act.invobject:HasTag("_equippable") then
                    if self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= act.invobject then
                        SendRPCToServer(RPC.EquipActionItem, act.invobject)
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
                        if self:CanLocomote() then
                            -- Some predict walking jazz
                            act.preview_cb = function()
                                SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target)
                            end
                        else
                            SendRPCToServer(rpc, act.action.code, position.x, position.z, act.target, nil, nil, attack, nil, nil, false)
                            SendRPCToServer(RPC.StopControl, CONTROL_PRIMARY)
                        end

                        act.modaction = nil

                        self:DoAction(act)
                        return
                    end)
                    return
                else
                    act.action = act.target:HasTag("fire") and ACTIONS.MANUALEXTINGUISH or ACTIONS.SMOTHER
                    if self:CanLocomote() then
                        act.preview_cb = function()
                            SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                        end
                    else
                        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, act.invobject, act.target)
                    end
                end
                self:DoAction(act)
                return
            elseif act.modaction == "wakeup" then
                DetachEvent(self, act.modaction)

                local position = TheInput:GetWorldPosition()

                if self:CanLocomote() then
                    act.preview_cb = function()
                        SendRPCToServer(
                            RPC.LeftClick,
                            act.action.code,
                            position.x,
                            position.z,
                            act.target
                        )
                    end
                else
                    SendRPCToServer(
                        RPC.LeftClick,
                        act.action.code,
                        position.x,
                        position.z,
                        act.target
                    )
                end

                local function callback(_, data)
                    if data.item then
                        OnGetBirdEvent(self, act.modaction, data.item, act.target)
                    end
                end

                AddEvent(self, "gotnewitem", act.modaction, callback)
                self:DoAction(act)
                return
            elseif act.modaction == "reset" then
                DetachEvent(self, act.modaction)

                local position = TheInput:GetWorldPosition()

                if self:CanLocomote() then
                    act.preview_cb = function()
                        SendRPCToServer(
                            RPC.LeftClick,
                            act.action.code,
                            position.x,
                            position.z,
                            act.target
                        )
                    end
                else
                    SendRPCToServer(
                        RPC.LeftClick,
                        act.action.code,
                        position.x,
                        position.z,
                        act.target
                    )
                end

                local function callback(_, data)
                    OnGetTrapEvent(self, act.modaction, data, act.target)
                end

                local pos = act.target:GetPosition()
                local function callback2(_, data)
                    OnTrapActiveItem(self, act.modaction, data, act.target, pos)
                end

                AddEvent(self, "gotnewitem", act.modaction, callback)
                AddEvent(self, "newactiveitem", act.modaction, callback2)
                self:DoAction(act)
                return
            end
        end

        OldOnRightClick(self, down)
    end

    -- 
    -- PlayerActionPicker Overrides
    -- 

    local OldDoGetMouseActions = PlayerActionPicker.DoGetMouseActions
    function PlayerActionPicker:DoGetMouseActions(position, target)
        local _, rmb_override = ModDoGetMouseActions(self, position, target)

        if rmb_override then
            return _, rmb_override
        end

        return OldDoGetMouseActions(self, position, target)
    end
end

return Init
