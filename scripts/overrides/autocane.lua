local InventoryFunctions = require "util/inventoryfunctions"
local ConfigFunctions = require "util/configfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local function CanWalkTo(action, doer, bufferedaction)
    if not action or action.instant then
        return false
    end

    local maxAllowedDistance = 3.0
    local actionDistance = action.distance or 0

    local extraDistance = action.extra_arrive_dist or 0
    if type(extraDistance) == "function" then
        extraDistance = 0
    end

    return (actionDistance + extraDistance) <= maxAllowedDistance
end

local function IsCompatibleLeftClickAction()
    local pc = ThePlayer and ThePlayer.components.playercontroller
    if not pc or not pc.GetLeftMouseAction then
        return true
    end

    local buffaction = pc:GetLeftMouseAction()
    if not buffaction then
        return true
    end

    return CanWalkTo(buffaction.action, ThePlayer, buffaction)
end

local AUTO_EQUIP_CANE = GetModConfigData("AUTO_EQUIP_CANE", MOD_EQUIPMENT_CONTROL.MODNAME)

local function ValidateCaneClick()
    return IsCompatibleLeftClickAction()
       and TheInput:GetHUDEntityUnderMouse() == nil
end

local function IsLightSourceEquipped()
    local equipped = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)

    if not equipped then
        return false
    end

    return Categories.LIGHTSOURCE.fn(equipped)
end

local function ShouldEquipCane()
    return not Categories.CANE.fn(InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS))
end

local function CanEquipCane()
    return AUTO_EQUIP_CANE
       and not IsLightSourceEquipped()
       and not InventoryFunctions:IsHeavyLifting()
       and ShouldEquipCane()
end

local function EquipCane()
    InventoryFunctions:Equip(
        ThePlayer.components.actioncontroller:GetItemFromCategory("CANE"),
        true
    )
end

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end

    local OldOnLeftClick = PlayerController.OnLeftClick

    function PlayerController:OnLeftClick(down, ...)
        local args = { ... } 
    
        if down and CanEquipCane() and ValidateCaneClick() then
            EquipCane()
    
            self.inst:DoTaskInTime(GetTickTime(), function()
                OldOnLeftClick(self, down, unpack(args))
            end)
            return
        end
    
        OldOnLeftClick(self, down, unpack(args))
    end
    
    local PlayerControllerDoDragWalking = PlayerController.DoDragWalking
    function PlayerController:DoDragWalking(...)
        local isDragWalking = PlayerControllerDoDragWalking(self, ...)

        if isDragWalking and CanEquipCane() then
            EquipCane()
        end

        return isDragWalking
    end

    local PlayerControllerDoDirectWalking = PlayerController.DoDirectWalking
    function PlayerController:DoDirectWalking(...)
        PlayerControllerDoDirectWalking(self, ...)
        if self.directwalking and CanEquipCane() then
            EquipCane()
        end
    end
end

KeybindService:AddKey("TOGGLE_AUTO_EQUIP_CANE", function()
    AUTO_EQUIP_CANE = ConfigFunctions:DoToggle("Auto-equip cane", AUTO_EQUIP_CANE)
end)

return Init
