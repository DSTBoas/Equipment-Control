local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE
local FileSystem = require "util/filesystem"
local Say = require "util/say"

-- 
-- Config
-- 

local Filter_File = "mod_equipment_control_attack_filter.txt"

-- 
-- Logic
-- 

local AttackFilters = {}

local function IsAttackFiltered(combat_replica, guy)
    for prefab, fn in pairs(AttackFilters) do
        if fn(guy, prefab, combat_replica) then
            return true
        end
    end

    return false
end

local CustomFilters = {}

local function AddCustomFilter(prefab, fn)
    CustomFilters[prefab] = fn
end

local function DefaultFilter(guy, prefab)
    return guy.prefab == prefab
end

local function GetFilter(prefab)
    return CustomFilters[prefab] or DefaultFilter
end

local function LoadFilter()
    local t = FileSystem:LoadFile(Filter_File)
    for i = 1, #t do
        AttackFilters[t[i]] = GetFilter(t[i])
    end
end

local function SaveFilter()
    local t = {}

    for prefab in pairs(AttackFilters) do
        t[#t + 1] = prefab
    end

    FileSystem:SaveFile(Filter_File, t)
end

local GroupTags =
{
    wall = true,
    bird = true,
}

local function GetUserID(player)
    return player.userid or player.prefab
end

local TagFuncs =
{
    player = GetUserID
}

local function GetPrefabGroup(ent)
    for tag, fn in pairs(TagFuncs) do
        if ent:HasTag(tag) then
            return fn(ent)
        end
    end

    for tag in pairs(GroupTags) do
        if ent:HasTag(tag) then
            return tag
        end
    end

    return ent.prefab
end

local function AddToFilter(ent)
    local prefab = GetPrefabGroup(ent)

    if not AttackFilters[prefab] then
        AttackFilters[prefab] = GetFilter(prefab)
    else
        AttackFilters[prefab] = nil
    end

    SaveFilter()

    return AttackFilters[prefab]
end

-- 
-- Helpers
-- 

local function IsFrozen(inst)
    return inst.AnimState
       and (inst.AnimState:IsCurrentAnimation("frozen")
           or inst.AnimState:IsCurrentAnimation("frozen_loop_pst"))
end

local function IsAsleep(inst)
    return inst.AnimState
       and (inst.AnimState:IsCurrentAnimation("sleep_pre")
           or inst.AnimState:IsCurrentAnimation("sleep_loop")
           or inst.AnimState:IsCurrentAnimation("sleep_pst"))
end

-- 
-- Custom filters
-- 

AddCustomFilter("wall", function(guy)
    return guy:HasTag("wall")
end)

AddCustomFilter("bird", function(guy)
    return guy:HasTag("bird")
       and not (IsFrozen(guy) or IsAsleep(guy))
end)

local function Init()
    LoadFilter()

    local OldIsAlly = ThePlayer.replica.combat.IsAlly
    function ThePlayer.replica.combat:IsAlly(guy, ...)
        return IsAttackFiltered(self, guy)
            or OldIsAlly(self, guy, ...)
    end

    print("FilterAttack init")
end

-- 
-- Keybinds
-- 

KeybindService:AddKey("ATTACK_FILTER", function()
    local ent = TheInput:GetWorldEntityUnderMouse()

    if ent and ent.replica.health then
        Say(
            string.format(
                AddToFilter(ent) and MOD_EQUIPMENT_CONTROL.STRINGS.ATTACK_FILTER.ADD
                or MOD_EQUIPMENT_CONTROL.STRINGS.ATTACK_FILTER.REMOVE,
                ent.name
            )
        )
    end
end)

return Init
