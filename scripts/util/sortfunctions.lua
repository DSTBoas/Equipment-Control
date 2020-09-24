local InventoryFunctions = require "util/inventoryfunctions"

local SortFunctions = {}

local function AddToInventoryTable(t, slot, item, overflow)
    t[slot + (overflow or 0)] = item
end

function SortFunctions:GetInventorySlots()
    local inventory = InventoryFunctions:GetInventory()
    return inventory
       and inventory:GetNumSlots()
        or 0
end

function SortFunctions:GetBackpackItems()
    local inventory = InventoryFunctions:GetInventory()
    local items = {}

    if inventory and InventoryFunctions:GetBackpack() then
        local overflow = inventory:GetNumSlots()
        for slot, item in pairs(InventoryFunctions:GetBackpackItems()) do
            AddToInventoryTable(items, slot, item, overflow)
        end
    end

    return items
end

function SortFunctions:GetPlayerInventory(noBackpack)
    local inventory = InventoryFunctions:GetInventory()
    local playerInventory = {}

    if inventory then
        local items = inventory:GetItems()
        for slot, item in pairs(items) do
            AddToInventoryTable(playerInventory, slot, item)
        end

        if not noBackpack and InventoryFunctions:GetBackpack() then
            local overflow = inventory:GetNumSlots()
            for slot, item in pairs(InventoryFunctions:GetBackpackItems()) do
                AddToInventoryTable(playerInventory, slot, item, overflow)
            end
        end
    end

    return playerInventory
end

function SortFunctions:FindFreeInventorySlot(item)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        local invSlots = inventory:GetNumSlots()
        for i = 1, invSlots do
            if not inventory:GetItemInSlot(i) then
                return i
            end
        end

        local backpack = InventoryFunctions:GetBackpack()
        if backpack then
            for i = 1, backpack:GetNumSlots() do
                if not backpack:GetItemInSlot(i) then
                    return invSlots + i
                end
            end
        end
    end

    return nil
end

function SortFunctions:IsStackable(item)
    return item
       and item.replica.stackable
end

function SortFunctions:MatchGUID(a, b)
    return a and b
       and a.GUID == b.GUID
end

local function FindItemInPlayerInventory(self, searchItem)
    local items = self:GetPlayerInventory()

    for _, item in pairs(items) do
        if self:MatchGUID(searchItem, item) then
            return item
        end
    end

    return false
end

local function GetItemInSlot(slot)
    if ThePlayer.components.inventory then
        return ThePlayer.components.inventory:GetItemInSlot(slot)
    else
        local classified = InventoryFunctions:GetClassified()
        if classified then
            return classified:GetItemInSlot(slot)
        end
    end

    return nil
end

function SortFunctions:IsSlotOccupied(slot)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        if slot > inventory:GetNumSlots() then
            slot = slot % inventory:GetNumSlots()
            local backpack = InventoryFunctions:GetBackpack()
            return backpack and backpack:GetItemInSlot(slot)
        else
            return GetItemInSlot(slot)
        end
    end

    return nil
end

function SortFunctions:GetBackpackEnt()
    local inventory = InventoryFunctions:GetInventory()
    return inventory
       and inventory:GetOverflowContainer()
       and inventory:GetOverflowContainer().inst
end

local function MoveHandToSlot(self, inventory, slot)
    local container = slot > inventory:GetNumSlots() and self:GetBackpackEnt() or nil
    local slotOccupied = self:IsSlotOccupied(slot)
    if container then
        slot = slot % inventory:GetNumSlots()
    end
    local code = slotOccupied and RPC.SwapActiveItemWithSlot
                 or RPC.PutAllOfActiveItemInSlot

    SendRPCToServer(code, slot, container)
end

function SortFunctions:ForceItemIntoSlot(item, slot)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        if self:MatchGUID(self:IsSlotOccupied(slot), item) then
            return true
        end

        if self:MatchGUID(InventoryFunctions:GetActiveItem(), item) then
            MoveHandToSlot(self, inventory, slot)
            return true
        end
    end

    return false
end

local function MoveSlotIntoHand(self, inventory, slot)
    local activeItem = inventory:GetActiveItem()
    local code = activeItem and RPC.SwapActiveItemWithSlot
                 or RPC.TakeActiveItemFromAllOfSlot
    local container = slot > inventory:GetNumSlots() and self:GetBackpackEnt() or nil
    if container then
        slot = slot % inventory:GetNumSlots()
    end

    SendRPCToServer(code, slot, container)
end

local function GetCorrespondingSlot(self, item)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        local items = inventory:GetItems()

        for slot, invItem in pairs(items) do
            if self:MatchGUID(invItem, item) then
                return slot
            end
        end

        if InventoryFunctions:GetBackpack() then
            local overflow = inventory:GetNumSlots()

            for slot, backpackItem in pairs(InventoryFunctions:GetBackpackItems()) do
                if self:MatchGUID(backpackItem, item) then
                    return slot + overflow
                end
            end
        end
    end
