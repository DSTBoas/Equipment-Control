local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"
local FileSystem = require "util/filesystem"
local Say = require "util/say"
local TheInput = GLOBAL.TheInput
local MOD_EQUIPMENT_CONTROL = GLOBAL.MOD_EQUIPMENT_CONTROL
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local ACTIONS = GLOBAL.ACTIONS
local CanEntitySeeTarget = GLOBAL.CanEntitySeeTarget
local TOOLACTIONS = GLOBAL.TOOLACTIONS
local BufferedAction = GLOBAL.BufferedAction
local STRINGS = GLOBAL.STRINGS
local TheSim = GLOBAL.TheSim
local CONTROL_ACTION = GLOBAL.CONTROL_ACTION
local Namemap = require "util/blueprint_namemap"

-- Config
local PRIORITIZE_VALUABLE = GetModConfigData("PRIOTIZE_VALUABLE_ITEMS", MOD_EQUIPMENT_CONTROL.MODNAME)
local MEAT_MODE = (GetModConfigData("MEAT_PRIORITIZATION_MODE", MOD_EQUIPMENT_CONTROL.MODNAME) or "NONE"):upper()
local Filter_File = "mod_equipment_control_pickup_filter.txt"
local PriotizedPickups = {
    greengem = .5,
    yellowgem = .45,
    orangegem = .4,
    deerclops_eyeball = 2,
    minotaurhorn = 1,
    hivehat = 2,
    dragon_scales = 1,
    bearger_fur = 1,
    klaussackkey = 2,
    shadowheart = 1,
    skeletonhat = 3,
    armorskeleton = 3,
    shroom_skin = 1,
    ["Blue Funcap Blueprint"] = 3,
    ["Green Funcap Blueprint"] = 3,
    ["Red Funcap Blueprint"] = 3,
    ["Mushlight Blueprint"] = 3,
    ["Glowcap Blueprint"] = 3,
    ["Scaled Furnace Blueprint"] = 2,
    ["Bundling Wrap Blueprint"] = 3,
    ["Winged Sail Kit Blueprint"] = 3,
    ["Feathery Canvas Blueprint"] = 3,
    ["The Lazy Deserter Blueprint"] = 1,
    ["Strident Trident Blueprint"] = 3
}

-- Logic
local PickupFilter = {prefabs = {}}

local function AddFilteredPrefab(prefab)
    PickupFilter.prefabs[prefab] = true
end

local function AddFilteredTag(tag)
    PickupFilter.tags[tag] = true
end
local function AddFilteredPrefab(prefab)
    PickupFilter.prefabs[prefab] = true
end

local TagCandidates = {"flower"}

local function GetFilterKey(ent)
    for _, tag in ipairs(TagCandidates) do
        if ent:HasTag(tag) then
            return "tag", tag
        end
    end
    return "prefab", ent.prefab
end

if GetModConfigData("PICKUP_IGNORE_FERNS", MOD_EQUIPMENT_CONTROL.MODNAME) then
    AddFilteredPrefab("cave_fern")
    AddFilteredPrefab("stalker_fern")
end

if GetModConfigData("PICKUP_IGNORE_SUCCULENTS", MOD_EQUIPMENT_CONTROL.MODNAME) then
    AddFilteredPrefab("succulent_plant")
end

if GetModConfigData("PICKUP_IGNORE_MARSH_BUSH", MOD_EQUIPMENT_CONTROL.MODNAME) then
    AddFilteredPrefab("marsh_bush")
end

local function SavePickupFilter()
    local list = {}
    for p in pairs(PickupFilter.prefabs) do
        table.insert(list, p)
    end
    FileSystem:SaveTableToFile(Filter_File, list)
end

local function LoadPickupFilter(onLoaded)
    FileSystem:LoadTableFromFile(
        Filter_File,
        function(list)
            for _, p in ipairs(list or {}) do
                PickupFilter.prefabs[p] = true
            end
            if onLoaded then
                onLoaded()
            end
        end
    )
end

local function AddColor(ent)
    if ent and ent.AnimState then
        ent.AnimState:SetMultColour(1, 0, 0, 1)
    end
end

local function RemoveColor(ent)
    if ent and ent.AnimState then
        ent.AnimState:SetMultColour(1, 1, 1, 1)
    end
end

local function SafeHasTag(ent, tag)
    return ent and ent.HasTag and ent:HasTag(tag)
end

local function IsFiltered(ent)
    return PickupFilter.prefabs[ent.prefab] or false
end

local function AddToFilter(ent)
    PickupFilter.prefabs[ent.prefab] = not IsFiltered(ent) or nil
    SavePickupFilter()
    return PickupFilter.prefabs[ent.prefab]
end

local DEBUG_PICKUP_PRIORITY = true

local function DebugPriority(fmt, ...)
    if DEBUG_PICKUP_PRIORITY then
        print(("[Pickup-Priority]  " .. fmt):format(...))
    end
end

local function GetBlueprintRecipeId(bp)
    if bp == nil then
        return nil
    end

    if bp.components and bp.components.blueprint then
        return bp.components.blueprint.recipename or
            (bp.components.blueprint.GetRecipeName and bp.components.blueprint:GetRecipeName())
    end

    if bp.replica and bp.replica.blueprint then
        local rb = bp.replica.blueprint
        return rb.recipename and rb.recipename:value() or (rb.GetRecipeName and rb:GetRecipeName())
    end
end

local function IsMeat(ent)
    return ent:HasTag("meat")
end

local function KnowsBlueprint(bp)
    if not (bp and bp.prefab == "blueprint") then
        return false
    end

    local id = GetBlueprintRecipeId(bp) or Namemap.DisplayToId(bp.name)

    DebugPriority('Blueprint %-24s  -> recipe id "%s"', bp.name, tostring(id))

    if not id then
        return false
    end

    local knows = CraftFunctions:KnowsRecipe(id)
    DebugPriority("Player knows recipe '%s'?  %s", id, tostring(knows))
    return knows
