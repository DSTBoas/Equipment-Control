local InventoryFunctions = require "util/inventoryfunctions"
local ItemFunctions = require "util/itemfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local function IsEquipped(item)
    for _, equippedItem in pairs(InventoryFunctions:GetEquips()) do
        if equippedItem.prefab == item.prefab then
            return true
        end
    end

    return false
end

local function GetLightSource()
    if ThePlayer.components.actioncontroller then
        local lightsources = ThePlayer.components.actioncontroller:GetItemsFromCategory("LIGHTSOURCE")

        for _, lightsource in ipairs(lightsources) do
            if ItemFunctions:GetEquipSlot(lightsource) == EQUIPSLOTS.HANDS then
                return lightsource
            end
        end
    end

    return nil
end

local function EquipLight()
    local item = GetLightSource()

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
    for control in pairs(MoveControls) do
        TheInput:AddControlHandler(control, function()
            if ThePlayer.LightWatcher and not ThePlayer.LightWatcher:IsInLight() then
                EquipLight()
            end 
        end)
    end
end


return Init
