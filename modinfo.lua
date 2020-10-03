name = "Equipment Control"
description = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tMade with 󰀍"

icon_atlas = "modicon.xml"
icon = "modicon.tex"

author = "Boas"
version = "2.8"
forumthread = ""

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

all_clients_require_mod = false
client_only_mod = true

api_version = 10

folder_name = folder_name or name
if not folder_name:find("workshop-") then
    name = name .. " (dev)"
end

--[[
    To add a language copy the [en] table below and change the table name to your current language (See below)
    Russian = ru
    Chinese = zh
    Spanish = es
    German = de
    French = fr
    Korean = ko
]]

local Languages =
{
    en =
    {
        option_titles =
        {
            Keybinds = "Keybinds",
            Toggles = "Toggles",
            Buttons = "Buttons",
            Preference = "Preferences",
            Automation = "Automation",
            DamageEstimation = "Damage estimation",
            QuickActions = "Quick actions",
            Pickup = "Pickup",
            Telepoof = "Telepoof",
            Estimation = "Estimation",
            Mousethrough = "Improved mousethrough",
            Sorting = "Sorting",
        },
        option_messages =
        {
            AssignKeyMessage = "Assign a key",
            AssignLanguageMessage = "Select your language",
            ModNeededMessage = " (Mod required)",
            PreferenceMessage = "Select your preference",
            SettingMessage = "Set to your liking",
            BetaSettingMessage = "(beta) ",
            ButtonPreferenceOptions = "Right click to change preference",
            ButtonAutoEquipOptions = "Shift + Right click to change Auto-equip",
            BetaSettingOptions = "Use this feature at your own discretion",
            ConfirmToEatOptions = "Avoid accidentally eating valuable foods",
            PickupFilterOptions = "Add entities under your mouse to the Pickup filter",
            AttackFilterOptions = "Add entities under your mouse to the Attack filter",
            AutoEquipCaneOptions = "Auto-equip your cane when moving",
            AutoEquipWeaponOptions = "Auto-equip your best weapon in combat",
            AutoEquipGlasscutterOptions = "Auto-equip your glass cutter against nightmare creatures",
            AutoDetectRepairableOptions = "Auto-unequip repairables before their last use",
            AutoSwitchOptions = "Auto-switch your bone armors to stay invulnerable",
            AutoReFuelOptions = "Auto-refuel your light sources",
            AutoReEquipArmorOptions = "Auto-re-equip to the next best armor",
            AutoReGearOptions = "Auto-regear when transforming back to Woodie",
        },
        option_config =
        {
            Disabled = "Disabled",
            Enabled = "Enabled",
            AutoReEquipOptions =
            {
                [1] =
                {
                    "Enabled (Same)",
                    "Same: re-equip to the same weapon"
                },
                [2] =
                {
                    "Enabled (Best)",
                    "Best: re-equip to the next best weapon"
                }
            },
            AutoEquipLightSourceOptions =
            {
                [1] =
                {
                    "Enabled",
                    "Auto-equip your light in the dark!"
                },
                [2] =
                {
                    "Enabled (Craft)",
                    "Auto-equip your light in the dark! (Auto-craft enabled)"
                },
            },
            AutoEquipToolOptions =
            {
                [1] =
                {
                    "Enabled",
                    "Auto-equip tools"
                },
                [2] =
                {
                    "Enabled (Craft)",
                    "Auto-equip tools (Auto-craft enabled)"
                },
            },
            SortContainerOptions =
            {
                [1] =
                {
                    "Full inventory",
                    "Sorts your inventory and backpack"
                },
                [2] =
                {
                    "Inventory",
                    "Sorts only your inventory"
                },
                [3] =
                {
                    "Backpack",
                    "Sorts only your backpack"
                }
            },
            EstimationOptions =
            {
                [1] =
                {
                    "Round",
                    "Example: 100%"
                },
                [2] =
                {
                    "Decimal",
                    "Example: 99.9%"
                }
            },
            LightsourcePreferenceOptions =
            {
                [1] = "Lantern",
                [2] = "Miner Hat",
                [3] = "Willow's Lighter",
                [4] = "Torch",
                [5] = "Moggles",
            },
            CanePreferenceOptions =
            {
                [1] = "The Lazy Explorer",
                [2] = "Walking Cane",
            },
            WeaponPreferenceOptions =
            {
                [1] = "Darksword",
                [2] = "Glasscutter",
                [3] = "Thulecite Club",
                [4] = "Hambat",
                [5] = "Tentacle Spike",
                [6] = "Morning Star",
                [7] = "Bat Bat",
                [8] = "Battle Spear",
                [9] = "Spear",
                [10] = "Tail o' Three Cats",
                [11] = "Bull Kelp Stalk",

                [12] = "[M] Katana",
                [13] = "[M] Poseidon",
                [14] = "[M] Skullspear",
                [15] = "[M] Halberd",
                [16] = "[M] Deathscythe",
                [17] = "[M] Purplesword",
                [18] = "[M] Battleaxe",
                [19] = "[M] Pirate",
                [20] = "[M] Lightningsword",
                [21] = "[M] Flamesword",
            },
            HeadArmorPreferenceOptions =
            {
                [1] = "Bone Helm",
                [2] = "Thulecite Crown",
                [3] = "Bee Queen Crown",
                [4] = "Battle Helm",
                [5] = "Football Helmet",
                [6] = "Beekeeper Hat",
                [7] = "CookieCutter Cap",
            },
            BodyArmorPreferenceOptions =
            {
                [1] = "Bone Armor",
                [2] = "Thulecite Suit",
                [3] = "Scalemail",
                [4] = "Marble Suit",
                [5] = "Snurtle Shell",
                [6] = "Night Armor",
                [7] = "Log Suit",
                [8] = "Bramble Husk",
                [9] = "Grass Suit",
            },
            AxePreferenceOptions =
            {
                [1] = "Lucy the Axe",
                [2] = "Moon Glass Axe",
                [3] = "Luxury Axe",
                [4] = "Axe",
            },
            PickaxePreferenceOptions =
            {
                [1] = "Pick/Axe",
                [2] = "Opulent Pickaxe",
                [3] = "Pickaxe",
            },
            RangedPreferenceOptions =
            {
                [1] = "Trusty Slingshot",
                [2] = "Blow Dart",
                [3] = "Electric Dart",
                [4] = "Fire Dart",
                [5] = "Sleep Dart",
                [6] = "Boomerang",
                [7] = "Napsack",
                [8] = "[M] Bow",
                [9] = "[M] Musket",
                [10] = "[M] Crossbow",
            },
            StaffPreferenceOptions =
            {
                [1] = "Star Caller Staff",
                [2] = "Moon Caller Staff",
                [3] = "Fire Staff",
                [4] = "Ice Staff",
                [5] = "Telelocator Staff",
                [6] = "Deconstruct Staff",
                [7] = "Weather Pain",
            },
            ScythePreferenceOptions =
            {
                [1] = "Golden Scythe",
                [2] = "Scythe",
            },
            FuelLanternPreferenceOptions =
            {
                [1] = "Light Bulb",
                [2] = "Slurtle Slime",
            },
            FuelMogglesPreferenceOptions =
            {
                [1] = "Glow Berry",
                [2] = "Lesser Glow Berry",
            },
            CampfireFuelPreferenceOptions =
            {
                [1] = "Charcoal",
                [2] = "Boards",
                [3] = "Rope",
                [4] = "Log",
                [5] = "Cut Grass",
                [6] = "Twigs",
                [7] = "Beefalo Wool",
                [8] = "Pine Cone",
                [9] = "Manure",
                [10] = "Rotten Egg",
                [11] = "Rot",
                [12] = "Nitre",
            },
            TelepoofDoubleClickOptions =
            {
                [1] = "Default",
                [2] = "Fast",
                [3] = "Ludicrous",
                [4] = "Plaid",
            },
            SortPriorityOptions =
            {
                [1] = "1",
                [2] = "2",
                [3] = "3",
                [4] = "4",
                [5] = "5",
                [6] = "6",
                [7] = "7",
            },
            ButtonCategoriesOptions =
            {
                [1] = "Cane",
                [2] = "Weapon",
                [3] = "Light source",
                [4] = "Armor",
                [5] = "Head armor",
                [6] = "Body armor",
                [7] = "Axe",
                [8] = "Pickaxe",
                [9] = "Hammer",
                [10] = "Shovel",
                [11] = "[M] Scythe",
                [12] = "Pitchfork",
                [13] = "Food",
                [14] = "Healing food",
                [15] = "Ranged weapon",
                [16] = "Staff",
            },
        },
        option_names =
        {
            LANGUAGE = "Language",
            DROPKEY = "Drop lantern",
            CONFIRM_TO_EAT = "Confirm to eat",
            PICKUP_FILTER = "Pickup filter",
            ATTACK_FILTER = "Attack filter",
            SORT_INVENTORY = "Sort inventory",
            SORT_CHEST = "Sort chest",
            TOGGLE_TELEPOOF = "Toggle Telepoof",
            TOGGLE_SORTING_CONTAINER = "Toggle Sorting container",
            TOGGLE_AUTO_EQUIP = "Toggle Auto-equip weapon",
            TOGGLE_AUTO_EQUIP_CANE = "Toggle Auto-equip cane",
            TOGGLE_TELEPOOF_MODE = "Toggle Telepoof mouse through",
            BUTTON_SHOW = "Buttons",
            BUTTON_ANIMATIONS = "Animate buttons",
            BUTTON_SHOW_KEYBIND = "Show keybind",
            BUTTON_PREFERENCE_CHANGE = "Preference shortcut",
            BUTTON_AUTO_EQUIP_CHANGE = "Auto-equip shortcut",
            BUTTON_1_CATEGORY = "Button 1 category",
            BUTTON_2_CATEGORY = "Button 2 category",
            BUTTON_3_CATEGORY = "Button 3 category",
            BUTTON_4_CATEGORY = "Button 4 category",
            BUTTON_5_CATEGORY = "Button 5 category",
            BUTTON_6_CATEGORY = "Button 6 category",
            BUTTON_7_CATEGORY = "Button 7 category",
            BUTTON_8_CATEGORY = "Button 8 category",
            BUTTON_9_CATEGORY = "Button 9 category",
            BUTTON_10_CATEGORY = "Button 10 category",
            BUTTON_11_CATEGORY = "Button 11 category",
            BUTTON_12_CATEGORY = "Button 12 category",
            BUTTON_13_CATEGORY = "Button 13 category",
            BUTTON_14_CATEGORY = "Button 14 category",
            BUTTON_15_CATEGORY = "Button 15 category",
            PREFERRED = "Preferred ",
            PREFERRED_FUEL_LANTERN = "Lantern fuel",
            PREFERRED_FUEL_MOGGLES = "Moggles fuel",
            PREFERRED_CAMPFIRE_FUEL = "Campfire fuel",
            AUTO_UNEQUIP_REPAIRABLES = "Auto-unequip repairables",
            AUTO_RE_EQUIP_WEAPON = "Auto-re-equip weapon",
            AUTO_RE_EQUIP_ARMOR = "Auto-re-equip armor",
            AUTO_EQUIP_WEAPON = "Auto-equip weapon",
            AUTO_EQUIP_CANE = "Auto-equip cane",
            AUTO_EQUIP_LIGHTSOURCE = "Auto-equip light",
            AUTO_EQUIP_TOOL = "Auto-equip tools",
            AUTO_EQUIP_GLASSCUTTER = "Auto-equip glass cutter",
            WOODIE_WEREITEM_UNEQUIP = "Auto-regear woodie",
            AUTO_SWITCH_BONE_ARMOR = "Auto-switch bone armor",
            AUTO_REFUEL_LIGHT_SOURCES = "Auto-refuel light sources",
            AUTO_CATCH_BOOMERANG = "Auto-catch boomerang",
            DAMAGE_ESTIMATION = "Damage estimation",
            QUICK_ACTION_NET = "Catch",
            QUICK_ACTION_HAMMER = "Hammer",
            QUICK_ACTION_DIG = "Dig",
            QUICK_ACTION_CAMPFIRE = "Add Fuel Campfires",
            QUICK_ACTION_TRAP = "Reset Trap",
            QUICK_ACTION_BEEFALO = "Shave Beefalo",
            QUICK_ACTION_KLAUS_SACK = "Unlock Loot Stash",
            QUICK_ACTION_BIRD_CAGE = "Feed Bird",
            QUICK_ACTION_WAKEUP_BIRD = "Wakeup Bird",
            QUICK_ACTION_WALLS = "Repair Wall",
            QUICK_ACTION_EXTINGUISH = "Extinguish Fire",
            QUICK_ACTION_SLURTLEHOLE = "Light Slurtle Mound",
            PRIOTIZE_VALUABLE_ITEMS = "Pickup valuables first",
            PICKUP_IGNORE_FLOWERS = "Ignore Flowers",
            PICKUP_IGNORE_SUCCULENTS = "Ignore Succulents",
            PICKUP_IGNORE_FERNS = "Ignore Ferns",
            PICKUP_IGNORE_MARSH_BUSH = "Ignore Spiky Bush",
            TELEPOOF_ENABLED = "Enabled by default",
            TELEPOOF_DOUBLECLICK = "Doubleclick",
            TELEPOOF_HOVER = "Hovertext",
            ORANGESTAFF_MOUSETHROUGH = "Star Caller Staff",
            YELLOWSTAFF_MOUSETHROUGH = "The Lazy Explorer",
            LANTERN_ESTIMATION = "Lantern fuel estimation",
            CONTAINER_SORT = "Sorting container",
            ARMOR_SORT_PRIORITY = "Armor priority",
            LIGHT_SORT_PRIORITY = "Light source priority",
            STAFF_SORT_PRIORITY = "Staff priority",
            EQUIPMENT_SORT_PRIORITY = "Equipment priority",
            FOOD_SORT_PRIORITY = "Food priority",
            RESOURCE_SORT_PRIORITY = "Resource priority",
            TOOL_SORT_PRIORITY = "Tool priority",
            OVERRIDE_SLOT1_SORT = "Keep in slot 1",
        }
    },
}

