local IsCancelControl = {}

for control = CONTROL_PRIMARY, CONTROL_MOVE_RIGHT do
    IsCancelControl[control] = true
end

local function ControlValidation(self, control, down)
    if not down or TheFrontEnd.forceProcessText then
        return false
    end

    if control == CONTROL_SECONDARY then
        return self:GetRightMouseAction()
    end

    if control == CONTROL_PRIMARY then
        return not TheInput:GetHUDEntityUnderMouse()
    end

    return IsCancelControl[control]
end

local function OnDeactivateWorld(self)
    for event in pairs(self.events) do
        self:DetachEvent(event)
    end
end

local EventTracker = Class(function(self, inst)
    local PlayerController = inst and inst.components.playercontroller

    if not PlayerController then
        return
    end

    self.inst = inst
    self.events = {}

    self.inst:ListenForEvent("deactivateworld", function() OnDeactivateWorld(self) end, TheWorld)

    local OldOnControl = PlayerController.OnControl
    local function NewOnControl(_self, control, down)
        if ControlValidation(_self, control, down) then
            print("Cancelling all events", control)
            for event in pairs(self.events) do
                self:DetachEvent(event)
            end
        end

        OldOnControl(_self, control, down)
    end
    PlayerController.OnControl = NewOnControl
end)

function EventTracker:AddEvent(event, modaction, callback, inst)
    if not inst then
        inst = self.inst
    end

    inst:ListenForEvent(event, callback)

    if not self.events[modaction] then
        self.events[modaction] = {}
    end

    self.events[modaction][#self.events[modaction] + 1] =
    {
        inst = inst,
        event = event,
        callback = callback,
    }
end

function EventTracker:DetachEvent(modaction)
    if self.events[modaction] then
        for _, eventData in pairs(self.events[modaction]) do
            if eventData.inst then
                eventData.inst:RemoveEventCallback(
                    eventData.event,
                    eventData.callback
                )
            end
        end
        self.events[modaction] = nil
    end
end

return EventTracker
