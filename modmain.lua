local _G = GLOBAL
local require = _G.require

local MOD_EQUIPMENT_CONTROL = {}
MOD_EQUIPMENT_CONTROL.MODNAME = modname
MOD_EQUIPMENT_CONTROL.SPECIALFOOD = require("util/specialfood")
MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE = require("util/keybindservice")(modname)
MOD_EQUIPMENT_CONTROL.STRINGS = require("equipment_control_strings")
MOD_EQUIPMENT_CONTROL.SPAWNING = false
MOD_EQUIPMENT_CONTROL.PICKUP_FILTER = {}
_G.MOD_EQUIPMENT_CONTROL = MOD_EQUIPMENT_CONTROL

require("categories")

local function EntityScriptPostConstruct(self)
    local OldRegisterComponentActions = self.RegisterComponentActions 
    function self:RegisterComponentActions(...)
        if _G.MOD_EQUIPMENT_CONTROL.SPAWNING then
            return
        end

        OldRegisterComponentActions(self, ...)
    end
end
AddGlobalClassPostConstruct("entityscript", "EntityScript", EntityScriptPostConstruct)

if GetModConfigData("BUTTON_SHOW") then
    local Buttons = require "widgets/buttons"

    AddClassPostConstruct("widgets/inventorybar", function(self)
        self.buttons = self.root:AddChild(Buttons(self.owner, self))
    end)
end

-- Don't do this, it's error prone
-- Each file should have its own config check table at the top of the file
local Overrides =
{
    autocane =
    {
        "TOGGLE_AUTO_EQUIP_CANE",
        "AUTO_EQUIP_CANE",
    },
    autolight =
    {
        "AUTO_EQUIP_LIGHTSOURCE",
    },
    autoweapon =
    {
        "TOGGLE_AUTO_EQUIP",
        "AUTO_EQUIP_WEAPON",
        "AUTO_EQUIP_GLASSCUTTER",
    },
    autotool =
    {
        "AUTO_EQUIP_TOOL",
        "AUTO_REPEAT_ACTIONS",
    },
    mousethrough =
    {
        "AUTO_EQUIP_TOOL",
        "FLYING_BIRDS_MOUSETHROUGH",
        "ORANGESTAFF_MOUSETHROUGH",
        "YELLOWSTAFF_MOUSETHROUGH",
    },
    woodieregear =
    {
        "WOODIE_WEREITEM_UNEQUIP",
    },
    eatconfirmation =
    {
        "CONFIRM_TO_EAT",
    },
    telepoof =
    {
        "TOGGLE_TELEPOOF",
        "TELEPOOF_DISABLED",
        "TELEPOOF_HOVER",
        "TELEPOOF_DOUBLECLICK",
    },
    filterattack =
    {
        "ATTACK_FILTER",
    },
    filterpickup =
    {
        "AUTO_EQUIP_TOOL",
        "PICKUP_FILTER",
        "IGNORE_KNOWN_BLUEPRINT",
        "PRIOTIZE_VALUABLE_ITEMS",
        "PICKUP_IGNORE_FLOWERS",
        "PICKUP_IGNORE_FERNS",
        "PICKUP_IGNORE_SUCCULENTS",
        "PICKUP_IGNORE_MARSH_BUSH",
        "MEAT_PRIORITIZATION_MODE",
    },
    quickactions =
    {
        "QUICK_ACTION_CAMPFIRE",
        "QUICK_ACTION_TRAP",
        "QUICK_ACTION_BEEFALO",
        "QUICK_ACTION_WALLS",
        "QUICK_ACTION_EXTINGUISH",
        "QUICK_ACTION_SLURTLEHOLE",
        "QUICK_ACTION_FEED_BIRD",
        "QUICK_ACTION_WAKEUP_BIRD",
        "QUICK_ACTION_IMPRISON_BIRD",
        "QUICK_ACTION_BUILD_FOSSIL",
        "QUICK_ACTION_DIG",
        "QUICK_ACTION_HAMMER",
        "QUICK_ACTION_NET",
        "QUICK_ACTION_KLAUS_SACK",
        "QUICK_ACTION_ATRIUM_GATE",
        "QUICK_ACTION_REPAIR_BOAT",
        "QUICK_ACTION_PIG_KING",
        "QUICK_ACTION_DIRTPILE",
    },
    autocandybag =
    {
        "AUTO_CANDYBAG",
    },
    autohelm =
    {
        "AUTO_EQUIP_HELM",
    },
    autoeat = 
    {
        "AUTO_EAT_FOOD",
    },
}

for override, confs in pairs(Overrides) do
    local loaded = false

    for _, conf in pairs(confs) do
        if GetModConfigData(conf) then
            Overrides[override] = require("overrides/" .. override)
            loaded = true
            break
        end
    end

    if not loaded then
        Overrides[override] = nil
    end
end

local function OnPlayerActivated(_, player)
    if player ~= _G.ThePlayer then
        return
    end

    player:AddComponent("actioncontroller")
    player:AddComponent("eventtracker")
    player:AddComponent("itemtracker")

    if GetModConfigData("SORT_INVENTORY") or GetModConfigData("SORT_CHEST") then
        player:AddComponent("sorter")
    end

    if GetModConfigData("DAMAGE_ESTIMATION") then
        player:AddComponent("damagetracker")
    end

    for _, override in pairs(Overrides) do
        override()
    end
end

local function OnWorldPostInit(inst)
    inst:ListenForEvent("playeractivated", OnPlayerActivated, _G.TheWorld)
end
AddPrefabPostInit("world", OnWorldPostInit)

-- Pickup filter colors
AddPrefabPostInitAny(function(inst)
    if inst and inst.prefab then
        if _G.MOD_EQUIPMENT_CONTROL.PICKUP_FILTER[inst.prefab] then
            if inst.AnimState then
                inst.AnimState:SetMultColour(1, 0, 0, 1)
            end
        end
    end
end)