local CurrentLanguage = Languages.en
local TheLocale = "en"
if locale ~= nil and Languages[locale] then
    CurrentLanguage = Languages[locale]
    TheLocale = locale
end

local function AddConfigOption(desc, data, hover)
    return {description = desc, data = data, hover = hover}
end

local function AddDisabledOption()
    return {description = CurrentLanguage.option_config.Disabled, data = false}
end

local function AddConfig(label, name, options, default, hover)
    return {
                label = label,
                name = name,
                options = options,
                default = default,
                hover = hover
           }
end

local function AddSectionTitle(title)
    return AddConfig(title, "", {{description = "", data = 0}}, 0)
end

local function GetKeyboardOptions(hover)
    local keys = {}
    local nameKeys =
    {
        "Tab",
        "-",
        "=",
        "Space",
        "Enter",
        "Esc",
        "Pause",
        "Print Screen",
        "Caps Lock",
        "Scroll Lock",
        "Right Shift",
        "Left Shift",
        "Shift",
        "Right Ctrl",
        "Left Ctrl",
        "Ctrl",
        "Right Alt",
        "Left Alt",
        "Alt",
        "Backspace",
        "\\",
        ".",
        "/",
        ";",
        "{",
        "}",
        "~",
        "Arrow Up",
        "Arrow Down",
        "Arrow Right",
        "Arrow Left",
        "Insert",
        "Delete",
        "Home",
        "End",
        "Page Up",
        "Page Down"
    }
    local specialKeys =
    {
        "TAB",
        "MINUS",
        "EQUALS",
        "SPACE",
        "ENTER",
        "ESCAPE",
        "PAUSE",
        "PRINT",
        "CAPSLOCK",
        "SCROLLOCK",
        "RSHIFT",
        "LSHIFT",
        "SHIFT",
        "RCTRL",
        "LCTRL",
        "CTRL",
        "RALT",
        "LALT",
        "ALT",
        "BACKSPACE",
        "BACKSLASH",
        "PERIOD",
        "SLASH",
        "SEMICOLON",
        "RIGHTBRACKET",
        "LEFTBRACKET",
        "TILDE",
        "UP",
        "DOWN",
        "RIGHT",
        "LEFT",
        "INSERT",
        "DELETE",
        "HOME",
        "END",
        "PAGEUP",
        "PAGEDOWN",
    }

    local function AddConfigKey(t, key, hover)
        t[#t + 1] = AddConfigOption(key, "KEY_" .. key, hover)
    end

    local function AddConfigSpecialKey(t, name, key, hover)
        t[#t + 1] = AddConfigOption(name, "KEY_" .. key, hover)
    end

    local function AddDisabledConfigOption(t, hover)
        t[#t + 1] = AddConfigOption(CurrentLanguage.option_config.Disabled, false, hover)
    end

    AddDisabledConfigOption(keys, hover)

    local string = ""
    for i = 1, 26 do
        AddConfigKey(keys, string.char(64 + i), hover)
    end

    for i = 1, 10 do
        AddConfigKey(keys, i % 10 .. "", hover)
    end

    for i = 1, 12 do
        AddConfigKey(keys, "F" .. i, hover)
    end

    for i = 1, #specialKeys do
        AddConfigSpecialKey(keys, nameKeys[i], specialKeys[i], hover)
    end
    
    AddDisabledConfigOption(keys, hover)

    return keys
end

local function GetDefaultOptions(hover)
    local function AddDefaultOption(t, desc, data, hover)
        t[#t + 1] = AddConfigOption(desc, data, hover)
    end

    local options = {}

    AddDefaultOption(options, CurrentLanguage.option_config.Disabled, false)
    AddDefaultOption(options, CurrentLanguage.option_config.Enabled, true, hover)

    return options
end

local KeyboardOptions = GetKeyboardOptions()
local ConfirmToEatOptions = GetKeyboardOptions(CurrentLanguage.option_messages.ConfirmToEatOptions)
local PickupFilterOptions = GetKeyboardOptions(CurrentLanguage.option_messages.PickupFilterOptions)
local AttackFilterOptions = GetKeyboardOptions(CurrentLanguage.option_messages.AttackFilterOptions)

local SettingOptions = GetDefaultOptions()
local BetaSettingOptions = GetDefaultOptions(CurrentLanguage.option_messages.BetaSettingOptions)

local AutoEquipCaneOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoEquipCaneOptions)
local AutoEquipWeaponOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoEquipWeaponOptions)
local AutoEquipGlasscutterOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoEquipGlasscutterOptions)
local AutoRefillSlingshotOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoRefillSlingshotOptions)
local AutoDetectRepairableOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoDetectRepairableOptions)
local AutoSwitchOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoSwitchOptions)
local AutoReFuelOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoReFuelOptions)
local AutoReEquipArmorOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoReEquipArmorOptions)
local AutoReGearOptions = GetDefaultOptions(CurrentLanguage.option_messages.AutoReGearOptions)

