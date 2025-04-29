name = "Equipment Control"
description = "If you have suggestions/ideas/bugs let me know in this mod's comment section on Steam\n\n\n\n\n\n\n\n\n\n\n\n\n\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tMade with 󰀍"
icon_atlas = "modicon.xml"
icon = "modicon.tex"
author = "Boas"
version = "7.30"
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


local YESNO = boolOpt()
local YESNO_BETA = boolOpt("Experimental – use at your own risk!")
local YESNO_PREF_SHORTCUT = boolOpt("Right click to change preference")
local YESNO_AUTOEQUIP_SHORTCUT = boolOpt("Hold Shift + Right click to change Auto-equip")
local YESNO_TELEPOOF_HOVER = boolOpt("Hovertext is hidden when Telepoof is disabled")
local YESNO_TELEPOOF_DISABLED = boolOpt("Telepoof is disabled when you enter the game")
local YESNO_FORCE_INSPECT = boolOpt("Requires you to hold Force Inspect to interact with Players")
local YESNO_FLYING_BIRDS = boolOpt("Flying birds are unclickable")
local YESNO_YELLOWSTAFF = boolOpt("Allows you to cast Dwarf Stars closer together")
local YESNO_ORANGESTAFF = boolOpt("Allows you to Telepoof through walls")
local YESNO_AUTO_EQUIP_GLASSCUTTER = boolOpt("Auto-equip your glass cutter against nightmare creatures")
local YESNO_AUTO_REGEAR_WOODIE = boolOpt("Auto-regear when transforming back to Woodie")
local YESNO_AUTO_REFUEL_LIGHT = boolOpt()

