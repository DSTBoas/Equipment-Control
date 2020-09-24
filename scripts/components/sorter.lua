local Inventory_Replica = require "components/inventory_replica"
local InventoryFunctions = require "util/inventoryfunctions"
local PriorityFunctions = require "util/priorityfunctions"
local SortFunctions = require "util/sortfunctions"
local Say = require("util/say")
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local Settings =
{
    "CONTAINER_SORT",
    "OVERRIDE_SLOT1_SORT",
}

local Sorter = Class(function(self, inst)
    self.inst = inst

    -- Thread
    self.sortingthread = nil

    -- Debug
    self.debug = false
    self.debug_level = 2
    self.debug_item_priority = false

    -- Memory
    self.blacklist = {}
    self.pickupaction = nil
    self.deployaction = nil

    -- Sorter
    self.sorting = false
    self.offsetslots = 0

    -- Network
    self.timeout = 15
    self.attemps = 5
end)

function Sorter:DebugPrint(level, str, ...)
    if self.debug then
        if level and level >= self.debug_level then
            print(string.format(string.rep("-", 14) .. "| " .. str, ...))
        elseif level == nil then
            print(string.format("[Sorter] " .. str, ...))
        end
    end
end

local function SetSettings()
    for i = 1, #Settings do
        Settings[Settings[i]] = GetModConfigData(Settings[i], MOD_EQUIPMENT_CONTROL.MODNAME)
        Settings[i] = nil
    end
end
SetSettings()

function Sorter:GetSetting(setting)
    return Settings[setting]
end

function Sorter:ChangeContainer()
    if Settings.CONTAINER_SORT ~= 1 then
        Settings.CONTAINER_SORT = Settings.CONTAINER_SORT - 1
    else
        Settings.CONTAINER_SORT = 3
    end
end

function Sorter:AwaitNetworkSlot(item, slot)
    local timeout = 0

    if SortFunctions:ForceItemIntoSlot(item, slot) then
        repeat
            if not SortFunctions:MatchGUID(InventoryFunctions:GetActiveItem(), item) then
                return true
            end
            Sleep(0)
            timeout = timeout + 1
        until timeout > self.timeout
    end

    return false
end

function Sorter:AwaitNetworkActiveItem(item)
    local timeout = 0

    if SortFunctions:ForceItemIntoActiveItem(item) then
        repeat
            if SortFunctions:MatchGUID(InventoryFunctions:GetActiveItem(), item) then
                return true
            end
            Sleep(0)
            timeout = timeout + 1
        until timeout > self.timeout
    end

    return false
end

local function AwaitNetworkActiveItemChange(self)
    local timeout = 0

    repeat
        if InventoryFunctions:GetActiveItem() == nil then
            return true
        end
        Sleep(0)
        timeout = timeout + 1
    until timeout > self.timeout

    return false
end

function Sorter:StackableToActiveItem(item)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        local activeItem = InventoryFunctions:GetActiveItem()
        if activeItem and activeItem.prefab == item.prefab and not SortFunctions:MatchGUID(item, activeItem) then
            if not InventoryFunctions:HasFreeSlot() then
                SendRPCToServer(RPC.ReturnActiveItem)
                if not AwaitNetworkActiveItemChange(self) then
                    return false
                end
            else
                local slot = SortFunctions:FindFreeInventorySlot(activeItem)
                if not self:AwaitNetworkSlot(activeItem, slot) then
                    return false
                end
            end
        end

        return self:AwaitNetworkActiveItem(item)
    end

    return false
end

function Sorter:AwaitNetworkStacking(item, slot)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        local container = slot > inventory:GetNumSlots() and SortFunctions:GetBackpackEnt() or nil
        local itemInSlot = SortFunctions:IsSlotOccupied(slot)
        if container then
            slot = slot % inventory:GetNumSlots()
        end
        local slotStackSize = SortFunctions:GetStackSize(itemInSlot)
        local handStackSize = SortFunctions:GetStackSize(InventoryFunctions:GetActiveItem())
        local stackDelta = SortFunctions:GetFreeStackSize(itemInSlot) - handStackSize

        SendRPCToServer(RPC.AddAllOfActiveItemToSlot, slot, container)
        local timeout = 0
        repeat
            if InventoryFunctions:GetActiveItem() == nil
            or stackDelta < 0 and slotStackSize ~= SortFunctions:GetStackSize(itemInSlot)
            then
                return true
            end
            Sleep(0)
            timeout = timeout + 1
        until timeout > self.timeout
    end

    return false
end

