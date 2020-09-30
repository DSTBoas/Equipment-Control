local InventoryFunctions = require "util/inventoryfunctions"

local CraftFunctions = {}

local function IsBuilding(animState)
    return animState:IsCurrentAnimation("build_pre")
        or animState:IsCurrentAnimation("build_loop")
end

function CraftFunctions:IsCrafting()
    local animState = ThePlayer and ThePlayer.AnimState

    if not animState then
        return false
    end

    return IsBuilding(animState)
end

function CraftFunctions:CanCraft(prefab)
    local recipe = AllRecipes[prefab]

    if recipe then
        for _, ingredient in pairs(recipe.ingredients) do
            if not InventoryFunctions:Has(ingredient.type, ingredient.amount) then
                return false
            end
        end

        return true
    end

    return false
end

function CraftFunctions:Craft(prefab)
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if PlayerController then
        local recipe = AllRecipes[prefab]

        if recipe then
            PlayerController:RemoteMakeRecipeFromMenu(recipe)
        end
    end
end


return CraftFunctions
