local CacheService = require "util/cacheservice"

local ItemFunctions = {}

function ItemFunctions:GetCachedItem(item)
    return CacheService:GetCachedItem(item)
end

function ItemFunctions:GetEquipSlot(item)
    return item
       and item.replica.equippable
       and item.replica.equippable:EquipSlot()
end

function ItemFunctions:GetClassified(item)
    return item
       and item.replica.inventoryitem
       and item.replica.inventoryitem.classified
end

function ItemFunctions:GetPerish(item)
    local classified = self:GetClassified(item)
    return classified
       and classified.perish:value() / 62
        or 0
end

function ItemFunctions:GetPercentUsed(item)
    local classified = self:GetClassified(item)
    return classified
       and classified.percentused:value()
        or 0
end

local function IsSpoilingFood(cachedItem, v)
    return not (cachedItem.components.edible.degrades_with_spoilage
       and v < 0
       and IsCharacterIgnoresSpoilage())
end

local FOODSTATES =
{
    FRESH = 1,
    STALE = 2,
    SPOILED = 3
}

local function GetFoodState(perish)
    local state = FOODSTATES.SPOILED

    if perish >= 0.5 then
        state = FOODSTATES.FRESH
    elseif perish > 0.2 then
        state = FOODSTATES.STALE
    end

    return state
end

function ItemFunctions:GetFoodMultiplier()
    return TUNING[ThePlayer.prefab:upper() .. "_FOOD_MULT"] or 1
end

function ItemFunctions:GetHunger(item)
    local hunger = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem and cachedItem.components.edible then
        local foodState = GetFoodState(self:GetPerish(item))
        local foodMult = self:GetFoodMultiplier()
        hunger = cachedItem.components.edible.hungervalue

        if IsSpoilingFood(cachedItem, hunger) then
            if foodState == FOODSTATES.STALE then
                hunger = hunger * (IsPickyEeater() and TUNING.WICKERBOTTOM_STALE_FOOD_HUNGER or TUNING.STALE_FOOD_HUNGER)
            elseif foodState == FOODSTATES.SPOILED then
                hunger = hunger * (IsPickyEeater() and TUNING.WICKERBOTTOM_SPOILED_FOOD_HUNGER or TUNING.SPOILED_FOOD_HUNGER)
            end
        end

        hunger = math.ceil(hunger * foodMult)
    end

    return hunger
end

local function IsCharacterIgnoresSpoilage()
    return ThePlayer
       and ThePlayer.prefab == "wx78"
end

local function IsPickyEeater()
    return ThePlayer
       and ThePlayer.prefab == "wickerbottom"
end

function ItemFunctions:GetHealth(item)
    local health = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem and cachedItem.components.edible then
        local foodState = GetFoodState(self:GetPerish(item))
        local foodMult = self:GetFoodMultiplier()
        health = cachedItem.components.edible.healthvalue

        if IsSpoilingFood(cachedItem, health) then
            if foodState == FOODSTATES.STALE then
                health = health * (IsPickyEeater() and TUNING.WICKERBOTTOM_STALE_FOOD_HEALTH or TUNING.STALE_FOOD_HEALTH)
            elseif foodState == FOODSTATES.SPOILED then
                health = health * (IsPickyEeater() and TUNING.WICKERBOTTOM_SPOILED_FOOD_HEALTH or TUNING.SPOILED_FOOD_HEALTH)
            end
        end

        health = math.ceil(health * foodMult)
    elseif cachedItem and cachedItem.components.healer then
        health = cachedItem.components.healer.health
    end

    return health
end

function ItemFunctions:GetUses(item)
    local uses = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem then
        if cachedItem.components.finiteuses then
            uses = cachedItem.components.finiteuses.total
            if cachedItem.components.tool then
                local _, effectiveness = next(cachedItem.components.tool.actions)
                if effectiveness then
                    uses = uses + effectiveness
                end
            end
            local _, consumption = next(cachedItem.components.finiteuses.consumption)
            if consumption then
                uses = uses - consumption
            end
        else
            uses = math.huge
        end
    end

    return uses
end

function ItemFunctions:GetWalkspeedMult(item)
    local walkspeedMult = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem and cachedItem.components.equippable and cachedItem.components.equippable.walkspeedmult then
        walkspeedMult = cachedItem.components.equippable.walkspeedmult
    end

    return walkspeedMult
end

local function GetHambatDamage(item)
    local damage = TUNING.HAMBAT_DAMAGE * item.replica.inventoryitem.classified.perish:value() / 62

    return Remap(
                damage,
                0,
                TUNING.HAMBAT_DAMAGE,
                TUNING.HAMBAT_MIN_DAMAGE_MODIFIER * TUNING.HAMBAT_DAMAGE,
                TUNING.HAMBAT_DAMAGE
           )
end

