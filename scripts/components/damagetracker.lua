local ItemFunctions = require "util/itemfunctions"
local easing = require("easing")

local HealthTracker = setmetatable({}, {__mode = "k"})

local function GetKlausHealth(target)
    local radius = target:GetPhysicsRadius(0)

    if string.format("%.1f", radius) == "1.7" then
        return TUNING.KLAUS_HEALTH * (TUNING.KLAUS_ENRAGE_SCALE * TUNING.KLAUS_ENRAGE_SCALE * TUNING.KLAUS_ENRAGE_SCALE)
    end

    return target._unchained:value() and 5000 or 10000
end

local ChessPieceScaling =
{
    shadow_rook   = {"1.6", "1.9", "2.6"},
    shadow_knight = {"0.3", "0.4", "0.6"},
    shadow_bishop = {"0.3", "0.5", "0.7"},
}

local function GetShadowPiecesHealth(target)
    local radius = string.format("%.1f", target:GetPhysicsRadius(0))

    for i = 1, #ChessPieceScaling[target.prefab] do
        if radius == ChessPieceScaling[target.prefab][i] then
            return TUNING[target.prefab:upper()].HEALTH[i]
        end
    end 

    return 0
end

local SpiderdenAnims =
{
    [1] =
    {
        hit = "cocoon_small_hit",
        idle = "cocoon_small",
        init = "grow_sac_to_small",
        freeze = "frozen_small",
        thaw = "frozen_loop_pst_small",
    },
    [2] =
    {
        hit = "cocoon_medium_hit",
        idle = "cocoon_medium",
        init = "grow_small_to_medium",
        freeze = "frozen_medium",
        thaw = "frozen_loop_pst_medium",
    },
    [3] =
    {
        hit = "cocoon_large_hit",
        idle = "cocoon_large",
        init = "grow_medium_to_large",
        freeze = "frozen_large",
        thaw = "frozen_loop_pst_large",
    },
}

local function GetSpiderdenLevel(target)
    for size, anims in pairs (SpiderdenAnims) do
        for _, anim in pairs(anims) do
            if target.AnimState:IsCurrentAnimation(anim) then
                return size
            end
        end
    end

    return 1
end

local function GetSpiderdenHealth(target)
    return TUNING.SPIDERDEN_HEALTH[GetSpiderdenLevel(target)]
end

local function GetRockyHealth(target)
    return math.floor(TUNING.ROCKY_HEALTH * target.Transform:GetScale())
end

local FuncHealth =
{
    klaus = GetKlausHealth,
    shadow_rook = GetShadowPiecesHealth,
    shadow_knight = GetShadowPiecesHealth,
    shadow_bishop = GetShadowPiecesHealth,
    spiderden = GetSpiderdenHealth,
    rocky = GetRockyHealth,
}

local TagToHealth =
{
    werepig = TUNING.WEREPIG_HEALTH,
    bird = TUNING.BIRD_HEALTH,
    warg = TUNING.WARG_HEALTH,
    leif = TUNING.LEIF_HEALTH,
    rook = TUNING.ROOK_HEALTH,
    knight = TUNING.KNIGHT_HEALTH,
    bishop = TUNING.BISHOP_HEALTH,
    hound = TUNING.HOUND_HEALTH,
    koalefant = TUNING.KOALEFANT_HEALTH,
}

local StaticHealth =
{
    -- Constants
    beehive = 200,
    wasphive = 250,
    slurtlehole = 350,
    houndmound = 300,
    mandrake_active = 20,
    birchnutdrake = 50,
    lureplant = 300,

    -- TUNING
    mermking = TUNING.MERM_KING_HEALTH,
    mermguard = TUNING.MERM_GUARD_HEALTH,
    lightninggoat = TUNING.LIGHTNING_GOAT_HEALTH,
    nightmarebeak = TUNING.TERRORBEAK_HEALTH,
    crawlingnightmare = TUNING.CRAWLINGHORROR_HEALTH,
    killerbee = TUNING.BEE_HEALTH,
    pigman = TUNING.PIG_HEALTH,
    catcoon = TUNING.CATCOON_LIFE,
    grassgekko = TUNING.GRASSGEKKO_LIFE,
    spider_dropper = TUNING.SPIDER_WARRIOR_HEALTH,
    wobster_sheller_land = TUNING.WOBSTER.HEALTH,
    wobster_moonglass_land = TUNING.WOBSTER.HEALTH,
    deer_red = TUNING.DEER_GEMMED_HEALTH,
    deer_blue = TUNING.DEER_GEMMED_HEALTH,
}

local InCompatible =
{
    butterfly = true,
    crabking = true,
}

local function GetTagHealth(inst)
    for tag, health in pairs(TagToHealth) do
        if inst:HasTag(tag) then
            return health
        end
    end

    return nil
end

local function GetMaxHealth(inst)
   return FuncHealth[inst.prefab] and FuncHealth[inst.prefab](inst)
       or GetTagHealth(inst)
       or StaticHealth[inst.prefab]
       or type(TUNING[inst.prefab:upper() .. "_HEALTH"]) == "number" and TUNING[inst.prefab:upper() .. "_HEALTH"]
       or 0
