---@type function[]? Callbacks for when our player is ready
local readyCallbacks = {}
local isReady = IsValid(LocalPlayer())

local function runWhenReady(callback)
    if (isReady) then
        callback()
        return
    end

    if (readyCallbacks == nil) then
        impulse.Logs:Error("Attempted to add a ready callback after the player was ready!")
        return
    end

    -- else just add it to the queue
    table.insert(readyCallbacks, callback)
end

net.Receive("impulse.net.local", function(len, ply)
    local varId = net.ReadUInt(impulse.Networking.BitCount)
    if (! varId) then -- no key defined
        impulse.Logs:Error("No key defined for local network variable!")
        return
    end
    local varTable = impulse.Networking.Registry[varId] -- get the variable table
    local value = varTable:Read()
    local entIndex = varTable:ReadTargetIndex()

    runWhenReady(function()
        local entity
        if entIndex then
            entity = Entity(entIndex) --[[@as Entity]]
            if (! IsValid(entity)) then -- This entity isn't known to us
                return
            end
        else
            entity = LocalPlayer()
        end

        entity:SetNetVar(varId, value)
    end)
end)

-- Callback for when we want to set a global networked variable.
net.Receive("impulse.net.global", function()
    local varId = net.ReadUInt(impulse.Networking.BitCount)
    if (! varId) then -- no key defined
        impulse.Logs:Error("No key defined for global network variable!")
        return
    end

    local varTable = impulse.Networking.Registry[varId] -- get the variable table
    if (! varTable) then
        impulse.Logs:Error("Invalid var id in global net var set: %s", tostring(varId))
        return
    end

    local value = varTable:Read()
    runWhenReady(function()
        varTable:Set(nil, value)
    end)
end)

-- Callback for when we want to sync all local networked variables for an entity.
net.Receive("impulse.net.sync.local", function()
    local entIndex = net.ReadUInt(13)
    local dataLen = net.ReadUInt(16) -- read the length of the compressed binary data
    local encodedData = net.ReadData(dataLen)
    local decodedData = util.Decompress(encodedData)
    local entVars = util.JSONToTable(decodedData)

    runWhenReady(function()
        impulse.Logs:Debug("Syncing local net vars")
        local ent = Entity(entIndex)
        if not IsValid(ent) then
            impulse.Logs:Error("Invalid entity in local net var sync: %s", tostring(ent))
            return
        end

        if not entVars then
            impulse.Logs:Error("Failed to decompress local net var data for entity %s", tostring(ent))
            return
        end

        ent = ent --[[ @as Entity]]
        impulse.Networking.Locals[ent] = entVars
    end)
end)

-- Callback for when we want to sync all global networked variables.
net.Receive("impulse.net.sync.global", function(len)
    local dataLen = net.ReadUInt(16) -- read the length of the compressed binary data
    local encodedData = net.ReadData(dataLen)
    local decodedData = util.Decompress(encodedData)
    local globalVars = util.JSONToTable(decodedData)

    impulse.Logs:Debug("Syncing global net vars")
    if not globalVars then
        impulse.Logs:Error("Failed to decompress global net var data")
        return
    end

    impulse.Networking.Globals = globalVars
end)

-- Callback for when we want to clear a local networked variable for an entity.
net.Receive("impulse.net.clear", function()
    impulse.Logs:Debug("Clearing local net vars")
    local entIndex = net.ReadUInt(13)
    local ent = Entity(entIndex)
    if (IsValid(ent)) then
        impulse.Logs:Error("Invalid entity in local net var clear: %s", tostring(ent))
        return
    end

    ent:ClearNetVars(false)
end)

hook.Add("InitPostEntity", "impulse.Networking.Sync", function()
    isReady = true
    for _, callback in ipairs(readyCallbacks) do
        callback()
    end
    readyCallbacks = nil -- we won't be needing this anymore
end)
