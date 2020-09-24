require "util/keyhandlers"

local ModKeybindService = Class(function(self, modname)
    self.modname = modname
end)

function ModKeybindService:GetKeyFromConfig(conf)
    return rawget(_G, GetModConfigData(conf, self.modname))
end

function ModKeybindService:AddGlobalKey(conf, fn)
    conf = self:GetKeyFromConfig(conf)
    if conf then
        ModKeyHandlers[conf] = ModKeyHandlers[conf] or {}
        ModKeyHandlers[conf][#ModKeyHandlers[conf] + 1] = fn
    end
end

local function GetActiveScreenName()
    local activeScreen = TheFrontEnd:GetActiveScreen()
    return activeScreen and activeScreen.name or ""
end

function ModKeybindService:ValidateKeybind()
    return GetActiveScreenName() == "HUD"
end

function ModKeybindService:AddKey(conf, fn)
    self:AddGlobalKey(conf, function()
        if self:ValidateKeybind() then
            fn()
        end
    end)
end

return ModKeybindService