local AutoReEquipOptions =
{
    AddConfigOption(CurrentLanguage.option_config.Disabled, false),
    AddConfigOption(CurrentLanguage.option_config.AutoReEquipOptions[1][1], 1, CurrentLanguage.option_config.AutoReEquipOptions[1][2]),
    AddConfigOption(CurrentLanguage.option_config.AutoReEquipOptions[2][1], 2, CurrentLanguage.option_config.AutoReEquipOptions[2][2]),
}

local AutoEquipLightSourceOptions =
{
    AddConfigOption(CurrentLanguage.option_config.Disabled, false),
    AddConfigOption(CurrentLanguage.option_config.AutoEquipLightSourceOptions[1][1], 1, CurrentLanguage.option_config.AutoEquipLightSourceOptions[1][2]),
    AddConfigOption(CurrentLanguage.option_config.AutoEquipLightSourceOptions[2][1], 2, CurrentLanguage.option_config.AutoEquipLightSourceOptions[2][2]),
}

local AutoEquipToolOptions =
{
    AddConfigOption(CurrentLanguage.option_config.Disabled, false),
    AddConfigOption(CurrentLanguage.option_config.AutoEquipToolOptions[1][1], 1, CurrentLanguage.option_config.AutoEquipToolOptions[1][2]),
    AddConfigOption(CurrentLanguage.option_config.AutoEquipToolOptions[2][1], 2, CurrentLanguage.option_config.AutoEquipToolOptions[2][2]),
}

