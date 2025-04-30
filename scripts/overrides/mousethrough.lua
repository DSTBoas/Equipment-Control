--------------------------------------------------------------------------
-- Equipment Control (mouse‑through) – delayed‑player + debug build
-- with **auto‑hook for existing `TheInput` instance**.
--
-- Load from modmain:
--     AddClassPostConstruct("input", require("overrides/mousethrough"))
-- …and the module will also patch the already-created `TheInput` so
-- `PostInit` always runs exactly once per instance.
--------------------------------------------------------------------------

local InventoryFunctions = require "util/inventoryfunctions"
local MOD_EQUIPMENT_CONTROL = GLOBAL.MOD_EQUIPMENT_CONTROL
local TheInput = GLOBAL.TheInput
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local TheNet = GLOBAL.TheNet

----------------------------------------------------------
-- debug helpers -----------------------------------------
----------------------------------------------------------
local DEBUG = true -- toggled later by config
local function dprint(...)
    if DEBUG then print("[EquipCtrl]", ...) end
end

----------------------------------------------------------
-- util ---------------------------------------------------
----------------------------------------------------------
local function tagList(ent)
    if not ent or not ent.tags then return "" end
    local t = {}
    for tag in pairs(ent.tags) do t[#t + 1] = tag end
    return table.concat(t, ",")
end

----------------------------------------------------------
-- constants ---------------------------------------------
----------------------------------------------------------
local trackedEquips = { orangestaff = true, yellowstaff = true }

----------------------------------------------------------
-- dynamic state -----------------------------------------
----------------------------------------------------------
local currentEquip
local funcToPriority = {}
local tagToPriority  = { player = 0 }

----------------------------------------------------------
-- helpers -----------------------------------------------
----------------------------------------------------------
local function isEquipped(prefab)
    return currentEquip == prefab
end

local function getFilterPriority(ent)
    if ent == nil then return 1 end
    for tag, fn in pairs(funcToPriority) do
        if ent:HasTag(tag) then
            local p = fn(ent)
            dprint("func", ent.prefab, tag, p)
            return p
        end
    end
    for tag, p in pairs(tagToPriority) do
        if ent:HasTag(tag) then
            dprint("static", ent.prefab, tag, p)
            return p
        end
    end
    return 1
end

local function chooseHoverInst(ents)
    local best, bestp = nil, -math.huge
    for i = 1, #ents do
        local p = getFilterPriority(ents[i])
        dprint("seen", ents[i] and ents[i].prefab, p, tagList(ents[i]))
        if p > bestp then best, bestp = ents[i], p end
    end
    if bestp < 0 then return nil end
    return best
end

----------------------------------------------------------
-- equipment tracking ------------------------------------
----------------------------------------------------------
local function refreshEquip()
    print("Refresh Equip")
    if not GLOBAL.ThePlayer or not GLOBAL.ThePlayer.replica or not GLOBAL.ThePlayer.replica.inventory then
        currentEquip = nil
        return
    end
    local item = GLOBAL.ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    currentEquip = item and trackedEquips[item.prefab] and item.prefab or nil
    dprint("equip =>", currentEquip or "none")
end

----------------------------------------------------------
-- priority‑table builder --------------------------------
----------------------------------------------------------
local function buildPriorityTables()
    funcToPriority = {}
    tagToPriority  = { player = 0 }

    if GetModConfigData("FORCE_INSPECT_PLAYERS", MOD_EQUIPMENT_CONTROL.MODNAME) then
        funcToPriority.player = function()
            return GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) and 1 or -1
        end
    end

    if GetModConfigData("ORANGESTAFF_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        funcToPriority.wall = function() return isEquipped("orangestaff") and -1 or 1 end
    end

    if GetModConfigData("YELLOWSTAFF_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        local f = function() return isEquipped("yellowstaff") and -1 or 1 end
        funcToPriority.daylight = f
        funcToPriority.blocker  = f
    end

    if GetModConfigData("FLYING_BIRDS_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        tagToPriority.flight = -1
    end

    dprint("funcToPriority >>>")
    for tag in pairs(funcToPriority) do dprint("  tag", tag) end
    dprint("tagToPriority >>>")
    for tag, p in pairs(tagToPriority) do dprint("  tag", tag, p) end
end

----------------------------------------------------------
-- safe player hook --------------------------------------
----------------------------------------------------------
local function attachPlayerListeners()
    dprint("Activating listeners", GLOBAL.ThePlayer)
    if not GLOBAL.ThePlayer then 
        return 
    end
    dprint("Activating listeners v2", GLOBAL.ThePlayer)
    refreshEquip()
    GLOBAL.ThePlayer:ListenForEvent("equip",   refreshEquip)
    GLOBAL.ThePlayer:ListenForEvent("unequip", refreshEquip)
end

----------------------------------------------------------
-- Input class post‑construct -----------------------------
----------------------------------------------------------
local function InputPostInit(input)
    if input.equipctrl_inited then return end  -- ← guard
    input.equipctrl_inited = true
    print("GOT HERE")
    -- guard so the same instance isn’t patched twice
    if TheNet:IsDedicated() then 
        return
     end  -- skip on servers
     print("GOT HERE 2")
    ----------------------------------------------------------------
    -- Patch OnUpdate *immediately*.  This part never touches
    -- TheWorld so it’s 100 % safe at menu time.
    ----------------------------------------------------------------
    local old_update = input.OnUpdate
    input.OnUpdate = function(self, ...)
        old_update(self, ...)
        print("OnUpdate")
        if not self.mouse_enabled then return end
        local inst = chooseHoverInst(self.entitiesundermouse or {})
        if inst ~= self.hoverinst then
            if inst and inst.Transform then inst:PushEvent("mouseover") end
            if self.hoverinst and self.hoverinst.Transform then
                self.hoverinst:PushEvent("mouseout")
            end
            self.hoverinst = inst
        end
    end
end

----------------------------------------------------------------
-- 4.  THE **LATE** HOOK  – runs once the world prefab has been
--     spawned (TheWorld is guaranteed to be valid here)
----------------------------------------------------------------
local function WorldPostInit(world)
    buildPriorityTables()
    if GLOBAL.ThePlayer then attachPlayerListeners() end

    -- track future player (re)spawns
    world:ListenForEvent("playeractivated", function(_, player)
        dprint("playeractivated", player)
        if player == GLOBAL.ThePlayer then
            -- dprint("player == ThePlayer")
            attachPlayerListeners()
        else
            -- dprint("player ~= ThePlayer")
        end
    end)
end

----------------------------------------------------------------
-- 5.  register the two hooks
----------------------------------------------------------------
AddClassPostConstruct("input", InputPostInit)
AddPrefabPostInit("world", WorldPostInit)

if TheInput and not TheInput.equipctrl_inited then
    InputPostInit(TheInput)
end
