name = "Equipment Control"
description = "If you have suggestions/ideas/bugs let me know in this mod's comment section on Steam\n\n\n\n\n\n\n\n\n\n\n\n\n\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tMade with 󰀍"
icon_atlas = "modicon.xml"
icon = "modicon.tex"
author = "Boas"
version = "8.09"
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

local function opt(desc, data, hover)
    return { description = desc, data = data, hover = hover }
end

local function boolOpt(hover)
    return {
        opt("Disabled", false, hover),
        opt("Enabled", true, hover),
    }
end

local function cfg(label, name, options, default, hover)
    return { label = label, name = name, options = options, default = default, hover = hover }
end

local function title(text)
    return cfg(text, "", { { description = "", data = 0 } }, 0)
end

local OPTION_SETS = {}

OPTION_SETS.YESNO = boolOpt()
OPTION_SETS.YESNO_BETA = boolOpt("Experimental - use at your own risk!")
OPTION_SETS.YESNO_PREF_SHORTCUT = boolOpt("Right click to change preference")
OPTION_SETS.YESNO_AUTOEQUIP_SHORTCUT = boolOpt("Hold Shift + Right click to change Auto-equip")
OPTION_SETS.YESNO_TELEPOOF_HOVER = boolOpt("Hovertext is hidden when Telepoof is disabled")
OPTION_SETS.YESNO_TELEPOOF_DISABLED = boolOpt("Telepoof is disabled when you enter the game")
OPTION_SETS.YESNO_FORCE_INSPECT = boolOpt("Requires you to hold Force Inspect to interact with Players")
OPTION_SETS.YESNO_FLYING_BIRDS = boolOpt("Flying birds are unclickable")
OPTION_SETS.YESNO_YELLOWSTAFF = boolOpt("Allows you to cast Dwarf Stars closer together")
OPTION_SETS.YESNO_ORANGESTAFF = boolOpt("Allows you to Telepoof through walls")
OPTION_SETS.YESNO_AUTO_EQUIP_GLASSCUTTER = boolOpt("Auto-equip your glass cutter against nightmare creatures")
OPTION_SETS.YESNO_AUTO_REGEAR_WOODIE = boolOpt("Auto-regear when transforming back to Woodie")
OPTION_SETS.YESNO_AUTO_REFUEL_LIGHT = boolOpt()

