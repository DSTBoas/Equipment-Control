local InventoryFunctions = require "util/inventoryfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local Compatible =
{
    [ACTIONS.PICK] = true,
    [ACTIONS.PICKUP] = true,
    [ACTIONS.JUMPIN] = true,
    [ACTIONS.MIGRATE] = true,
}

local function IsCompatibleLeftClickAction()
    local buffaction = ThePlayer.components.playercontroller:GetLeftMouseAction()

    if not buffaction then
        return true
    end

    return Compatible[buffaction.action]
end

local AUTO_EQUIP_CANE = GetModConfigData("AUTO_EQUIP_CANE", MOD_EQUIPMENT_CONTROL.MODNAME)

local function ValidateCaneClick()
    return IsCompatibleLeftClickAction()
       and InventoryFunctions:GetActiveItem() == nil
       and TheInput:GetHUDEntityUnderMouse() == nil
end

local function IsLightSourceEquipped()
    local equipped = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)
    return equipped
       and Categories.LIGHTSOURCE.fn(equipped)
end

local function CanEquipCane()
    return AUTO_EQUIP_CANE
       and not IsLightSourceEquipped()
       and not InventoryFunctions:IsHeavyLifting()
end

local function EquipCane()
    local item = ThePlayer.components.actioncontroller:GetItemFromCategory("CANE")
    
    InventoryFunctions:Equip(item, true)
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
        if CanEquipCane() and ValidateCaneClick() then
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
            if CanEquipCane() and KeybindService:ValidateKeybind() then
                EquipCane()
            end
        end)
    end
end

KeybindService:AddKey("TOGGLE_AUTO_EQUIP_CANE", function()
    AUTO_EQUIP_CANE = DoToggle("Auto-equip cane", AUTO_EQUIP_CANE)
end)

return Init
