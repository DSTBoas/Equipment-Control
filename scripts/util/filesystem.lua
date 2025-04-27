local FileSystem = {}

function FileSystem:LoadTableFromFile(path)
    local fileExists, file = pcall(io.open, path, "r")

    if not fileExists or not file then
        local success, newFile = pcall(io.open, path, "w")
        if success and newFile then
            newFile:close()
        else
            print("[FileSystem Error] Failed to create file:", path)
        end
        return {}
    end

    local t = {}
    for line in file:lines() do
        t[#t + 1] = line
    end

    file:close()

    return t
end

function FileSystem:SaveTableToFile(path, t)
    local success, file = pcall(io.open, path, "w")

    if not success or not file then
        print("[FileSystem Error] Could not open file for writing:", path)
        return false
    end

    local writeSuccess = pcall(function()
        file:write(table.concat(t, "\n"))
    end)

    if not writeSuccess then
        print("[FileSystem Error] Failed writing to file:", path)
        file:close()
        return false
    end

    file:close()
    return true
end

return FileSystem
