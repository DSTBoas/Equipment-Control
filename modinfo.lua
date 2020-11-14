name = "Equipment Control"
description = "If you have suggestions/ideas/bugs let me know in this mod's comment section on Steam\n\n\n\n\n\n\n\n\n\n\n\n\n\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tMade with 󰀍"

icon_atlas = "modicon.xml"
icon = "modicon.tex"

author = "Boas"
version = "6.1"
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

local function AddConfigOption(desc, data, hover)
    return {
                description = desc,
                data = data,
                hover = hover
           }
end

local function AddDisabledOption()
    return {
                description = "Disabled",
                data = false
           }
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
        t[#t + 1] = AddConfigOption("Disabled", false, hover)
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

    AddDefaultOption(options, "Disabled", false)
    AddDefaultOption(options, "Enabled", true, hover)

    return options
end

local KeyboardOptions = GetKeyboardOptions()
local ConfirmToEatOptions = GetKeyboardOptions("Avoid accidentally eating valuable foods")
local PickupFilterOptions = GetKeyboardOptions("Add entities under your mouse to the Pickup filter")
local AttackFilterOptions = GetKeyboardOptions("Add entities under your mouse to the Attack filter")

local SettingOptions = GetDefaultOptions()
local BetaSettingOptions = GetDefaultOptions("Experimental feature use at your own risk!")

local TelepoofHoverOptions = GetDefaultOptions("Hovertext is hidden when Telepoof is disabled")
local TelepoofDisabledOptions = GetDefaultOptions("Telepoof is disabled when you enter the game")

local ForceInspectPlayerOptions = GetDefaultOptions("Requires you to hold Force Inspect to interact with Players")
local FlyingBirdsOptions = GetDefaultOptions("Flying birds are unclickable")
local YellowStaffOptions = GetDefaultOptions("Allows you to cast Dwarf Stars closer together")
local OrangeStaffOptions = GetDefaultOptions("Allows you to Telepoof through walls")

local AutoEquipCaneOptions = GetDefaultOptions("Auto-equip your cane when moving")
local AutoEquipWeaponOptions = GetDefaultOptions("Auto-equip your best weapon in combat")
local AutoEquipGlasscutterOptions = GetDefaultOptions("Auto-equip your glass cutter against nightmare creatures")
local AutoDetectRepairableOptions = GetDefaultOptions("Auto-unequip repairables before their last use")
local AutoSwitchOptions = GetDefaultOptions("Auto-switch your bone armors to stay invulnerable")
local AutoReEquipArmorOptions = GetDefaultOptions("Auto-re-equip to the next best armor")
local AutoReGearOptions = GetDefaultOptions("Auto-regear when transforming back to Woodie")
local AutoCandyBagOptions = GetDefaultOptions("Auto-store candy & trinkets in the Candy Bag")

local ButtonPreferenceOptions = GetDefaultOptions("Right click to change preference")
local ButtonAutoEquipOptions = GetDefaultOptions("Hold Shift + Right click to change Auto-equip")

local TelepoofDoubleclickOptions =
{
    AddDisabledOption(),
    AddConfigOption("Default", .5, "Double-click speed is 1/2 of a second"),
    AddConfigOption("Fast", .3, "Double-click speed is 1/3 of a second"),
    AddConfigOption("Ludicrous", .25, "Double-click speed is 1/4 of a second"),
    AddConfigOption("Plaid", .2, "Double-click speed is 1/5 of a second"),
}

local AutoReEquipOptions =
{
    AddDisabledOption(),
    AddConfigOption("Enabled (Same)", 1, "Auto-re-equip to the same weapon"),
    AddConfigOption("Enabled (Best)", 2, "Auto-re-equip to the next best weapon"),
}

local AutoEquipLightSourceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Enabled", 1, "Auto-equip your light in the dark!"),
    AddConfigOption("Enabled (Craft)", 2, "Auto-equip your light in the dark! (Auto-craft enabled)"),
}

local AutoEquipToolOptions =
{
    AddDisabledOption(),
    AddConfigOption("Enabled", 1, "Auto-equip tools"),
    AddConfigOption("Enabled (Craft)", 2, "Auto-equip tools (Auto-craft enabled)"),
}

local SortContainerOptions =
{
    AddConfigOption("Full inventory", 3, "Sorts your inventory and backpack"),
    AddConfigOption("Inventory", 2, "Sorts only your inventory"),
    AddConfigOption("Backpack", 1, "Sorts only your backpack"),
}

local LightsourcePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Lantern", "lantern"),
    AddConfigOption("Miner Hat", "minerhat"),
    AddConfigOption("Willow's Lighter", "lighter"),
    AddConfigOption("Torch", "torch"),
    AddConfigOption("Moggles", "molehat"),
}

local FuelLanternPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Light Bulb", "lightbulb"),
    AddConfigOption("Slurtle Slime", "slurtleslime"),
}

local FuelMogglesPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Glow Berry", "wormlight"),
    AddConfigOption("Lesser Glow Berry", "wormlight_lesser"),
}

local CampfireFuelPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Charcoal", "charcoal"),
    AddConfigOption("Boards", "boards"),
    AddConfigOption("Rope", "rope"),
    AddConfigOption("Log", "log"),
    AddConfigOption("Cut Grass", "cutgrass"),
    AddConfigOption("Twigs", "twigs"),
    AddConfigOption("Beefalo Wool", "beefalowool"),
    AddConfigOption("Pine Cone", "pinecone"),
    AddConfigOption("Manure", "poop"),
    AddConfigOption("Rotten Egg", "rottenegg"),
    AddConfigOption("Rot", "spoiled_food"),
    AddConfigOption("Nitre", "nitre"),
}

local CanePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("The Lazy Explorer", "orangestaff"),
    AddConfigOption("Walking Cane", "cane"),
}

local WeaponPreferenceOptions =
{
    AddDisabledOption(),

    AddConfigOption("Darksword", "nightsword"),
    AddConfigOption("Glasscutter", "glasscutter"),
    AddConfigOption("Thulecite Club", "ruins_bat"),
    AddConfigOption("Hambat", "hambat"),
    AddConfigOption("Tentacle Spike", "tentaclespike"),
    AddConfigOption("Morning Star", "nightstick"),
    AddConfigOption("Bat Bat", "batbat"),
    AddConfigOption("Battle Spear", "spear_wathgrithr"),
    AddConfigOption("Spear", "spear"),
    AddConfigOption("Tail o' Three Cats", "whip"),
    AddConfigOption("Bull Kelp Stalk", "bullkelp_root"),

    -- More Weapons and Magic MOD
    -- http://steamcommunity.com/sharedfiles/filedetails/?id=1234341720
    AddConfigOption("[M] Katana", "katana"),
    AddConfigOption("[M] Poseidon", "poseidon"),
    AddConfigOption("[M] Skullspear", "skullspear"),
    AddConfigOption("[M] Halberd", "halberd"),
    AddConfigOption("[M] Deathscythe", "deathscythe"),
    AddConfigOption("[M] Purplesword", "purplesword"),
    AddConfigOption("[M] Battleaxe", "battleaxe"),
    AddConfigOption("[M] Pirate", "pirate"),
    AddConfigOption("[M] Lightningsword", "lightningsword"),
    AddConfigOption("[M] Flamesword", "flamesword"),
}

local HeadArmorPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Bone Helm", "skeletonhat"),
    AddConfigOption("Thulecite Crown", "ruinshat"),
    AddConfigOption("Shelmet", "slurtlehat"),
    AddConfigOption("Bee Queen Crown", "hivehat"),
    AddConfigOption("Battle Helm", "wathgrithrhat"),
    AddConfigOption("Football Helmet", "footballhat"),
    AddConfigOption("Beekeeper Hat", "beehat"),
    AddConfigOption("CookieCutter Cap", "cookiecutterhat"),
}

local BodyArmorPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Bone Armor", "armorskeleton"),
    AddConfigOption("Thulecite Suit", "armorruins"),
    AddConfigOption("Scalemail", "armordragonfly"),
    AddConfigOption("Marble Suit", "armormarble"),
    AddConfigOption("Snurtle Shell", "armorsnurtleshell"),
    AddConfigOption("Night Armor", "armor_sanity"),
    AddConfigOption("Log Suit", "armorwood"),
    AddConfigOption("Bramble Husk", "armor_bramble"), 
    AddConfigOption("Grass Suit", "armorgrass"),
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
    AddConfigOption("Lucy the Axe", "lucy"),
    AddConfigOption("Moon Glass Axe", "moonglassaxe"),
    AddConfigOption("Luxury Axe", "goldenaxe"),
    AddConfigOption("Axe", "axe"),
}

local PickaxePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Pick/Axe", "multitool_axe_pickaxe"),
    AddConfigOption("Opulent Pickaxe", "goldenpickaxe"),
    AddConfigOption("Pickaxe", "pickaxe"),
}

