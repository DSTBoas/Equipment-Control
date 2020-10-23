local _G = GLOBAL
local require = _G.require

local MOD_EQUIPMENT_CONTROL = {}
MOD_EQUIPMENT_CONTROL.MODNAME = modname
MOD_EQUIPMENT_CONTROL.SPECIALFOOD = require("util/specialfood")
MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE = require("util/keybindservice" .. modname)
MOD_EQUIPMENT_CONTROL.STRINGS = require("strings")
MOD_EQUIPMENT_CONTROL.SPAWNING = false
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

local Overrides =
{
    autocane =
    {
        "AUTO_EQUIP_CANE",
    },
    autolight =
    {
        "AUTO_EQUIP_LIGHTSOURCE",
    },
    autoweapon =
    {
        "AUTO_EQUIP_WEAPON",
        "AUTO_EQUIP_GLASSCUTTER",
    },
    autotool =
    {
        "AUTO_EQUIP_TOOL",
    },
    mousethrough =
    {
        "AUTO_EQUIP_TOOL",
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
        "PRIOTIZE_VALUABLE_ITEMS",
        "PICKUP_IGNORE_FLOWERS",
        "PICKUP_IGNORE_FERNS",
        "PICKUP_IGNORE_SUCCULENTS",
        "PICKUP_IGNORE_MARSH_BUSH",
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
