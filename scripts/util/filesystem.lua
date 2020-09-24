local FileSystem = {}

function FileSystem:LoadFile(path)
    local file = io.open(path, "r")

    if not file then
        local newFile = io.open(path, "w")
        newFile:close()
        return {}
    end

    local t = {}
    local newLine = file:read("*line")

    while newLine do
        t[#t + 1] = newLine
        newLine = file:read("*line")
    end

    file:close()

    return t
end

function FileSystem:SaveFile(path, t)
    local file = io.open(path, "w")
    file:write(table.concat(t, "\n"))
    file:close()
end

return FileSystem
