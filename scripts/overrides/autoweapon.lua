local InventoryFunctions = require "util/inventoryfunctions"
local ConfigFunctions = require "util/configfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

-- 
-- Logic
-- 

local AutoEquipFns = {}

local function AddAutoEquip(config, trigger, fn, opts)
    opts = opts or {}
    local requires_target = (opts.requires_target ~= false)

    if GetModConfigData(config, MOD_EQUIPMENT_CONTROL.MODNAME) then
        AutoEquipFns[#AutoEquipFns + 1] =
        {
            trigger = trigger,
            fn = fn,
            requires_target = requires_target,
        }
    end
end

-- 
-- Helpers
-- 

local function GlasscutterTrigger(target)
    return target:HasTag("shadow")
        or target:HasTag("shadowminion")
        or target:HasTag("shadowchesspiece")
        or target:HasTag("stalker")
        or target:HasTag("stalkerminion")
end

local AUTO_EQUIP_WEAPON = GetModConfigData("AUTO_EQUIP_WEAPON", MOD_EQUIPMENT_CONTROL.MODNAME)

local function IsRangeWeaponEquipped()
    local equipped = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)

    if not equipped then
        return false
    end

    return Categories.RANGED.fn(equipped)
end

local function WeaponTrigger(target)
    return AUTO_EQUIP_WEAPON
       and not IsRangeWeaponEquipped()
       and not target:HasTag("butterfly")
end

local function GetPrefabFromInventory(prefab)
    for _, invItem in pairs(InventoryFunctions:GetPlayerInventory(true)) do
        if invItem.prefab == prefab then
            return invItem
        end
    end

    return nil
end

local function EquipWeapon(target)
    if not ThePlayer or not ThePlayer.components.actioncontroller then
        return
    end

    local weapon = ThePlayer.components.actioncontroller:GetAutoEquipCategoryItem(target)

    InventoryFunctions:Equip(weapon, true)
end

local function EquipGlasscutter()
    local weapon = GetPrefabFromInventory("glasscutter")

    if not weapon then
        EquipWeapon()
        return
    end

    InventoryFunctions:Equip(weapon, true)
end

local function IsMountedOnBigWoby()
    return ThePlayer
        and ThePlayer:HasTag("dogrider")
        and ThePlayer.replica.rider ~= nil
        and ThePlayer.replica.rider:GetMount() ~= nil
        and ThePlayer.replica.rider:GetMount().prefab == "wobybig"
end

local function EquipRanged()
    if not ThePlayer or not ThePlayer.components.actioncontroller then return end
    local ranged = ThePlayer.components.actioncontroller:GetItemFromCategory("WEAPON")
    if ranged then
        InventoryFunctions:Equip(ranged, true)
    end
end

local function WobyRangedTrigger(_)
    local target = ThePlayer.components.actioncontroller:GetItemFromCategory("WEAPON")
    local equipped = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)
    return AUTO_EQUIP_WEAPON
        and IsMountedOnBigWoby()
        and target ~= equipped
end

-- 
-- Auto equips
-- 

AddAutoEquip("AUTO_EQUIP_GLASSCUTTER", GlasscutterTrigger, EquipGlasscutter)
AddAutoEquip("AUTO_EQUIP_WEAPON", WeaponTrigger, EquipWeapon)
AddAutoEquip("AUTO_EQUIP_WEAPON", WobyRangedTrigger, EquipRanged, { requires_target = false })

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end

    local PlayerControllerDoAttackButton = PlayerController.DoAttackButton
    function PlayerController:DoAttackButton(retarget)
        local force_attack = TheInput:IsControlPressed(CONTROL_FORCE_ATTACK)
        local target = self:GetAttackTarget(force_attack, retarget, retarget ~= nil)

        local handled = false
        for i = 1, #AutoEquipFns do
            local rule = AutoEquipFns[i]
            if rule.requires_target == false and rule.trigger(nil) then
                rule.fn(nil)
                handled = true
                break
            end
        end

        if not handled and target then
            for i = 1, #AutoEquipFns do
                local rule = AutoEquipFns[i]
                if rule.requires_target ~= false and rule.trigger(target) then
                    rule.fn(target)
                    break
                end
            end
        end

        PlayerControllerDoAttackButton(self, retarget)
    end
end

KeybindService:AddKey("TOGGLE_AUTO_EQUIP", function()
    AUTO_EQUIP_WEAPON = ConfigFunctions:DoToggle("Auto-equip weapon", AUTO_EQUIP_WEAPON)
end)

return Init
