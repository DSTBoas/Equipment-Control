local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"

local PREFERRED_AUTO_LIGHT = GetModConfigData("PREFERRED_AUTO_LIGHT", MOD_EQUIPMENT_CONTROL.MODNAME)
local CRAFTING_ALLOWED = GetModConfigData("AUTO_EQUIP_LIGHTSOURCE", MOD_EQUIPMENT_CONTROL.MODNAME) == 2

local function GetCurrentAnimationLength()
    return ThePlayer
       and ThePlayer.AnimState
       and ThePlayer.AnimState:GetCurrentAnimationLength()
        or 0
end

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
                Sleep(GetCurrentAnimationLength())
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

local function DarkTrigger()
    return ThePlayer
       and ThePlayer.LightWatcher
       and ThePlayer.LightWatcher:GetTimeInDark() > 0
end

local function UnEquip(item)
    if not InventoryFunctions:IsEquipped(item) or not InventoryFunctions:HasFreeSlot() then
        return false
    end

    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.UNEQUIP.code, item)
    return true
end

local function GetFalloff(lightsource)
    local fallOff = lightsource.Light:GetFalloff()

    if lightsource.prefab == "spawnlight_multiplayer" then
        if fallOff > 0 and fallOff < 1 then
            return fallOff
        end
    end

    if fallOff > 0 and fallOff < 1 then
        return 1 - fallOff
    end

    return 1
end

local LIGHTS_TAGS = {"lightsource", "daylight"}

local function LightTrigger(equippedLight)
    if TheWorld:HasTag("forest") and not TheWorld.state.isnight then
        return UnEquip(equippedLight)
    end

    local x, _, z = ThePlayer.Transform:GetWorldPosition()
    local lightsources = TheSim:FindEntities(x, 0, z, 60, nil, nil, LIGHTS_TAGS)

    local radius
    for i = 1, #lightsources do
        if lightsources[i].entity:GetParent() ~= ThePlayer then
            radius = lightsources[i].Light:GetCalculatedRadius() * GetFalloff(lightsources[i])
            if lightsources[i]:GetDistanceSqToPoint(x, 0, z) < radius * radius then
                return UnEquip(equippedLight)
            end
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
            if DarkTrigger() then
                local lightsource = EquipLight()
                if lightsource then
                    Sleep(FRAMES * 4)
                    while InventoryFunctions:IsEquipped(lightsource) and not LightTrigger(lightsource) do
                        Sleep(.25)
                    end
                end
            end
            Sleep(1)
        end
    end, "AutoLightThread")
end

return Init
