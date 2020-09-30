local Say = require("util/say")
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE
local SpecialFood = MOD_EQUIPMENT_CONTROL.SPECIALFOOD

local KeyToNames =
{
    TAB = "Tab",
    MINUS = "-",
    EQUALS = "=",
    SPACE = "Space",
    ENTER = "Enter",
    ESCAPE = "Esc",
    PAUSE = "Pause",
    PRINT = "Print Screen",
    CAPSLOCK = "Caps Lock",
    SCROLLOCK = "Scroll Lock",
    RSHIFT = "Right Shift",
    LSHIFT = "Left Shift",
    SHIFT = "Shift",
    RCTRL = "Right Ctrl",
    LCTRL = "Left Ctrl",
    CTRL = "Ctrl",
    RALT = "Right Alt",
    LALT = "Left Alt",
    ALT = "Alt",
    BACKSPACE = "Backspace",
    BACKSLASH = "\\",
    PERIOD = ".",
    SLASH = "/",
    SEMICOLON = ";",
    RIGHTBRACKET = "{",
    LEFTBRACKET = "}",
    TILDE = "~",
    UP = "Arrow up",
    DOWN = "Arrow down",
    RIGHT = "Arrow right",
    LEFT = "Arrow left",
    INSERT = "Insert",
    DELETE = "Delete",
    HOME = "Home",
    END = "End",
    PAGEUP ="Page up",
    PAGEDOWN = "Page down",
}

local function Init()
    local InventoryReplica = ThePlayer and ThePlayer.replica.inventory

    if not InventoryReplica then
        return
    end

    local EatOverrideKey = KeybindService:GetKeyFromConfig("CONFIRM_TO_EAT", MOD_EQUIPMENT_CONTROL.MODNAME)
    local EatOverrideKeyDisplay = GetModConfigData("CONFIRM_TO_EAT", MOD_EQUIPMENT_CONTROL.MODNAME)

    if EatOverrideKeyDisplay:sub(1, 4) == "KEY_" then
        EatOverrideKeyDisplay = EatOverrideKeyDisplay:sub(5)
    end

    EatOverrideKeyDisplay = KeyToNames[EatOverrideKeyDisplay] or EatOverrideKeyDisplay

    local OldUseItemFromInvTile = InventoryReplica.UseItemFromInvTile
    function InventoryReplica:UseItemFromInvTile(item)
        if item and SpecialFood[item.prefab] and not TheInput:IsKeyDown(EatOverrideKey) then
            Say(
                string.format(
                    "Hold %s to eat %s.",
                    EatOverrideKeyDisplay,
                    item.name
                )
            )
            return
        end

        OldUseItemFromInvTile(self, item)
    end
end

return Init
