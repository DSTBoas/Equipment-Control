local IsCancelControl = {}

for control = CONTROL_PRIMARY, CONTROL_MOVE_RIGHT do
    IsCancelControl[control] = true
end

local EventTracker = Class(function(self, inst)
    local PlayerController = inst and inst.components.playercontroller

    if not PlayerController then
        return
    end

    self.inst = inst
    self.events = {}

    local OldOnControl = PlayerController.OnControl

    local function NewOnControl(_self, control, down)
        if down and IsCancelControl[control] then
            for event in pairs(self.events) do
                self:DetachEvent(event)
            end
        end
        OldOnControl(_self, control, down)
    end

    PlayerController.OnControl = NewOnControl
end)

function EventTracker:AddEvent(event, modaction, callback)
    self.inst:ListenForEvent(event, callback)

    if not self.events[modaction] then
        self.events[modaction] = {}
    end

    self.events[modaction][#self.events[modaction] + 1] =
    {
        event = event,
        callback = callback,
    }
end

function EventTracker:DetachEvent(modaction)
    if self.events[modaction] then
        for _, eventData in pairs(self.events[modaction]) do
            self.inst:RemoveEventCallback(
                eventData.event,
                eventData.callback
            )
        end
        self.events[modaction] = nil
    end
end

return EventTracker
