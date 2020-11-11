local InventoryFunctions = require "util/inventoryfunctions"

local TrackedEquips =
{
    orangestaff = true,
    yellowstaff = true,
}

local CurrentEquip = nil

local function IsEquipped(prefab)
    return CurrentEquip == prefab
end

local FuncToPriority = {}
local TagToPriority =
{
    player = 0,
}

local function GetFilterPriority(ent)
    for tag, func in pairs(FuncToPriority) do
        if ent and ent.HasTag and ent:HasTag(tag) then
            return func(ent)
        end
    end

    for tag, priority in pairs(TagToPriority) do
        if ent and ent.HasTag and ent:HasTag(tag) then
            return priority
        end
    end

    return 1
end

local function GetHoverPriorityTable(ents)
    local ret = {}

    for i = 1, #ents do
        ret[#ret + 1] =
        {
            ent = ents[i],
            priority = GetFilterPriority(ents[i])
        }
    end

    return ret
end

local function OrderByPriority(l, r)
    return l.priority > r.priority
end

local function GetHoverInst(ents)
    -- if InventoryFunctions:GetActiveItem() then
    --     return ents[1]
    -- end

    local hoverPriorityTable = GetHoverPriorityTable(ents)
    table.sort(hoverPriorityTable, OrderByPriority)

    if hoverPriorityTable[1] and hoverPriorityTable[1].priority < 0 then
        return nil
    end

    return hoverPriorityTable[1] and hoverPriorityTable[1].ent
end

local function DoUnequip()
    CurrentEquip = nil
end

local function DoEquip(item)
    if item and TrackedEquips[item.prefab] then
        CurrentEquip = item.prefab
    end
end

local function Init()
    if not ThePlayer then
        return
    end

    if GetModConfigData("FORCE_INSPECT_PLAYERS", MOD_EQUIPMENT_CONTROL.MODNAME) then
        FuncToPriority.player = function()
            return ThePlayer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) and 1
                or -1
        end
    end

    if GetModConfigData("ORANGESTAFF_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        FuncToPriority.wall = function()
            return IsEquipped("orangestaff") and -1
                or 1
        end
    end

    if GetModConfigData("YELLOWSTAFF_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        local func = function()
            return IsEquipped("yellowstaff") and -1
                or 1
        end   
        FuncToPriority.daylight = func
        FuncToPriority.blocker = func
    end

    if GetModConfigData("FLYING_BIRDS_MOUSETHROUGH", MOD_EQUIPMENT_CONTROL.MODNAME) then
        TagToPriority.flight = -1
    end

    function TheInput:OnUpdate()
        if self.mouse_enabled then
            self.entitiesundermouse = TheSim:GetEntitiesAtScreenPoint(TheSim:GetPosition())
            local inst = GetHoverInst(self.entitiesundermouse)
            print("Hover Inst = ", inst)
            if inst ~= nil and inst.CanMouseThrough ~= nil then
                local mousethrough, keepnone = inst:CanMouseThrough()
                if mousethrough then
                    for i = 2, #self.entitiesundermouse do
                        local nextinst = self.entitiesundermouse[i]
                        if nextinst == nil or
                            nextinst:HasTag("player") or
                            (nextinst.Transform ~= nil) ~= (inst.Transform ~= nil) then
                            if keepnone then
                                inst = nextinst
                                mousethrough, keepnone = false, false
                            end
                            break
                        end
                        inst = nextinst
                        if nextinst.CanMouseThrough == nil then
                            mousethrough, keepnone = false, false
                        else
                            mousethrough, keepnone = nextinst:CanMouseThrough()
                        end
                        if not mousethrough then
                            break
                        end
                    end
                    if mousethrough and keepnone then
                        inst = nil
                    end
                end
            end

            if inst ~= self.hoverinst then
                if inst ~= nil and inst.Transform ~= nil then
                    inst:PushEvent("mouseover")
                end

                if self.hoverinst ~= nil and self.hoverinst.Transform ~= nil then
                    self.hoverinst:PushEvent("mouseout")
                end

                self.hoverinst = inst
            end
        end
    end

    if ThePlayer.replica.inventory then
        DoEquip(ThePlayer.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS))
    end

    ThePlayer:ListenForEvent("equip", function(_, data)
        DoUnequip()
        if data then
            DoEquip(data.item)
        end
    end)

    ThePlayer:ListenForEvent("unequip", function(_, data)
        DoUnequip()
    end)
end

return Init