end

function SortFunctions:GetTotalInventorySlots()
    local inventory = InventoryFunctions:GetInventory()
    local numSlots = 0

    if inventory then
        numSlots = numSlots + inventory:GetNumSlots()

        local backpack = InventoryFunctions:GetBackpack()
        if backpack then
            numSlots = numSlots + backpack:GetNumSlots()
        end
    end

    return numSlots
end

function SortFunctions:ForceItemIntoActiveItem(item)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        if self:MatchGUID(InventoryFunctions:GetActiveItem(), item) then
            return true
        end

        local inventoryItem = FindItemInPlayerInventory(self, item)
        local slot = GetCorrespondingSlot(self, inventoryItem)

        if inventoryItem then
            MoveSlotIntoHand(self, inventory, slot)
            return true
        end
    end

    return false
end

function SortFunctions:GetStackSize(item)
    return self:IsStackable(item)
       and item.replica.stackable:StackSize()
        or 0
end

function SortFunctions:GetStackMaxSize(item)
    return self:IsStackable(item)
       and item.replica.stackable:MaxSize()
        or 0
end

function SortFunctions:GetFreeStackSize(item)
    return self:GetStackMaxSize(item) - self:GetStackSize(item)
end

function SortFunctions:GetSlotFromItem(item)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        local items = self:GetPlayerInventory()
        for i, v in pairs(items) do
            if self:MatchGUID(item, v) then
                return i
            end
        end
    end

    return nil
end

-- 
-- Container functions are duplicates for now need to redo the sorter to make every function compatible
--

function SortFunctions:FindFreeInventorySlot(item)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        local invSlots = inventory:GetNumSlots()
        for i = 1, invSlots do
            if not inventory:GetItemInSlot(i) then
                return i
            end
        end

        local backpack = InventoryFunctions:GetBackpack()
        if backpack then
            for i = 1, backpack:GetNumSlots() do
                if not backpack:GetItemInSlot(i) then
                    return invSlots + i
                end
            end
        end
    end

    return nil
end

function SortFunctions:FindFreeContainerSlot(item, container)
    for slot = 1, self:GetSlotsFromContainer(container) do
        if not self:IsSlotOccupiedContainer(slot, container) then
            return slot
        end
    end

    return nil
end

function SortFunctions:IsFullContainer(container)
    return container
       and container.replica.container
       and container.replica.container:IsFull()
end

function SortFunctions:GetItemsFromContainer(container)
    return container
       and container.replica.container
       and container.replica.container:GetItems()
        or {}
end

function SortFunctions:GetSlotsFromContainer(container)
    return container
       and container.replica.container
       and container.replica.container:GetNumSlots()
        or 0
end

function SortFunctions:GetSlotFromItemContainer(searchItem, container)
    for slot, item in pairs(self:GetItemsFromContainer(container)) do
        if self:MatchGUID(item, searchItem) then
            return slot
        end
    end

    return nil
end

local function FindItemInContainer(self, container, searchItem)
    for slot, item in pairs(self:GetItemsFromContainer(container)) do
        if self:MatchGUID(searchItem, item) then
            return item, slot
        end
    end

    return false
end

local function MoveSlotIntoHandContainer(container, slot)
    local activeItem = InventoryFunctions:GetActiveItem()
    local code = activeItem and RPC.SwapActiveItemWithSlot
                 or RPC.TakeActiveItemFromAllOfSlot
    SendRPCToServer(code, slot, container)
end

function SortFunctions:ForceItemIntoActiveItemContainer(item, container)
    if container and container.replica.container then
        if self:MatchGUID(InventoryFunctions:GetActiveItem(), item) then
            return true
        end

        local containerItem, slot = FindItemInContainer(self, container, item)

        if containerItem then
            MoveSlotIntoHandContainer(container, slot)
            return true
        end
    end

    return false
end

function SortFunctions:IsSlotOccupiedContainer(slot, container)
    return container
      and container.replica.container
      and container.replica.container:GetItemInSlot(slot)
end

local function MoveHandToSlotContainer(self, slot, container)
    local slotOccupied = self:IsSlotOccupiedContainer(slot, container)
    local code = slotOccupied and RPC.SwapActiveItemWithSlot
                 or RPC.PutAllOfActiveItemInSlot

    SendRPCToServer(code, slot, container)
end

function SortFunctions:GetOpenContainers()
    local inventory = InventoryFunctions:GetInventory()
    return inventory
       and inventory:GetOpenContainers()
        or {}
end

function SortFunctions:ForceItemIntoSlotContainer(item, slot, container)
    if container and container.replica.container then
        if self:MatchGUID(self:IsSlotOccupiedContainer(slot), item) then
            return true
        end

        if self:MatchGUID(InventoryFunctions:GetActiveItem(), item) then
            MoveHandToSlotContainer(self, slot, container)
            return true
        end
    end

    return false
end

return SortFunctions
