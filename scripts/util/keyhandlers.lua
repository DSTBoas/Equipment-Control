ModKeyHandlers = {}

local KeyDebounce = {}
local function DoKey(key, down)
    if ModKeyHandlers[key] then
        if down and not KeyDebounce[key] then
            for i = 1, #ModKeyHandlers[key] do
                ModKeyHandlers[key][i]()
            end
        end
        KeyDebounce[key] = down
    end
end

local OldOnRawKey = FrontEnd.OnRawKey
function FrontEnd:OnRawKey(key, down)
    DoKey(key, down)
    OldOnRawKey(self, key, down)
end
