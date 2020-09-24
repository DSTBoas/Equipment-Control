local Button = require("widgets/button")
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ItemButtonTile = require "widgets/itembuttontile"

local BUTTON_PREFERENCE_CHANGE = GetModConfigData("BUTTON_PREFERENCE_CHANGE", MOD_EQUIPMENT_CONTROL.MODNAME)
local BUTTON_AUTO_EQUIP_CHANGE = GetModConfigData("BUTTON_AUTO_EQUIP_CHANGE", MOD_EQUIPMENT_CONTROL.MODNAME)
local BUTTON_ANIMATIONS = GetModConfigData("BUTTON_ANIMATIONS", MOD_EQUIPMENT_CONTROL.MODNAME)

local function GetKey(category)
    local key = rawget(_G, GetModConfigData(category, MOD_EQUIPMENT_CONTROL.MODNAME))
    if key then
        if key > 47 and key < 58 then
            key = key - 48
        elseif key > 96 and key < 123 then
            key = string.char(key)
            key = key:upper()
        elseif key > 281 and key < 294 then
            key = "F" .. key - 281
        end

        return key
    end
end

local ItemButton = Class(Widget, function(self, bgim, owner, category)
    Widget._ctor(self, "ItemButton")
    self.owner = owner

    self.bgimage = self:AddChild(Image(HUD_ATLAS, bgim))
    self.category = category
    self.tile = nil
    self.item = nil

    self.highlight_scale = 1.2
    self.base_scale = 1

    self:SetTile(ItemButtonTile(self.category))

    if GetModConfigData("BUTTON_SHOW_KEYBIND", MOD_EQUIPMENT_CONTROL.MODNAME) then
        local key = GetKey(self.category)
        if key then
            self:SetKey(key)
        end
    end
end)

function ItemButton:SetDefaultPosition()
    self.default_position = self:GetPosition()
end

function ItemButton:GetCategory()
    return self.category
end

function ItemButton:Highlight()
    if BUTTON_ANIMATIONS and not self.big then
        self:ScaleTo(self.base_scale, self.highlight_scale, .125)
        self.big = true
    end
end

function ItemButton:DeHighlight()
    if BUTTON_ANIMATIONS and self.big then
        if not self.highlight then
            self:ScaleTo(self.highlight_scale, self.base_scale, .25)
        end
        self.big = false
    end
end

function ItemButton:OnGainFocus()
    self:Highlight()
end

function ItemButton:OnLoseFocus()
    self:DeHighlight()
    self:SetPosition(self.default_position)
end

function ItemButton:OnMouseButton(button, down)
    if not self.owner.components.actioncontroller then
        return 
    end

    if button == MOUSEBUTTON_LEFT then
        if down then
            if BUTTON_ANIMATIONS then
                self:SetPosition(self:GetPosition() + Vector3(0,-3,0))
            end
            if self.item then
                self.owner.components.actioncontroller:UseItem(self.item)
            end
        elseif BUTTON_ANIMATIONS then
            self:SetPosition(self.default_position)
        end
    elseif button == MOUSEBUTTON_RIGHT and down then
        if BUTTON_AUTO_EQUIP_CHANGE and TheInput:IsControlPressed(CONTROL_FORCE_TRADE) then
            self.owner.components.actioncontroller:SetAutoEquipCategory(self.category)
        elseif BUTTON_PREFERENCE_CHANGE and self.item then
            self.owner.components.actioncontroller:ChangePreferredItem(self.category, self.item)
        end
    end
end

function ItemButton:SetTile(tile)
    if self.tile ~= tile then
        if self.tile ~= nil then
            self.tile = self.tile:Kill()
        end
        if tile ~= nil then
            self.tile = self:AddChild(tile)
        end
    end
end

function ItemButton:SetKey(letter)
    self.key = self:AddChild(Button())
    self.key:SetPosition(5, 0, 0)
    self.key:SetFont("stint-ucr")
    self.key:SetTextColour(1, 1, 1, 1)
    self.key:SetTextFocusColour(1, 1, 1, 1)
    self.key:SetTextSize(50)
    self.key:SetText(letter)
end

function ItemButton:SetItem(item)
    if self.tile ~= nil then
        self.item = item
        self.tile:SetImage(item)
    end
end

return ItemButton
