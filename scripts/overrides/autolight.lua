local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"

local PREFERRED_AUTO_LIGHT = GetModConfigData("PREFERRED_AUTO_LIGHT", MOD_EQUIPMENT_CONTROL.MODNAME)
local CRAFTING_ALLOWED = GetModConfigData("AUTO_EQUIP_LIGHTSOURCE", MOD_EQUIPMENT_CONTROL.MODNAME) == 2

local function GetLightSource(recur)
    if ThePlayer.components.playercontroller then
        local lightsources = ThePlayer.components.actioncontroller:GetItemsFromCategory("LIGHTSOURCE")

        for _, lightsource in ipairs(lightsources) do
            if lightsource.prefab == PREFERRED_AUTO_LIGHT then
                return lightsource
            end
        end

        if #lightsources > 0 then
            return lightsources[1]
        end

        if not CRAFTING_ALLOWED or recur then
            return nil
        end

        if CraftFunctions:CanCraft("torch") then
            CraftFunctions:Craft("torch")

            if ThePlayer.components.locomotor == nil then
                Sleep(FRAMES * 3)
            end

             -- @TODO Might wanna use an event based trigger here @TAG PERF, REFACTOR
            while CraftFunctions:IsCrafting() do
                Sleep(FRAMES)
            end

            Sleep(FRAMES * 3)

            return GetLightSource(true)
        end
    end

    return nil
end

local function EquipLight()
    local item = GetLightSource()

    if not item or InventoryFunctions:IsEquipped(item) then
        return item
    end

    InventoryFunctions:Equip(item)

    return item
end

local function Unequip(item)
    if not InventoryFunctions:IsEquipped(item) or not InventoryFunctions:HasFreeSlot() then
        return false
    end

    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.UNEQUIP.code, item)

    return true
end

local EmitLookup =
{
    yellowamulet = 0.788,
    lantern = 0.739,
    minerhat = 0.739,
    torch = 0.730,
    lighter = 0.601,
    molehat = 0.01, -- Kinda hacky
}

local function GetEmitValue()
    local ret = 0

    for _, equip in pairs(InventoryFunctions:GetEquips()) do
        if not equip:HasTag("fueldepleted") and EmitLookup[equip.prefab] then
            ret = ret + EmitLookup[equip.prefab]
        end
    end

    return ret
end

local LightTresh = .051 -- .05 from /prefabs/player_common

local function IsInDarkness()
    local emitVal = GetEmitValue()

    if emitVal > 0 then
        local lightValue = string.format(
                                "%.3f",
                                ThePlayer.LightWatcher:GetLightValue()
                           )
        lightValue = tonumber(lightValue)
        local lightDelta = lightValue - emitVal
        if lightDelta < LightTresh then
            return true
        end
    end

    return false
end

local function Init()
    if not ThePlayer or not ThePlayer.LightWatcher then
        return
    end

    StartThread(function()
        while ThePlayer do
            if ThePlayer.LightWatcher:GetTimeInDark() > 0 then
                local lightsource = EquipLight()
                if lightsource then
                    Sleep(FRAMES * 4)
                    while IsInDarkness() do
                        Sleep(.25)
                    end
                    Unequip(lightsource)
                end
            end
            Sleep(.5)
        end
    end, "AutoLightThread")
end

return Init
