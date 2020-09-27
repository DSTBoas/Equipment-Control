local InventoryFunctions = require "util/inventoryfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local Compatible =
{
    [ACTIONS.PICK] = true,
    [ACTIONS.PICKUP] = true,
    [ACTIONS.JUMPIN] = true,
    [ACTIONS.MIGRATE] = true,
}

local function CompatibleAction()
    local buffaction = ThePlayer.components.playercontroller:GetLeftMouseAction()

    return not buffaction
        or buffaction
       and Compatible[buffaction.action]
end

local AUTO_EQUIP_CANE = GetModConfigData("AUTO_EQUIP_CANE", MOD_EQUIPMENT_CONTROL.MODNAME)

local function ValidateCaneClick()
    return CompatibleAction()
       and InventoryFunctions:GetActiveItem() == nil
       and TheInput:GetHUDEntityUnderMouse() == nil
end

local function IsLightSourceEquipped()
    local handItem = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)
    return handItem
       and Categories.LIGHTSOURCE.fn(handItem)
end

local function CanEquipCane()
    return AUTO_EQUIP_CANE
       and not IsLightSourceEquipped()
       and not InventoryFunctions:IsHeavyLifting()
end

local function IsEquipped(item)
    for _, equippedItem in pairs(InventoryFunctions:GetEquips()) do
        if equippedItem.prefab == item.prefab then
            return true
        end
    end

    return false
end

local function EquipCane()
    local item = ThePlayer.components.actioncontroller:GetItemFromCategory("CANE")

    if not item or IsEquipped(item) then
        return
    end

    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, item)
end

local MoveControls =
{
    [CONTROL_MOVE_UP] = true,
    [CONTROL_MOVE_DOWN] = true,
    [CONTROL_MOVE_LEFT] = true,
    [CONTROL_MOVE_RIGHT] = true,
}

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end

    local PlayerControllerOnLeftClick = PlayerController.OnLeftClick
    function PlayerController:OnLeftClick(down)
        if ThePlayer.components.actioncontroller
        and CanEquipCane()
        and ValidateCaneClick() then
            EquipCane()

            if self:IsDoingOrWorking() then
                self.inst:DoTaskInTime(0, function()
                    PlayerControllerOnLeftClick(self, true)
                end)
                return
            end
        end

        PlayerControllerOnLeftClick(self, down)
    end

    for control in pairs(MoveControls) do
        TheInput:AddControlHandler(control, function()
            if KeybindService:ValidateKeybind()
            and ThePlayer.components.actioncontroller
            and CanEquipCane() then
                EquipCane()
            end
        end)
    end
end

KeybindService:AddKey("TOGGLE_AUTO_EQUIP_CANE", function()
    AUTO_EQUIP_CANE = DoToggle("Auto-equip cane", AUTO_EQUIP_CANE)
end)

return Init