local ButtonPreferenceOptions = GetDefaultOptions(CurrentLanguage.option_messages.ButtonPreferenceOptions)
local ButtonAutoEquipOptions = GetDefaultOptions(CurrentLanguage.option_messages.ButtonAutoEquipOptions)

local SortContainerOptions =
{
    AddConfigOption(CurrentLanguage.option_config.SortContainerOptions[1][1], 3, CurrentLanguage.option_config.SortContainerOptions[1][2]),
    AddConfigOption(CurrentLanguage.option_config.SortContainerOptions[2][1], 2, CurrentLanguage.option_config.SortContainerOptions[2][2]),
    AddConfigOption(CurrentLanguage.option_config.SortContainerOptions[3][1], 1, CurrentLanguage.option_config.SortContainerOptions[3][2]),
}

local EstimationOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.EstimationOptions[1][1], 0, CurrentLanguage.option_config.EstimationOptions[1][2]),
    AddConfigOption(CurrentLanguage.option_config.EstimationOptions[2][1], 1, CurrentLanguage.option_config.EstimationOptions[2][2]),
}

local LightsourcePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.LightsourcePreferenceOptions[1], "lantern"),
    AddConfigOption(CurrentLanguage.option_config.LightsourcePreferenceOptions[2], "minerhat"),
    AddConfigOption(CurrentLanguage.option_config.LightsourcePreferenceOptions[3], "lighter"),
    AddConfigOption(CurrentLanguage.option_config.LightsourcePreferenceOptions[4], "torch"),
    AddConfigOption(CurrentLanguage.option_config.LightsourcePreferenceOptions[5], "molehat"),
}

local FuelLanternPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.FuelLanternPreferenceOptions[1], "lightbulb"),
    AddConfigOption(CurrentLanguage.option_config.FuelLanternPreferenceOptions[2], "slurtleslime"),
}

local FuelMogglesPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.FuelMogglesPreferenceOptions[1], "wormlight"),
    AddConfigOption(CurrentLanguage.option_config.FuelMogglesPreferenceOptions[2], "wormlight_lesser"),
}

local CampfireFuelPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[1], "charcoal"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[2], "boards"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[3], "rope"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[4], "log"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[5], "cutgrass"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[6], "twigs"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[7], "beefalowool"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[8], "pinecone"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[9], "poop"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[10], "rottenegg"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[11], "spoiled_food"),
    AddConfigOption(CurrentLanguage.option_config.CampfireFuelPreferenceOptions[12], "nitre"),
}

local CanePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.CanePreferenceOptions[1], "orangestaff"),
    AddConfigOption(CurrentLanguage.option_config.CanePreferenceOptions[2], "cane"),
}

local WeaponPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[1], "nightsword"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[2], "glasscutter"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[3], "ruins_bat"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[4], "hambat"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[5], "tentaclespike"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[6], "nightstick"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[7], "batbat"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[8], "spear_wathgrithr"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[9], "spear"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[10], "whip"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[11], "bullkelp_root"),
    -- More Weapons and Magic MOD
    -- http://steamcommunity.com/sharedfiles/filedetails/?id=1234341720
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[12], "katana"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[13], "poseidon"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[14], "skullspear"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[15], "halberd"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[16], "deathscythe"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[17], "purplesword"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[18], "battleaxe"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[19], "pirate"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[20], "lightningsword"),
    AddConfigOption(CurrentLanguage.option_config.WeaponPreferenceOptions[21], "flamesword"),
}

local HeadArmorPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.HeadArmorPreferenceOptions[1], "skeletonhat"),
    AddConfigOption(CurrentLanguage.option_config.HeadArmorPreferenceOptions[2], "ruinshat"),
    AddConfigOption(CurrentLanguage.option_config.HeadArmorPreferenceOptions[3], "slurtlehat"),
    AddConfigOption(CurrentLanguage.option_config.HeadArmorPreferenceOptions[4], "hivehat"),
    AddConfigOption(CurrentLanguage.option_config.HeadArmorPreferenceOptions[5], "wathgrithrhat"),
    AddConfigOption(CurrentLanguage.option_config.HeadArmorPreferenceOptions[6], "footballhat"),
    AddConfigOption(CurrentLanguage.option_config.HeadArmorPreferenceOptions[7], "beehat"),
    AddConfigOption(CurrentLanguage.option_config.HeadArmorPreferenceOptions[8], "cookiecutterhat"),
}

local BodyArmorPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[1], "armorskeleton"),
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[2], "armorruins"),
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[3], "armordragonfly"),
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[4], "armormarble"),
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[5], "armorsnurtleshell"),
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[6], "armor_sanity"),
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[7], "armorwood"),
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[8], "armor_bramble"), 
    AddConfigOption(CurrentLanguage.option_config.BodyArmorPreferenceOptions[9], "armorgrass"),
}

local ArmorPreferenceOptions = {}

for i = 1, #HeadArmorPreferenceOptions do
    ArmorPreferenceOptions[#ArmorPreferenceOptions + 1] = HeadArmorPreferenceOptions[i]
end

for i = 1, #BodyArmorPreferenceOptions do
    if BodyArmorPreferenceOptions[i].data then
        ArmorPreferenceOptions[#ArmorPreferenceOptions + 1] = BodyArmorPreferenceOptions[i]
    end
end

local AxePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.AxePreferenceOptions[1], "lucy"),
    AddConfigOption(CurrentLanguage.option_config.AxePreferenceOptions[2], "moonglassaxe"),
    AddConfigOption(CurrentLanguage.option_config.AxePreferenceOptions[3], "goldenaxe"),
    AddConfigOption(CurrentLanguage.option_config.AxePreferenceOptions[4], "axe"),
}

local PickaxePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.PickaxePreferenceOptions[1], "multitool_axe_pickaxe"),
    AddConfigOption(CurrentLanguage.option_config.PickaxePreferenceOptions[2], "goldenpickaxe"),
    AddConfigOption(CurrentLanguage.option_config.PickaxePreferenceOptions[3], "pickaxe"),
}

local RangedPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[1], "slingshot"),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[2], "blowdart_pipe"),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[3], "blowdart_yellow"),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[4], "blowdart_fire"),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[5], "blowdart_sleep"),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[6], "boomerang"),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[7], "sleepbomb"),
    -- Archery MOD
    -- https://steamcommunity.com/sharedfiles/filedetails/?id=2141379038
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[8], "bow"),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[9], "musket"),
    AddConfigOption(CurrentLanguage.option_config.RangedPreferenceOptions[10], "crossbow"),
}

local StaffPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.StaffPreferenceOptions[1], "yellowstaff"),
    AddConfigOption(CurrentLanguage.option_config.StaffPreferenceOptions[2], "opalstaff"),
    AddConfigOption(CurrentLanguage.option_config.StaffPreferenceOptions[3], "firestaff"),
    AddConfigOption(CurrentLanguage.option_config.StaffPreferenceOptions[4], "icestaff"),
    AddConfigOption(CurrentLanguage.option_config.StaffPreferenceOptions[5], "telestaff"),
    AddConfigOption(CurrentLanguage.option_config.StaffPreferenceOptions[6], "greenstaff"),
    AddConfigOption(CurrentLanguage.option_config.StaffPreferenceOptions[7], "staff_tornado"),
}

