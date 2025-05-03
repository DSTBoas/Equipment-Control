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
local FindEntity = GLOBAL.FindEntity
local Namemap = require "util/blueprint_namemap"

-- Config
local PRIORITIZE_VALUABLE = GetModConfigData("PRIOTIZE_VALUABLE_ITEMS", MOD_EQUIPMENT_CONTROL.MODNAME)
local MEAT_MODE = (GetModConfigData("MEAT_PRIORITIZATION_MODE", MOD_EQUIPMENT_CONTROL.MODNAME) or "NONE"):upper()
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

local function IsFiltered(ent)
    return PickupFilter.prefabs[ent.prefab] or false
end

local DEBUG_PICKUP_PRIORITY = false

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
        return PrioritizedPickups[ent.name] or PrioritizedPickups[ent.prefab] or 0
    end

    return 0
end

local function GetModifiedEnts(inst, exclude_tags, pickup_tags)
    local x, y, z = inst.Transform:GetWorldPosition()
    local raw = TheSim:FindEntities(x, y, z, inst.components.playercontroller.directwalking and 3 or 6, nil, exclude_tags, pickup_tags)

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

if GetModConfigData("PICKUP_FILTER", MOD_EQUIPMENT_CONTROL.MODNAME) then
    LoadPickupFilter(function()
        for _, ent in pairs(GLOBAL.Ents) do
            if PickupFilter.prefabs[ent.prefab] then
                AddColor(ent)
            end
        end
    end)
end

AddPrefabPostInitAny(tintIfFiltered)

local exclude = {
    "FX",
    "NOCLICK",
    "DECOR",
    "INLIMBO",
    "catchable",
    "mineactive",
    "intense"
}
local include = {
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

local function is_tool_action(action)
    return TOOLACTIONS[action.id] ~= nil
end

local function pick_first_tool(list)
    for _, a in ipairs(list or emptytable) do
        if a.action and is_tool_action(a.action) then
            return a
        end
    end
end

--
-- Carbon copy of the /components/playercontroller func
--
local function GetPickupAction(self, target, tool)
    if target:HasTag("smolder") then
        return ACTIONS.SMOTHER
    elseif tool ~= nil then
        for k, v in pairs(TOOLACTIONS) do
            if target:HasTag(k.."_workable") then
                if tool:HasTag(k.."_tool") then
                    return ACTIONS[k]
                end
                break
            end
        end
    end

    if target:HasTag("quagmireharvestabletree") and not target:HasTag("fire") then
        return ACTIONS.HARVEST_TREE
    elseif target:HasTag("trapsprung") then
        return ACTIONS.CHECKTRAP
    elseif target:HasTag("minesprung") and not target:HasTag("mine_not_reusable") then
        return ACTIONS.RESETMINE
    elseif target:HasTag("inactive") and not target:HasTag("activatable_forcenopickup") and target.replica.inventoryitem == nil then
		return (not target:HasTag("wall") or self.inst:IsNear(target, 2.5))
			and ACTIONS.ACTIVATE
			or nil
    elseif target.replica.inventoryitem ~= nil and
        target.replica.inventoryitem:CanBePickedUp(self.inst) and
		not (target:HasTag("heavy") or (target:HasTag("fire") and not target:HasTag("lighter")) or target:HasTag("catchable")) and
        not target:HasTag("spider") then
        if self:HasItemSlots() or target.replica.equippable ~= nil then
            return ACTIONS.PICKUP
        end
        return nil
    elseif target:HasTag("pickable") and not target:HasTag("fire") then
        return ACTIONS.PICK
    elseif target:HasTag("harvestable") then
        return ACTIONS.HARVEST
    elseif target:HasTag("readyforharvest") or
        (target:HasTag("notreadyforharvest") and target:HasTag("withered")) then
        return ACTIONS.HARVEST
    elseif target:HasTag("tapped_harvestable") and not target:HasTag("fire") then
        return ACTIONS.HARVEST
    elseif target:HasTag("tendable_farmplant") and not self.inst:HasTag("mime") and not target:HasTag("fire") then
        return ACTIONS.INTERACT_WITH
    elseif target:HasTag("dried") and not target:HasTag("burnt") then
        return ACTIONS.HARVEST
    elseif target:HasTag("donecooking") and not target:HasTag("burnt") then
        return ACTIONS.HARVEST
    elseif target:HasTag("inventoryitemholder_take") and not target:HasTag("fire") then
        return ACTIONS.TAKEITEM
    elseif tool ~= nil and tool:HasTag("unsaddler") and target:HasTag("saddled") and not IsEntityDead(target) then
        return ACTIONS.UNSADDLE
    elseif tool ~= nil and tool:HasTag("brush") and target:HasTag("brushable") and not IsEntityDead(target) then
        return ACTIONS.BRUSH
    elseif self.inst.components.revivablecorpse ~= nil and target:HasTag("corpse") and ValidateCorpseReviver(target, self.inst) then
        return ACTIONS.REVIVE_CORPSE
    end
    --no action found
end


local TARGET_EXCLUDE_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "stealth" }
local REGISTERED_CONTROLLER_ATTACK_TARGET_TAGS = TheSim:RegisterFindTags({ "_combat" }, TARGET_EXCLUDE_TAGS)