local function GetItemStacks(t, prefab)
    local itemStacks = {}

    for i = 1, #t do
        if t[i].item.prefab == prefab then
            itemStacks[#itemStacks + 1] = t[i].item
        end
    end

    return itemStacks
end

local function GetStackableSlot(item, slot)
    local totalSlots = SortFunctions:GetTotalInventorySlots()
    local itemInSlot

    for i = slot, totalSlots do
        itemInSlot = SortFunctions:IsSlotOccupied(i)
        if not itemInSlot or itemInSlot.prefab ~= item.prefab or SortFunctions:GetFreeStackSize(itemInSlot) > 0 then
            return i
        end
    end

    return nil
end

local function AddStack(self, item, slot)
    if not self:StackableToActiveItem(item) then
        return false
    end

    local totalSlots = SortFunctions:GetTotalInventorySlots()
    for i = slot, totalSlots do
        local itemInSlot = SortFunctions:IsSlotOccupied(i)
        if not itemInSlot or itemInSlot.prefab ~= item.prefab then
            return self:AwaitNetworkSlot(item, i)
        elseif SortFunctions:GetFreeStackSize(itemInSlot) > 0 then
            self:AwaitNetworkStacking(item, i)
            local activeItem = InventoryFunctions:GetActiveItem()
            if activeItem == nil then
                return true
            elseif activeItem.prefab ~= item.prefab then
                return false
            end
        end
    end

    return false
end

local function ShouldSortItem(item, slot)
    local totalSlots = SortFunctions:GetTotalInventorySlots()
    local itemInSlot

    for i = slot, totalSlots do
        itemInSlot = SortFunctions:IsSlotOccupied(i)
        if SortFunctions:MatchGUID(itemInSlot, item) then
            return false
        elseif not itemInSlot 
        or itemInSlot.prefab ~= item.prefab
        or SortFunctions:GetFreeStackSize(itemInSlot) > 0 then
            return true
        end
    end

    return false
end

function Sorter:DoStacking(t, item, slot)
    local itemStacks = GetItemStacks(t, item.prefab)
    local stackableSlot = slot

    for _, item in pairs(itemStacks) do
        if ShouldSortItem(item, slot) then
            stackableSlot = GetStackableSlot(item, stackableSlot)
            if not stackableSlot then
                return false
            end
            if not AddStack(self, item, stackableSlot) then
                return false
            end
        end
    end

    return true
end

function Sorter:MoveStackable(t, item, slot)
    return self:DoStacking(t, item, slot)
end

local function IsMovePossible(item)
    local inventory = InventoryFunctions:GetInventory()

    if inventory then
        local activeItem = InventoryFunctions:GetActiveItem()
        if SortFunctions:MatchGUID(item, activeItem) then
            return true
        end
        for _, invItem in pairs(SortFunctions:GetPlayerInventory()) do
            if SortFunctions:MatchGUID(item, invItem) then
                return true
            end
        end
    end

    return false
end

function Sorter:Move(item, slot)
    return self:AwaitNetworkActiveItem(item) and self:AwaitNetworkSlot(item, slot)
end

function Sorter:MoveToSlot(t, item, slot)
    local succes = false

    if SortFunctions:IsStackable(item) then
        self:DebugPrint(nil, "Stacking of %s started at slot [%s]", item.prefab, slot)
        for i = 1, self.attemps do
            if IsMovePossible(item) then
                if self:MoveStackable(t, item, slot) then
                    self.blacklist[item.prefab] = true
                    succes = true
                    break
                end
                self:DebugPrint(2, "%s unsuccesful attempt.",  i, item.prefab)
                Sleep(FRAMES)
            end
        end
    else
        self:DebugPrint(nil, "Regular move %s to slot [%s]", item.prefab, slot)
        if slot ~= SortFunctions:GetSlotFromItem(item) then
            for i = 1, self.attemps do
                if IsMovePossible(item) then
                    if self:Move(item, slot) then
                        succes = true
                        break
                    end
                    self:DebugPrint(2, "%s unsuccesful attempt.",  i, item.prefab)
                Sleep(FRAMES)
                end
            end
        else
            self:DebugPrint(1, "Skipping... %s.", item.prefab)
            succes = true
        end
    end

    return succes
end

local function DoPreStacking(t, item)
    local stackTab = {}
    local currentStack = 0
    local maxStack = SortFunctions:GetStackMaxSize(item)
    table.insert(stackTab, item)
    for _, prioObject in pairs(t) do
        if prioObject.item.prefab == item.prefab then
            local stackSize = SortFunctions:GetStackSize(prioObject.item)
            currentStack = currentStack + stackSize
            if currentStack > maxStack then
                currentStack = currentStack - maxStack
                table.insert(stackTab, prioObject.item)
            end
        end
    end
    return stackTab
end

local function DoPreSorting(t)
    local newInventory = {}
    local shadowBlacklist = {}

    for _, prioObject in pairs(t) do
        if not shadowBlacklist[prioObject.item.prefab] then
            if SortFunctions:IsStackable(prioObject.item) then
                shadowBlacklist[prioObject.item.prefab] = true
                for _, v in pairs(DoPreStacking(t, prioObject.item)) do
                    table.insert(newInventory, v)
                end
            else
                table.insert(newInventory, prioObject.item)
            end
        end
    end

    return newInventory
end

local function GetPrioritizedSorts(self, t)
    local totalInvSlots = SortFunctions:GetInventorySlots()
    local replacers = {}

    for i, v in pairs(t) do
        if i > totalInvSlots and PriorityFunctions:CanOnlyGoInPocket(v) then
            table.insert(replacers, v)
        end
    end

    if Settings.OVERRIDE_SLOT1_SORT then
        for _, v in pairs(t) do
            if Settings.OVERRIDE_SLOT1_SORT == v.prefab then
               table.insert(replacers, v) 
            end
        end
    end

    return replacers
end

local function IsNotReplacer(t, item)
    for i = 1, #t do
        if SortFunctions:MatchGUID(t[i], item) then
            return false
        end
    end
    return true
end

local function StripPrioritizedSorts(t, replacers)
    local correctedInv = {}

    for x = 1, #t do
        if IsNotReplacer(replacers, t[x]) then
            table.insert(correctedInv, t[x])
        end
    end

    return correctedInv
end

local function GetSortedInventory(self, t)
    local sortedInventory = DoPreSorting(t)
    local prioritizedSorts = GetPrioritizedSorts(self, sortedInventory)

    if #prioritizedSorts > 0 then
        sortedInventory = StripPrioritizedSorts(sortedInventory, prioritizedSorts)
        for i = 1, #prioritizedSorts do
            table.insert(sortedInventory, 1, prioritizedSorts[i])
        end
    end

    return sortedInventory
end

function Sorter:Sort(t)
    local sortedInventory = GetSortedInventory(self, t)

    for i = 1, #sortedInventory do
        if PriorityFunctions:CanOnlyGoInPocket(sortedInventory[i]) then
            self:MoveToSlot(t, sortedInventory[i], i)
        end
    end

    for i = 1, #sortedInventory do
        local item = sortedInventory[i]
        if not self.blacklist[item.prefab] then
            if not self:MoveToSlot(t, item, i + self.offsetslots) then
                self:DebugPrint(2, "Sorting has failed at slot [%s] sorting item %s.",  i, item.prefab)
                break
            end
        end
    end

    self:Stop()
end

function Sorter:Stop()
    if self.sortingthread then
        self.sortingthread:SetList(nil)
        self.sortingthread = nil
    end
    self.blacklist = {}
    self.offsetslots = 0
    local inventory = InventoryFunctions:GetInventory()
    if inventory then
        inventory.ReturnActiveItem = Inventory_Replica.ReturnActiveItem
    end
    if self.pickupaction then
        ACTIONS.PICKUP = self.pickupaction
        self.pickupaction = nil
    end
    if self.deployaction then
        ACTIONS.DEPLOY = self.deployaction
        self.deployaction = nil
    end
    self.sorting = false
    self:DebugPrint(nil, "Sorting stopped.")
end

local function DisableUserInput()
    local inventory = InventoryFunctions:GetInventory()
    if inventory then
        inventory.ReturnActiveItem = function() end
    end
end

local function DebugPrintPriorities(self, t)
    if self.debug_item_priority then
        for i = 1, #t do
            print("[Prio] " .. t[i].priority, t[i].item)
        end
    end
end

function Sorter:Start()
    if self.sorting then
        return
    end

    self.sorting = true
    self:DebugPrint(nil, "Sorting of inventory started.")
    DisableUserInput()
    self.pickupaction = ACTIONS.PICKUP
    self.deployaction = ACTIONS.DEPLOY
    ACTIONS.PICKUP = nil
    ACTIONS.DEPLOY = nil

    local priorityTable = {}

    if Settings.CONTAINER_SORT == 3 then
        priorityTable = PriorityFunctions:CreatePriorityTable(SortFunctions:GetPlayerInventory())
    elseif Settings.CONTAINER_SORT == 2 then
        priorityTable = PriorityFunctions:CreatePriorityTable(SortFunctions:GetPlayerInventory(true))
    elseif Settings.CONTAINER_SORT == 1 then
        priorityTable = PriorityFunctions:CreatePriorityTable(SortFunctions:GetBackpackItems())
        self.offsetslots = self.offsetslots + SortFunctions:GetInventorySlots()
    else
        priorityTable = PriorityFunctions:CreatePriorityTable(SortFunctions:GetPlayerInventory())
    end

    DebugPrintPriorities(self, priorityTable)

    self.sortingthread = self.inst:StartThread(function()
        self:Sort(priorityTable)
    end)
end

function Sorter:AwaitNetworkSlotContainer(item, slot, container)
    local timeout = 0

    if SortFunctions:ForceItemIntoSlotContainer(item, slot, container) then
        repeat
            if not SortFunctions:MatchGUID(InventoryFunctions:GetActiveItem(), item) then
                return true
            end
            Sleep(0)
            timeout = timeout + 1
        until timeout > self.timeout
    end

    return false
end

function Sorter:AwaitNetworkActiveItemContainer(item, container)
    local timeout = 0

    if SortFunctions:ForceItemIntoActiveItemContainer(item, container) then
        repeat
            if SortFunctions:MatchGUID(InventoryFunctions:GetActiveItem(), item) then
                return true
            end
            Sleep(0)
            timeout = timeout + 1
        until timeout > self.timeout
    end

    return false
end

function Sorter:MoveItemToSlotContainer(item, slot, container)
    return self:AwaitNetworkActiveItemContainer(item, container) and self:AwaitNetworkSlotContainer(item, slot, container)
end

local function IsMovePossibleContainer(item, container)
    if SortFunctions:MatchGUID(item, InventoryFunctions:GetActiveItem()) then
        return true
    end

    for _, containerItem in pairs(SortFunctions:GetItemsFromContainer(container)) do
        if SortFunctions:MatchGUID(item, containerItem) then
            return true
        end
    end

    return false
end

function Sorter:StackableToActiveItemContainer(item, container)
    local activeItem = InventoryFunctions:GetActiveItem()

    if activeItem and activeItem.prefab == item.prefab and not SortFunctions:MatchGUID(item, activeItem) then
        if SortFunctions:IsFullContainer(container) then
            SendRPCToServer(RPC.ReturnActiveItem)
            if not AwaitNetworkActiveItemChange(self) then
                return false
            end
        else
            local slot = SortFunctions:FindFreeContainerSlot(activeItem, container)
            if not self:AwaitNetworkSlotContainer(activeItem, slot, container) then
                return false
            end
        end
    end

    return self:AwaitNetworkActiveItemContainer(item, container)
end

function Sorter:AwaitNetworkStackingContainer(item, slot, container)
    local itemInSlot = SortFunctions:IsSlotOccupiedContainer(slot, container)
    local slotStackSize = SortFunctions:GetStackSize(itemInSlot)
    local handStackSize = SortFunctions:GetStackSize(InventoryFunctions:GetActiveItem())
    local stackDelta = SortFunctions:GetFreeStackSize(itemInSlot) - handStackSize

    SendRPCToServer(RPC.AddAllOfActiveItemToSlot, slot, container)
    local timeout = 0
    repeat
        if InventoryFunctions:GetActiveItem() == nil
        or stackDelta < 0 and slotStackSize ~= SortFunctions:GetStackSize(itemInSlot)
        then
            return true
        end
        Sleep(0)
        timeout = timeout + 1
    until timeout > self.timeout

    return false
end


local function AddStackContainer(self, item, slot, container)
    if not self:StackableToActiveItemContainer(item, container) then
        return false
    end

    local totalSlots = SortFunctions:GetSlotsFromContainer(container)
    for i = slot, totalSlots do
        local itemInSlot = SortFunctions:IsSlotOccupiedContainer(i, container)
        if not itemInSlot or itemInSlot.prefab ~= item.prefab then
            return self:AwaitNetworkSlotContainer(item, i, container)
        elseif SortFunctions:GetFreeStackSize(itemInSlot) > 0 then
            self:AwaitNetworkStackingContainer(item, i, container)
            local activeItem = InventoryFunctions:GetActiveItem()
            if activeItem == nil then
                return true
            elseif activeItem.prefab ~= item.prefab then
                return false
            end
        end
    end

    return false
end

local function ShouldSortItemContainer(item, slot, container)
    local totalSlots = SortFunctions:GetSlotsFromContainer(container)
    local itemInSlot

    for i = slot, totalSlots do
        itemInSlot = SortFunctions:IsSlotOccupiedContainer(i, container)
        if SortFunctions:MatchGUID(itemInSlot, item) then
            return false
        elseif not itemInSlot 
        or itemInSlot.prefab ~= item.prefab
        or SortFunctions:GetFreeStackSize(itemInSlot) > 0 then
            return true
        end
    end

    return false
end

local function GetStackableSlotContainer(item, slot, container)
    local totalSlots = SortFunctions:GetSlotsFromContainer(container)
    local itemInSlot

    for i = slot, totalSlots do
        itemInSlot = SortFunctions:IsSlotOccupiedContainer(i, container)
        if not itemInSlot or itemInSlot.prefab ~= item.prefab or SortFunctions:GetFreeStackSize(itemInSlot) > 0 then
            return i
        end
    end

    return nil
end

function Sorter:DoStackingContainer(t, item, slot, container)
    local itemStacks = GetItemStacks(t, item.prefab)
    local stackableSlot = slot

    for _, item in pairs(itemStacks) do
        if ShouldSortItemContainer(item, slot, container) then
            stackableSlot = GetStackableSlotContainer(item, stackableSlot, container)
            if not stackableSlot then
                return false
            end
            if not AddStackContainer(self, item, stackableSlot, container) then
                return false
            end
        end
    end

    return true
end

function Sorter:MoveStackableContainer(t, item, slot, container)
    return self:DoStackingContainer(t, item, slot, container)
end

function Sorter:MoveToSlotContainer(t, item, slot, container)
    local succes = false

    if SortFunctions:IsStackable(item) then
        self:DebugPrint(nil, "Stacking of %s started at slot [%s]", item.prefab, slot)
        for i = 1, self.attemps do
	        if IsMovePossibleContainer(item, container) then
	            if self:MoveStackableContainer(t, item, slot, container) then
	            	self.blacklist[item.prefab] = true
	                succes = true
	                break
	            end
	        end
	    end
    else
        self:DebugPrint(nil, "Regular move %s to slot [%s]", item.prefab, slot)
        if slot ~= SortFunctions:GetSlotFromItemContainer(item, container) then
        	for i = 1, self.attemps do
	            if IsMovePossibleContainer(item, container) then
	                if self:MoveItemToSlotContainer(item, slot, container) then
	                    succes = true
	                    break
	                end
	            end
	        end
        else
            self:DebugPrint(1, "Skipping... %s.", item.prefab)
            succes = true
        end
    end

    return succes
end

local function GetSortedContainer(self, t)
    return DoPreSorting(t)
end

function Sorter:SortChest(t, container)
    local sortedContainer = GetSortedContainer(self, t)

    for i = 1, #sortedContainer do
        local item = sortedContainer[i]
        if not self.blacklist[item.prefab] then
	        if not self:MoveToSlotContainer(t, item, i, container) then
	            self:DebugPrint(2, "Sorting of [%s] has failed.", container.prefab)
	            break
	        end
	    end
    end

    self:Stop()
end

function Sorter:StartChest()
    if self.sorting then
        return
    end

    local openContainers = SortFunctions:GetOpenContainers()
    if next(openContainers) == nil then
        self:DebugPrint(nil, "There are no open containers to sort.")
        Say("Please open a container to sort.")
        return
    end

    self.sorting = true
    self:DebugPrint(nil, "Sorting of containers started.")

    DisableUserInput()

    local overflowEnt = SortFunctions:GetBackpackEnt()

    for container in pairs(openContainers) do
        if container ~= overflowEnt then
            self:DebugPrint(nil, "Now sorting %s.", container.prefab)
            local priorityTable = PriorityFunctions:CreatePriorityTable(
                                    SortFunctions:GetItemsFromContainer(container)
                                  )
            DebugPrintPriorities(self, priorityTable)
            self.sortingthread = self.inst:StartThread(function()
                self:SortChest(priorityTable, container)
            end)
            break
        end
    end
end

local Containers =
{
    "backpack",
    "only inventory",
    "inventory",
}

KeybindService:AddKey("SORT_INVENTORY", function()
    local container = Containers[ThePlayer.components.sorter:GetSetting("CONTAINER_SORT")]
    Say("Sorting " .. container .. ".")
    ThePlayer.components.sorter:Start()
end)

KeybindService:AddKey("SORT_CHEST", function()
    Say("Sorting chest.")
    ThePlayer.components.sorter:StartChest()
end)

KeybindService:AddKey("TOGGLE_SORTING_CONTAINER", function()
    ThePlayer.components.sorter:ChangeContainer()
    Say(
        string.format(
            "Sorting container (%s)",
            Containers[ThePlayer.components.sorter:GetSetting("CONTAINER_SORT")]
        )
    )
end)

return Sorter
