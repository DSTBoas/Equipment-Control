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
local AUTO_EQUIP_TOOL = GetModConfigData("AUTO_EQUIP_TOOL", MOD_EQUIPMENT_CONTROL.MODNAME)
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
local PickupFilter = {
    tags = {},
    prefabs = {}
}

local function AddFilteredPrefab(prefab)
    PickupFilter.prefabs[prefab] = true
end

local function AddFilteredTag(tag)
    table.insert(PickupFilter.tags, tag)
end

if GetModConfigData("PICKUP_IGNORE_FLOWERS", MOD_EQUIPMENT_CONTROL.MODNAME) then
    AddFilteredTag("flower")
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
    local t = {}
    for prefab in pairs(PickupFilter.prefabs) do
        t[#t + 1] = prefab
    end
    FileSystem:SaveTableToFile(Filter_File, t)
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

local function IsFiltered(ent)
    for i = 1, #PickupFilter.tags do
        if ent:HasTag(PickupFilter.tags[i]) then
            return true
        end
    end
    return PickupFilter.prefabs[ent.prefab]
end

local function AddToFilter(ent)
    PickupFilter.prefabs[ent.prefab] = not IsFiltered(ent) or nil
    SavePickupFilter()
    return PickupFilter.prefabs[ent.prefab]
end

local function LoadPickupFilter(onLoaded)
    FileSystem:LoadTableFromFile(
        Filter_File,
        function(filterList)
            for _, prefab in ipairs(filterList) do
                PickupFilter.prefabs[prefab] = true
            end
            if onLoaded then
                onLoaded()
            end
        end
    )
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
    local priority
    if ent.prefab == "blueprint" then
        if KnowsBlueprint(ent) then
            priority = -1
        else
            priority = PriotizedPickups[ent.name] or 1
        end
    else
        priority = PriotizedPickups[ent.prefab] or 0
    end

    DebugPriority("Scored %-28s (%s)  ->  %d", ent.name or ent.prefab, ent.prefab, priority)

    return priority
end

local function GetModifiedEnts(inst, exclude, tags)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 6, nil, exclude, tags)
    local prioritized = {}
    for i, ent in ipairs(ents) do
        if
            not IsFiltered(ent) and
                not (ent.prefab == "blueprint" and KnowsBlueprint(ent) and
                    GetModConfigData("IGNORE_KNOWN_BLUEPRINT", MOD_EQUIPMENT_CONTROL.MODNAME))
         then
            table.insert(prioritized, {ent = ent, priority = GetPriority(ent)})
        end
    end
    table.sort(
        prioritized,
        function(a, b)
            return a.priority > b.priority
        end
    )
    local result = {}
    for i, v in ipairs(prioritized) do
        result[i] = v.ent
    end

    for i, v in ipairs(prioritized) do
        DebugPriority("  #%d  %-25s  priority %d", i, v.ent.name or v.ent.prefab, v.priority)
    end
    return result
end

local function GetToolsFromInventory(self, excludeTool)
    local ret = {}
    if AUTO_EQUIP_TOOL then
        local toolCategories = {
            AXE = "CHOP",
            PICKAXE = "MINE"
        }
        if excludeTool then
            for category, tag in pairs(toolCategories) do
                if excludeTool:HasTag(tag .. "_tool") then
                    toolCategories[category] = nil
                end
            end
        end
        local tool
        for category, tag in pairs(toolCategories) do
            tool = self.inst.components.actioncontroller:GetItemFromCategory(category)
            if tool then
                ret[tag] = tool
            end
        end
    end
    return ret
end

local function tintIfFiltered(inst)
    if inst and inst.prefab and PickupFilter.prefabs[inst.prefab] and inst.AnimState then
        AddColor(inst)
    end
end

AddPrefabPostInitAny(tintIfFiltered)

local function ActionButtonOverride(inst, force_target)
    local tool = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    if force_target and AUTO_EQUIP_TOOL then
        -- Existing logic remains unchanged
        for k, v in pairs(TOOLACTIONS) do
            if force_target:HasTag(k .. "_workable") then
                local tools = GetToolsFromInventory(inst, tool)
                local mod_tool = tools[k]
                if mod_tool then
                    InventoryFunctions:Equip(mod_tool)
                    return BufferedAction(inst, force_target, ACTIONS[k])
                end
            end
        end
        if force_target:HasTag("saddled") then
            local unsaddler = inst.components.inventory:GetItemWithTag("unsaddler")
            if unsaddler then
                inst.components.inventory:Equip(unsaddler)
                return BufferedAction(inst, force_target, ACTIONS.UNSADDLE)
            end
        end
        if force_target:HasTag("brushable") then
            local brush = inst.components.inventory:GetItemWithTag("brush")
            if brush then
                inst.components.inventory:Equip(brush)
                return BufferedAction(inst, force_target, ACTIONS.BRUSH)
            end
        end
        return nil, true
    else
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

        -- If no prioritized entity is visible or interactable, defer to default logic.
        return nil, true
    end
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
    return ent and ent.replica.inventoryitem and ent.replica.inventoryitem:CanBePickedUp()
end

KeybindService:AddKey(
    "PICKUP_FILTER",
    function()
        local ent = TheInput:GetWorldEntityUnderMouse()
        if CanBePickedUp(ent) then
            local added = AddToFilter(ent)
            local message = added and "Added '%s' to pickup filter" or "Removed '%s' from pickup filter"
            Say(string.format(message, ent.name or ent.prefab))
            for _, v in pairs(GLOBAL.Ents) do
                if v.prefab == ent.prefab then
                    if added then
                        AddColor(v)
                    else
                        RemoveColor(v)
                    end
                end
            end
        else
            Say("Cannot filter this entity.")
        end
    end
)
