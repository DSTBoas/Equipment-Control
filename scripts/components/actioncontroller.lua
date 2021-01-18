local InventoryFunctions = require "util/inventoryfunctions"
local ItemFunctions = require "util/itemfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE
local Say = require "util/say"

local AUTO_UNEQUIP_REPAIRABLES = GetModConfigData("AUTO_UNEQUIP_REPAIRABLES", MOD_EQUIPMENT_CONTROL.MODNAME)

local Preferences =
{
    AutoEquipCategory = "WEAPON",
    User = {},
    Static =
    {
        glasscutter = TUNING.GLASSCUTTER.DAMAGE - .5,
        molehat = .5,
    },
}

local ActionController = Class(function(self, inst)
    self.inst = inst

    for category in pairs(Categories) do
        local conf = GetModConfigData("PREFERRED_" .. category, MOD_EQUIPMENT_CONTROL.MODNAME)
        if conf then
            Preferences.User[category] = conf
        end
    end

    if GetModConfigData("AUTO_EQUIP_GLASSCUTTER", MOD_EQUIPMENT_CONTROL.MODNAME) then
        Preferences.Static.glasscutter = TUNING.SPEAR_DAMAGE - 1
    end
end)

local function GetPreference(category, item)
    return Preferences.User[category] == item.prefab and math.huge
        or Preferences.Static[item.prefab]
end

local function GetNamePriority(item)
    return item.prefab
       and #item.prefab * .001
        or 0
end

local function GetPercentUsedPriority(item)
    return ItemFunctions:GetPercentUsed(item) * .01
end

local function GetPriority(category, item, ignorePreferences, target)
    return not ignorePreferences and GetPreference(category, item)
        or Categories[category].priority(item, target)
         + (not Categories.CANE.fn(item) and GetNamePriority(item) - GetPercentUsedPriority(item) or 0)
end

local function IsAutoUnEquipping(item)
    return AUTO_UNEQUIP_REPAIRABLES
       and ItemFunctions:IsRepairable(item)
       and ItemFunctions:GetPercentUsed(item) <= ItemFunctions:GetFiniteUses(item)
end

local function GetItemPriorityTable(category, ignorePreferences, target)
    local ret = {}

    for _, item in pairs(InventoryFunctions:GetPlayerInventory(true)) do
        if not IsAutoUnEquipping(item) and Categories[category].fn(item) then
            ret[#ret + 1] =
            {
                item = item,
                priority = GetPriority(category, item, ignorePreferences, target)
            }
        end
    end

    table.sort(ret, function(a, b)
        return a.priority > b.priority
    end)

    return ret
end

local function GetNextItemInPriorityTable(category, item)
    local t = GetItemPriorityTable(category, true)
    local nextItem = t[#t] and t[#t].item

    local found = false
    for i = #t, 1, -1 do
        if t[i].item.prefab == item.prefab then
            found = true
        elseif found then
            nextItem = t[i].item
            break 
        end
    end

    return nextItem
end

function ActionController:ChangePreferredItem(category, item)
    local nextItem = GetNextItemInPriorityTable(category, item)
    if nextItem and self.inst.HUD.controls.inv.buttons then
        Preferences.User[category] = nextItem.prefab
        self.inst.HUD.controls.inv.buttons:Refresh()
        Say("Preferred item: " .. nextItem.name)
    end
end

local function FirstToUpperRestToLowerCase(str)
    return str:sub(1,1):upper() .. str:sub(2):lower()
end

function ActionController:SetAutoEquipCategory(category)
    if Categories[category].autoequip then
        Preferences.AutoEquipCategory = category
        Say("Auto-equip category: " .. FirstToUpperRestToLowerCase(category))
    end
end

local function GetBestItem(category, target)
    local itemPriorityTable = GetItemPriorityTable(category, false, target)
    return itemPriorityTable[1] 
       and itemPriorityTable[1].item
end

function ActionController:GetAutoEquipCategoryItem(target)
    return GetBestItem(Preferences.AutoEquipCategory, target)
end

function ActionController:KeybindUseItem(category)
    self:UseItem(GetBestItem(category))
end

function ActionController:UseItem(item)
    if not item then
        return
    end

    if item:HasTag("_equippable") then
        for _, invItem in pairs(InventoryFunctions:GetEquips()) do
            if invItem.prefab == item.prefab and not invItem:HasTag("fueldepleted") then
                if InventoryFunctions:HasFreeSlot() then
                     SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.UNEQUIP.code, invItem)
                else
                    Say(
                        string.format(
                            "Cannot unequip %s.",
                            invItem.name
                        )
                    )
                end
                return
            end
        end
        InventoryFunctions:Equip(item)
        return
    end

    InventoryFunctions:UseItemFromInvTile(item)
end

function ActionController:GetItemFromCategory(category)
    return GetBestItem(category)
end

function ActionController:GetItemsFromCategory(category)
    local ret = {}
    
    for _, t in pairs(GetItemPriorityTable(category)) do
        ret[#ret + 1] = t.item
    end

    return ret
end

KeybindService:AddKey("DROPKEY", function()
    for _, item in pairs(InventoryFunctions:GetPlayerInventory(true, true)) do
        if item.prefab == "lantern" and not item:HasTag("fueldepleted") then
            InventoryFunctions:DropItemFromInvTile(item)
            return
        end
    end
end)

return ActionController
