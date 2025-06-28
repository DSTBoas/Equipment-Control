local MOD_EQUIPMENT_CONTROL = GLOBAL.MOD_EQUIPMENT_CONTROL
local TheInput = GLOBAL.TheInput
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local TheNet = GLOBAL.TheNet

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

local function shouldFilterOut(ent)
    return getFilterPriority(ent) < 0
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
            return GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.playercontroller:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) and 1 or -1
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

local function findNextValidEntity(entities, startIdx)
    if not entities then return nil end
    
    for i = startIdx, #entities do
        local ent = entities[i]
        if ent and ent.entity:IsValid() and ent.entity:IsVisible() then
            -- Apply client_forward_target like the game does
            ent = ent.client_forward_target or ent
            
            if not shouldFilterOut(ent) then
                return ent, i
            end
        end
    end
    
    return nil
end

local function InputPostInit(input)
    if input.equipctrl_inited then
        return
    end
    input.equipctrl_inited = true
    if TheNet:IsDedicated() then
        return
    end

    local oldOnUpdate = input.OnUpdate
    input.OnUpdate = function(self)
        -- Call original update first
        oldOnUpdate(self)
        
        if not self.mouse_enabled then
            return
        end
        
        -- Check if current hover should be filtered
        if self.hoverinst and shouldFilterOut(self.hoverinst) then
            -- Find the index of current hover inst
            local currentIdx = 1
            if self.entitiesundermouse then
                for i = 1, #self.entitiesundermouse do
                    local ent = self.entitiesundermouse[i]
                    ent = ent and ent.client_forward_target or ent
                    if ent == self.hoverinst then
                        currentIdx = i
                        break
                    end
                end
            end
            
            -- Find next valid entity
            local newinst = findNextValidEntity(self.entitiesundermouse, currentIdx + 1)
            
            if newinst ~= self.hoverinst then
                -- Trigger mouse events like the game does
                if newinst and newinst.Transform then
                    newinst:PushEvent("mouseover")
                end
                if self.hoverinst and self.hoverinst.Transform then
                    self.hoverinst:PushEvent("mouseout")
                end
                
                self.hoverinst = newinst
            end
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

buildPriorityTables()

AddClassPostConstruct("input", InputPostInit)
AddPrefabPostInit("world", WorldPostInit)

if TheInput and not TheInput.equipctrl_inited then
    InputPostInit(TheInput)
end