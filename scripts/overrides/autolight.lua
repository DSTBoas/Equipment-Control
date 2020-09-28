local InventoryFunctions = require "util/inventoryfunctions"
local ItemFunctions = require "util/itemfunctions"

local PREFERRED_AUTO_LIGHT = GetModConfigData("PREFERRED_AUTO_LIGHT", MOD_EQUIPMENT_CONTROL.MODNAME)

local function IsEquipped(item)
    if not item then
        return false
    end

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
            if lightsource.prefab == PREFERRED_AUTO_LIGHT then
                return lightsource
            end
        end

        return lightsources[1]
    end

    return nil
end

local function EquipLight()
    local item = GetLightSource()

    if not item or IsEquipped(item) then
        return
    end

    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, item)

    return item
end

local function DarkTrigger()
    return ThePlayer 
       and ThePlayer.LightWatcher:GetTimeInDark() > 1
end

local LIGHTS_TAGS = {"lightsource", "daylight"}

local function LightTrigger()
    if TheWorld:HasTag("forest") and not TheWorld.state.isnight then
        return true
    end

    local x, y, z = ThePlayer.Transform:GetWorldPosition()
    local lightsources = TheSim:FindEntities(x, y, z, 30, nil, nil, LIGHTS_TAGS)

    local parent, rad
    for _, lightsource in pairs(lightsources) do
        parent = lightsource.entity:GetParent()
        if not parent or parent ~= ThePlayer then
            rad = lightsource.Light:GetCalculatedRadius() * .7
            if lightsource:GetDistanceSqToPoint(x, y, z) < rad * rad then
                return true
            end
        end
    end

    return false
end

local function UnEquip(item)
    if not IsEquipped(item) or not InventoryFunctions:HasFreeSlot() then
        return
    end

    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.UNEQUIP.code, item)
end

local function Init()
    if not ThePlayer or not ThePlayer.LightWatcher then
        return
    end

    ThePlayer:StartThread(function()
        while true do
            if DarkTrigger() then
                local lightsource = EquipLight()
                if lightsource then
                    Sleep(FRAMES * 4)
                    while IsEquipped(lightsource) and not LightTrigger() do
                        Sleep(.25)
                    end
                    UnEquip(lightsource)
                end
            end
            Sleep(1)
        end
    end)
end

return Init