local RangedPreferenceOptions =
{
    AddDisabledOption(),

    AddConfigOption("Trusty Slingshot", "slingshot"),
    AddConfigOption("Blow Dart", "blowdart_pipe"),
    AddConfigOption("Electric Dart", "blowdart_yellow"),
    AddConfigOption("Fire Dart", "blowdart_fire"),
    AddConfigOption("Sleep Dart", "blowdart_sleep"),
    AddConfigOption("Boomerang", "boomerang"),
    AddConfigOption("Napsack", "sleepbomb"),

    -- Archery MOD
    -- https://steamcommunity.com/sharedfiles/filedetails/?id=2141379038
    AddConfigOption("[M] Bow", "bow"),
    AddConfigOption("[M] Musket", "musket"),
    AddConfigOption("[M] Crossbow", "crossbow"),
}

local StaffPreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Star Caller Staff", "yellowstaff"),
    AddConfigOption("Moon Caller Staff", "opalstaff"),
    AddConfigOption("Fire Staff", "firestaff"),
    AddConfigOption("Ice Staff", "icestaff"),
    AddConfigOption("Telelocator Staff", "telestaff"),
    AddConfigOption("Deconstruct Staff", "greenstaff"),
    AddConfigOption("Weather Pain", "staff_tornado"),
}

-- Scythe MOD
-- https://steamcommunity.com/sharedfiles/filedetails/?id=537902048&searchtext=Scythe
local ScythePreferenceOptions =
{
    AddDisabledOption(),
    AddConfigOption("Golden Scythe", "scythe_golden"),
    AddConfigOption("Scythe", "scythe"),
}

local SortPriorityOptions =
{
    AddConfigOption("1", 7),
    AddConfigOption("2", 6),
    AddConfigOption("3", 5),
    AddConfigOption("4", 4),
    AddConfigOption("5", 3),
    AddConfigOption("6", 2),
    AddConfigOption("7", 1),
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
    AddConfigOption("Cane", "CANE"),
    AddConfigOption("Weapon", "WEAPON"),
    AddConfigOption("Light", "LIGHTSOURCE"),
    AddConfigOption("Armor", "ARMOR"),
    AddConfigOption("Head armor", "ARMORHAT"),
    AddConfigOption("Body armor", "ARMORBODY"),
    AddConfigOption("Axe", "AXE"),
    AddConfigOption("Pickaxe", "PICKAXE"),
    AddConfigOption("Hammer", "HAMMER"),
    AddConfigOption("Shovel", "SHOVEL"),
    AddConfigOption("[M] Scythe", "SCYTHE"),
    AddConfigOption("Pitchfork", "PITCHFORK"),
    AddConfigOption("Food", "FOOD"),
    AddConfigOption("Healing food", "HEALINGFOOD"),
    AddConfigOption("Ranged", "RANGED"),
    AddConfigOption("Staff", "STAFF"),
}

local AssignKeyMessage = "Assign a key"
local PreferenceMessage = "Select your preference"
local SettingMessage = "Set to your liking"
local BetaSettingMessage = "(beta) " .. SettingMessage

