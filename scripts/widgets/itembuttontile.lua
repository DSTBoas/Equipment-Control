local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"

local ItemButtonTile = Class(Widget, function(self, category)
    Widget._ctor(self, "ItemButtonTile")

    local img = Categories[category].image or category:lower()

    self.imagedefault = img .. ".tex"

    if Categories[category].imagepath and softresolvefilepath("images/inventoryimages/".. Categories[category].imagepath.. ".xml") then
        self.imagebg = self:AddChild(Image("images/inventoryimages/" .. Categories[category].imagepath .. ".xml", self.imagedefault))
    else
        self.imagebg = self:AddChild(Image("images/inventoryimages.xml", self.imagedefault, "default.tex"))
    end

    self.imagebg:SetTint(0,0,0,0.7)
    self.imagebg:SetClickable(false)
    self:SetScale(.75)
end)

function ItemButtonTile:SetImage(item)
    if item then
        self.imagebg:SetTint(1,1,1,1)
        self.imagebg:SetTexture(item.replica.inventoryitem:GetAtlas(), item.replica.inventoryitem:GetImage())
    else
        self.imagebg:SetTint(0,0,0,0.7)
        self.imagebg:SetTexture("images/inventoryimages.xml", self.imagedefault)
    end

end

return ItemButtonTile
