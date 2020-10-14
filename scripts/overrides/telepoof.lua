local ConfigFunctions = require "util/configfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local TELEPOOF_DISABLED = GetModConfigData("TELEPOOF_DISABLED", MOD_EQUIPMENT_CONTROL.MODNAME)
local TELEPOOF_DOUBLECLICK = GetModConfigData("TELEPOOF_DOUBLECLICK", MOD_EQUIPMENT_CONTROL.MODNAME)
local TELEPOOF_CLICKS = 2

if TELEPOOF_DOUBLECLICK and type(TELEPOOF_DOUBLECLICK) ~= "number" then
    TELEPOOF_DOUBLECLICK = .5
end

local OldBlinkGeneric = STRINGS.ACTIONS.BLINK.GENERIC

local function SetBlinkText(delta)
    TELEPOOF_CLICKS = TELEPOOF_CLICKS + delta
    if not TELEPOOF_DISABLED then
        ACTIONS.BLINK.str.GENERIC = string.format(
                                        OldBlinkGeneric .. " (%s)",
                                        TELEPOOF_CLICKS
                                    )
    end
end

local function ToggleBlink(bool)
    if not bool then
        if TELEPOOF_DOUBLECLICK then
            SetBlinkText(0)
        else
            ACTIONS.BLINK.str.GENERIC = OldBlinkGeneric
        end
    else
        ACTIONS.BLINK.str.GENERIC = OldBlinkGeneric .. " (Disabled)"
    end
end

local function ValidateAction(self)
    local act = self:GetRightMouseAction()
    return act
       and act.action == ACTIONS.BLINK
       and act.action.strfn(act) ~= "SOUL"
end

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end
    
    ToggleBlink(TELEPOOF_DISABLED)

    local OldOnRightClick = PlayerController.OnRightClick
    function PlayerController:OnRightClick(down)
        if down and ValidateAction(self) then
            if TELEPOOF_DISABLED then
                return
            end

            if TELEPOOF_DOUBLECLICK then
                if TELEPOOF_CLICKS > 0 then
                    SetBlinkText(-1)
                    self.inst:DoTaskInTime(TELEPOOF_DOUBLECLICK, function()
                        SetBlinkText(1)
                    end)
                end

                if TELEPOOF_CLICKS > 0 then
                    return
                end
            end
        end

        OldOnRightClick(self, down)
    end

    if GetModConfigData("TELEPOOF_HOVER", MOD_EQUIPMENT_CONTROL.MODNAME) then
        function PlayerController:GetRightMouseAction()
            if TELEPOOF_DISABLED
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
    TELEPOOF_DISABLED = not ConfigFunctions:DoToggle("Telepoof", not TELEPOOF_DISABLED)
    ToggleBlink(TELEPOOF_DISABLED)
end)

return Init
