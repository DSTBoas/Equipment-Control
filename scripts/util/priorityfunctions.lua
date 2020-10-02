local ItemFunctions = require "util/itemfunctions"

local PriorityFunctions = {}

local Settings =
{
    "ARMOR_SORT_PRIORITY",
    "LIGHT_SORT_PRIORITY",
    "STAFF_SORT_PRIORITY",
    "EQUIPMENT_SORT_PRIORITY",
    "FOOD_SORT_PRIORITY",
    "RESOURCE_SORT_PRIORITY",
    "TOOL_SORT_PRIORITY",
}

local function SetSettings()
    for i = 1, #Settings do
        Settings[Settings[i]] = GetModConfigData(Settings[i], MOD_EQUIPMENT_CONTROL.MODNAME)
        Settings[i] = nil
    end
end
SetSettings()

local function IsEquippable(item)
    return item
       and item.replica.equippable
end

local function IsEdible(item)
    return ItemFunctions:CanEat(item)
end

local function GetBaseHealthValue(item)
    local cachedItem = ItemFunctions:GetCachedItem(item)
    local mult = ItemFunctions:GetFoodMultiplier()
    return cachedItem
       and cachedItem.components.edible
       and math.ceil(cachedItem.components.edible.healthvalue * mult)
end

local function GetBaseHungerValue(item)
    if item:HasTag("soul") then
        return TUNING.CALORIES_MEDSMALL
    end

    local mult = ItemFunctions:GetFoodMultiplier()
    local cachedItem = ItemFunctions:GetCachedItem(item)
    return cachedItem
       and cachedItem.components.edible
       and math.ceil(cachedItem.components.edible.hungervalue * mult)
end

local cachedPriority = {}

local function GetNamePriority(prefab)
    local num = 0

    if not cachedPriority[prefab] then
        for name in pairs(Prefabs) do
            num = num + 1
            if name == prefab then
                cachedPriority[prefab] = num
                break
            end
        end
    end

    return cachedPriority[prefab] or 0
end

local Resources =
{
    -- Gems
    "opalpreciousgem",
    "greengem",
    "yellowgem",
    "orangegem",
    "purplegem",
    "bluegem",
    "redgem",

    -- Basic
    "twigs",
    "cutgrass",
    "log",

    -- Ore
    "goldnugget",
    "rocks",
    "flint",
    "nitre",

    -- Refined
    "rope",
    "cutstone",
    "boards",
}

local function GetPriorityRank(v)
    return v * .00001
end

local function GetResourceValue(item)
    local val = 0

    for i = #Resources, 1, -1 do
        val = val + 1
        if item.prefab == Resources[i] then
            return val * .001
        end
    end

    return 0
end

local function IsResource(item)
	for i = 1, #Resources do
		if item.prefab == Resources[i] then
			return true
		end
	end

    return false
end

local function IsTool(item)
    return item:HasTag("tool") or item.prefab == "pitchfork"
end

function PriorityFunctions:CanOnlyGoInPocket(item)
    return item and item.replica.inventoryitem:CanOnlyGoInPocket()
end

-- @TODO Refactoring
local function GetPriority(item)
    local priority = 0

    if IsEquippable(item) then
        if IsTool(item) then
            priority = priority + Settings.TOOL_SORT_PRIORITY
            priority = priority + GetPriorityRank(ItemFunctions:GetPercentUsed(item) * .0000001)
        elseif ItemFunctions:IsLightSource(item) then
            priority = priority + Settings.LIGHT_SORT_PRIORITY
            priority = priority + GetPriorityRank(ItemFunctions:GetMaxFuel(item) + ItemFunctions:GetPercentUsed(item) * .0000001)
        elseif ItemFunctions:IsStaff(item) then
            priority = priority + Settings.STAFF_SORT_PRIORITY
            priority = priority + GetPriorityRank(ItemFunctions:GetPercentUsed(item) * .0000001)
        elseif ItemFunctions:IsArmor(item) then
            priority = priority + Settings.ARMOR_SORT_PRIORITY
            priority = priority + GetPriorityRank(ItemFunctions:GetArmor(item) + ItemFunctions:GetPercentUsed(item))
            if item.prefab:find("hat") then
                priority = priority + .25
            end
        elseif ItemFunctions:IsMeleeWeapon(item) then
            priority = priority + Settings.EQUIPMENT_SORT_PRIORITY
            priority = priority + GetPriorityRank(ItemFunctions:GetDamage(item, nil, true) + GetPriorityRank(ItemFunctions:GetPercentUsed(item)))
        else
            priority = priority + Settings.EQUIPMENT_SORT_PRIORITY
            priority = priority + GetPriorityRank(ItemFunctions:GetPercentUsed(item))
        end
    elseif IsEdible(item) then
        priority = priority + Settings.FOOD_SORT_PRIORITY
        if GetBaseHealthValue(item) then
            priority = priority + GetPriorityRank(GetBaseHealthValue(item))
        end
        if GetBaseHungerValue(item) then
            priority = priority + GetPriorityRank(GetBaseHungerValue(item))
        end
    elseif IsResource(item) then
        priority = priority + Settings.RESOURCE_SORT_PRIORITY
        priority = priority + GetResourceValue(item)
    end

    priority = priority + (GetNamePriority(item.prefab) * .00000000001) + (GetPriorityRank(item.GUID) * .00000000001)

    return priority
end

function PriorityFunctions:CreatePriorityTable(items)
    local ret = {}

    for _, item in pairs(items) do
        ret[#ret +1] =
        {
            item = item,
            priority = GetPriority(item)
        }
    end

    table.sort(ret, function(a, b)
        return a.priority > b.priority
    end)

    return ret
end

return PriorityFunctions