OPTION_SETS.PRIORITY = {}
for p = 7, 1, -1 do
    OPTION_SETS.PRIORITY[#OPTION_SETS.PRIORITY + 1] = opt("" .. (8 - p), p)
end

do
    local base_kb = {}
    base_kb[#base_kb + 1] = opt("Disabled", false)
    local ALPHA = {
        "A","B","C","D","E","F","G","H","I","J","K","L","M",
        "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    }
    for i = 1, #ALPHA do base_kb[#base_kb + 1] = opt(ALPHA[i], "KEY_" .. ALPHA[i]) end
    for i = 0, 9 do base_kb[#base_kb + 1] = opt("" .. i, "KEY_" .. i) end
    for i = 1, 12 do base_kb[#base_kb + 1] = opt("F" .. i, "KEY_F" .. i) end
    local specialsTXT = {
        "Tab","-","=","Space","Enter","Esc","Pause","Print Screen","Caps Lock",
        "Scroll Lock","Right Shift","Left Shift","Shift","Right Ctrl","Left Ctrl",
        "Ctrl","Right Alt","Left Alt","Alt","Backspace","\\",".","/",";","{","}","~",
        "Arrow Up","Arrow Down","Arrow Right","Arrow Left","Insert","Delete",
        "Home","End","Page Up","Page Down",
    }
    local specialsKEY = {
        "TAB","MINUS","EQUALS","SPACE","ENTER","ESCAPE","PAUSE","PRINT","CAPSLOCK",
        "SCROLLOCK","RSHIFT","LSHIFT","SHIFT","RCTRL","LCTRL","CTRL","RALT","LALT",
        "ALT","BACKSPACE","BACKSLASH","PERIOD","SLASH","SEMICOLON","RIGHTBRACKET",
        "LEFTBRACKET","TILDE","UP","DOWN","RIGHT","LEFT","INSERT","DELETE",
        "HOME","END","PAGEUP","PAGEDOWN",
    }
    for i = 1, #specialsTXT do base_kb[#base_kb + 1] = opt(specialsTXT[i], "KEY_" .. specialsKEY[i]) end
    base_kb[#base_kb + 1] = opt("Disabled", false)

    OPTION_SETS.KB = base_kb

    local function create_kb_variant(hover_text)
        local variant = {}
        for i = 1, #base_kb do
            variant[#variant + 1] = opt(base_kb[i].description, base_kb[i].data, hover_text)
        end
        return variant
    end
    OPTION_SETS.KB_CONFIRM_EAT = create_kb_variant("Avoid accidentally eating valuable foods")
    OPTION_SETS.KB_PICKUP_FILTER = create_kb_variant("Add entities under your mouse to the Pickup filter")
    OPTION_SETS.KB_ATTACK_FILTER = create_kb_variant("Add entities under your mouse to the Attack filter")
end

OPTION_SETS.BUTTON_CATEGORIES = {
    opt("Disabled", false), opt("Cane", "CANE"), opt("Weapon", "WEAPON"), opt("Light", "LIGHTSOURCE"),
    opt("Armor", "ARMOR"), opt("Head armor", "ARMORHAT"), opt("Body armor", "ARMORBODY"), opt("Axe", "AXE"),
    opt("Pickaxe", "PICKAXE"), opt("Hammer", "HAMMER"), opt("Shovel", "SHOVEL"), opt("[M] Scythe", "SCYTHE"),
    opt("Pitchfork", "PITCHFORK"), opt("Food", "FOOD"), opt("Healing food", "HEALINGFOOD"),
    opt("Ranged", "RANGED"), opt("Staff", "STAFF"), opt("Amulet", "AMULET"),
}

OPTION_SETS.PREF_CANE = {
    opt("Disabled", false), opt("The Lazy Explorer", "orangestaff"), opt("Walking Cane", "cane"),
    opt("Dumbbell", "dumbbell"), opt("Golden Dumbbell", "dumbbell_golden"), opt("Marbell", "dumbbell_marble"),
    opt("Gembell", "dumbbell_gem"), opt("Firebell", "dumbell_redgem"), opt("Icebell", "dumbell_bluegem"),
    opt("Thermbell", "dumbell_heat"),
}

OPTION_SETS.PREF_WEAPON = {
    opt("Disabled", false), opt("Shield of Terror", "shieldofterror"), opt("Darksword", "nightsword"),
    opt("Glasscutter", "glasscutter"), opt("Thulecite Club", "ruins_bat"), opt("Hambat", "hambat"),
    opt("Tentacle Spike", "tentaclespike"), opt("Morning Star", "nightstick"), opt("Bat Bat", "batbat"),
    opt("Battle Spear", "spear_wathgrithr"), opt("Spear", "spear"), opt("Tail o' Three Cats", "whip"),
    opt("Bull Kelp Stalk", "bullkelp_root"), opt("[M] Katana", "katana"), opt("[M] Poseidon", "poseidon"),
    opt("[M] Skullspear", "skullspear"), opt("[M] Halberd", "halberd"), opt("[M] Deathscythe", "deathscythe"),
    opt("[M] Purplesword", "purplesword"), opt("[M] Battleaxe", "battleaxe"), opt("[M] Pirate", "pirate"),
    opt("[M] Lightningsword", "lightningsword"), opt("[M] Flamesword", "flamesword"),
}

OPTION_SETS.PREF_LIGHTSOURCE = {
    opt("Disabled", false), opt("Lantern", "lantern"), opt("Miner Hat", "minerhat"),
    opt("Willow's Lighter", "lighter"), opt("Torch", "torch"), opt("Moggles", "molehat"),
}

OPTION_SETS.PREF_RANGED = {
    opt("Disabled", false), opt("Trusty Slingshot", "slingshot"), opt("Blow Dart", "blowdart_pipe"),
    opt("Electric Dart", "blowdart_yellow"), opt("Fire Dart", "blowdart_fire"), opt("Sleep Dart", "blowdart_sleep"),
    opt("Boomerang", "boomerang"), opt("Napsack", "sleepbomb"), opt("[M] Bow", "bow"), opt("[M] Musket", "musket"),
    opt("[M] Crossbow", "crossbow"),
}

OPTION_SETS.PREF_HEAD_ARMOR = {
    opt("Disabled", false), opt("Eye Mask", "eyemaskhat"), opt("Bone Helm", "skeletonhat"),
    opt("Thulecite Crown", "ruinshat"), opt("Shelmet", "slurtlehat"), opt("Bee Queen Crown", "hivehat"),
    opt("Battle Helm", "wathgrithrhat"), opt("Football Helmet", "footballhat"), opt("Beekeeper Hat", "beehat"),
    opt("CookieCutter Cap", "cookiecutterhat"),
}

OPTION_SETS.PREF_BODY_ARMOR = {
    opt("Disabled", false), opt("Bone Armor", "armorskeleton"), opt("Thulecite Suit", "armorruins"),
    opt("Scalemail", "armordragonfly"), opt("Marble Suit", "armormarble"), opt("Snurtle Shell", "armorsnurtleshell"),
    opt("Night Armor", "armor_sanity"), opt("Log Suit", "armorwood"), opt("Bramble Husk", "armor_bramble"),
    opt("Grass Suit", "armorgrass"),
}

OPTION_SETS.PREF_ARMOR = {}
for i = 1, #OPTION_SETS.PREF_HEAD_ARMOR do OPTION_SETS.PREF_ARMOR[#OPTION_SETS.PREF_ARMOR + 1] = OPTION_SETS.PREF_HEAD_ARMOR[i] end
for i = 1, #OPTION_SETS.PREF_BODY_ARMOR do if OPTION_SETS.PREF_BODY_ARMOR[i].data then OPTION_SETS.PREF_ARMOR[#OPTION_SETS.PREF_ARMOR + 1] = OPTION_SETS.PREF_BODY_ARMOR[i] end end

OPTION_SETS.PREF_AXE = {
    opt("Disabled", false), opt("Lucy the Axe", "lucy"), opt("Moon Glass Axe", "moonglassaxe"),
    opt("Luxury Axe", "goldenaxe"), opt("Axe", "axe"),
}

OPTION_SETS.PREF_PICKAXE = {
    opt("Disabled", false), opt("Pick/Axe", "multitool_axe_pickaxe"), opt("Opulent Pickaxe", "goldenpickaxe"),
    opt("Pickaxe", "pickaxe"),
}

OPTION_SETS.PREF_SCYTHE = {
    opt("Disabled", false), opt("Golden Scythe", "scythe_golden"), opt("Scythe", "scythe"),
}

OPTION_SETS.PREF_STAFF = {
    opt("Disabled", false), opt("Star Caller Staff", "yellowstaff"), opt("Moon Caller Staff", "opalstaff"),
    opt("Fire Staff", "firestaff"), opt("Ice Staff", "icestaff"), opt("Telelocator Staff", "telestaff"),
    opt("Deconstruct Staff", "greenstaff"), opt("Weather Pain", "staff_tornado"),
}

OPTION_SETS.PREF_FUEL_LANTERN = {
    opt("Disabled", false), opt("Light Bulb", "lightbulb"), opt("Slurtle Slime", "slurtleslime"),
}

OPTION_SETS.PREF_FUEL_MOGGLES = {
    opt("Disabled", false), opt("Glow Berry", "wormlight"), opt("Lesser Glow Berry", "wormlight_lesser"),
}

OPTION_SETS.PREF_CAMPFIRE_FUEL = {
    opt("Disabled", false), opt("Charcoal", "charcoal"), opt("Boards", "boards"), opt("Rope", "rope"),
    opt("Log", "log"), opt("Cut Grass", "cutgrass"), opt("Twigs", "twigs"), opt("Beefalo Wool", "beefalowool"),
    opt("Pine Cone", "pinecone"), opt("Manure", "poop"), opt("Rotten Egg", "rottenegg"),
    opt("Rot", "spoiled_food"), opt("Nitre", "nitre"),
}

OPTION_SETS.AUTO_RE_EQUIP_WEAPON = {
    opt("Disabled", false), opt("Enabled (Same)", 1, "Auto-re-equip to the same weapon"),
    opt("Enabled (Best)", 2, "Auto-re-equip to the next best weapon"),
}

OPTION_SETS.AUTO_EQUIP_LIGHT = {
    opt("Disabled", false), opt("Enabled", 1, "Auto-equip your light in the dark!"),
    opt("Enabled (Craft)", 2, "Auto-equip your light in the dark! (Auto-craft enabled)"),
}

OPTION_SETS.AUTO_EQUIP_TOOL = {
    opt("Disabled", false), opt("Enabled", 1, "Auto-equip tools"),
    opt("Enabled (Craft)", 2, "Auto-equip tools (Auto-craft enabled)"),
}

OPTION_SETS.TRAP = {
    opt("Disabled", false), opt("Sprung", 1, "Only display on traps in a sprung state"), opt("Always", 2),
}

OPTION_SETS.TELEPOOF_SPEED = {
    opt("Disabled", false), opt("Default", .5, "Double-click speed is 1/2 of a second"),
    opt("Fast", .3, "Double-click speed is 1/3 of a second"),
    opt("Ludicrous", .25, "Double-click speed is 1/4 of a second"),
    opt("Plaid", .2, "Double-click speed is 1/5 of a second"),
}

OPTION_SETS.SORT_OVERRIDE = {
    opt("Disabled", false), opt("Abigail's Flower", "abigail_flower"),
}

OPTION_SETS.SORT_CONTAINER = {
    opt("Full inventory", 3, "Sorts your inventory and backpack"),
    opt("Inventory", 2, "Sorts only your inventory"),
    opt("Backpack", 1, "Sorts only your backpack"),
}

local CONFIG_STRUCTURE = {
    {
        title = "Keybinds",
        default_hover = "Assign a key",
        items = {
            -- Label, Name, Options Key, Default, Hover Text Override (optional)
            {"Cane","CANE","KB","KEY_Z"},
            {"Weapon","WEAPON","KB","KEY_X"},
            {"Light","LIGHTSOURCE","KB","KEY_C"},
            {"Ranged","RANGED","KB","KEY_R"},
            {"Armor","ARMOR","KB",false},
            {"Head armor","ARMORHAT","KB","KEY_H"},
            {"Body armor","ARMORBODY","KB","KEY_B"},
            {"Axe","AXE","KB",false},
            {"Pickaxe","PICKAXE","KB",false},
            {"Hammer","HAMMER","KB",false},
            {"Shovel","SHOVEL","KB",false},
            {"Pitchfork","PITCHFORK","KB",false},
            {"[M] Scythe","SCYTHE","KB",false},
            {"Staff","STAFF","KB",false},
            {"Food","FOOD","KB",false},
            {"Healing food","HEALINGFOOD","KB",false},
            {"Drop lantern","DROPKEY","KB","KEY_K"},
            {"Meat prioritization mode","MEAT_PRIORITIZATION_MODE","KB","KEY_F9"},
            {"Eat confirmation","CONFIRM_TO_EAT","KB_CONFIRM_EAT","KEY_CTRL"},
            {"Pickup filter","PICKUP_FILTER","KB_PICKUP_FILTER","KEY_F1"},
            {"Attack filter","ATTACK_FILTER","KB_ATTACK_FILTER","KEY_F2"},
            {"Sort inventory","SORT_INVENTORY","KB","KEY_F3"},
            {"Sort chest","SORT_CHEST","KB","KEY_F4"},
        },
    },
    {
        title = "Toggles",
        default_hover = "Assign a key",
        items = {
            {"Toggle Telepoof","TOGGLE_TELEPOOF","KB","KEY_F5"},
            {"Toggle Sorting container","TOGGLE_SORTING_CONTAINER","KB","KEY_F6"},
            {"Toggle Auto-equip weapon","TOGGLE_AUTO_EQUIP","KB","KEY_F7"},
            {"Toggle Auto-equip cane","TOGGLE_AUTO_EQUIP_CANE","KB","KEY_F8"},
        },
    },
    {
        title = "Buttons",
        default_hover = "Set to your liking",
        items = {
            {"Show buttons","BUTTON_SHOW", "YESNO", true},
            {"Button animations","BUTTON_ANIMATIONS", "YESNO", true},
            {"Display keybind on button","BUTTON_SHOW_KEYBIND", "YESNO", false},
            {"Preference shortcut", "BUTTON_PREFERENCE_CHANGE", "YESNO_PREF_SHORTCUT", true},
            {"Auto-equip shortcut", "BUTTON_AUTO_EQUIP_CHANGE", "YESNO_AUTOEQUIP_SHORTCUT", true},
            {"Button 1 category", "BUTTON_1_CATEGORY", "BUTTON_CATEGORIES", "ARMORHAT"},
            {"Button 2 category", "BUTTON_2_CATEGORY", "BUTTON_CATEGORIES", "ARMORBODY"},
            {"Button 3 category", "BUTTON_3_CATEGORY", "BUTTON_CATEGORIES", "WEAPON"},
            {"Button 4 category", "BUTTON_4_CATEGORY", "BUTTON_CATEGORIES", "CANE"},
            {"Button 5 category", "BUTTON_5_CATEGORY", "BUTTON_CATEGORIES", "LIGHTSOURCE"},
            {"Button 6 category", "BUTTON_6_CATEGORY", "BUTTON_CATEGORIES", "AXE"},
            {"Button 7 category", "BUTTON_7_CATEGORY", "BUTTON_CATEGORIES", "PICKAXE"},
            {"Button 8 category", "BUTTON_8_CATEGORY", "BUTTON_CATEGORIES", "SHOVEL"},
            {"Button 9 category", "BUTTON_9_CATEGORY", "BUTTON_CATEGORIES", "HAMMER"},
            {"Button 10 category", "BUTTON_10_CATEGORY", "BUTTON_CATEGORIES", "PITCHFORK"},
            {"Button 11 category", "BUTTON_11_CATEGORY", "BUTTON_CATEGORIES", "RANGED"},
            {"Button 12 category", "BUTTON_12_CATEGORY", "BUTTON_CATEGORIES", "STAFF"},
            {"Button 13 category", "BUTTON_13_CATEGORY", "BUTTON_CATEGORIES", false},
            {"Button 14 category", "BUTTON_14_CATEGORY", "BUTTON_CATEGORIES", false},
            {"Button 15 category", "BUTTON_15_CATEGORY", "BUTTON_CATEGORIES", false},
        },
    },
    {
        title = "Preferences",
        default_hover = "Select your preference",
        items = {
            {"Preferred Cane", "PREFERRED_CANE", "PREF_CANE", false},
            {"Preferred Weapon", "PREFERRED_WEAPON", "PREF_WEAPON", false},
            {"Preferred Light", "PREFERRED_LIGHTSOURCE", "PREF_LIGHTSOURCE", false},
            {"Preferred Ranged", "PREFERRED_RANGED", "PREF_RANGED", false},
            {"Preferred Armor", "PREFERRED_ARMOR", "PREF_ARMOR", false},
            {"Preferred Head Armor", "PREFERRED_ARMORHAT", "PREF_HEAD_ARMOR", false},
            {"Preferred Body Armor", "PREFERRED_ARMORBODY", "PREF_BODY_ARMOR", false},
            {"Preferred Axe", "PREFERRED_AXE", "PREF_AXE", false},
            {"Preferred Pickaxe", "PREFERRED_PICKAXE", "PREF_PICKAXE", false},
            {"[M] Preferred Scythe", "PREFERRED_SCYTHE", "PREF_SCYTHE", false},
            {"Preferred Staff", "PREFERRED_STAFF", "PREF_STAFF", false},
            {"Preferred Auto-equip light", "PREFERRED_AUTO_LIGHT", "PREF_LIGHTSOURCE", false},
            {"Preferred Lantern fuel", "PREFERRED_FUEL_LANTERN", "PREF_FUEL_LANTERN", false},
            {"Preferred Moggles fuel", "PREFERRED_FUEL_MOGGLES", "PREF_FUEL_MOGGLES", false},
            {"Preferred Campfire fuel", "PREFERRED_CAMPFIRE_FUEL", "PREF_CAMPFIRE_FUEL", false},
        },
    },
    {
        title = "Automation",
        default_hover = "Set to your liking",
        items = {
            {"Auto-unequip repairables","AUTO_UNEQUIP_REPAIRABLES", "YESNO", true, "Auto-unequip repairables before their last use"},
            {"Auto-repeat actions","AUTO_REPEAT_ACTIONS", "YESNO", false, "Auto-repeat actions e.g. cutting wood, mining rocks"},
            {"Auto-re-equip weapon", "AUTO_RE_EQUIP_WEAPON", "AUTO_RE_EQUIP_WEAPON", 2},
            {"Auto-re-equip armor","AUTO_RE_EQUIP_ARMOR", "YESNO", true, "Auto-re-equip to the next best armor"},
            {"Auto-equip weapon","AUTO_EQUIP_WEAPON", "YESNO", true, "Auto-equip your best weapon in combat"},
            {"Auto-equip cane","AUTO_EQUIP_CANE", "YESNO", true, "Auto-equip your cane when moving"},
            {"Auto-equip light", "AUTO_EQUIP_LIGHTSOURCE", "AUTO_EQUIP_LIGHT", 2},
            {"Auto-equip helm","AUTO_EQUIP_HELM", "YESNO", false, "Auto-equip your helm in combat"},
            {"Auto-equip tool","AUTO_EQUIP_TOOL", "AUTO_EQUIP_TOOL", false},
            {"Auto-equip glass cutter", "AUTO_EQUIP_GLASSCUTTER", "YESNO_AUTO_EQUIP_GLASSCUTTER", true},
            {"Auto-regear woodie", "WOODIE_WEREITEM_UNEQUIP", "YESNO_AUTO_REGEAR_WOODIE", true},
            {"Auto-switch bone armor","AUTO_SWITCH_BONE_ARMOR", "YESNO", true, "Auto-switch your bone armors to stay invulnerable"},
            {"Auto-catch boomerang","AUTO_CATCH_BOOMERANG", "YESNO", true},
            {"Auto-store candy bag","AUTO_CANDYBAG", "YESNO", true, "Auto-store candy & trinkets in the Candy Bag"},
            {"Auto-refuel light", "AUTO_REFUEL_LIGHT_SOURCES", "YESNO_AUTO_REFUEL_LIGHT", false},
            {"Auto-eat food","AUTO_EAT_FOOD", "YESNO", false, "Auto-eat food at 0 hunger"},
        },
    },
    {
        title = "Quick Actions",
        default_hover = "Set to your liking",
        items = {
            {"Catch", "QUICK_ACTION_NET", "YESNO", true},
            {"Hammer", "QUICK_ACTION_HAMMER", "YESNO", false},
            {"Dig", "QUICK_ACTION_DIG", "YESNO", true},
            {"Add Fuel Campfires", "QUICK_ACTION_CAMPFIRE", "YESNO", true},
            {"Reset Trap", "QUICK_ACTION_TRAP", "TRAP", 2},
            {"Shave Beefalo", "QUICK_ACTION_BEEFALO", "YESNO", true},
            {"Unlock Loot Stash", "QUICK_ACTION_KLAUS_SACK", "YESNO", true},
            {"Repair Boat", "QUICK_ACTION_REPAIR_BOAT", "YESNO", true},
            {"Build Odd Skeleton", "QUICK_ACTION_BUILD_FOSSIL", "YESNO", true},
            {"Socket Ancient Key", "QUICK_ACTION_ATRIUM_GATE", "YESNO", true},
            {"Track Animal", "QUICK_ACTION_DIRTPILE", "YESNO", true},
            {"Trade Pig King", "QUICK_ACTION_PIG_KING", "YESNO", true},
            {"Feed Bird", "QUICK_ACTION_FEED_BIRD", "YESNO", true},
            {"Wakeup Bird", "QUICK_ACTION_WAKEUP_BIRD", "YESNO", true},
            {"Imprison Bird", "QUICK_ACTION_IMPRISON_BIRD", "YESNO", true},
            {"Repair Wall", "QUICK_ACTION_WALLS", "YESNO", true},
            {"Extinguish Fire", "QUICK_ACTION_EXTINGUISH", "YESNO", true},
            {"Light Slurtle Mound", "QUICK_ACTION_SLURTLEHOLE", "YESNO", false},
        },
    },
    {
        title = "Pickup",
        default_hover = "Set to your liking",
        items = {
            {"Pickup valuables first","PRIOTIZE_VALUABLE_ITEMS", "YESNO", true},
            {"Pickup resurrection item first","PRIOTIZE_RESURRECTION", "YESNO", true, "As ghost prioritise resurrection items"},
            {"Ignore known blueprints","IGNORE_KNOWN_BLUEPRINT", "YESNO", true, "Filter known blueprints from pickup"},
        },
    },
    {
        title = "Telepoof",
        default_hover = "Set to your liking",
        items = {
            {"Disabled by default", "TELEPOOF_DISABLED", "YESNO_TELEPOOF_DISABLED", false},
            {"Hide hovertext", "TELEPOOF_HOVER", "YESNO_TELEPOOF_HOVER", false},
            {"Double-click speed", "TELEPOOF_DOUBLECLICK", "TELEPOOF_SPEED", 0.5},
            {"Double-click Soul Hop", "TELEPOOF_WORTOX", "YESNO", true},
        },
    },
    {
        title = "Mousethrough",
        default_hover = "Set to your liking",
        items = {
            {"Force Inspect Player", "FORCE_INSPECT_PLAYERS", "YESNO_FORCE_INSPECT", false},
            {"Unclickable flying birds", "FLYING_BIRDS_MOUSETHROUGH", "YESNO_FLYING_BIRDS", true},
            {"Star Caller Staff", "YELLOWSTAFF_MOUSETHROUGH", "YESNO_YELLOWSTAFF", true},
            {"The Lazy Explorer", "ORANGESTAFF_MOUSETHROUGH", "YESNO_ORANGESTAFF", true},
        },
    },
    {
        title = "Sorting",
        default_hover = "Set to your liking",
        items = {
            {"Sorting container","CONTAINER_SORT", "SORT_CONTAINER", 3},
            {"Armor priority","ARMOR_SORT_PRIORITY", "PRIORITY", 7},
            {"Light priority","LIGHT_SORT_PRIORITY", "PRIORITY", 6},
            {"Staff priority","STAFF_SORT_PRIORITY", "PRIORITY", 5},
            {"Equipment priority","EQUIPMENT_SORT_PRIORITY", "PRIORITY", 4},
            {"Food priority","FOOD_SORT_PRIORITY", "PRIORITY", 3},
            {"Resource priority","RESOURCE_SORT_PRIORITY", "PRIORITY", 2},
            {"Tool priority","TOOL_SORT_PRIORITY", "PRIORITY", 1},
            {"Keep in slot 1","OVERRIDE_SLOT1_SORT", "SORT_OVERRIDE", false},
        },
    },
    {
        title = "Miscellaneous",
        default_hover = "Set to your liking",
        items = {
            {"Damage estimation","DAMAGE_ESTIMATION", "YESNO", true},
            {"Allow Tools on Weapon button","TOOLS_ON_WEAPON", "YESNO", true},
        },
    },
}

configuration_options = {}

for i = 1, #CONFIG_STRUCTURE do
    local section = CONFIG_STRUCTURE[i]

    configuration_options[#configuration_options + 1] = title(section.title)

    if section.items then
        for j = 1, #section.items do
            local item_data = section.items[j]

            local label = item_data[1]
            local name = item_data[2]
            local options_key = item_data[3]
            local default_value = item_data[4]
            local hover = item_data[5] or section.default_hover

            local options_list = OPTION_SETS[options_key]

            if not options_list then
                options_list = {}
            end
            configuration_options[#configuration_options + 1] = cfg(label, name, options_list, default_value, hover)
        end
    end
end