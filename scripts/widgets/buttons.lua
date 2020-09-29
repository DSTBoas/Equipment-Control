local Widget = require "widgets/widget"
local ItemButton = require "widgets/itembutton"

local function IsPlatformHopping(inst)
    return inst
       and inst.sg ~= nil
       and inst.sg:HasStateTag("jumping")
        or inst.AnimState
       and (inst.AnimState:IsCurrentAnimation("boat_jump_pre")
        or inst.AnimState:IsCurrentAnimation("boat_jump_loop"))
end

local Buttons = Class(Widget, function(self, owner, inventorybar)
    Widget._ctor(self, "Buttons")

    self.owner = owner

    self.buttons = {}

    if TheWorld.ismastersim then
        self.inst:ListenForEvent("newactiveitem", function() self:Refresh() end, self.owner)
        self.inst:ListenForEvent("itemget", function() self:Refresh() end, self.owner)
        self.inst:ListenForEvent("itemlose", function() self:Refresh() end, self.owner)
    else
        self.inst:ListenForEvent("refreshinventory", function() self:Refresh() end, self.owner)
    end

    self.inst:ListenForEvent("playeractivated", function()
        self.inst:DoTaskInTime(0, function() self:Refresh() end)
    end, self.owner)

    self.inst:ListenForEvent("got_on_platform", function() self:Refresh() end, self.owner)

    self.inst:ListenForEvent("got_off_platform", function()
        self.inst:StartThread(function()
            while IsPlatformHopping(self.owner) do
                Sleep(0)
            end
            if self.owner and self.owner:IsValid() then
                self:Refresh()
            end
        end)
    end, self.owner)

    self.inst:ListenForEvent("wetdirty", function() self:Refresh() end, TheWorld.net)

    self.rebuild = inventorybar.Rebuild
    inventorybar.Rebuild = function(_self)
        self:UpdatePositions(_self)
    end

    self:Build()
end)

function Buttons:Build()
    for i = 1, 15 do
        local btnCategory = GetModConfigData("BUTTON_" .. i .. "_CATEGORY", MOD_EQUIPMENT_CONTROL.MODNAME)
        if btnCategory then
            self.buttons[i] = self:AddChild(ItemButton("inv_slot_spoiled.tex", self.owner, btnCategory))
        end
    end
end

function Buttons:Refresh()
    if self.owner.components.actioncontroller then
        for _, button in pairs(self.buttons) do
            local bestItem = self.owner.components.actioncontroller:GetItemFromCategory(button:GetCategory())
            button:SetItem(bestItem)
        end
    end
end

function Buttons:UpdatePositions(inventorybar)
    self.rebuild(inventorybar)
    for i, slot in pairs(inventorybar.inv) do
        if self.buttons[i] then
            local _, sizeY = slot.bgimage:GetSize()
            local slotX = slot:GetPosition().x
            local toprowY = inventorybar.toprow:GetPosition().y
            self.buttons[i]:SetPosition(slotX, toprowY + (sizeY * 1.5))
            self.buttons[i]:SetDefaultPosition()
        end
    end
end

return Buttons
