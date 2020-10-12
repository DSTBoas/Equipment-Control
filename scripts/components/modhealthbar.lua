local function CreateBG(self)
    local inst = CreateEntity("HealthBarBG")
    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddImage()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")

    inst.Image:SetTexture(resolvefilepath(self.bar_atlas), self.bar_image)
    inst.Image:SetTint(unpack(self.bg_colour))
    inst.Image:SetWorldOffset(self.bar_world_offset:Get())
    inst.Image:SetUIOffset(self.bar_ui_offset:Get())
    inst.Image:SetSize(self.bar_width, self.bar_height)
    inst.Image:Enable(false)
    inst.persists = false

    return inst
end

local function CreateBar(self)
    local inst = CreateEntity("healthBar")
    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddImage()
    inst.entity:AddLabel()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")

    inst.Image:SetTexture(resolvefilepath(self.bar_atlas), self.bar_image)
    inst.Image:SetTint(unpack(self.bar_colour))
    inst.Image:SetWorldOffset(self.bar_world_offset:Get())
    inst.Image:Enable(false)

    inst.Label:SetFontSize(16)
    inst.Label:SetFont(NUMBERFONT)
    inst.Label:SetColour(1, 1, 1)
    inst.Label:SetWorldOffset(self.bar_world_offset:Get())
    inst.Label:SetUIOffset(self.label_ui_offset:Get())
    inst.Label:Enable(false)

    inst.fill_width = self.bar_width - self.bar_border * 2
    inst.fill_height = self.bar_height - self.bar_border * 2

    inst.persists = false

    return inst
end

local function OnInit(inst, self)
    self.bg = CreateBG(self)
    self.bg.entity:SetParent(inst.entity)

    self.bar = CreateBar(self)
    self.bar.entity:SetParent(inst.entity)
end

local HealthBar = Class(function(self, inst)
    self.inst = inst

    self.maxhealth = 0
    ----------------------------------

    self.bar_atlas = "images/hud.xml"
    self.bar_image = "stat_bar.tex"

    self.bar_width = 100
    self.bar_height = 17
    self.bar_border = 1
    self.bar_colour = { .7, .1, 0, 1 }
    self.bg_colour = { .075, .07, .07, 1 }

    self.bar_world_offset = Vector3(0, 3, 0)
    self.bar_ui_offset = Vector3(0, 0, 0)
    self.label_ui_offset = Vector3(0, 0, 0)

    ----------------------------------

    self.enabled = true

    self._healthpct = 1
    OnInit(inst, self)
end)

function HealthBar:SetPosition(pos1)
    self.bar.Image:SetWorldOffset(pos1:Get())
    self.bar.Label:SetWorldOffset(pos1:Get())
    self.bg.Image:SetWorldOffset(pos1:Get())
end

local function SetVisible(self, visible)
    if self.bar ~= nil then
        self.bar.Label:Enable(visible)
        self.bar.Image:Enable(visible)
    end
    if self.bg ~= nil then
        self.bg.Image:Enable(visible)
    end
end

function HealthBar:SetMaxHealth(maxhealth)
    self.maxhealth = maxhealth
end

function HealthBar:GetMaxHealth()
    return self.maxhealth
end

function HealthBar:SetValue(percent, damage, maxHealth)
    if percent > 0 then
        local newwidth = self.bar.fill_width * percent
        self.bar.Label:SetText(math.floor(maxHealth - damage) .. " / " .. maxHealth)
        self.bar.Image:SetSize(newwidth, self.bar.fill_height)
        self.bar.Image:SetUIOffset(self.bar_ui_offset.x + (newwidth - self.bar.fill_width) * .5, self.bar_ui_offset.y, self.bar_ui_offset.z)
        SetVisible(self, self.enabled)
    else
        SetVisible(self, false)
    end
end

return HealthBar
