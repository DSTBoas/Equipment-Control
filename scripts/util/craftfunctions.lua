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

local function GetBuilder()
    return ThePlayer
       and ThePlayer.replica.builder
end

function CraftFunctions:CanCraft(recipename)
    local builder = GetBuilder()
    return builder
       and builder:CanBuild(recipename)
end

function CraftFunctions:Craft(recipe)
    recipe = GetValidRecipe(recipe)

    if not recipe then
        return
    end

    local builder = GetBuilder()
    if builder then
        builder:MakeRecipeFromMenu(recipe)
    end
end


return CraftFunctions