configuration_options =
{
    AddSectionTitle("Keybinds"),
    AddConfig(
        "Cane",
        "CANE",
        KeyboardOptions,
        "KEY_Z",
        AssignKeyMessage
    ),
    AddConfig(
        "Weapon",
        "WEAPON",
        KeyboardOptions,
        "KEY_X",
        AssignKeyMessage
    ),
    AddConfig(
        "Light",
        "LIGHTSOURCE",
        KeyboardOptions,
        "KEY_C",
        AssignKeyMessage
    ),
    AddConfig(
        "Ranged",
        "RANGED",
        KeyboardOptions,
        "KEY_R",
        AssignKeyMessage
    ),
    AddConfig(
        "Armor",
        "ARMOR",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Head armor",
        "ARMORHAT",
        KeyboardOptions,
        "KEY_H",
        AssignKeyMessage
    ),
    AddConfig(
        "Body armor",
        "ARMORBODY",
        KeyboardOptions,
        "KEY_B",
        AssignKeyMessage
    ),
    AddConfig(
        "Axe",
        "AXE",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Pickaxe",
        "PICKAXE",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Hammer",
        "HAMMER",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Shovel",
        "SHOVEL",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Pitchfork",
        "PITCHFORK",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "[M] Scythe",
        "SCYTHE",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Staff",
        "STAFF",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Food",
        "FOOD",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Healing food",
        "HEALINGFOOD",
        KeyboardOptions,
        false,
        AssignKeyMessage
    ),
    AddConfig(
        "Drop lantern",
        "DROPKEY",
        KeyboardOptions,
        "KEY_K",
        AssignKeyMessage
    ),
    AddConfig(
        "Eat confirmation",
        "CONFIRM_TO_EAT",
        ConfirmToEatOptions,
        "KEY_CTRL",
        AssignKeyMessage
    ),
    AddConfig(
        "Pickup filter",
        "PICKUP_FILTER",
        PickupFilterOptions,
        "KEY_F1",
        AssignKeyMessage
    ),
    AddConfig(
        "Attack filter",
        "ATTACK_FILTER",
        AttackFilterOptions,
        "KEY_F2",
        AssignKeyMessage
    ),
    AddConfig(
        "Sort inventory",
        "SORT_INVENTORY",
        KeyboardOptions,
        "KEY_F3",
        AssignKeyMessage
    ),
    AddConfig(
        "Sort chest",
        "SORT_CHEST",
        KeyboardOptions,
        "KEY_F4",
        AssignKeyMessage
    ),
    AddSectionTitle("Toggles"),
    AddConfig(
        "Toggle Telepoof",
        "TOGGLE_TELEPOOF",
        KeyboardOptions,
        "KEY_F5",
        AssignKeyMessage
    ),
    AddConfig(
        "Toggle Sorting container",
        "TOGGLE_SORTING_CONTAINER",
        KeyboardOptions,
        "KEY_F6",
        AssignKeyMessage
    ),
    AddConfig(
        "Toggle Auto-equip weapon",
        "TOGGLE_AUTO_EQUIP",
        KeyboardOptions,
        "KEY_F7",
        AssignKeyMessage
    ),
    AddConfig(
        "Toggle Auto-equip cane",
        "TOGGLE_AUTO_EQUIP_CANE",
        KeyboardOptions,
        "KEY_F8",
        AssignKeyMessage
    ),


    AddSectionTitle("Buttons"),
    AddConfig(
        "Show buttons",
        "BUTTON_SHOW",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Button animations",
        "BUTTON_ANIMATIONS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Display keybind on button",
        "BUTTON_SHOW_KEYBIND",
        SettingOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        "Preference shortcut",
        "BUTTON_PREFERENCE_CHANGE",
        ButtonPreferenceOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-equip shortcut",
        "BUTTON_AUTO_EQUIP_CHANGE",
        ButtonAutoEquipOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Button 1 category",
        "BUTTON_1_CATEGORY",
        ButtonCategoriesOptions,
        "ARMORHAT",
        SettingMessage
    ),
    AddConfig(
        "Button 2 category",
        "BUTTON_2_CATEGORY",
        ButtonCategoriesOptions,
        "ARMORBODY",
        SettingMessage
    ),
    AddConfig(
        "Button 3 category",
        "BUTTON_3_CATEGORY",
        ButtonCategoriesOptions,
        "WEAPON",
        SettingMessage
    ),
    AddConfig(
        "Button 4 category",
        "BUTTON_4_CATEGORY",
        ButtonCategoriesOptions,
        "CANE",
        SettingMessage
    ),
    AddConfig(
        "Button 5 category",
        "BUTTON_5_CATEGORY",
        ButtonCategoriesOptions,
        "LIGHTSOURCE",
        SettingMessage
    ),
    AddConfig(
        "Button 6 category",
        "BUTTON_6_CATEGORY",
        ButtonCategoriesOptions,
        "AXE",
        SettingMessage
    ),
    AddConfig(
        "Button 7 category",
        "BUTTON_7_CATEGORY",
        ButtonCategoriesOptions,
        "PICKAXE",
        SettingMessage
    ),
    AddConfig(
        "Button 8 category",
        "BUTTON_8_CATEGORY",
        ButtonCategoriesOptions,
        "SHOVEL",
        SettingMessage
    ),
    AddConfig(
        "Button 9 category",
        "BUTTON_9_CATEGORY",
        ButtonCategoriesOptions,
        "HAMMER",
        SettingMessage
    ),
    AddConfig(
        "Button 10 category",
        "BUTTON_10_CATEGORY",
        ButtonCategoriesOptions,
        "PITCHFORK",
        SettingMessage
    ),
    AddConfig(
        "Button 11 category",
        "BUTTON_11_CATEGORY",
        ButtonCategoriesOptions,
        "RANGED",
        SettingMessage
    ),
    AddConfig(
        "Button 12 category",
        "BUTTON_12_CATEGORY",
        ButtonCategoriesOptions,
        "STAFF",
        SettingMessage
    ),
    AddConfig(
        "Button 13 category",
        "BUTTON_13_CATEGORY",
        ButtonCategoriesOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        "Button 14 category",
        "BUTTON_14_CATEGORY",
        ButtonCategoriesOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        "Button 15 category",
        "BUTTON_15_CATEGORY",
        ButtonCategoriesOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle("Preferences"),
    AddConfig(
        "Preferred Cane",
        "PREFERRED_CANE",
        CanePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Weapon",
        "PREFERRED_WEAPON",
        WeaponPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Light",
        "PREFERRED_LIGHTSOURCE",
        LightsourcePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Ranged",
        "PREFERRED_RANGED",
        RangedPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Armor",
        "PREFERRED_ARMOR",
        ArmorPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Head Armor",
        "PREFERRED_ARMORHAT",
        HeadArmorPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Body Armor",
        "PREFERRED_ARMORBODY",
        BodyArmorPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Axe",
        "PREFERRED_AXE",
        AxePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Pickaxe",
        "PREFERRED_PICKAXE",
        PickaxePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "[M] Preferred Scythe",
        "PREFERRED_SCYTHE",
        ScythePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Staff",
        "PREFERRED_STAFF",
        StaffPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Auto-equip light",
        "PREFERRED_AUTO_LIGHT",
        LightsourcePreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Lantern fuel",
        "PREFERRED_FUEL_LANTERN",
        FuelLanternPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Moggles fuel",
        "PREFERRED_FUEL_MOGGLES",
        FuelMogglesPreferenceOptions,
        false,
        PreferenceMessage
    ),
    AddConfig(
        "Preferred Campfire fuel",
        "PREFERRED_CAMPFIRE_FUEL",
        CampfireFuelPreferenceOptions,
        false,
        PreferenceMessage
    ),


    AddSectionTitle("Automation"),
    AddConfig(
        "Auto-unequip repairables",
        "AUTO_UNEQUIP_REPAIRABLES",
        AutoDetectRepairableOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-re-equip weapon",
        "AUTO_RE_EQUIP_WEAPON",
        AutoReEquipOptions,
        2,
        SettingMessage
    ),
    AddConfig(
        "Auto-re-equip armor",
        "AUTO_RE_EQUIP_ARMOR",
        AutoReEquipArmorOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-equip weapon",
        "AUTO_EQUIP_WEAPON",
        AutoEquipWeaponOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-equip cane",
        "AUTO_EQUIP_CANE",
        AutoEquipCaneOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-equip light",
        "AUTO_EQUIP_LIGHTSOURCE",
        AutoEquipLightSourceOptions,
        2,
        SettingMessage
    ),
    AddConfig(
        "Auto-equip tool",
        "AUTO_EQUIP_TOOL",
        AutoEquipToolOptions,
        2,
        SettingMessage
    ),
    AddConfig(
        "Auto-equip glass cutter",
        "AUTO_EQUIP_GLASSCUTTER",
        AutoEquipGlasscutterOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-regear woodie",
        "WOODIE_WEREITEM_UNEQUIP",
        AutoReGearOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-switch bone armor",
        "AUTO_SWITCH_BONE_ARMOR",
        AutoSwitchOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-catch boomerang",
        "AUTO_CATCH_BOOMERANG",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-store candy bag",
        "AUTO_CANDYBAG",
        AutoCandyBagOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Auto-refuel light",
        "AUTO_REFUEL_LIGHT_SOURCES",
        SettingOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle("Quick Actions"),
    AddConfig(
        "Catch",
        "QUICK_ACTION_NET",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Hammer",
        "QUICK_ACTION_HAMMER",
        SettingOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        "Dig",
        "QUICK_ACTION_DIG",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Add Fuel Campfires",
        "QUICK_ACTION_CAMPFIRE",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Reset Trap",
        "QUICK_ACTION_TRAP",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Shave Beefalo",
        "QUICK_ACTION_BEEFALO",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Unlock Loot Stash",
        "QUICK_ACTION_KLAUS_SACK",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Repair Boat",
        "QUICK_ACTION_REPAIR_BOAT",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Build Odd Skeleton",
        "QUICK_ACTION_BUILD_FOSSIL",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Socket Ancient Key",
        "QUICK_ACTION_ATRIUM_GATE",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Track Animal",
        "QUICK_ACTION_DIRTPILE",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Trade Pig King",
        "QUICK_ACTION_PIG_KING",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Feed Bird",
        "QUICK_ACTION_FEED_BIRD",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Wakeup Bird",
        "QUICK_ACTION_WAKEUP_BIRD",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Imprison Bird",
        "QUICK_ACTION_IMPRISON_BIRD",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Repair Wall",
        "QUICK_ACTION_WALLS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Extinguish Fire",
        "QUICK_ACTION_EXTINGUISH",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Light Slurtle Mound",
        "QUICK_ACTION_SLURTLEHOLE",
        SettingOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle("Pickup"),
    AddConfig(
        "Pickup valuables first",
        "PRIOTIZE_VALUABLE_ITEMS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Ignore known Blueprints",
        "IGNORE_KNOWN_BLUEPRINT",
        SettingOptions,
        true,
        SettingMessage
    ),


    AddSectionTitle("Picking"),
    AddConfig(
        "Never pick Flowers",
        "PICKUP_IGNORE_FLOWERS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Never pick Succulents",
        "PICKUP_IGNORE_SUCCULENTS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Never pick Ferns",
        "PICKUP_IGNORE_FERNS",
        SettingOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Never pick Spiky Bush",
        "PICKUP_IGNORE_MARSH_BUSH",
        SettingOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle("Telepoof"),
    AddConfig(
        "Disabled by default",
        "TELEPOOF_DISABLED",
        TelepoofDisabledOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        "Hide hovertext",
        "TELEPOOF_HOVER",
        TelepoofHoverOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        "Double-click speed",
        "TELEPOOF_DOUBLECLICK",
        TelepoofDoubleclickOptions,
        .5,
        SettingMessage
    ),
    AddConfig(
        "Double-click Soul Hop",
        "TELEPOOF_WORTOX",
        SettingOptions,
        true,
        SettingMessage
    ),


    AddSectionTitle("Mousethrough"),
    AddConfig(
        "Force Inspect Player",
        "FORCE_INSPECT_PLAYERS",
        ForceInspectPlayerOptions,
        false,
        SettingMessage
    ),
    AddConfig(
        "Unclickable flying birds",
        "FLYING_BIRDS_MOUSETHROUGH",
        FlyingBirdsOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "Star Caller Staff",
        "YELLOWSTAFF_MOUSETHROUGH",
        YellowStaffOptions,
        true,
        SettingMessage
    ),
    AddConfig(
        "The Lazy Explorer",
        "ORANGESTAFF_MOUSETHROUGH",
        OrangeStaffOptions,
        true,
        SettingMessage
    ),


    AddSectionTitle("Sorting"),
    AddConfig(
        "Sorting container",
        "CONTAINER_SORT",
        SortContainerOptions,
        3,
        SettingMessage
    ),
    AddConfig(
        "Armor priority",
        "ARMOR_SORT_PRIORITY",
        SortPriorityOptions,
        7,
        SettingMessage
    ),
    AddConfig(
        "Light priority",
        "LIGHT_SORT_PRIORITY",
        SortPriorityOptions,
        6,
        SettingMessage
    ),
    AddConfig(
        "Staff priority",
        "STAFF_SORT_PRIORITY",
        SortPriorityOptions,
        5,
        SettingMessage
    ),
    AddConfig(
        "Equipment priority",
        "EQUIPMENT_SORT_PRIORITY",
        SortPriorityOptions,
        4,
        SettingMessage
    ),
    AddConfig(
        "Food priority",
        "FOOD_SORT_PRIORITY",
        SortPriorityOptions,
        3,
        SettingMessage
    ),
    AddConfig(
        "Resource priority",
        "RESOURCE_SORT_PRIORITY",
        SortPriorityOptions,
        2,
        SettingMessage
    ),
    AddConfig(
        "Tool priority",
        "TOOL_SORT_PRIORITY",
        SortPriorityOptions,
        1,
        SettingMessage
    ),
    AddConfig(
        "Keep in slot 1",
        "OVERRIDE_SLOT1_SORT",
        SortOverrideOptions,
        false,
        SettingMessage
    ),


    AddSectionTitle("Miscellaneous"),
    AddConfig(
        "Damage estimation",
        "DAMAGE_ESTIMATION",
        SettingOptions,
        true,
        SettingMessage
    ),
}
