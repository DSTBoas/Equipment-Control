local InventoryFunctions = require "util/inventoryfunctions"

local EventManager = {}
local IsMasterSim = TheWorld and TheWorld.ismastersim

local function AddEvent(event, callback)
    ThePlayer:ListenForEvent(event, callback)
    EventManager[#EventManager + 1] =
    {
        event = event,
        callback = callback
    }
end

local function RemoveEvents()
    for i = 1, #EventManager do
        ThePlayer:RemoveEventCallback(
            EventManager[i].event,
            EventManager[i].callback
        )

        EventManager[i] = nil
    end
end

local function ValidateCandyBag(data)
    return data
       and data.item
       and data.item.prefab == "candybag"
end

local function ValidateHalloweenItem(data)
    local item = data and data.item

    if not item then
        return false
    end

    return item:HasTag("halloweencandy")
        or item:HasTag("halloween_ornament")
        or string.sub(item.prefab, 1, 8) == "trinket_"
end

local function ContainerCanTake()
    local container = InventoryFunctions:GetOverflowContainer()

    return container and not container:IsFull()
end

local function ValidateMove(item)
    for _, invItem in pairs(InventoryFunctions:GetInventoryItems()) do
        if invItem == item then
            return true
        end
    end

    return false
end

local function OnGetCandy(inst, data)
    if ValidateHalloweenItem(data) then
        inst:DoTaskInTime(IsMasterSim and 0 or FRAMES * 4, function()
            if ValidateMove(data.item) and ContainerCanTake() then
                InventoryFunctions:MoveItemFromAllOfSlot(
                    data.slot,
                    InventoryFunctions:GetEquippedItem(EQUIPSLOTS.BODY)
                )
            end
        end)
    end
end

local function OnCandyBagUnequip(inst, data)
    if data and data.eslot == EQUIPSLOTS.BODY then
        RemoveEvents()
    end
end

local function OnCandyBagEquip(candybag)
    RemoveEvents()
    AddEvent("gotnewitem", OnGetCandy)
    AddEvent("unequip", OnCandyBagUnequip)
end

local function Init()
    if not ThePlayer or not ThePlayer.player_classified then
        return
    end

    local item = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.BODY)
    if item and item.prefab == "candybag" then
        OnCandyBagEquip(item)
    end

    ThePlayer:ListenForEvent("equip", function(inst, data)
        if ValidateCandyBag(data) then
            OnCandyBagEquip(data)
        else
            OnCandyBagUnequip(inst, data)
        end
    end)

    ThePlayer.player_classified:ListenForEvent("isghostmodedirty", function()
        RemoveEvents()
    end)
end

return Init
