local Say = require("util/say")

local ConfigFunctions = {}

function ConfigFunctions:DoToggle(str, bool)
    bool = not bool
    Say(
        string.format(
            str .. " (%s)",
            bool and MOD_EQUIPMENT_CONTROL.STRINGS.TOGGLE.ENABLED
            or MOD_EQUIPMENT_CONTROL.STRINGS.TOGGLE.DISABLED
        )
    )
    return bool
end

return ConfigFunctions
