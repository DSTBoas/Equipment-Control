local InventoryFunctions = require "util/inventoryfunctions"

local function PlayerCanPerformAction()
    return not InventoryFunctions:IsBusyClassified()
       and ThePlayer
       and not ThePlayer:HasTag("busy")
       and not (ThePlayer.sg ~= nil and ThePlayer.sg:HasStateTag("busy"))
       and ThePlayer.components.playeractionpicker ~= nil
       and ThePlayer.components.playercontroller ~= nil
end

local TransformationUnEquips = {}

local function Equip(inst)
    if inst.weremode:value() == 0 then
        inst:DoTaskInTime(FRAMES * 23, function()
            for _, invItem in pairs(InventoryFunctions:GetPlayerInventory()) do
                for _, transformItem in pairs(TransformationUnEquips) do
                    if invItem == transformItem then
                        SendRPCToServer(RPC.UseItemFromInvTile, ACTIONS.EQUIP.code, transformItem)
                        break
                    end
                end
            end

            TransformationUnEquips = {}
        end)
    end
end

local function UnEquip()
    if PlayerCanPerformAction() then
        local equips = {}

        for _, item in pairs(InventoryFunctions:GetEquips()) do
            equips[#equips + 1] = item
        end

        for i = #equips, 1, -1 do
            if InventoryFunctions:HasFreeSlot() then
                SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.UNEQUIP.code, equips[i])
                TransformationUnEquips[#TransformationUnEquips + 1] = equips[i]
            end
        end
    end
end

local function IsFullMoon(cycle)
    return (cycle - 11) % 20 == 0
end

local function Init()
    if not ThePlayer or not ThePlayer:HasTag("werehuman") or not TheWorld:HasTag("forest") then
        return
    end

    local InventoryReplica = ThePlayer.replica.inventory

    if not InventoryReplica then
        return
    end

    local OldUseItemFromInvTile = InventoryReplica.UseItemFromInvTile
    InventoryReplica.UseItemFromInvTile = function(self, item)
        if item and item:HasTag("wereitem") then
            UnEquip()
        end

        OldUseItemFromInvTile(self, item)
    end

    TheWorld:ListenForEvent("phasechanged", function(inst, phase)
        if IsFullMoon(inst.state.cycles + 1) and phase == "dusk" then
            local timeUntilPhase = inst.net.components.clock:GetTimeUntilPhase("night")
            ThePlayer:DoTaskInTime(timeUntilPhase - FRAMES, function()
                if IsFullMoon(inst.state.cycles + 1) then
                    UnEquip()
                end
            end)
        end
    end)

    ThePlayer:ListenForEvent("weremodedirty", function(inst)
        Equip(inst)
    end)

    print("WoodieRegear init")
end

return Init
