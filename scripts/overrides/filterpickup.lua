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
local TheSim = GLOBAL.TheSim
local UpvalueHacker = require "util/upvaluehacker"
local PlayerController = require "components/playercontroller"
local Namemap = require "util/blueprint_namemap"

-- Config
local PRIORITIZE_VALUABLE = GetModConfigData("PRIOTIZE_VALUABLE_ITEMS", MOD_EQUIPMENT_CONTROL.MODNAME)
local IGNORE_KNOWN_BLUEPRINT = GetModConfigData("IGNORE_KNOWN_BLUEPRINT", MOD_EQUIPMENT_CONTROL.MODNAME)
local MEAT_MODE = "DISABLED"
local Filter_File = "mod_equipment_control_pickup_filter.txt"
local PrioritizedPickups = {
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

local function KnowsBlueprint(bp)
    if not bp or bp.prefab ~= "blueprint" then
        return false
    end
    local id =
        (bp.replica and bp.replica.blueprint and
        (bp.replica.blueprint.recipename:value() or
            (bp.replica.blueprint.GetRecipeName and bp.replica.blueprint:GetRecipeName()))) or
        Namemap.DisplayToId(bp.name)
    return id and CraftFunctions:KnowsRecipe(id)
end

local function IsMeat(ent)
    return ent:HasTag("meat")
end

local function Score(ent)
    if PickupFilter.prefabs[ent.prefab] then
        return -math.huge
    end

    if IsMeat(ent) and MEAT_MODE == "IGNORE" then
        return -math.huge
    end

    if ent.prefab == "blueprint" and KnowsBlueprint(ent) and IGNORE_KNOWN_BLUEPRINT then
        return -math.huge
    end

    if IsMeat(ent) then
        if MEAT_MODE == "FIRST" then
            return 100
        end
        if MEAT_MODE == "LAST" then
            return -100
        end
    end

    if ent.prefab == "blueprint" and KnowsBlueprint(ent) then
        return -1
    end

    if PRIORITIZE_VALUABLE then
        return PrioritizedPickups[ent.name] or PrioritizedPickups[ent.prefab] or 0
    end

    return 0
end

local function TintIfFiltered(inst)
    if inst and inst.AnimState and PickupFilter.prefabs[inst.prefab] then
        AddColor(inst)
    end
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

AddPrefabPostInitAny(TintIfFiltered)

local GetPickupAction = UpvalueHacker.GetUpvalue(PlayerController.GetActionButtonAction, "GetPickupAction")
local PICKUP_EXCLUDE_TAGS =
    UpvalueHacker.GetUpvalue(PlayerController.GetActionButtonAction, "PICKUP_TARGET_EXCLUDE_TAGS")

AddClassPostConstruct(
    "components/playercontroller",
    function(self)
        if self.inst ~= GLOBAL.ThePlayer then
            return
        end
        local _orig = self.GetActionButtonAction

        function self:GetActionButtonAction(force_target, ...)
            local act = _orig(self, force_target, ...)
            if act and (act.action == ACTIONS.PICK or act.action == ACTIONS.PICKUP) and
                    ((PickupFilter.prefabs[act.target.prefab]) or (IsMeat(act.target) and MEAT_MODE == "IGNORE"))
             then
                act = nil
            end

            local tool = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

            local pickup_tags = {
                "_inventoryitem",
                "pickable",
                "donecooking",
                "readyforharvest",
                "notreadyforharvest",
                "harvestable",
                "trapsprung",
                "minesprung",
                "dried",
                "inactive",
                "smolder",
                "saddled",
                "brushable",
                "tapped_harvestable",
                "tendable_farmplant",
                "inventoryitemholder_take",
                "client_forward_action_target"
            }

            if tool then
                for tag, _ in pairs(TOOLACTIONS) do
                    if tool:HasTag(tag .. "_tool") then
                        pickup_tags[#pickup_tags + 1] = tag .. "_workable"
                    end
                end
            end
            if self.inst.components.revivablecorpse then
                pickup_tags[#pickup_tags + 1] = "corpse"
            end

            local x, y, z = self.inst.Transform:GetWorldPosition()
            local ents =
                TheSim:FindEntities(x, y, z, self.directwalking and 3 or 6, nil, PICKUP_EXCLUDE_TAGS, pickup_tags)

            table.sort(
                ents,
                function(a, b)
                    return Score(a) > Score(b)
                end
            )

            for _, e in ipairs(ents) do
                if Score(e) ~= -math.huge and not PickupFilter.prefabs[e.prefab] and CanEntitySeeTarget(self.inst, e) then
                    local a = GetPickupAction(self, e, tool)
                    if a then
                        if act and act.target == e then
                            return act
                        end
                        return BufferedAction(self.inst, e, a, a ~= ACTIONS.SMOTHER and tool or nil)
                    end
                end
            end

            return act
        end
    end
)

local function CanBePickedUp(ent)
    return ent and ent.replica.inventoryitem and ent.replica.inventoryitem:CanBePickedUp() or
        ent and ent:HasTag("pickable")
end

local function AddToFilter(prefab)
    PickupFilter.prefabs[prefab] = not PickupFilter.prefabs[prefab] or nil
    SavePickupFilter()
    return PickupFilter.prefabs[prefab]
end

KeybindService:AddKey(
    "PICKUP_FILTER",
    function()
        local ent = TheInput:GetWorldEntityUnderMouse()
        if not CanBePickedUp(ent) then
            Say("Hm… I can’t filter that.")
            return
        end

        local added = AddToFilter(ent.prefab)
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

local meatModes = {"DISABLED", "FIRST", "LAST", "IGNORE"}

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
