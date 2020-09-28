local ItemFunctions = require "util/itemfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE
local SpecialFood = MOD_EQUIPMENT_CONTROL.SPECIALFOOD

local Category = Class(function(self, image, autoequip, imagepath)
    self.priority = function() return 0 end
    self.fn = function() return false end
    self.image = image or nil
    self.imagepath = imagepath
    self.autoequip = autoequip
end)

Categories =
{
    WEAPON = Category("spear", true),
    CANE = Category(),
    LIGHTSOURCE = Category("torch"),
    ARMOR = Category("footballhat"),
    ARMORHAT = Category("footballhat"),
    ARMORBODY = Category("armorwood"),
    AXE = Category(),
    PICKAXE = Category(),
    SHOVEL = Category(),
    HAMMER = Category(),
    PITCHFORK = Category(),
    RANGED = Category("blowdart_pipe", true),
    STAFF = Category("firestaff", true),
    FOOD = Category("berries"),
    HEALINGFOOD = Category("healingsalve"),
    SCYTHE = Category("scythe", false, "scythe"),
}

Categories.WEAPON.fn = function(item)
    return ItemFunctions:IsMeleeWeapon(item)
end

Categories.WEAPON.priority = function(item, target)
    return ItemFunctions:GetDamage(item, target)
end

Categories.CANE.fn = function(item)
    return ItemFunctions:IsCane(item)
end

Categories.CANE.priority = function(item)
    return ItemFunctions:GetWalkspeedMult(item)
end

Categories.LIGHTSOURCE.fn = function(item)
    return ItemFunctions:IsLightSource(item)
end

Categories.LIGHTSOURCE.priority = function(item)
    return ItemFunctions:GetFuelTime(item)
end

Categories.ARMOR.fn = function(item)
    return ItemFunctions:IsArmor(item)
end

Categories.ARMOR.priority = function(item)
    return ItemFunctions:GetArmor(item)
end

Categories.ARMORHAT.fn = function(item)
    return Categories.ARMOR.fn(item)
       and ItemFunctions:GetEquipSlot(item) == EQUIPSLOTS.HEAD
end

Categories.ARMORHAT.priority = Categories.ARMOR.priority

Categories.ARMORBODY.fn = function(item)
    return Categories.ARMOR.fn(item)
       and ItemFunctions:GetEquipSlot(item) == EQUIPSLOTS.BODY
end

Categories.ARMORBODY.priority = Categories.ARMOR.priority

Categories.AXE.fn = function(item)
    return item:HasTag(ACTIONS.CHOP.id .. "_tool")
end

Categories.AXE.priority = function(item)
    return ItemFunctions:GetUses(item)
end

Categories.PICKAXE.fn = function(item)
    return item:HasTag(ACTIONS.MINE.id .. "_tool")
end

Categories.PICKAXE.priority = Categories.AXE.priority

Categories.SHOVEL.fn = function(item)
    return item:HasTag(ACTIONS.DIG.id .. "_tool")
end

Categories.SHOVEL.priority = Categories.AXE.priority

Categories.HAMMER.fn = function(item)
    return item:HasTag(ACTIONS.HAMMER.id .. "_tool")
end

Categories.HAMMER.priority = Categories.AXE.priority

Categories.PITCHFORK.fn = function(item)
    return item.prefab == "pitchfork"
end

Categories.PITCHFORK.priority = Categories.PITCHFORK.priority

Categories.STAFF.fn = function(item)
    return ItemFunctions:IsStaff(item)
       and item.prefab ~= "orangestaff"
end

Categories.STAFF.priority = Categories.WEAPON.priority

Categories.RANGED.fn = function(item)
    return ItemFunctions:IsRangedWeapon(item)
end

Categories.RANGED.priority = Categories.WEAPON.priority

Categories.FOOD.fn = function(item)
    return not SpecialFood[item.prefab]
       and ItemFunctions:CanEat(item)
       and (ItemFunctions:GetHunger(item) >= 0
            and ItemFunctions:GetHealth(item) >= 0
            or (item:HasTag("monstermeat") and ThePlayer.prefab == "webber"))
end

Categories.FOOD.priority = function(item)
    local hunger = ItemFunctions:GetHunger(item)

    if item:HasTag("soul") then
        hunger = TUNING.CALORIES_MEDSMALL
    end

    return hunger + ItemFunctions:GetHealth(item)
end

Categories.HEALINGFOOD.fn = function(item)
    return not SpecialFood[item.prefab]
       and (ItemFunctions:CanEat(item)
           and ItemFunctions:GetHealth(item) > 0
            or ItemFunctions:IsHealingItem(item))
end

Categories.HEALINGFOOD.priority = function(item)
    return ItemFunctions:GetHealth(item)
end

Categories.SCYTHE.fn = function(item)
    return item.prefab == "scythe"
        or item.prefab == "scythe_golden"
end

Categories.SCYTHE.priority = Categories.AXE.priority

for category in pairs(Categories) do
    KeybindService:AddKey(category, function()
        if ThePlayer and ThePlayer.components.actioncontroller then
            ThePlayer.components.actioncontroller:KeybindUseItem(category)
        end
    end)
end