local function ApplyStimuli(self, item, damage, target)
    local cachedItem = self:GetCachedItem(item)

    if cachedItem and cachedItem.components.weapon and cachedItem.components.weapon.stimuli then
        if cachedItem.components.weapon.stimuli == "electric" then
            if target then
                damage = damage * (TUNING.ELECTRIC_DAMAGE_MULT +
                         (target:GetIsWet() and TUNING.ELECTRIC_WET_DAMAGE_MULT
                         or 0))
            else
                damage = damage * (TUNING.ELECTRIC_DAMAGE_MULT +
                         (TheWorld.state.iswet and TUNING.ELECTRIC_WET_DAMAGE_MULT
                         or 0))
            end
        end
    end

    return damage
end

function ItemFunctions:GetDamage(item, target, noStimuli)
    if item.prefab == "hambat" then
        return GetHambatDamage(item)
    end

    local damage = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem and cachedItem.components.weapon then
        if type(cachedItem.components.weapon.damage) == "number" then
            damage = cachedItem.components.weapon.damage
        elseif type(cachedItem.components.weapon.damage) == "function" then
            damage = cachedItem.components.weapon.damage(item, ThePlayer, target or ThePlayer)
        end
        if not noStimuli then 
            damage = ApplyStimuli(self, item, damage, target)
        end
    end

    return damage
end

function ItemFunctions:GetArmor(item)
    local armor = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem then
        if cachedItem.components.armor then
            armor = cachedItem.components.armor.condition
        elseif cachedItem.components.resistance then
            armor = 9999
        end
    end

    return armor
end

function ItemFunctions:GetAttackRange(item)
    local cachedItem = self:GetCachedItem(item)
    return cachedItem
       and cachedItem.components.weapon
       and cachedItem.components.weapon.attackrange
        or 0
end

function ItemFunctions:GetFiniteUses(item)
    local lastUsePercent = 2

    local cachedItem = self:GetCachedItem(item)
    if cachedItem and cachedItem.components.finiteuses then
        lastUsePercent = math.ceil(100 / cachedItem.components.finiteuses:GetUses())
    end

    return lastUsePercent
end

function ItemFunctions:GetFuelTime(item)
    local priority = 0

    local prefab = item.prefab:upper()
    if TUNING[prefab .. "_LIGHTTIME"] then
        priority = TUNING[prefab .. "_LIGHTTIME"]
    elseif TUNING[prefab .. "_FUEL"] then
        priority = TUNING[prefab .. "_FUEL"]
    elseif TUNING[prefab .. "_PERISHTIME"] then
        priority = TUNING[prefab .. "_PERISHTIME"]
    end

    return priority
end

function ItemFunctions:IsRepairable(item)
    local cachedItem = self:GetCachedItem(item)
    return item.prefab == "staff_tornado"
        or cachedItem
       and cachedItem.components.fueled
       and not cachedItem.components.fueled.no_sewing
       and cachedItem.components.fueled.depleted == EntityScript.Remove
       and (cachedItem.components.fueled.fueltype == FUELTYPE.USAGE
           or cachedItem.components.fueled.fueltype == FUELTYPE.NIGHTMARE)
end

function ItemFunctions:IsTerraformer(item)
    local cachedItem = self:GetCachedItem(item)
    return cachedItem and cachedItem.components.terraformer
end

function ItemFunctions:IsCane(item)
    return self:GetWalkspeedMult(item) > 1
       and self:GetEquipSlot(item) == EQUIPSLOTS.HANDS
end

function ItemFunctions:IsLightSource(item)
    return not item:HasTag("fueldepleted")
       and (item:HasTag(FUELTYPE.CAVE .. "_fueled")
           or item:HasTag(FUELTYPE.WORMLIGHT .. "_fueled")
           or item:HasTag("lighter"))
end

function ItemFunctions:IsMeleeWeapon(item)
    return item:HasTag("weapon")
       and not self:IsCane(item)
       and not item:HasTag("tool")
       and not self:IsTerraformer(item)
       and self:GetAttackRange(item) == 0
end

function ItemFunctions:IsRangedWeapon(item)
    return not self:IsStaff(item)
       and self:GetAttackRange(item) > 0
end

function ItemFunctions:IsArmor(item)
    return self:GetArmor(item) > 0
end

function ItemFunctions:IsStaff(item)
    local cachedItem = self:GetCachedItem(item)
    return cachedItem
       and cachedItem.components.spellcaster
        or item.prefab:sub(-5, #item.prefab) == "staff"
end

function ItemFunctions:CanEat(item)
    if ThePlayer:HasTag("souleater") and item:HasTag("soul") then
        return true
    end

    for _, v in pairs(FOODGROUP) do
        if ThePlayer:HasTag(v.name .. "_eater") then
            for i, v2 in ipairs(v.types) do
                if item:HasTag("edible_" .. v2) then
                    return true
                end
            end
        end
    end

    for _, v in pairs(FOODTYPE) do
        if item:HasTag("edible_" .. v) and ThePlayer:HasTag(v .. "_eater") then
            return true
        end
    end

    return false
end

function ItemFunctions:IsHealingItem(item)
    local cachedItem = self:GetCachedItem(item)
    return cachedItem
       and cachedItem.components.healer
end

return ItemFunctions
