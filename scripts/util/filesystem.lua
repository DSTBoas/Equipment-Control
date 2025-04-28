local FileSystem = {}
require "dumper"

local DEBUG_MODE = false

function FileSystem:SetDebugMode(enabled)
    DEBUG_MODE = enabled
end

local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end

local function serialiseTable(t) return 
    DataDumper(t, nil, true) 
end

local function _sandbox(chunk)
    local ok, result = RunInSandbox(chunk)
    if not ok then
        debugPrint("[FileSystem ERROR] RunInSandbox failed")
        return {}
    end
    return result
end

local function deserialiseTable(str)
    if str:match("^%s*{") then
        str = "return " .. str
    end
    local result = _sandbox(str)
    return type(result) == "table" and result or {}
end

local function tryUnsafeRead(path)
    local full = "unsafedata/" .. path
    local f = io.open(full, "r")
    if not f then
        debugPrint("[FileSystem DEBUG] tryUnsafeRead: cannot open", full)
        return nil
    end
    local raw = f:read("*a"); f:close()
    debugPrint("[FileSystem DEBUG] tryUnsafeRead: read", #raw, "bytes from", full)
    return deserialiseTable(raw)
end

local function tryUnsafeWrite(path, payload)
    local full = "unsafedata/" .. path
    local f = io.open(full, "w")
    if not f then
        debugPrint("[FileSystem ERROR] tryUnsafeWrite: cannot write", full)
        return
    end
    f:write(payload); f:close()
    debugPrint("[FileSystem DEBUG] tryUnsafeWrite: wrote", #payload, "bytes to", full)
end

local function loadFromPersistent(path, cb)
    debugPrint("[FileSystem DEBUG] loadFromPersistent: querying TheSim for", path)
    TheSim:GetPersistentString(path, function(success, data)
        if not success or not data then
            debugPrint("[FileSystem DEBUG] nothing in persistent, fallback to disk")
            cb(tryUnsafeRead(path) or {})
            return
        end
        local tbl = deserialiseTable(data)
        cb(tbl)
    end)
end

function FileSystem:LoadTableFromFile(path, callback)
    local f = io.open("unsafedata/" .. path, "r")
    if f then f:close() end
    local localExists = f ~= nil

    if callback then
        if localExists then
            callback(tryUnsafeRead(path) or {})
        else
            loadFromPersistent(path, callback)
        end
        return
    end

    if localExists then
        return tryUnsafeRead(path) or {}
    end

    local succ, data = TheSim:GetPersistentString(path)
    if succ and data then
        local tbl = deserialiseTable(data)
        return tbl
    end

    return {}
end

function FileSystem:SaveTableToFile(path, tbl, callback)
    local payload = serialiseTable(tbl)

    local legacy = io.open("unsafedata/" .. path, "r")
    if legacy then
        legacy:close()
        tryUnsafeWrite(path, payload)
    end

    TheSim:SetPersistentString(path, payload, false, function(success)
        if not success then
            debugPrint("[FileSystem ERROR] failed saving persistent string:", path)
        end
        if callback then callback(success) end
    end)
    return true
end

return FileSystem