local PRIORITY = {}
for p = 7, 1, -1 do
    PRIORITY[#PRIORITY + 1] = opt("" .. (8 - p), p)
end

local KB = {}
KB[#KB + 1] = opt("Disabled", false)
do -- Scope for local vars
    local ALPHA = {
        "A","B","C","D","E","F","G","H","I","J","K","L","M",
        "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    }
    for i = 1, #ALPHA do
        local letter = ALPHA[i]
        KB[#KB + 1] = opt(letter, "KEY_" .. letter)
    end

    for i = 0, 9 do
        KB[#KB + 1] = opt("" .. i, "KEY_" .. i)
    end

    for i = 1, 12 do
        KB[#KB + 1] = opt("F" .. i, "KEY_F" .. i)
    end

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
    for i = 1, #specialsTXT do
        KB[#KB + 1] = opt(specialsTXT[i], "KEY_" .. specialsKEY[i])
    end
end
KB[#KB + 1] = opt("Disabled", false)

local KB_CONFIRM_EAT = {}
for i=1,#KB do KB_CONFIRM_EAT[i] = opt(KB[i].description, KB[i].data, "Avoid accidentally eating valuable foods") end

local KB_PICKUP_FILTER = {}
for i=1,#KB do KB_PICKUP_FILTER[i] = opt(KB[i].description, KB[i].data, "Add entities under your mouse to the Pickup filter") end

local KB_ATTACK_FILTER = {}
for i=1,#KB do KB_ATTACK_FILTER[i] = opt(KB[i].description, KB[i].data, "Add entities under your mouse to the Attack filter") end

local BUTTON_CATEGORIES = {
    opt("Disabled", false),
    opt("Cane", "CANE"),
    opt("Weapon", "WEAPON"),
    opt("Light", "LIGHTSOURCE"),
    opt("Armor", "ARMOR"),
    opt("Head armor", "ARMORHAT"),
    opt("Body armor", "ARMORBODY"),
    opt("Axe", "AXE"),
    opt("Pickaxe", "PICKAXE"),
    opt("Hammer", "HAMMER"),
    opt("Shovel", "SHOVEL"),
    opt("[M] Scythe", "SCYTHE"),
    opt("Pitchfork", "PITCHFORK"),
    opt("Food", "FOOD"),
    opt("Healing food", "HEALINGFOOD"),
    opt("Ranged", "RANGED"),
    opt("Staff", "STAFF"),
    opt("Amulet", "AMULET"),
}

local PREF_CANE = {
    opt("Disabled", false),
    opt("The Lazy Explorer", "orangestaff"),
    opt("Walking Cane", "cane"),
    opt("Dumbbell", "dumbbell"),
    opt("Golden Dumbbell", "dumbbell_golden"),
    opt("Marbell", "dumbbell_marble"),
    opt("Gembell", "dumbbell_gem"),
    opt("Firebell", "dumbell_redgem"),
    opt("Icebell", "dumbell_bluegem"),
    opt("Thermbell", "dumbell_heat"),
}

local PREF_WEAPON = {
    opt("Disabled", false),
    opt("Shield of Terror", "shieldofterror"),
    opt("Darksword", "nightsword"),
    opt("Glasscutter", "glasscutter"),
    opt("Thulecite Club", "ruins_bat"),
    opt("Hambat", "hambat"),
    opt("Tentacle Spike", "tentaclespike"),
    opt("Morning Star", "nightstick"),
    opt("Bat Bat", "batbat"),
    opt("Battle Spear", "spear_wathgrithr"),
    opt("Spear", "spear"),
    opt("Tail o' Three Cats", "whip"),
    opt("Bull Kelp Stalk", "bullkelp_root"),
    opt("[M] Katana", "katana"),
    opt("[M] Poseidon", "poseidon"),
    opt("[M] Skullspear", "skullspear"),
    opt("[M] Halberd", "haolberd"),
    opt("[M] Deathscythe", "deathscythe"),
    opt("[M] Purplesword", "purplesword"),
    opt("[M] Battleaxe", "battleaxe"),
    opt("[M] Pirate", "pirate"),
    opt("[M] Lightningsword", "lightningsword"),
    opt("[M] Flamesword", "flamesword"),
}

local PREF_LIGHTSOURCE = {
    opt("Disabled", false),
    opt("Lantern", "lantern"),
    opt("Miner Hat", "minerhat"),
    opt("Willow's Lighter", "lighter"),
    opt("Torch", "torch"),
    opt("Moggles", "molehat"),
}

local PREF_RANGED = {
    opt("Disabled", false),
    opt("Trusty Slingshot", "slingshot"),
    opt("Blow Dart", "blowdart_pipe"),
    opt("Electric Dart", "blowdart_yellow"),
    opt("Fire Dart", "blowdart_fire"),
    opt("Sleep Dart", "blowdart_sleep"),
    opt("Boomerang", "boomerang"),
    opt("Napsack", "sleepbomb"),
    opt("[M] Bow", "bow"),
    opt("[M] Musket", "musket"),
    opt("[M] Crossbow", "crossbow"),
}

local PREF_HEAD_ARMOR = {
    opt("Disabled", false),
    opt("Eye Mask", "eyemaskhat"),
    opt("Bone Helm", "skeletonhat"),
    opt("Thulecite Crown", "ruinshat"),
    opt("Shelmet", "slurtlehat"),
    opt("Bee Queen Crown", "hivehat"),
    opt("Battle Helm", "wathgrithrhat"),
    opt("Football Helmet", "footballhat"),
    opt("Beekeeper Hat", "beehat"),
    opt("CookieCutter Cap", "cookiecutterhat"),
}

local PREF_BODY_ARMOR = {
    opt("Disabled", false),
    opt("Bone Armor", "armorskeleton"),
    opt("Thulecite Suit", "armorruins"),
    opt("Scalemail", "armordragonfly"),
    opt("Marble Suit", "armormarble"),
    opt("Snurtle Shell", "armorsnurtleshell"),
    opt("Night Armor", "armor_sanity"),
    opt("Log Suit", "armorwood"),
    opt("Bramble Husk", "armor_bramble"),
    opt("Grass Suit", "armorgrass"),
}

local PREF_ARMOR = {}
for i = 1, #PREF_HEAD_ARMOR do PREF_ARMOR[#PREF_ARMOR + 1] = PREF_HEAD_ARMOR[i] end
for i = 1, #PREF_BODY_ARMOR do
    if PREF_BODY_ARMOR[i].data then PREF_ARMOR[#PREF_ARMOR + 1] = PREF_BODY_ARMOR[i] end
end

local PREF_AXE = {
    opt("Disabled", false),
    opt("Lucy the Axe", "lucy"),
    opt("Moon Glass Axe", "moonglassaxe"),
    opt("Luxury Axe", "goldenaxe"),
    opt("Axe", "axe"),
}

local PREF_PICKAXE = {
    opt("Disabled", false),
    opt("Pick/Axe", "multitool_axe_pickaxe"),
    opt("Opulent Pickaxe", "goldenpickaxe"),
    opt("Pickaxe", "pickaxe"),
}

local PREF_SCYTHE = {
    opt("Disabled", false),
    opt("Golden Scythe", "scythe_golden"),
    opt("Scythe", "scythe"),
}

local PREF_STAFF = {
    opt("Disabled", false),
    opt("Star Caller Staff", "yellowstaff"),
    opt("Moon Caller Staff", "opalstaff"),
    opt("Fire Staff", "firestaff"),
    opt("Ice Staff", "icestaff"),
    opt("Telelocator Staff", "telestaff"),
    opt("Deconstruct Staff", "greenstaff"),
    opt("Weather Pain", "staff_tornado"),
}

local PREF_FUEL_LANTERN = {
    opt("Disabled", false),
    opt("Light Bulb", "lightbulb"),
    opt("Slurtle Slime", "slurtleslime"),
}

local PREF_FUEL_MOGGLES = {
    opt("Disabled", false),
    opt("Glow Berry", "wormlight"),
    opt("Lesser Glow Berry", "wormlight_lesser"),
}

local PREF_CAMPFIRE_FUEL = {
    opt("Disabled", false),
    opt("Charcoal", "charcoal"),
    opt("Boards", "boards"),
    opt("Rope", "rope"),
    opt("Log", "log"),
    opt("Cut Grass", "cutgrass"),
    opt("Twigs", "twigs"),
    opt("Beefalo Wool", "beefalowool"),
    opt("Pine Cone", "pinecone"),
    opt("Manure", "poop"),
    opt("Rotten Egg", "rottenegg"),
    opt("Rot", "spoiled_food"),
    opt("Nitre", "nitre"),
}

local AUTO_RE_EQUIP_WEAPON_OPTS = {
    opt("Disabled", false),
    opt("Enabled (Same)", 1, "Auto-re-equip to the same weapon"),
    opt("Enabled (Best)", 2, "Auto-re-equip to the next best weapon"),
}

local AUTO_EQUIP_LIGHT_OPTS = {
    opt("Disabled", false),
    opt("Enabled", 1, "Auto-equip your light in the dark!"),
    opt("Enabled (Craft)", 2, "Auto-equip your light in the dark! (Auto-craft enabled)"),
}

local AUTO_EQUIP_TOOL_OPTS = {
    opt("Disabled", false),
    opt("Enabled", 1, "Auto-equip tools"),
    opt("Enabled (Craft)", 2, "Auto-equip tools (Auto-craft enabled)"),
}

local TRAP_OPTS = {
    opt("Disabled", false),
    opt("Sprung", 1, "Only display on traps in a sprung state"),
    opt("Always", 2),
}

local TELEPOOF_SPEED = {
    opt("Disabled", false),
    opt("Default", .5, "Double-click speed is 1/2 of a second"),
    opt("Fast", .3, "Double-click speed is 1/3 of a second"),
    opt("Ludicrous", .25, "Double-click speed is 1/4 of a second"),
    opt("Plaid", .2, "Double-click speed is 1/5 of a second"),
}

local SORT_OVERRIDE_OPTS = {
    opt("Disabled", false),
    opt("Abigail's Flower", "abigail_flower"),
}

local SORT_CONTAINER_OPTS = {
    opt("Full inventory", 3, "Sorts your inventory and backpack"),
    opt("Inventory", 2, "Sorts only your inventory"),
    opt("Backpack", 1, "Sorts only your backpack"),
}

local DATA = {
    keybinds = {
        {"Cane","CANE","KEY_Z"},
        {"Weapon","WEAPON","KEY_X"},
        {"Light","LIGHTSOURCE","KEY_C"},
        {"Ranged","RANGED","KEY_R"},
        {"Armor","ARMOR",false},
        {"Head armor","ARMORHAT","KEY_H"},
        {"Body armor","ARMORBODY","KEY_B"},
        {"Axe","AXE",false},
        {"Pickaxe","PICKAXE",false},
        {"Hammer","HAMMER",false},
        {"Shovel","SHOVEL",false},
        {"Pitchfork","PITCHFORK",false},
        {"[M] Scythe","SCYTHE",false},
        {"Staff","STAFF",false},
        {"Food","FOOD",false},
        {"Healing food","HEALINGFOOD",false},
        {"Drop lantern","DROPKEY","KEY_K"},
        {"Meat prioritization mode","MEAT_PRIORITIZATION_MODE","KEY_F9"},
        {"Eat confirmation","CONFIRM_TO_EAT","KEY_CTRL", true},
        {"Pickup filter","PICKUP_FILTER","KEY_F1", true},
        {"Attack filter","ATTACK_FILTER","KEY_F2", true},
        {"Sort inventory","SORT_INVENTORY","KEY_F3"},
        {"Sort chest","SORT_CHEST","KEY_F4"},
    },
    toggles = {
        -- Label, Name, Default
        {"Toggle Telepoof","TOGGLE_TELEPOOF","KEY_F5"},
        {"Toggle Sorting container","TOGGLE_SORTING_CONTAINER","KEY_F6"},
        {"Toggle Auto-equip weapon","TOGGLE_AUTO_EQUIP","KEY_F7"},
        {"Toggle Auto-equip cane","TOGGLE_AUTO_EQUIP_CANE","KEY_F8"},
    },
    buttons = {
        -- Label, Name, Options, Default, Hover
        {"Show buttons","BUTTON_SHOW", YESNO, true, "Set to your liking"},
        {"Button animations","BUTTON_ANIMATIONS", YESNO, true, "Set to your liking"},
        {"Display keybind on button","BUTTON_SHOW_KEYBIND", YESNO, false, "Set to your liking"},
        {"Preference shortcut", "BUTTON_PREFERENCE_CHANGE", YESNO_PREF_SHORTCUT, true, "Set to your liking"},
        {"Auto-equip shortcut", "BUTTON_AUTO_EQUIP_CHANGE", YESNO_AUTOEQUIP_SHORTCUT, true, "Set to your liking"},
        {"Button 1 category", "BUTTON_1_CATEGORY", BUTTON_CATEGORIES, "ARMORHAT", "Set to your liking"},
        {"Button 2 category", "BUTTON_2_CATEGORY", BUTTON_CATEGORIES, "ARMORBODY", "Set to your liking"},
        {"Button 3 category", "BUTTON_3_CATEGORY", BUTTON_CATEGORIES, "WEAPON", "Set to your liking"},
        {"Button 4 category", "BUTTON_4_CATEGORY", BUTTON_CATEGORIES, "CANE", "Set to your liking"},
        {"Button 5 category", "BUTTON_5_CATEGORY", BUTTON_CATEGORIES, "LIGHTSOURCE", "Set to your liking"},
        {"Button 6 category", "BUTTON_6_CATEGORY", BUTTON_CATEGORIES, "AXE", "Set to your liking"},
        {"Button 7 category", "BUTTON_7_CATEGORY", BUTTON_CATEGORIES, "PICKAXE", "Set to your liking"},
        {"Button 8 category", "BUTTON_8_CATEGORY", BUTTON_CATEGORIES, "SHOVEL", "Set to your liking"},
        {"Button 9 category", "BUTTON_9_CATEGORY", BUTTON_CATEGORIES, "HAMMER", "Set to your liking"},
        {"Button 10 category", "BUTTON_10_CATEGORY", BUTTON_CATEGORIES, "PITCHFORK", "Set to your liking"},
        {"Button 11 category", "BUTTON_11_CATEGORY", BUTTON_CATEGORIES, "RANGED", "Set to your liking"},
        {"Button 12 category", "BUTTON_12_CATEGORY", BUTTON_CATEGORIES, "STAFF", "Set to your liking"},
        {"Button 13 category", "BUTTON_13_CATEGORY", BUTTON_CATEGORIES, false, "Set to your liking"},
        {"Button 14 category", "BUTTON_14_CATEGORY", BUTTON_CATEGORIES, false, "Set to your liking"},
        {"Button 15 category", "BUTTON_15_CATEGORY", BUTTON_CATEGORIES, false, "Set to your liking"},
    },
    preferences = {
        -- Label, Name, Options, Default
        {"Preferred Cane", "PREFERRED_CANE", PREF_CANE, false},
        {"Preferred Weapon", "PREFERRED_WEAPON", PREF_WEAPON, false},
        {"Preferred Light", "PREFERRED_LIGHTSOURCE", PREF_LIGHTSOURCE, false},
        {"Preferred Ranged", "PREFERRED_RANGED", PREF_RANGED, false},
        {"Preferred Armor", "PREFERRED_ARMOR", PREF_ARMOR, false},
        {"Preferred Head Armor", "PREFERRED_ARMORHAT", PREF_HEAD_ARMOR, false},
        {"Preferred Body Armor", "PREFERRED_ARMORBODY", PREF_BODY_ARMOR, false},
        {"Preferred Axe", "PREFERRED_AXE", PREF_AXE, false},
        {"Preferred Pickaxe", "PREFERRED_PICKAXE", PREF_PICKAXE, false},
        {"[M] Preferred Scythe", "PREFERRED_SCYTHE", PREF_SCYTHE, false},
        {"Preferred Staff", "PREFERRED_STAFF", PREF_STAFF, false},
        {"Preferred Auto-equip light", "PREFERRED_AUTO_LIGHT", PREF_LIGHTSOURCE, false},
        {"Preferred Lantern fuel", "PREFERRED_FUEL_LANTERN", PREF_FUEL_LANTERN, false},
        {"Preferred Moggles fuel", "PREFERRED_FUEL_MOGGLES", PREF_FUEL_MOGGLES, false},
        {"Preferred Campfire fuel", "PREFERRED_CAMPFIRE_FUEL", PREF_CAMPFIRE_FUEL, false},
    },
    automation = {
        -- Label, Name, Options, Default, Hover
        {"Auto-unequip repairables","AUTO_UNEQUIP_REPAIRABLES", YESNO, true, "Auto-unequip repairables before their last use"},
        {"Auto-repeat actions","AUTO_REPEAT_ACTIONS", YESNO, false, "Auto-repeat actions e.g. cutting wood, mining rocks"},
        {"Auto-re-equip weapon", "AUTO_RE_EQUIP_WEAPON", AUTO_RE_EQUIP_WEAPON_OPTS, 2, "Set to your liking"}, -- Updated
        {"Auto-re-equip armor","AUTO_RE_EQUIP_ARMOR", YESNO, true, "Auto-re-equip to the next best armor"},
        {"Auto-equip weapon","AUTO_EQUIP_WEAPON", YESNO, true, "Auto-equip your best weapon in combat"},
        {"Auto-equip cane","AUTO_EQUIP_CANE", YESNO, true, "Auto-equip your cane when moving"},
        {"Auto-equip light", "AUTO_EQUIP_LIGHTSOURCE", AUTO_EQUIP_LIGHT_OPTS, 2, "Set to your liking"}, -- Added
        {"Auto-equip helm","AUTO_EQUIP_HELM", YESNO, false, "Auto-equip your helm in combat"},
        {"Auto-equip tool","AUTO_EQUIP_TOOL", AUTO_EQUIP_TOOL_OPTS, false, "Set to your liking"}, -- Updated
        {"Auto-equip glass cutter", "AUTO_EQUIP_GLASSCUTTER", YESNO_AUTO_EQUIP_GLASSCUTTER, true, "Set to your liking"}, -- Added
        {"Auto-regear woodie", "WOODIE_WEREITEM_UNEQUIP", YESNO_AUTO_REGEAR_WOODIE, true, "Set to your liking"}, -- Added
        {"Auto-switch bone armor","AUTO_SWITCH_BONE_ARMOR", YESNO, true, "Auto-switch your bone armors to stay invulnerable"},
        {"Auto-catch boomerang","AUTO_CATCH_BOOMERANG", YESNO, true, "Set to your liking"},
        {"Auto-store candy bag","AUTO_CANDYBAG", YESNO, true, "Auto-store candy & trinkets in the Candy Bag"},
        {"Auto-refuel light", "AUTO_REFUEL_LIGHT_SOURCES", YESNO_AUTO_REFUEL_LIGHT, false, "Set to your liking"}, -- Added
        {"Auto-eat food","AUTO_EAT_FOOD", YESNO, false, "Auto-eat food at 0 hunger"},
    },
    quick_actions = {
        -- Label, Name, Options, Default
        {"Catch", "QUICK_ACTION_NET", YESNO, true},
        {"Hammer", "QUICK_ACTION_HAMMER", YESNO, false},
        {"Dig", "QUICK_ACTION_DIG", YESNO, true},
        {"Add Fuel Campfires", "QUICK_ACTION_CAMPFIRE", YESNO, true},
        {"Reset Trap", "QUICK_ACTION_TRAP", TRAP_OPTS, 2},
        {"Shave Beefalo", "QUICK_ACTION_BEEFALO", YESNO, true},
        {"Unlock Loot Stash", "QUICK_ACTION_KLAUS_SACK", YESNO, true},
        {"Repair Boat", "QUICK_ACTION_REPAIR_BOAT", YESNO, true},
        {"Build Odd Skeleton", "QUICK_ACTION_BUILD_FOSSIL", YESNO, true},
        {"Socket Ancient Key", "QUICK_ACTION_ATRIUM_GATE", YESNO, true},
        {"Track Animal", "QUICK_ACTION_DIRTPILE", YESNO, true},
        {"Trade Pig King", "QUICK_ACTION_PIG_KING", YESNO, true},
        {"Feed Bird", "QUICK_ACTION_FEED_BIRD", YESNO, true},
        {"Wakeup Bird", "QUICK_ACTION_WAKEUP_BIRD", YESNO, true},
        {"Imprison Bird", "QUICK_ACTION_IMPRISON_BIRD", YESNO, true},
        {"Repair Wall", "QUICK_ACTION_WALLS", YESNO, true},
        {"Extinguish Fire", "QUICK_ACTION_EXTINGUISH", YESNO, true},
        {"Light Slurtle Mound", "QUICK_ACTION_SLURTLEHOLE", YESNO, false},
    },
    pickup = {
        -- Label, Name, Options, Default, Hover
        {"Pickup valuables first","PRIOTIZE_VALUABLE_ITEMS", YESNO, true, "Set to your liking"},
        {"Pickup resurrection item first","PRIOTIZE_RESURRECTION", YESNO, true, "As ghost prioritise resurrection items"},
        {"Ignore known blueprints","IGNORE_KNOWN_BLUEPRINT", YESNO, true, "Filter known blueprints from pickup"},
    },
    picking = {
        -- Label, Name, Options, Default
        {"Never pick Flowers","PICKUP_IGNORE_FLOWERS", YESNO, true},
        {"Never pick Succulents","PICKUP_IGNORE_SUCCULENTS", YESNO, true},
        {"Never pick Ferns","PICKUP_IGNORE_FERNS", YESNO, true},
        {"Never pick Spiky Bush","PICKUP_IGNORE_MARSH_BUSH", YESNO, false},
    },
    telepoof = {
        -- Label, Name, Options, Default
        {"Disabled by default", "TELEPOOF_DISABLED", YESNO_TELEPOOF_DISABLED, false},
        {"Hide hovertext", "TELEPOOF_HOVER", YESNO_TELEPOOF_HOVER, false},
        {"Double-click speed", "TELEPOOF_DOUBLECLICK", TELEPOOF_SPEED, 0.5},
        {"Double-click Soul Hop", "TELEPOOF_WORTOX", YESNO, true},
    },
    mousethrough = {
        -- Label, Name, Options, Default
        {"Force Inspect Player", "FORCE_INSPECT_PLAYERS", YESNO_FORCE_INSPECT, false},
        {"Unclickable flying birds", "FLYING_BIRDS_MOUSETHROUGH", YESNO_FLYING_BIRDS, true},
        {"Star Caller Staff", "YELLOWSTAFF_MOUSETHROUGH", YESNO_YELLOWSTAFF, true},
        {"The Lazy Explorer", "ORANGESTAFF_MOUSETHROUGH", YESNO_ORANGESTAFF, true},
    },
    sorting = {
        -- Label, Name, Options, Default
        {"Sorting container","CONTAINER_SORT", SORT_CONTAINER_OPTS, 3},
        {"Armor priority","ARMOR_SORT_PRIORITY", PRIORITY, 7},
        {"Light priority","LIGHT_SORT_PRIORITY", PRIORITY, 6},
        {"Staff priority","STAFF_SORT_PRIORITY", PRIORITY, 5},
        {"Equipment priority","EQUIPMENT_SORT_PRIORITY", PRIORITY, 4},
        {"Food priority","FOOD_SORT_PRIORITY", PRIORITY, 3},
        {"Resource priority","RESOURCE_SORT_PRIORITY", PRIORITY, 2},
        {"Tool priority","TOOL_SORT_PRIORITY", PRIORITY, 1},
        {"Keep in slot 1","OVERRIDE_SLOT1_SORT", SORT_OVERRIDE_OPTS, false},
    },
    misc = {
        -- Label, Name, Options, Default
        {"Damage estimation","DAMAGE_ESTIMATION", YESNO, true},
        {"Allow Tools on Weapon button","TOOLS_ON_WEAPON", YESNO, true},
    },
}

configuration_options = {}

local assignKeyMsg = "Assign a key"
local preferenceMsg = "Select your preference"
local settingMsg = "Set to your liking"

-- Keybinds
configuration_options[#configuration_options+1] = title("Keybinds")
for i = 1, #DATA.keybinds do
    local e = DATA.keybinds[i]
    local kb_options = KB
    local hover = e[4] or assignKeyMsg
    if e[4] == true then
        if e[2] == "CONFIRM_TO_EAT" then kb_options = KB_CONFIRM_EAT end
        if e[2] == "PICKUP_FILTER" then kb_options = KB_PICKUP_FILTER end
        if e[2] == "ATTACK_FILTER" then kb_options = KB_ATTACK_FILTER end
        hover = assignKeyMsg
    end
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], kb_options, e[3], hover)
end

-- Toggles
configuration_options[#configuration_options+1] = title("Toggles")
for i = 1, #DATA.toggles do
    local e = DATA.toggles[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], KB, e[3], assignKeyMsg)
end

-- Buttons
configuration_options[#configuration_options+1] = title("Buttons")
for i = 1, #DATA.buttons do
    local e = DATA.buttons[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], e[5] or settingMsg)
end

-- Preferences
configuration_options[#configuration_options+1] = title("Preferences")
for i = 1, #DATA.preferences do
    local e = DATA.preferences[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], preferenceMsg)
end

-- Automation
configuration_options[#configuration_options+1] = title("Automation")
for i = 1, #DATA.automation do
    local e = DATA.automation[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], e[5] or settingMsg)
end

-- Quick Actions
configuration_options[#configuration_options+1] = title("Quick Actions")
for i = 1, #DATA.quick_actions do
    local e = DATA.quick_actions[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], settingMsg)
end

-- Pickup
configuration_options[#configuration_options+1] = title("Pickup")
for i = 1, #DATA.pickup do
    local e = DATA.pickup[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], e[5] or settingMsg)
end

-- Picking
configuration_options[#configuration_options+1] = title("Picking")
for i = 1, #DATA.picking do
    local e = DATA.picking[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], settingMsg)
end

-- Telepoof
configuration_options[#configuration_options+1] = title("Telepoof")
for i = 1, #DATA.telepoof do
    local e = DATA.telepoof[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], settingMsg)
end

-- Mousethrough
configuration_options[#configuration_options+1] = title("Mousethrough")
for i = 1, #DATA.mousethrough do
    local e = DATA.mousethrough[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], settingMsg)
end

-- Sorting
configuration_options[#configuration_options+1] = title("Sorting")
for i = 1, #DATA.sorting do
    local e = DATA.sorting[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], settingMsg)
end

-- Miscellaneous
configuration_options[#configuration_options+1] = title("Miscellaneous")
for i = 1, #DATA.misc do
    local e = DATA.misc[i]
    configuration_options[#configuration_options+1] = cfg(e[1], e[2], e[3], e[4], settingMsg)
end