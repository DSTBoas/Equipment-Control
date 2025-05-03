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

local function ActionButtonOverride(inst, force_target)
    if force_target then
        return nil
    end

    local pc = inst.components.playercontroller
    if pc and pc:IsDoingOrWorking() then
        return nil
    end

    local ents = GetModifiedEnts(inst, exclude, include)
    local picker = inst.components.playeractionpicker

    for i, ent in ipairs(ents) do
        if CanEntitySeeTarget(inst, ent) then
            local r = picker:GetRightClickActions(ent:GetPosition(), ent)
            local l = picker:GetLeftClickActions(ent:GetPosition(), ent)

            local act = pick_first_tool(r) or (l and l[1])

            if act then
                return act
            end
        end
    end

    DebugPriority("No suitable action found.")
    return nil
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

AddClassPostConstruct("components/playercontroller", function(self)
    if self.inst ~= GLOBAL.ThePlayer then
        return
    end

    function self:GetActionButtonAction(force_target)
        local isenabled, ishudblocking = self:IsEnabled()

        if (not self.ismastersim and (self.remote_controls[CONTROL_ACTION] or 0) > 0)
            or (not isenabled and not ishudblocking)
            or self:IsBusy()
            or (   force_target ~= nil
               and (   not force_target.entity:IsVisible()
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
            local tool = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

            local pickup_tags =
            {
                "_inventoryitem","pickable","donecooking","readyforharvest",
                "notreadyforharvest","harvestable","trapsprung","minesprung",
                "dried","inactive","smolder","saddled","brushable",
                "tapped_harvestable","tendable_farmplant",
                "inventoryitemholder_take","client_forward_action_target",
            }
            if tool ~= nil then
                for k in pairs(TOOLACTIONS) do
                    if tool:HasTag(k .. "_tool") then
                        table.insert(pickup_tags, k .. "_workable")
                    end
                end
            end
            if self.inst.components.revivablecorpse ~= nil then
                table.insert(pickup_tags, "corpse")
            end

            if force_target == nil then
                local ents = GetModifiedEnts(self.inst, PICKUP_EXCLUDE, pickup_tags)

                for _, v in ipairs(ents) do
                    v = v.client_forward_target or v
                    if v ~= self.inst and v.entity:IsVisible()
                        and CanEntitySeeTarget(self.inst, v) then
                        local act = GetPickupAction(self, v, tool)
                        if act ~= nil then
                            return BufferedAction(self.inst, v, act,
                                act ~= ACTIONS.SMOTHER and tool or nil)
                        end
                    end
                end
            else
                local dist2 = self.inst:GetDistanceSqToInst(force_target)
                if dist2 <= (self.directwalking and 9 or 36) then
                    if not GetModifiedEnts(self.inst, PICKUP_EXCLUDE, { "_inventoryitem" })[force_target] then
                        return
                    end
                    local act = GetPickupAction(self, force_target, tool)
                    if act ~= nil then
                        return BufferedAction(self.inst, force_target, act,
                            act ~= ACTIONS.SMOTHER and tool or nil)
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