local PICKUP_TARGET_EXCLUDE_TAGS = { "catchable", "mineactive", "intense", "paired" }
local HAUNT_TARGET_EXCLUDE_TAGS = { "haunted", "catchable" }
for i, v in ipairs(TARGET_EXCLUDE_TAGS) do
    table.insert(PICKUP_TARGET_EXCLUDE_TAGS, v)
    table.insert(HAUNT_TARGET_EXCLUDE_TAGS, v)
end

local CATCHABLE_TAGS = { "catchable" }
local PINNED_TAGS = { "pinned" }
local CORPSE_TAGS = { "corpse" }

AddClassPostConstruct("components/playercontroller", function(self)
    if self.inst ~= GLOBAL.ThePlayer then
        return
    end

    function self:GetActionButtonAction(force_target)
        local isenabled, ishudblocking = self:IsEnabled()

        if (not self.ismastersim and (self.remote_controls[CONTROL_ACTION] or 0) > 0)
            or (not isenabled and not ishudblocking)
            or self:IsBusy()
            or (force_target ~= nil
                and (not force_target.entity:IsVisible()
                     or force_target:HasTag("INLIMBO")
                     or force_target:HasTag("NOCLICK"))) then
            return
        end

        if self.actionbuttonoverride ~= nil then
            local buffaction, usedefault = self.actionbuttonoverride(self.inst, force_target)
            if not usedefault or buffaction ~= nil then
                return buffaction
            end
        end

        if self.inst.replica.inventory:IsHeavyLifting()
           and not (self.inst.replica.rider ~= nil and self.inst.replica.rider:IsRiding()) then
            return
        end

        if not self:IsDoingOrWorking() then
            local force_target_distsq = force_target and self.inst:GetDistanceSqToInst(force_target) or nil

            if self.inst:HasTag("playerghost") then
                if force_target == nil then
                    local target = FindEntity(self.inst, self.directwalking and 3 or 6,
                                              ValidateHaunt,
                                              nil, HAUNT_TARGET_EXCLUDE_TAGS)
                    if CanEntitySeeTarget(self.inst, target) then
                        return BufferedAction(self.inst, target, ACTIONS.HAUNT)
                    end
                elseif force_target_distsq <= (self.directwalking and 9 or 36)
                       and not (force_target:HasTag("haunted") or force_target:HasTag("catchable"))
                       and ValidateHaunt(force_target) then
                    return BufferedAction(self.inst, force_target, ACTIONS.HAUNT)
                end
                return
            end

            local tool = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

            if tool ~= nil and tool:HasTag(ACTIONS.NET.id.."_tool") then
                if force_target == nil then
                    local target = FindEntity(self.inst, 5,
                                              ValidateBugNet,
                                              { "_health", ACTIONS.NET.id.."_workable" },
                                              TARGET_EXCLUDE_TAGS)
                    if CanEntitySeeTarget(self.inst, target) then
                        return BufferedAction(self.inst, target, ACTIONS.NET, tool)
                    end
                elseif force_target_distsq <= 25
                       and force_target.replica.health ~= nil
                       and ValidateBugNet(force_target)
                       and force_target:HasTag(ACTIONS.NET.id.."_workable") then
                    return BufferedAction(self.inst, force_target, ACTIONS.NET, tool)
                end
            end

            if self.inst:HasTag("cancatch") then
                if force_target == nil then
                    local target = FindEntity(self.inst, 10,
                                              nil,
                                              CATCHABLE_TAGS,
                                              TARGET_EXCLUDE_TAGS)
                    if CanEntitySeeTarget(self.inst, target) then
                        return BufferedAction(self.inst, target, ACTIONS.CATCH)
                    end
                elseif force_target_distsq <= 100
                       and force_target:HasTag("catchable") then
                    return BufferedAction(self.inst, force_target, ACTIONS.CATCH)
                end
            end

            if force_target == nil then
                local target = FindEntity(self.inst, self.directwalking and 3 or 6,
                                          nil,
                                          PINNED_TAGS,
                                          TARGET_EXCLUDE_TAGS)
                if CanEntitySeeTarget(self.inst, target) then
                    return BufferedAction(self.inst, target, ACTIONS.UNPIN)
                end
            elseif force_target_distsq <= (self.directwalking and 9 or 36)
                   and force_target:HasTag("pinned") then
                return BufferedAction(self.inst, force_target, ACTIONS.UNPIN)
            end

            if self.inst.components.revivablecorpse ~= nil then
                if force_target == nil then
                    local target = FindEntity(self.inst, 3,
                                              ValidateCorpseReviver,
                                              CORPSE_TAGS,
                                              TARGET_EXCLUDE_TAGS)
                    if CanEntitySeeTarget(self.inst, target) then
                        return BufferedAction(self.inst, target, ACTIONS.REVIVE_CORPSE)
                    end
                elseif force_target_distsq <= 9
                       and force_target:HasTag("corpse")
                       and ValidateCorpseReviver(force_target, self.inst) then
                    return BufferedAction(self.inst, force_target, ACTIONS.REVIVE_CORPSE)
                end
            end

            local pickup_tags =
            {
                "_inventoryitem", "pickable", "donecooking", "readyforharvest",
                "notreadyforharvest", "harvestable", "trapsprung", "minesprung", "dried",
                "inactive", "smolder", "saddled", "brushable", "tapped_harvestable",
                "tendable_farmplant", "inventoryitemholder_take", "client_forward_action_target"
            }

            if tool then
                for action_name in pairs(TOOLACTIONS) do
                    if tool:HasTag(action_name.."_tool") then
                        table.insert(pickup_tags, action_name.."_workable")
                    end
                end
            end
            if self.inst.components.revivablecorpse then
                table.insert(pickup_tags, "corpse")
            end

            if force_target == nil then
                local ents = GetModifiedEnts(self.inst, PICKUP_TARGET_EXCLUDE_TAGS, pickup_tags)
                for i, v in ipairs(ents or {}) do
                    local act = GetPickupAction(self, v, tool)
                    if act then
                        return BufferedAction(self.inst, v, act, act~=ACTIONS.SMOTHER and tool or nil)
                    end
                end
            else
                local allowed = GetModifiedEnts(self.inst, PICKUP_TARGET_EXCLUDE_TAGS, { "_inventoryitem" })[force_target]
                if force_target_distsq <= (self.directwalking and 9 or 36) and allowed then
                    local act = GetPickupAction(self, force_target, tool)
                    if act then
                        return BufferedAction(self.inst, force_target, act, act~=ACTIONS.SMOTHER and tool or nil)
                    end
                end
            end
        end

        return
    end
end)

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
