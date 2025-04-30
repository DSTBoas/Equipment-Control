local Namemap = {}

local NAME_TO_ID = {}
local ID_TO_NAME = {}

local function BuildMaps()
    local u = string.upper
    local Recipes = rawget(_G, "AllRecipes") or {}

    for id, _ in pairs(Recipes) do
        local key_id = u(id)
        local key_blueprint = key_id .. "_BLUEPRINT"

        local disp = STRINGS.NAMES[key_blueprint]

        if not disp then
            local itemname = STRINGS.NAMES[key_id] or id
            disp = itemname .. " Blueprint"
        end

        NAME_TO_ID[disp] = id
        ID_TO_NAME[id] = disp
    end
end

BuildMaps()

function Namemap.DisplayToId(display)
    return NAME_TO_ID[display]
end

function Namemap.IdToDisplay(id)
    return ID_TO_NAME[id]
end

function Namemap.DebugDump(limit)
    limit = limit or 20
    print("[Namemap] showing first " .. limit .. " entries:")
    local c = 0
    for name, rid in pairs(NAME_TO_ID) do
        print(("  %-35s  ->  %s"):format(name, rid))
        c = c + 1
        if c >= limit then
            break
        end
    end
end

return Namemap