-- Scythe MOD
-- https://steamcommunity.com/sharedfiles/filedetails/?id=537902048&searchtext=Scythe
local ScythePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.ScythePreferenceOptions[1], "scythe_golden"),
    AddConfigOption(CurrentLanguage.option_config.ScythePreferenceOptions[2], "scythe"),
}

local TelepoofDoubleClickOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.TelepoofDoubleClickOptions[1], .5),
    AddConfigOption(CurrentLanguage.option_config.TelepoofDoubleClickOptions[2], .3),
    AddConfigOption(CurrentLanguage.option_config.TelepoofDoubleClickOptions[3], .25),
    AddConfigOption(CurrentLanguage.option_config.TelepoofDoubleClickOptions[4], .2),
}

local SortPriorityOptions =
{
    AddConfigOption(CurrentLanguage.option_config.SortPriorityOptions[1], 7),
    AddConfigOption(CurrentLanguage.option_config.SortPriorityOptions[2], 6),
    AddConfigOption(CurrentLanguage.option_config.SortPriorityOptions[3], 5),
    AddConfigOption(CurrentLanguage.option_config.SortPriorityOptions[4], 4),
    AddConfigOption(CurrentLanguage.option_config.SortPriorityOptions[5], 3),
    AddConfigOption(CurrentLanguage.option_config.SortPriorityOptions[6], 2),
    AddConfigOption(CurrentLanguage.option_config.SortPriorityOptions[7], 1),
}

local LabelSizeOptions = {}

for i = 8, 26, 2 do
    LabelSizeOptions[#LabelSizeOptions + 1] = AddConfigOption(i .. "", i)
end

local FontOptions =
{
    AddConfigOption("Open Sans", "DEFAULTFONT"),

    AddConfigOption("Bp100", "TITLEFONT"),
    AddConfigOption("Bp50", "UIFONT"),

    AddConfigOption("Button Font", "BUTTONFONT"),

    AddConfigOption("Spirequal", "NEWFONT"),
    AddConfigOption("Spirequal Small", "NEWFONT_SMALL"),
    AddConfigOption("Spirequal Outline", "NEWFONT_OUTLINE"),
    AddConfigOption("Spirequal S Outline", "NEWFONT_OUTLINE_SMALL"),

    AddConfigOption("Stint Ucr", "BODYTEXTFONT"),
    AddConfigOption("Stint Small", "SMALLNUMBERFONT"),

    AddConfigOption("Talking Font", "TALKINGFONT"),
    AddConfigOption("Bellefair", "CHATFONT"),
    AddConfigOption("Bellefair Outline", "CHATFONT_OUTLINE"),
    AddConfigOption("Hammerhead", "HEADERFONT"),
}

local SortOverrideOptions =
{
    AddDisabledOption(),
    AddConfigOption("Abigail's Flower", "abigail_flower"),
}

local ButtonCategoriesOptions =
{
    AddDisabledOption(),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[1], "CANE"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[2], "WEAPON"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[3], "LIGHTSOURCE"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[4], "ARMOR"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[5], "ARMORHAT"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[6], "ARMORBODY"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[7], "AXE"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[8], "PICKAXE"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[9], "HAMMER"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[10], "SHOVEL"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[11], "SCYTHE"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[12], "PITCHFORK"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[13], "FOOD"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[14], "HEALINGFOOD"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[15], "RANGED"),
    AddConfigOption(CurrentLanguage.option_config.ButtonCategoriesOptions[16], "STAFF"),
}

local LanguageOptions =
{
    AddConfigOption("English", "en"),
}

local AssignKeyMessage = CurrentLanguage.option_messages.AssignKeyMessage
local AssignLanguageMessage = CurrentLanguage.option_messages.AssignLanguageMessage
local ModNeededMessage = CurrentLanguage.option_messages.ModNeededMessage
local PreferenceMessage = CurrentLanguage.option_messages.PreferenceMessage
local SettingMessage = CurrentLanguage.option_messages.SettingMessage
local BetaSettingMessage = CurrentLanguage.option_messages.BetaSettingMessage .. SettingMessage