end

local function GetPriority(ent)
    if ent.prefab == "blueprint" and KnowsBlueprint(ent) then
        return -1
    end

    if IsMeat(ent) then
        if MEAT_MODE == "IGNORE" then
            return 0
        elseif MEAT_MODE == "FIRST" then
            return 99
        elseif MEAT_MODE == "LAST" then
            return -99
        end
    end

    if PRIORITIZE_VALUABLE then
        return PriotizedPickups[ent.name] or PriotizedPickups[ent.prefab] or 0
    end

    return 0
end

local function GetModifiedEnts(inst, exclude, tags)
    local x, y, z = inst.Transform:GetWorldPosition()
    local raw = TheSim:FindEntities(x, y, z, 6, nil, exclude, tags)

    local scored = {}
    for _, ent in ipairs(raw) do
        if
            not (MEAT_MODE == "IGNORE" and IsMeat(ent)) and not IsFiltered(ent) and
                not (ent.prefab == "blueprint" and KnowsBlueprint(ent) and
                    GetModConfigData("IGNORE_KNOWN_BLUEPRINT", MOD_EQUIPMENT_CONTROL.MODNAME))
         then
            table.insert(scored, {ent = ent, priority = GetPriority(ent)})
        end
    end

    table.sort(
        scored,
        function(a, b)
            return a.priority > b.priority
        end
    )

    local result = {}
    for i, v in ipairs(scored) do
        result[i] = v.ent
        DebugPriority("  #%d  %-25s  priority %d", i, v.ent.name or v.ent.prefab, v.priority)
    end
    return result
end

local function tintIfFiltered(inst)
    if inst and inst.AnimState and PickupFilter.prefabs[inst.prefab] then
        AddColor(inst)
    end
end

AddPrefabPostInitAny(tintIfFiltered)

local function ActionButtonOverride(inst, force_target)
    if force_target then
        return nil, true
    end

    local pc = inst.components.playercontroller
    if pc ~= nil and pc:IsDoingOrWorking() then
        return nil, true
    end

    local exclude_tags = {"FX", "NOCLICK", "DECOR", "INLIMBO", "catchable", "mineactive", "intense"}
    local tags = {
        "_inventoryitem",
        "pickable",
        "harvestable",
        "trapsprung",
        "minesprung",
        "inactive",
        "smolder",
        "tapped_harvestable",
        "dried",
        "donecooking",
        "corpse"
    }

    local ents = GetModifiedEnts(inst, exclude_tags, tags)
    for _, ent in ipairs(ents) do
        DebugPriority("Picking up %s with priority %d", ent.name or ent.prefab, GetPriority(ent))
        if CanEntitySeeTarget(inst, ent) then
            local action = inst.components.playeractionpicker:GetLeftClickActions(ent:GetPosition(), ent)[1]
            if action then
                return action
            end
        end
    end

    return nil, true
end

local function Init(_, player)
    local PlayerController = player and player.components.playercontroller
    if not PlayerController then
        return
    end
    if GetModConfigData("PICKUP_FILTER", MOD_EQUIPMENT_CONTROL.MODNAME) then
        LoadPickupFilter(
            function()
                for _, ent in pairs(GLOBAL.Ents) do
                    if PickupFilter.prefabs[ent.prefab] then
                        AddColor(ent)
                    end
                end
            end
        )
    end
    PlayerController.actionbuttonoverride = ActionButtonOverride
end

local function OnWorldPostInit(inst)
    inst:ListenForEvent("playeractivated", Init, GLOBAL.TheWorld)
end
AddPrefabPostInit("world", OnWorldPostInit)

local function CanBePickedUp(ent)
    return ent and ent.replica.inventoryitem and ent.replica.inventoryitem:CanBePickedUp() or
        ent and ent:HasTag("pickable")
end

local function ToggleFilter(prefab)
    local added
    if PickupFilter.prefabs[prefab] then
        PickupFilter.prefabs[prefab] = nil
        added = false
    else
        PickupFilter.prefabs[prefab] = true
        added = true
    end
    SavePickupFilter()
    return added
end

KeybindService:AddKey(
    "PICKUP_FILTER",
    function()
        local ent = TheInput:GetWorldEntityUnderMouse()
        if not CanBePickedUp(ent) then
            Say("Hm… I can’t filter that.")
            return
        end

        local added = ToggleFilter(ent.prefab)
        local label = ent.name or ent.prefab

        Say(
            added and string.format("Okay! I’ll leave “%s” on the ground from now on.", label) or
                string.format("Got it! I’ll pick up “%s” again.", label)
        )

        for _, v in pairs(GLOBAL.Ents) do
            if v.prefab == ent.prefab then
                if added then
                    AddColor(v)
                else
                    RemoveColor(v)
                end
            end
        end
    end
)

local meatModes = {"NONE", "FIRST", "LAST", "IGNORE"}

local currentMeatPrioritizationMode = 1
for i, m in ipairs(meatModes) do
    if m == MEAT_MODE then
        currentMeatPrioritizationMode = i
        break
    end
end

local function SetMeatModeByIndex(idx)
    currentMeatPrioritizationMode = idx
    MEAT_MODE = meatModes[idx]
end

KeybindService:AddKey(
    "MEAT_PRIORITIZATION_MODE",
    function()
        local nextIdx = currentMeatPrioritizationMode % #meatModes + 1
        SetMeatModeByIndex(nextIdx)

        Say(string.format("Current meat pickup mode is: %s.", MEAT_MODE))
    end
)