end

local function CalculateLevel(links)
    return (links < 1 and 0)
        or (links < 5 and 1)
        or (links < 8 and 2)
        or 3
end

local function GetToadstoolAbsorb(target)
    local x, y, z = target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, {"mushroomsprout"})
    local level = CalculateLevel(#ents)
    return target.prefab == "toadstool" and TUNING.TOADSTOOL_ABSORPTION_LVL[level]
        or TUNING.TOADSTOOL_DARK_ABSORPTION_LVL[level]
end

local function GetPlayerAbsorb(target)
    return TUNING.PVP_DAMAGE_MOD
end

local DamageAbsorption =
{
    anims =
    {
        "hide",
        "hide_loop",
    },
    prefabs =
    {
        spider_hider = TUNING.SPIDER_HIDER_SHELL_ABSORB,
        slurtle = TUNING.SLURTLE_SHELL_ABSORB,
        snurtle = TUNING.SLURTLE_SHELL_ABSORB,
        rocky = TUNING.ROCKY_ABSORB,
        toadstool = GetToadstoolAbsorb,
        toadstool_dark = GetToadstoolAbsorb,
    },
    tags =
    {
        player = GetPlayerAbsorb,
    }
}

local function GetAbsorbtion(target)
    for tag, absorb in pairs(DamageAbsorption.tags) do
        if target:HasTag(tag) then
            return absorb
        end
    end

    return DamageAbsorption.prefabs[target.prefab]
end

local function GetDamageAbsorption(target)
    local absorb = 1

    local absorbtion = GetAbsorbtion(target)
    if absorbtion then
        if type(absorbtion) == "function" then
            absorb = math.clamp(1 - absorbtion(target), 0, 1)
        else
            for _, anim in pairs(DamageAbsorption.anims) do
                if target.AnimState:IsCurrentAnimation(anim) then
                    absorb = math.clamp(1 - absorbtion, 0, 1)
                    break
                end
            end
        end
    end

    return absorb
end

local CurrentState = 2

local function GetDamageMultiplier(player)
    if player.prefab == "wolfgang" then
        local percent = player.replica.hunger:GetPercent()
        local damage_mult = TUNING.WOLFGANG_ATTACKMULT_NORMAL
        if CurrentState == 3 then
            local mighty_start = TUNING.WOLFGANG_START_MIGHTY_THRESH / TUNING.WOLFGANG_HUNGER
            local mighty_percent = math.max(0, (percent - mighty_start) / (1 - mighty_start))
            damage_mult = easing.linear(mighty_percent, TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MIN, TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MAX - TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MIN, 1)
        elseif CurrentState == 1 then
            local wimpy_start = TUNING.WOLFGANG_START_WIMPY_THRESH / TUNING.WOLFGANG_HUNGER
            local wimpy_percent = math.min(1, percent / wimpy_start)
            damage_mult = easing.linear(wimpy_percent, TUNING.WOLFGANG_ATTACKMULT_WIMPY_MIN, TUNING.WOLFGANG_ATTACKMULT_WIMPY_MAX - TUNING.WOLFGANG_ATTACKMULT_WIMPY_MIN, 1)
        end

        return damage_mult
    end

    return TUNING[player.prefab:upper() .. "_DAMAGE_MULT"] or 1
end

local function BeaverBonusDamage(target)
    return target:HasTag("tree")
        or target:HasTag("beaverchewable")
end

local function GetUnArmedDamage(target)
    if ThePlayer:HasTag("werehuman") then
        if ThePlayer:HasTag("beaver") then
            return TUNING.BEAVER_DAMAGE + (BeaverBonusDamage(target) and TUNING.BEAVER_WOOD_DAMAGE or 0)
        elseif ThePlayer:HasTag("weremoose") then
            return TUNING.WEREMOOSE_DAMAGE
        end
    end

    return TUNING.UNARMED_DAMAGE
end

local MostRecentDamage = 0

local function GetWeaponDamage(target)
    if ThePlayer.AnimState:IsCurrentAnimation("item_in") then
        return MostRecentDamage
    end

    local weapon = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    if not weapon then
        return GetUnArmedDamage(target)
    end

    MostRecentDamage = ItemFunctions:GetDamage(weapon, target)

    return MostRecentDamage
end

local function GetDamageDealt(target)
    return (GetWeaponDamage(target) * GetDamageMultiplier(ThePlayer)) * GetDamageAbsorption(target)
end

local function GetHealthBarMaxHealth(target)
    return target
       and target.components.modhealthbar
       and target.components.modhealthbar:GetMaxHealth()
        or 0
end

local function SetNewMaxHealth(target)
    if target and target.components.modhealthbar then
        target.components.modhealthbar:SetMaxHealth(GetMaxHealth(target))
    end
end

local IsTransformHealing =
{
    pigman = true,
    klaus = true,
}

local function GetPercentHealth(target)
    local maxHealth = GetMaxHealth(target)

    if GetHealthBarMaxHealth(target) ~= maxHealth then
        if IsTransformHealing[target.prefab] then
            HealthTracker[target] = 0
        end

        SetNewMaxHealth(target)
    end

    HealthTracker[target] = HealthTracker[target] + GetDamageDealt(target)
    return (maxHealth - HealthTracker[target]) / maxHealth, HealthTracker[target], maxHealth
end

local NpcOffset =
{
    beeguard = 3,
    rook = 3,
    bat = 3,
    rocky = 3,
    rook_nightmare = 3,
    crawlingnightmare = 4,
    nightmarebeak = 5,
    minotaur = 5,
    tallbird = 6,
    beequeen = 7,
    klaus = 7,
    dragonfly = 8,
    crabking = 9,
    deerclops = 10,
    malbatross = 10,
}

local TagToOffset =
{
    hive = 3,
    rook = 3,
    pig = 3,
    merm = 3,
    knight = 3.5,
    beefalo = 4,
    koalefant = 4,
    deer = 4,
    warg = 4,
    lightninggoat = 4,
    bishop = 4.5,
    toadstool = 7,
    leif = 9,
}

local function GetHealthBarOffset(target)
    for tag, offset in pairs(TagToOffset) do
        if target:HasTag(tag) then
            return offset
        end
    end

    return NpcOffset[target.prefab] or 2
end

local function UpdateHealthbar(target)
    if not target.components.modhealthbar then
        target:AddComponent("modhealthbar")
        SetNewMaxHealth(target)
        local offset = GetHealthBarOffset(target)
        target.components.modhealthbar:SetPosition(Vector3(0, offset, 0))
    end
    
    local percent, damage, maxHealth = GetPercentHealth(target)

    target.components.modhealthbar:SetValue(percent, damage, maxHealth)
end

local function CalcHitRangeSq(target)
    local range = target:GetPhysicsRadius(0) + ThePlayer.replica.combat:GetAttackRangeWithWeapon()
    return range * range
end

local function IsInAttackRange(target)
    return distsq(target:GetPosition(), ThePlayer:GetPosition()) <= CalcHitRangeSq(target)
end

local function IsNightmareCreature(target)
    return target:HasTag("nightmarecreature")
end

local function CanHitNightmare(target)
    if target.AnimState:IsCurrentAnimation("disappear") then
        return true
    end

    return IsInAttackRange(target)
       and target.replica.combat
       and target.replica.combat:CanBeAttacked(ThePlayer)
end

local function ValidateRange(target)
    if IsNightmareCreature(target) then
        return CanHitNightmare(target)
    end

    return IsInAttackRange(target)
       and target.replica.combat
       and target.replica.combat:CanBeAttacked(ThePlayer)
end

local function IsInOneOfAnimations(inst, anims)
    for i = 1, #anims do
        if inst.AnimState:IsCurrentAnimation(anims[i]) then
            return true
        end
    end

    return false
end

local AttackAnimations =
{
    "atk",
    "punch",
    "punch_a",
    "punch_b",
    "punch_c",
    "item_in",
}

local function GetTarget(inst)
    return inst.replica.combat:GetTarget()
        or inst.player_classified.lastcombattarget:value()
end

local function OnPerformAction(inst)
    if IsInOneOfAnimations(inst, AttackAnimations) then
        local target = GetTarget(inst)

        if target and not InCompatible[target.prefab] and ValidateRange(target) then
            if not HealthTracker[target] then
                HealthTracker[target] = 0
            end
            UpdateHealthbar(target)
        end
    end
end

local WolfgangThresh =
{
    WIMPY =
    {
        START = TUNING.WOLFGANG_START_WIMPY_THRESH,
        END   = TUNING.WOLFGANG_END_WIMPY_THRESH,
    },
    MIGHTY =
    {
        START = TUNING.WOLFGANG_START_MIGHTY_THRESH,
        END   = TUNING.WOLFGANG_END_MIGHTY_THRESH,
    },
}

local WolfgangStates =
{
    WIMPY  = 1,
    NORMAL = 2,
    MIGHTY = 3,
}

local function GetWolfgangStateFromHunger(currentHunger, lastState)
    local mightyThresh = lastState == WolfgangStates.MIGHTY and WolfgangThresh.MIGHTY.END
                         or WolfgangThresh.MIGHTY.START

    local wimpyThresh = lastState == WolfgangStates.WIMPY and WolfgangThresh.WIMPY.END
                        or WolfgangThresh.WIMPY.START

    return currentHunger > mightyThresh and WolfgangStates.MIGHTY
        or currentHunger > wimpyThresh and WolfgangStates.NORMAL
        or WolfgangStates.WIMPY
end

local function OnHungerDelta(inst)
    local currentHunger = inst.player_classified.currenthunger:value()
    CurrentState = GetWolfgangStateFromHunger(currentHunger, CurrentState)
end

local DamageTracker = Class(function(self, inst)
    self.inst = inst

    self.inst:ListenForEvent("performaction", OnPerformAction)

    if self.inst.prefab == "wolfgang" then
        OnHungerDelta(self.inst)
        self.inst:ListenForEvent("hungerdelta", OnHungerDelta)
    end
end)

return DamageTracker
