local _G = GLOBAL

local TheInput = _G.TheInput
local TheSim = _G.TheSim
local require = _G.require
local rawget = _G.rawget

local MOD_EQUIPMENT_CONTROL = {}
MOD_EQUIPMENT_CONTROL.MODNAME = modname
MOD_EQUIPMENT_CONTROL.SPECIALFOOD = require "util/specialfood"
MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE = require "util/keybindservice"(modname)
MOD_EQUIPMENT_CONTROL.STRINGS = require("locales/" .. GetModConfigData("LANGUAGE"))
MOD_EQUIPMENT_CONTROL.SPAWNING = false
_G.MOD_EQUIPMENT_CONTROL = MOD_EQUIPMENT_CONTROL

require("categories")

local Say = require("util/say")

local function DoToggle(str, val)
    val = not val
    Say(
        string.format(
            str .. " (%s)",
            val and MOD_EQUIPMENT_CONTROL.STRINGS.TOGGLE.ENABLED
            or MOD_EQUIPMENT_CONTROL.STRINGS.TOGGLE.DISABLED
        )
    )
    return val
end
_G.DoToggle = DoToggle

local function EntityScriptPostConstruct(entityscript)
    local OldRegisterComponentActions = entityscript.RegisterComponentActions 
    function entityscript:RegisterComponentActions(name)
        if _G.MOD_EQUIPMENT_CONTROL.SPAWNING then
            return
        end

        return OldRegisterComponentActions(self, name)
    end
end
AddGlobalClassPostConstruct("entityscript", "EntityScript", EntityScriptPostConstruct)

if GetModConfigData("BUTTON_SHOW") then
    local Buttons = require "widgets/buttons"

    AddClassPostConstruct("widgets/inventorybar", function(self)
        self.buttons = self.root:AddChild(Buttons(self.owner, self))
    end)
end

local InventoryFunctions = require "util/inventoryfunctions"

local TagToPriority =
{
    player = 0,
    flight = -1,
}

local function IsOrangeStaffEquipped()
    for _, equippedItem in pairs(InventoryFunctions:GetEquips()) do
        if equippedItem.prefab == "orangestaff" then
            return true
        end
    end

    return false
end

local function FilterWall()
    return IsOrangeStaffEquipped() and -1
        or 1
end

local FuncToPriority = {}

if GetModConfigData("TELEPOOF_MOUSETHROUGH") then
    FuncToPriority.wall = FilterWall
end

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
    if InventoryFunctions:GetActiveItem() then
        return ents[1]
    end

    local hoverPriorityTable = GetHoverPriorityTable(ents)
    table.sort(hoverPriorityTable, OrderByPriority)

    if hoverPriorityTable[1] and hoverPriorityTable[1].priority < 0 then
        return nil
    end

    return hoverPriorityTable[1] and hoverPriorityTable[1].ent
end

function TheInput:OnUpdate()
    if self.mouse_enabled then
        self.entitiesundermouse = TheSim:GetEntitiesAtScreenPoint(TheSim:GetPosition())
        local inst = GetHoverInst(self.entitiesundermouse)
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

local Overrides =
{
    autocane =
    {
        "AUTO_EQUIP_CANE",
    },
    autoweapon =
    {
        "AUTO_EQUIP_WEAPON",
        "AUTO_EQUIP_GLASSCUTTER",
    },
    autotool =
    {
        "AUTO_EQUIP_TOOL",
    },
    woodieregear =
    {
        "WOODIE_WEREITEM_UNEQUIP",
    },
    confirmtoeat =
    {
        "CONFIRM_TO_EAT",
    },
    telepoof =
    {
        "TELEPOOF_ENABLED",
        "TELEPOOF_DOUBLECLICK",
        "TELEPOOF_HOVER",
    },
    filterattack =
    {
        "ATTACK_FILTER",
    },
    filterpickup =
    {
        "PICKUP_FILTER",
        "PRIOTIZE_VALUABLE_ITEMS",
        "PICKUP_IGNORE_FLOWERS",
        "PICKUP_IGNORE_FERNS",
        "PICKUP_IGNORE_SUCCULENTS",
        "PICKUP_IGNORE_MARSH_BUSH",
    },
    quickactions =
    {
        "QUICK_ACTION_CAMPFIRE",
        "QUICK_ACTION_TRAP",
        "QUICK_ACTION_BIRD_CAGE",
        "QUICK_ACTION_WAKEUP_BIRD",
        "QUICK_ACTION_WALLS",
        "QUICK_ACTION_EXTINGUISH",
        "QUICK_ACTION_SLURTLEHOLE",
    }
}

for override, confs in pairs(Overrides) do
    local loaded = false

    for _, conf in pairs(confs) do
        if GetModConfigData(conf) then
            Overrides[override] = require("overrides/" .. override)
            loaded = true
            break
        end
    end

    if not loaded then
        Overrides[override] = nil
    end
end

local function OnPlayerActivated(_, player)
    if player ~= _G.ThePlayer then
        return
    end

    player:AddComponent("actioncontroller")
    player:AddComponent("itemtracker")

    if GetModConfigData("SORT_INVENTORY") or GetModConfigData("SORT_CHEST") then
        player:AddComponent("sorter")
    end

    if GetModConfigData("DAMAGE_ESTIMATION") then
        player:AddComponent("damagetracker")
    end

    for _, override in pairs(Overrides) do
        override()
    end
end

local function OnWorldPostInit(inst)
    inst:ListenForEvent("playeractivated", OnPlayerActivated, _G.TheWorld)
end
AddPrefabPostInit("world", OnWorldPostInit)
