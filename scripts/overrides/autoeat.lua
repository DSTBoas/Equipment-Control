local InventoryFunctions = require "util/inventoryfunctions"

local function OnHungerDirty(inst)
    if inst._parent ~= nil and inst.currenthunger:value() == 0 then
        local item = ThePlayer.components.actioncontroller:GetItemFromCategory("FOOD")

        if item then
            InventoryFunctions:UseItemFromInvTile(item)
        end
    end
end

local function Init()
    if not ThePlayer or not ThePlayer.player_classified then
        return
    end

    ThePlayer.player_classified:ListenForEvent("hungerdirty", OnHungerDirty)
end

return Init