configuration_options =
{
    AddConfig(
        CurrentLanguage.option_names.LANGUAGE,
        "LANGUAGE",
        LanguageOptions,
        TheLocale,
        AssignLanguageMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.Keybinds),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[1],
        "CANE",
        KeyboardOptions,
        "KEY_Z",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[2],
        "WEAPON",
        KeyboardOptions,
        "KEY_X",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[3],
        "LIGHTSOURCE",
        KeyboardOptions,
        "KEY_C",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[15],
        "RANGED",
        KeyboardOptions,
        "KEY_R",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[4],
        "ARMOR",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[5],
        "ARMORHAT",
        KeyboardOptions,
        "KEY_H",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[6],
        "ARMORBODY",
        KeyboardOptions,
        "KEY_B",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[7],
        "AXE",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[8],
        "PICKAXE",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[9],
        "HAMMER",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[10],
        "SHOVEL",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[12],
        "PITCHFORK",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[11],
        "SCYTHE",
        KeyboardOptions,
        false,
        AssignKeyMessage .. ModNeededMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[13],
        "FOOD",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_config.ButtonCategoriesOptions[14],
        "HEALINGFOOD",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.DROPKEY,
        "DROPKEY",
        KeyboardOptions,
        "KEY_K",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.CONFIRM_TO_EAT,
        "CONFIRM_TO_EAT",
        ConfirmToEatOptions,
        "KEY_CTRL",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PICKUP_FILTER,
        "PICKUP_FILTER",
        PickupFilterOptions,
        "KEY_F1",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.ATTACK_FILTER,
        "ATTACK_FILTER",
        AttackFilterOptions,
        "KEY_F2",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.SORT_INVENTORY,
        "SORT_INVENTORY",
        KeyboardOptions,
        "KEY_F3",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.SORT_CHEST,
        "SORT_CHEST",
        KeyboardOptions,
        "KEY_F4",
        AssignKeyMessage
    ),
    AddSectionTitle(CurrentLanguage.option_titles.Toggles),
    AddConfig(
        CurrentLanguage.option_names.TOGGLE_TELEPOOF,
        "TOGGLE_TELEPOOF",
        KeyboardOptions,
        "KEY_F5",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.TOGGLE_SORTING_CONTAINER,
        "TOGGLE_SORTING_CONTAINER",
        KeyboardOptions,
        "KEY_F6",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.TOGGLE_AUTO_EQUIP,
        "TOGGLE_AUTO_EQUIP",
        KeyboardOptions,
        "KEY_F7",
        AssignKeyMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.TOGGLE_AUTO_EQUIP_CANE,
        "TOGGLE_AUTO_EQUIP_CANE",
        KeyboardOptions,
        "KEY_F8",
        AssignKeyMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.Buttons),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_SHOW,
        "BUTTON_SHOW",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_ANIMATIONS,
        "BUTTON_ANIMATIONS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_SHOW_KEYBIND,
        "BUTTON_SHOW_KEYBIND",
        SettingOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_PREFERENCE_CHANGE,
        "BUTTON_PREFERENCE_CHANGE",
        ButtonPreferenceOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_AUTO_EQUIP_CHANGE,
        "BUTTON_AUTO_EQUIP_CHANGE",
        ButtonAutoEquipOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_1_CATEGORY,
        "BUTTON_1_CATEGORY",
        ButtonCategoriesOptions,
        "ARMORHAT",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_2_CATEGORY,
        "BUTTON_2_CATEGORY",
        ButtonCategoriesOptions,
        "ARMORBODY",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_3_CATEGORY,
        "BUTTON_3_CATEGORY",
        ButtonCategoriesOptions,
        "WEAPON",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_4_CATEGORY,
        "BUTTON_4_CATEGORY",
        ButtonCategoriesOptions,
        "CANE",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_5_CATEGORY,
        "BUTTON_5_CATEGORY",
        ButtonCategoriesOptions,
        "LIGHTSOURCE",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_6_CATEGORY,
        "BUTTON_6_CATEGORY",
        ButtonCategoriesOptions,
        "AXE",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_7_CATEGORY,
        "BUTTON_7_CATEGORY",
        ButtonCategoriesOptions,
        "PICKAXE",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_8_CATEGORY,
        "BUTTON_8_CATEGORY",
        ButtonCategoriesOptions,
        "SHOVEL",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_9_CATEGORY,
        "BUTTON_9_CATEGORY",
        ButtonCategoriesOptions,
        "HAMMER",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_10_CATEGORY,
        "BUTTON_10_CATEGORY",
        ButtonCategoriesOptions,
        "PITCHFORK",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_11_CATEGORY,
        "BUTTON_11_CATEGORY",
        ButtonCategoriesOptions,
        "RANGED",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_12_CATEGORY,
        "BUTTON_12_CATEGORY",
        ButtonCategoriesOptions,
        "STAFF",
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_13_CATEGORY,
        "BUTTON_13_CATEGORY",
        ButtonCategoriesOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_14_CATEGORY,
        "BUTTON_14_CATEGORY",
        ButtonCategoriesOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.BUTTON_15_CATEGORY,
        "BUTTON_15_CATEGORY",
        ButtonCategoriesOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.Preference),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[1],
        "PREFERRED_CANE",
        CanePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[2],
        "PREFERRED_WEAPON",
        WeaponPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[3],
        "PREFERRED_LIGHTSOURCE",
        LightsourcePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[15],
        "PREFERRED_RANGED",
        RangedPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[4],
        "PREFERRED_ARMOR",
        ArmorPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[5],
        "PREFERRED_ARMORHAT",
        HeadArmorPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[6],
        "PREFERRED_ARMORBODY",
        BodyArmorPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[7],
        "PREFERRED_AXE",
        AxePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[8],
        "PREFERRED_PICKAXE",
        PickaxePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[11],
        "PREFERRED_SCYTHE",
        ScythePreferenceOptions,
        false,
        PreferenceMessage .. ModNeededMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_config.ButtonCategoriesOptions[16],
        "PREFERRED_STAFF",
        StaffPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_names.AUTO_EQUIP_LIGHTSOURCE,
        "PREFERRED_AUTO_LIGHT",
        LightsourcePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_names.PREFERRED_FUEL_LANTERN,
        "PREFERRED_FUEL_LANTERN",
        FuelLanternPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_names.PREFERRED_FUEL_MOGGLES,
        "PREFERRED_FUEL_MOGGLES",
        FuelMogglesPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PREFERRED .. CurrentLanguage.option_names.PREFERRED_CAMPFIRE_FUEL,
        "PREFERRED_CAMPFIRE_FUEL",
        CampfireFuelPreferenceOptions,
        false,
        PreferenceMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.Automation),
    AddConfig(
        CurrentLanguage.option_names.AUTO_UNEQUIP_REPAIRABLES,
        "AUTO_UNEQUIP_REPAIRABLES",
        AutoDetectRepairableOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_RE_EQUIP_WEAPON,
        "AUTO_RE_EQUIP_WEAPON",
        AutoReEquipOptions,
        2,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_RE_EQUIP_ARMOR,
        "AUTO_RE_EQUIP_ARMOR",
        AutoReEquipArmorOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_EQUIP_WEAPON,
        "AUTO_EQUIP_WEAPON",
        AutoEquipWeaponOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_EQUIP_CANE,
        "AUTO_EQUIP_CANE",
        AutoEquipCaneOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_EQUIP_LIGHTSOURCE,
        "AUTO_EQUIP_LIGHTSOURCE",
        AutoEquipLightSourceOptions,
        1,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_EQUIP_TOOL,
        "AUTO_EQUIP_TOOL",
        AutoEquipToolOptions,
        1,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_EQUIP_GLASSCUTTER,
        "AUTO_EQUIP_GLASSCUTTER",
        AutoEquipGlasscutterOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.WOODIE_WEREITEM_UNEQUIP,
        "WOODIE_WEREITEM_UNEQUIP",
        AutoReGearOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_SWITCH_BONE_ARMOR,
        "AUTO_SWITCH_BONE_ARMOR",
        AutoSwitchOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_CATCH_BOOMERANG,
        "AUTO_CATCH_BOOMERANG",
        SettingOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.AUTO_REFUEL_LIGHT_SOURCES,
        "AUTO_REFUEL_LIGHT_SOURCES",
        AutoReFuelOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.DamageEstimation),
    AddConfig(
        CurrentLanguage.option_names.DAMAGE_ESTIMATION,
        "DAMAGE_ESTIMATION",
        SettingOptions,
        true,
        SettingMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.QuickActions),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_NET,
        "QUICK_ACTION_NET",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_HAMMER,
        "QUICK_ACTION_HAMMER",
        SettingOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_DIG,
        "QUICK_ACTION_DIG",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_CAMPFIRE,
        "QUICK_ACTION_CAMPFIRE",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_TRAP,
        "QUICK_ACTION_TRAP",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_BEEFALO,
        "QUICK_ACTION_BEEFALO",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_KLAUS_SACK,
        "QUICK_ACTION_KLAUS_SACK",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_BIRD_CAGE,
        "QUICK_ACTION_BIRD_CAGE",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_WAKEUP_BIRD,
        "QUICK_ACTION_WAKEUP_BIRD",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_WALLS,
        "QUICK_ACTION_WALLS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_EXTINGUISH,
        "QUICK_ACTION_EXTINGUISH",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.QUICK_ACTION_SLURTLEHOLE,
        "QUICK_ACTION_SLURTLEHOLE",
        SettingOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.Pickup),
    AddConfig(
        CurrentLanguage.option_names.PRIOTIZE_VALUABLE_ITEMS,
        "PRIOTIZE_VALUABLE_ITEMS",
        SettingOptions,
        true,
        SettingMessage
    ), 
    AddConfig(
        CurrentLanguage.option_names.PICKUP_IGNORE_FLOWERS,
        "PICKUP_IGNORE_FLOWERS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PICKUP_IGNORE_SUCCULENTS,
        "PICKUP_IGNORE_SUCCULENTS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PICKUP_IGNORE_FERNS,
        "PICKUP_IGNORE_FERNS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.PICKUP_IGNORE_MARSH_BUSH,
        "PICKUP_IGNORE_MARSH_BUSH",
        SettingOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.Telepoof),
    AddConfig(
        CurrentLanguage.option_names.TELEPOOF_ENABLED,
        "TELEPOOF_ENABLED",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.TELEPOOF_HOVER,
        "TELEPOOF_HOVER",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.TELEPOOF_DOUBLECLICK,
        "TELEPOOF_DOUBLECLICK",
        TelepoofDoubleClickOptions,
        .5,
        SettingMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.Mousethrough),
    AddConfig(
        CurrentLanguage.option_names.ORANGESTAFF_MOUSETHROUGH,
        "ORANGESTAFF_MOUSETHROUGH",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.YELLOWSTAFF_MOUSETHROUGH,
        "YELLOWSTAFF_MOUSETHROUGH",
        SettingOptions,
        true,
        SettingMessage
    ),


    AddSectionTitle(CurrentLanguage.option_titles.Sorting),
    AddConfig(
        CurrentLanguage.option_names.CONTAINER_SORT,
        "CONTAINER_SORT",
        SortContainerOptions,
        3,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.ARMOR_SORT_PRIORITY,
        "ARMOR_SORT_PRIORITY",
        SortPriorityOptions,
        7,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.LIGHT_SORT_PRIORITY,
        "LIGHT_SORT_PRIORITY",
        SortPriorityOptions,
        6,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.STAFF_SORT_PRIORITY,
        "STAFF_SORT_PRIORITY",
        SortPriorityOptions,
        5,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.EQUIPMENT_SORT_PRIORITY,
        "EQUIPMENT_SORT_PRIORITY",
        SortPriorityOptions,
        4,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.FOOD_SORT_PRIORITY,
        "FOOD_SORT_PRIORITY",
        SortPriorityOptions,
        3,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.RESOURCE_SORT_PRIORITY,
        "RESOURCE_SORT_PRIORITY",
        SortPriorityOptions,
        2,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.TOOL_SORT_PRIORITY,
        "TOOL_SORT_PRIORITY",
        SortPriorityOptions,
        1,
        SettingMessage
    ),
    AddConfig(
        CurrentLanguage.option_names.OVERRIDE_SLOT1_SORT,
        "OVERRIDE_SLOT1_SORT",
        SortOverrideOptions,
        false,
        SettingMessage
    ),
}
