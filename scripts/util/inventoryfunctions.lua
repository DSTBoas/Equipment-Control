local InventoryFunctions = {}

function InventoryFunctions:GetInventory()
    return ThePlayer
       and ThePlayer.replica.inventory
end

function InventoryFunctions:GetInventoryItems()
    local inventory = self:GetInventory()
    return inventory
       and inventory:GetItems()
        or {}
end

function InventoryFunctions:Equip(item, prefab)
    if not item or prefab and InventoryFunctions:IsEquipped(item.prefab) then
        return
    end

    if ThePlayer.components.inventory ~= nil then
        ThePlayer.components.locomotor:PushAction(
            BufferedAction(ThePlayer, nil, ACTIONS.EQUIP, item),
            true
        )
    else
        SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.EQUIP.code, item)
    end
end

function InventoryFunctions:IsEquipped(item)
    if not item then
        return false
    end

    if type(item) == "string" then
        for _, equippedItem in pairs(self:GetEquips()) do
            if equippedItem.prefab == item then
                return true
            end
        end
    else
        for _, equippedItem in pairs(self:GetEquips()) do
            if equippedItem == item then
                return true
            end
        end
    end

    return false
end

function InventoryFunctions:GetPlayerInventory(equips, noActiveItem)
    local playerInventory = {}

    for _, item in pairs(self:GetInventoryItems()) do
        playerInventory[#playerInventory + 1] = item
    end

    for _, item in pairs(self:GetBackpackItems()) do
        playerInventory[#playerInventory + 1] = item
    end

    if equips then
        for _, item in pairs(self:GetEquips()) do
            playerInventory[#playerInventory + 1] = item
        end

        if not noActiveItem then
            local activeItem = self:GetActiveItem()
            if activeItem then
                playerInventory[#playerInventory + 1] = activeItem
            end
        end
    end

    return playerInventory
end

function InventoryFunctions:GetEquips()
    local inventory = self:GetInventory()
    return inventory
       and inventory:GetEquips()
        or {}
end

function InventoryFunctions:GetEquippedItem(eslot)
    local inventory = self:GetInventory()
    return inventory
       and inventory:GetEquippedItem(eslot)
end

function InventoryFunctions:GetBackpack()
    local inventory = self:GetInventory()
    return inventory
       and inventory:GetOverflowContainer()
       and inventory:GetOverflowContainer().inst.replica.container
end

function InventoryFunctions:GetBackpackItems()
    local backpack = self:GetBackpack()
    return backpack
       and backpack:GetItems()
        or {}
end

function InventoryFunctions:Has(prefab, amount)
    local inventory = self:GetInventory()
    return inventory
       and inventory:Has(prefab, amount)
end

function InventoryFunctions:EquipHasTag(tag)
    local inventory = self:GetInventory()
    return inventory
       and inventory:EquipHasTag(tag)
end

function InventoryFunctions:IsHeavyLifting()
    local inventory = self:GetInventory()
    return inventory
       and inventory:IsHeavyLifting()
end

function InventoryFunctions:HasFreeSlot()
    local inventory = self:GetInventory()
    local backpack = self:GetBackpack()
    return inventory and not inventory:IsFull()
        or backpack and not backpack:IsFull()
end

function InventoryFunctions:GetActiveItem()
    local inventory = self:GetInventory()
    return inventory
       and inventory:GetActiveItem()
end

function InventoryFunctions:GetClassified()
    local inventory = self:GetInventory()
    return inventory
       and inventory.classified
end

function InventoryFunctions:GetOverflowContainer()
    local inventory = self:GetInventory()
    return inventory
       and inventory:GetOverflowContainer()
end

function InventoryFunctions:IsBusyClassified()
    local classified = self:GetClassified()
    return classified
       and classified.IsBusy
       and classified:IsBusy()
end

function InventoryFunctions:UseItemFromInvTile(item)
    local inventory = self:GetInventory()
    return inventory
       and inventory:UseItemFromInvTile(item)
end

function InventoryFunctions:ControllerUseItemOnSelfFromInvTile(item)
    local inventory = self:GetInventory()
    return inventory
       and inventory:ControllerUseItemOnSelfFromInvTile(item)
end

function InventoryFunctions:DropItemFromInvTile(item)
    local inventory = self:GetInventory()
    return inventory
       and inventory:DropItemFromInvTile(item)
end

function InventoryFunctions:ReturnActiveItem()
    local inventory = self:GetInventory()
    return inventory
       and inventory:ReturnActiveItem()
end

function InventoryFunctions:TakeActiveItemFromEquipSlot(eslot)
    local inventory = self:GetInventory()
    return inventory
       and inventory:TakeActiveItemFromEquipSlot(eslot)
end

function InventoryFunctions:DropItemFromInvTile(item)
    local inventory = self:GetInventory()
    return inventory
       and inventory:DropItemFromInvTile(item)
end

function InventoryFunctions:TakeActiveItemFromAllOfSlot(slot)
    local inventory = self:GetInventory()
    return inventory
       and inventory:TakeActiveItemFromAllOfSlot(slot)
end

function InventoryFunctions:MoveItemFromAllOfSlot(slot, container)
    local inventory = self:GetInventory()
    return inventory
       and inventory:MoveItemFromAllOfSlot(slot, container)
end

return InventoryFunctions
