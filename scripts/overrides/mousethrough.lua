local InventoryFunctions = require "util/inventoryfunctions"
local MOD_EQUIPMENT_CONTROL = GLOBAL.MOD_EQUIPMENT_CONTROL
local TheInput = GLOBAL.TheInput
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local TheNet = GLOBAL.TheNet

local function tagList(ent)
    if not ent or not ent.tags then
        return ""
    end
    local t = {}
    for tag in pairs(ent.tags) do t[#t + 1] = tag end
    return table.concat(t, ",")
end

local trackedEquips = { orangestaff = true, yellowstaff = true }
local currentEquip
local funcToPriority = {}
local tagToPriority = { player = 0 }

local function isEquipped(prefab)
    return currentEquip == prefab
end

local function getFilterPriority(ent)
    if ent == nil then return 1 end
    for tag, fn in pairs(funcToPriority) do
        if ent:HasTag(tag) then
            return fn(ent)
        end
    end
    for tag, p in pairs(tagToPriority) do
        if ent:HasTag(tag) then
            return p
        end
    end
    return 1
end

local function chooseHoverInst(ents)
    local best, bestp = nil, -math.huge
    for i = 1, #ents do
        local p = getFilterPriority(ents[i])
        if p > bestp then best, bestp = ents[i], p end
    end
    if bestp < 0 then return nil end
    return best
end

local function refreshEquip()
    if not GLOBAL.ThePlayer or not GLOBAL.ThePlayer.replica or not GLOBAL.ThePlayer.replica.inventory then
        currentEquip = nil
        return
    end
    local item = GLOBAL.ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    currentEquip = item and trackedEquips[item.prefab] and item.prefab or nil
end

local function buildPriorityTables()
    funcToPriority = {}
    tagToPriority = { player = 0 }

    if GetModConfigData("FORCE_INSPECT_PLAYERS", MOD_EQUIPMENT_CONTROL.MODNAME) then
        funcToPriority.player = function()
            return GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) and 1 or -1
        end
    end

    if GetModConfigData("ORANGESTAFF_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        funcToPriority.wall = function()
            return isEquipped("orangestaff") and -1 or 1
        end
    end

    if GetModConfigData("YELLOWSTAFF_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        local f = function()
            return isEquipped("yellowstaff") and -1 or 1
        end
        funcToPriority.daylight = f
        funcToPriority.blocker = f
    end

    if GetModConfigData("FLYING_BIRDS_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        tagToPriority.flight = -1
    end
end

local function attachPlayerListeners()
    if not GLOBAL.ThePlayer then
        return
    end
    refreshEquip()
    GLOBAL.ThePlayer:ListenForEvent("equip", refreshEquip)
    GLOBAL.ThePlayer:ListenForEvent("unequip", refreshEquip)
end

local function InputPostInit(input)
    if input.equipctrl_inited then
        return
    end
    input.equipctrl_inited = true
    if TheNet:IsDedicated() then 
        return
    end

    local oldUpdate = input.OnUpdate
    input.OnUpdate = function(self, ...)
        oldUpdate(self, ...)
        if not self.mouse_enabled then
            return
        end
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

local function WorldPostInit(world)
    if GLOBAL.ThePlayer then 
        attachPlayerListeners()
    end

    world:ListenForEvent("playeractivated", function(_, player)
        if player == GLOBAL.ThePlayer then
            attachPlayerListeners()
        end
    end)
end

AddClassPostConstruct("input", InputPostInit)
AddPrefabPostInit("world", WorldPostInit)

if TheInput and not TheInput.equipctrl_inited then
    InputPostInit(TheInput)
end

buildPriorityTables()