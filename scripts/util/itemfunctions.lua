local CacheService = require "util/cacheservice"

local TOOLS_ON_WEAPON = GetModConfigData("TOOLS_ON_WEAPON", MOD_EQUIPMENT_CONTROL.MODNAME)

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

local function IsCharacterIgnoresSpoilage()
    return ThePlayer
       and ThePlayer.prefab == "wx78"
end

local function IsSpoilingFood(cachedItem, val)
    return not IsCharacterIgnoresSpoilage()
       and cachedItem.components.edible.degrades_with_spoilage
       and val > 0
end

function ItemFunctions:GetGoldValue(item)
    local cachedItem = self:GetCachedItem(item)

    return cachedItem
       and cachedItem.components.tradable
       and cachedItem.components.tradable.goldvalue
        or 0
end

local FOODSTATES =
{
    FRESH = 1,
    STALE = 2,
    SPOILED = 3,
}

local function GetFoodState(item)
    return item:HasTag("stale") and FOODSTATES.STALE
        or item:HasTag("spoiled") and FOODSTATES.SPOILED
        or FOODSTATES.FRESH
end

function ItemFunctions:GetFoodMultiplier()
    return TUNING[ThePlayer.prefab:upper() .. "_FOOD_MULT"] or 1
end

local function IsPickyEeater()
    return ThePlayer
       and ThePlayer.prefab == "wickerbottom"
end

function ItemFunctions:GetHunger(item)
    local hunger = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem and cachedItem.components.edible then
        hunger = cachedItem.components.edible.hungervalue

        if IsSpoilingFood(cachedItem, hunger) then
            local foodState = GetFoodState(item)

            if foodState == FOODSTATES.STALE then
                hunger = hunger * (IsPickyEeater() and TUNING.WICKERBOTTOM_STALE_FOOD_HUNGER or TUNING.STALE_FOOD_HUNGER)
            elseif foodState == FOODSTATES.SPOILED then
                hunger = hunger * (IsPickyEeater() and TUNING.WICKERBOTTOM_SPOILED_FOOD_HUNGER or TUNING.SPOILED_FOOD_HUNGER)
            end
        end

        hunger = math.ceil(hunger * self:GetFoodMultiplier())
    end

    return hunger
end

function ItemFunctions:GetHealth(item)
    local health = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem and cachedItem.components.edible then
        health = cachedItem.components.edible.healthvalue

        if IsSpoilingFood(cachedItem, health) then
            local foodState = GetFoodState(item)
            if foodState == FOODSTATES.STALE then
                health = health * (IsPickyEeater() and TUNING.WICKERBOTTOM_STALE_FOOD_HEALTH or TUNING.STALE_FOOD_HEALTH)
            elseif foodState == FOODSTATES.SPOILED then
                health = health * (IsPickyEeater() and TUNING.WICKERBOTTOM_SPOILED_FOOD_HEALTH or TUNING.SPOILED_FOOD_HEALTH)
            end
        end

        health = math.ceil(health * self:GetFoodMultiplier())
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
    local cachedItem = self:GetCachedItem(item)

    return cachedItem
       and cachedItem.components.equippable
       and cachedItem.components.equippable.walkspeedmult
        or 0
end

local function GetHambatDamage(self, item)
    local damage = TUNING.HAMBAT_DAMAGE * self:GetPerish(item)

    return Remap(
                damage,
                0,
                TUNING.HAMBAT_DAMAGE,
                TUNING.HAMBAT_MIN_DAMAGE_MODIFIER * TUNING.HAMBAT_DAMAGE,
                TUNING.HAMBAT_DAMAGE
           )
end

local function ApplyStimuli(self, item, damage, target)
    if not target then
        return damage
    end

    local cachedItem = self:GetCachedItem(item)

    if cachedItem and cachedItem.components.weapon and cachedItem.components.weapon.stimuli then
        if cachedItem.components.weapon.stimuli == "electric" then
            damage = damage * (TUNING.ELECTRIC_DAMAGE_MULT +
                     (target:GetIsWet() and TUNING.ELECTRIC_WET_DAMAGE_MULT
                     or 0))
        end
    end

    return damage
end

local BadPrefabs =
{
    lilina_wrath = 68,
}

function ItemFunctions:GetDamage(item, target, noStimuli)
    if item.prefab == "hambat" then
        return GetHambatDamage(self, item)
    end

    local damage = 0

    local cachedItem = self:GetCachedItem(item)
    if cachedItem and cachedItem.components.weapon then
        if BadPrefabs[item.prefab] then
            return BadPrefabs[item.prefab]
        elseif type(cachedItem.components.weapon.damage) == "number" then
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

function ItemFunctions:GetMaxFuel(item)
    local cachedItem = self:GetCachedItem(item)

    return cachedItem
       and cachedItem.components.fueled
       and cachedItem.components.fueled.maxfuel
        or 0
end

function ItemFunctions:IsLightSource(item)
    return not item:HasTag("fueldepleted")
       and (item:HasTag(FUELTYPE.CAVE .. "_fueled")
            or item:HasTag(FUELTYPE.WORMLIGHT .. "_fueled")
            or item:HasTag("lighter"))
end

function ItemFunctions:IsRepairable(item)
    local cachedItem = self:GetCachedItem(item)

    if item.prefab == "staff_tornado" or item.prefab == "molehat" then
        return true
    end

    return cachedItem
       and cachedItem.components.fueled
       and not cachedItem.components.fueled.no_sewing
       and cachedItem.components.fueled.depleted == EntityScript.Remove
       and cachedItem.components.fueled.fueltype ~= FUELTYPE.BURNABLE
end

function ItemFunctions:IsTerraformer(item)
    local cachedItem = self:GetCachedItem(item)

    return cachedItem
       and cachedItem.components.terraformer
end

function ItemFunctions:IsCane(item)
    return self:GetWalkspeedMult(item) > 1
       and self:GetEquipSlot(item) == EQUIPSLOTS.HANDS
end

function ItemFunctions:IsProjectile(item)
    local cachedItem = self:GetCachedItem(item)

    return cachedItem
       and (cachedItem.components.projectile
           or cachedItem.components.complexprojectile)
end

function ItemFunctions:IsTool(item)
    local cachedItem = self:GetCachedItem(item)

    return cachedItem
       and cachedItem.components.tool
end

function ItemFunctions:IsWeapon(item)
    local cachedItem = self:GetCachedItem(item)

    return cachedItem
       and cachedItem.components.weapon
       and not cachedItem.components.weapon:CanRangedAttack()
end

function ItemFunctions:IsMeleeWeapon(item)
    return self:IsWeapon(item)
       and not self:IsLightSource(item)
       and (TOOLS_ON_WEAPON or not self:IsTool(item))
       and not self:IsTerraformer(item)
       and not self:IsProjectile(item)
       and not self:IsStaff(item)
end

function ItemFunctions:IsRangedWeapon(item)
    return self:IsProjectile(item)
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
