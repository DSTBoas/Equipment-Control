local InventoryFunctions = require "util/inventoryfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local function IsEquipped(item)
    for _, equippedItem in pairs(InventoryFunctions:GetEquips()) do
        if equippedItem.prefab == item.prefab then
            return true
        end
    end

    return false
end

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller
    local PlayerActionPicker = ThePlayer and ThePlayer.components.playeractionpicker

    if not PlayerController or not PlayerActionPicker then
        return
    end

    local PlayerControllerOnLeftClick = PlayerController.OnLeftClick
    function PlayerController:OnLeftClick(down)
        if down and KeybindService:ValidateKeybind() and ThePlayer.components.playercontroller then
            local act = ThePlayer.components.playercontroller:GetLeftMouseAction()
            if act and act.MOD_AUTO_EQUIP then
                SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, act.MOD_AUTO_EQUIP)
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
            if target:HasTag(toolAction .. "_workable") then
                ret[#ret + 1] = toolAction .. "_tool"
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

        return ret
    end

    local PlayerActionPickerDoGetMouseActions = PlayerActionPicker.DoGetMouseActions
    function PlayerActionPicker:DoGetMouseActions(...)
        local ent = TheInput:GetWorldEntityUnderMouse()
        if ent and CanEntitySeeTarget(self.inst, ent) and not InventoryFunctions:GetActiveItem() then
            local tools = GetTools(ent)
            for _, tool in pairs(tools) do
                if not IsEquipped(tool) then
                    local lmboverride = self:GetEquippedItemActions(ent, tool)

                    lmboverride = lmboverride and lmboverride[1]

                    if lmboverride then
                        lmboverride.MOD_AUTO_EQUIP = tool
                    end

                    return lmboverride, nil
                end
            end
        end

        return PlayerActionPickerDoGetMouseActions(self, ...)
    end
end

return Init
