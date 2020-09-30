local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local CRAFTING_ALLOWED = GetModConfigData("AUTO_EQUIP_TOOL", MOD_EQUIPMENT_CONTROL.MODNAME) == 2

local Axes =
{
    "goldenaxe",
    "axe",
}

local PickAxes =
{
    "goldenpickaxe",
    "pickaxe",
}

-- This is not the most elegant solution
-- @TODO redo this file @TAG CLEANUP, PERF
local ToolData =
{
    [ACTIONS.CHOP.id .. "_tool"] =
    {
        action = ACTIONS.CHOP,
        tools = Axes,
    },
    [ACTIONS.MINE.id .. "_tool"] =
    {
        action = ACTIONS.MINE,
        tools = PickAxes,
    },
}

local function GetCurrentAnimationLength()
    return ThePlayer
       and ThePlayer.AnimState
       and ThePlayer.AnimState:GetCurrentAnimationLength()
        or 0
end

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller
    local PlayerActionPicker = ThePlayer and ThePlayer.components.playeractionpicker

    if not PlayerController or not PlayerActionPicker then
        return
    end

    local PlayerControllerOnLeftClick = PlayerController.OnLeftClick
    function PlayerController:OnLeftClick(down)
        if down and ThePlayer.components.playercontroller then
            local act = ThePlayer.components.playercontroller:GetLeftMouseAction()
            if act then
                if act.MOD_AUTO_EQUIP then
                    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, act.MOD_AUTO_EQUIP)
                elseif act.HASTOCRAFT then
                    for _, prefab in pairs(ToolData[act.HASTOCRAFT].tools) do
                        if CraftFunctions:CanCraft(prefab) then
                            local target = TheInput:GetWorldEntityUnderMouse()
                            local position = TheInput:GetWorldPosition()

                            ThePlayer:StartThread(function()
                                self.inst:ClearBufferedAction()

                                CraftFunctions:Craft(prefab)

                                if not self:CanLocomote() then
                                    Sleep(FRAMES * 3)
                                end

                                 -- @TODO Might wanna use an event based trigger here @TAG PERF, REFACTOR
                                while CraftFunctions:IsCrafting() do
                                    Sleep(GetCurrentAnimationLength())
                                end

                                if not InventoryFunctions:EquipHasTag(act.HASTOCRAFT) then
                                    for _, item in pairs(InventoryFunctions:GetPlayerInventory(true)) do
                                        if item:HasTag(act.HASTOCRAFT) then
                                            SendRPCToServer(RPC.EquipActionItem, item)
                                            break
                                        end
                                    end
                                end

                                local hasTool = InventoryFunctions:EquipHasTag(act.HASTOCRAFT)

                                if hasTool then
                                    local act = BufferedAction(self.inst, target, ToolData[act.HASTOCRAFT].action)
                                    if self:CanLocomote() then
                                        act.preview_cb = function()
                                            SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, target)
                                        end
                                    else
                                        SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, target)
                                    end

                                    self:DoAction(act)
                                end
                            end)
                        end
                    end
                end
            end
        end

        -- Automagic control repeat
        if self:IsDoingOrWorking() then
            PlayerControllerOnLeftClick(self, true)
            return
        end

        PlayerControllerOnLeftClick(self, down)
    end

    local MODIFIED_TOOLACTIONS = {}

    for action, val in pairs(TOOLACTIONS) do
        if action ~= "NET" and action ~= "DIG" then
            MODIFIED_TOOLACTIONS[action] = val
        end
    end

    local function GetToolTags(target)
        local ret = {}

        for toolAction in pairs(MODIFIED_TOOLACTIONS) do
            if target:HasTag(toolAction .. "_workable") and not InventoryFunctions:EquipHasTag(toolAction .. "_tool") then
                ret[#ret + 1] = toolAction .. "_tool"
            end
        end

        return ret
    end

    local function CheckCanCraft(tags)
        local ret = {}

        for _, tag in pairs(tags) do
            if ToolData[tag] then
                for _, tool in pairs(ToolData[tag].tools) do
                    if CraftFunctions:CanCraft(tool) then
                        return {tag}
                    end
                end
            end
        end

        return ret
    end

    local function GetTools(target)
        local ret = {}

        local tags = GetToolTags(target)
        for _, invItem in pairs(InventoryFunctions:GetPlayerInventory()) do
            for _, tag in pairs(tags) do
                if invItem:HasTag(tag) then
                    ret[#ret + 1] = invItem
                end
            end
        end

        if CRAFTING_ALLOWED and #ret == 0 and #tags > 0 then
            return CheckCanCraft(tags), true
        end

        return ret
    end

    local function CreateBufferedAction(action, target)
        return BufferedAction(target, target, action)
    end

    local function GetToolActions(toolTag, target)
        for tag, data in pairs(ToolData) do
            if toolTag == tag then
                return {CreateBufferedAction(data.action, target)}
            end
        end
    end

    local FilteredActions =
    {
        [ACTIONS.WALKTO] = true,
        [ACTIONS.LOOKAT] = true,
    }

    local PlayerActionPickerDoGetMouseActions = PlayerActionPicker.DoGetMouseActions
    function PlayerActionPicker:DoGetMouseActions(...)
        local target = TheInput:GetWorldEntityUnderMouse()
        if target and CanEntitySeeTarget(self.inst, target) and not InventoryFunctions:GetActiveItem() then
            local tools, hasToCraft = GetTools(target)
            for _, tool in pairs(tools) do
                local lmboverride = not hasToCraft and self:GetEquippedItemActions(target, tool)
                                    or GetToolActions(tool, target)

                lmboverride = lmboverride and lmboverride[1]

                if lmboverride then
                    if not hasToCraft then
                        lmboverride.MOD_AUTO_EQUIP = tool
                    else
                        lmboverride.HASTOCRAFT = tool
                    end

                    local rmb = self:GetRightClickActions(TheInput:GetWorldPosition(), target)[1]

                    if rmb and FilteredActions[rmb.action] then 
                        rmb = nil
                    end

                    return lmboverride, rmb
                end
            end
        end

        return PlayerActionPickerDoGetMouseActions(self, ...)
    end
end

return Init
