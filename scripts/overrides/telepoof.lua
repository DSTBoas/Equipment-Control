local ConfigFunctions = require "util/configfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local TELEPOOF_ENABLED = GetModConfigData("TELEPOOF_ENABLED", MOD_EQUIPMENT_CONTROL.MODNAME)
local TELEPOOF_DOUBLECLICK = GetModConfigData("TELEPOOF_DOUBLECLICK", MOD_EQUIPMENT_CONTROL.MODNAME)
local TELEPOOF_CLICKS = 2

local OLD_BLINK_GENERIC = STRINGS.ACTIONS.BLINK.GENERIC

if TELEPOOF_DOUBLECLICK and type(TELEPOOF_DOUBLECLICK) ~= "number"  then
    TELEPOOF_DOUBLECLICK = .5
end

if not TELEPOOF_ENABLED then
    ACTIONS.BLINK.str.GENERIC = OLD_BLINK_GENERIC .. " (Disabled)"
end

local function SetBlinkText(delta)
    TELEPOOF_CLICKS = TELEPOOF_CLICKS + delta
    if TELEPOOF_ENABLED then
        ACTIONS.BLINK.str.GENERIC = string.format(
                                        OLD_BLINK_GENERIC .. " (%s)",
                                        TELEPOOF_CLICKS
                                    )
    end
end

if TELEPOOF_DOUBLECLICK then
    SetBlinkText(0)
end

local function ToggleBlink(blink)
    if blink then
        if TELEPOOF_DOUBLECLICK then
            SetBlinkText(0)
        else
            ACTIONS.BLINK.str.GENERIC = OLD_BLINK_GENERIC
        end
    else
        ACTIONS.BLINK.str.GENERIC = OLD_BLINK_GENERIC .. " (Disabled)"
    end
end

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end

    local OldOnRightClick = PlayerController.OnRightClick
    function PlayerController:OnRightClick(down)
        if not down or TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() or self.placer_recipe then
            return OldOnRightClick(self, down)
        end

        local act = self:GetRightMouseAction()
        if act and act.action == ACTIONS.BLINK
        and act.action.strfn(act) ~= "SOUL"
        then
            if not TELEPOOF_ENABLED then
                return
            end

            if TELEPOOF_DOUBLECLICK then
                if TELEPOOF_CLICKS > 0 then
                    SetBlinkText(-1)
                    if TELEPOOF_CLICKS == 0 then
                        OldOnRightClick(self, down)
                    end
                    self.inst:DoTaskInTime(TELEPOOF_DOUBLECLICK, function()
                        SetBlinkText(1)
                    end)
                else
                    OldOnRightClick(self, down)
                end
                return
            end
        end

        OldOnRightClick(self, down)
    end

    if not GetModConfigData("TELEPOOF_HOVER", MOD_EQUIPMENT_CONTROL.MODNAME) then
        function PlayerController:GetRightMouseAction()
            if not TELEPOOF_ENABLED
            and self.RMBaction
            and self.RMBaction.action == ACTIONS.BLINK
            and self.RMBaction.invobject
            and self.RMBaction.invobject.prefab == "orangestaff" then
                return
            end

            return self.RMBaction
        end
    end
end

KeybindService:AddKey("TOGGLE_TELEPOOF", function()
    TELEPOOF_ENABLED = ConfigFunctions:DoToggle("Telepoof", TELEPOOF_ENABLED)
    ToggleBlink(TELEPOOF_ENABLED)
end)

return Init
