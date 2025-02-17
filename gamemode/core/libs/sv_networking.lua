--[[--
Networking library for sending and receiving networked variables.

This library is used to send and receive networked variables between the server and clients. It is used to synchronize data between the server and clients, such as player data, entity data, and global data. See `Player:SetLocalVar`, `Player:GetLocalVar`, `Entity:SetNetVar`, `Entity:GetNetVar`, `Entity:SendNetVar`, `Entity:ClearNetVars`, `SetNetVar`, and `GetNetVar` for more information.

@module impulse.Networking
]]

--- @class Entity
local entityMeta = FindMetaTable("Entity")

--- @class Player
local playerMeta = FindMetaTable("Player")

impulse.Networking = impulse.Networking or {}
impulse.Networking.List = impulse.Networking.List or {}
impulse.Networking.Locals = impulse.Networking.Locals or {}
impulse.Networking.Globals = impulse.Networking.Globals or {}

util.AddNetworkString("impulseGlobalVarSet")
util.AddNetworkString("impulseLocalVarSet")
util.AddNetworkString("impulseNetVarSet")
util.AddNetworkString("impulseNetVarDelete")

-- Check if there is an attempt to send a function. Can't send those.
local function CheckBadType(name, object)
    if (isfunction(object)) then
        ErrorNoHalt("Net var '" .. name .. "' contains a bad object type!")

        return true
    elseif (istable(object)) then
        for k, v in pairs(object) do
            -- Check both the key and the value for tables, and has recursion.
            if (CheckBadType(name, k) or CheckBadType(name, v)) then
                return true
            end
        end
    end
end

--- Retrieves a global networked variable. If it is not set, it'll return the default that you've specified.
-- @realm shared
-- @string key Identifier of the global variable
-- @param default Default value to return if the global variable is not set
-- @return Value associated with the key, or the default that was given if it doesn't exist
-- @usage print(GetNetVar("example", "Hello World!"))
-- > Hello World!
function GetNetVar(key, default) -- luacheck: globals GetNetVar
    local value = impulse.Networking.Globals[key]

    return value != nil and value or default
end

--- Sets the value of a global networked variable.
-- @realm server
-- @string key Identifier of the global variable
-- @param value New value to assign to the global variable
-- @tab[opt=nil] receiver The players to send the networked variable to
-- @usage SetNetVar("example", "Hello World!")
function SetNetVar(key, value, receiver) -- luacheck: globals SetNetVar
    if (CheckBadType(key, value)) then return end
    if (GetNetVar(key) == value and !istable(value)) then return end

    impulse.Networking.Globals[key] = value

    net.Start("impulseGlobalVarSet")
    net.WriteString(key)
    net.WriteType(value)

    if (receiver == nil) then
        net.Broadcast()
    else
        net.Send(receiver)
    end
end

--- Player networked variable functions
-- @classmod Player

--- Synchronizes networked variables to the client.
-- @realm server
-- @internal
function playerMeta:SyncVars()
    for k, v in pairs(impulse.Networking.Globals) do
        net.Start("impulseGlobalVarSet")
            net.WriteString(k)
            net.WriteType(v)
        net.Send(self)
    end

    for k, v in pairs(impulse.Networking.Locals[self] or {}) do
        net.Start("impulseLocalVarSet")
            net.WriteString(k)
            net.WriteType(v)
        net.Send(self)
    end

    for entity, data in pairs(impulse.Networking.List) do
        if (IsValid(entity)) then
            local index = entity:EntIndex()

            for k, v in pairs(data) do
                net.Start("impulseNetVarSet")
                    net.WriteUInt(index, 16)
                    net.WriteString(k)
                    net.WriteType(v)
                net.Send(self)
            end
        end
    end
end

--- Retrieves a local networked variable. If it is not set, it'll return the default that you've specified.
-- Locally networked variables can only be retrieved from the owning player when used from the client.
-- @realm shared
-- @string key Identifier of the local variable
-- @param default Default value to return if the local variable is not set
-- @return Value associated with the key, or the default that was given if it doesn't exist
-- @usage print(client:GetLocalVar("secret"))
-- > 12345678
-- @see SetLocalVar
function playerMeta:GetLocalVar(key, default)
    if (impulse.Networking.Locals[self] and impulse.Networking.Locals[self][key] != nil) then
        return impulse.Networking.Locals[self][key]
    end

    return default
end

--- Sets the value of a local networked variable.
-- @realm server
-- @string key Identifier of the local variable
-- @param value New value to assign to the local variable
-- @usage client:SetLocalVar("secret", 12345678)
-- @see GetLocalVar
function playerMeta:SetLocalVar(key, value)
    if (CheckBadType(key, value)) then return end

    impulse.Networking.Locals[self] = impulse.Networking.Locals[self] or {}
    impulse.Networking.Locals[self][key] = value

    net.Start("impulseLocalVarSet")
        net.WriteString(key)
        net.WriteType(value)
    net.Send(self)
end

--- Entity networked variable functions
-- @classmod Entity

--- Retrieves a networked variable. If it is not set, it'll return the default that you've specified.
-- @realm shared
-- @string key Identifier of the networked variable
-- @param default Default value to return if the networked variable is not set
-- @return Value associated with the key, or the default that was given if it doesn't exist
-- @usage print(client:GetNetVar("example"))
-- > Hello World!
-- @see SetNetVar
function entityMeta:GetNetVar(key, default)
    if (impulse.Networking.List[self] and impulse.Networking.List[self][key] != nil) then
        return impulse.Networking.List[self][key]
    end

    return default
end

--- Sets the value of a networked variable.
-- @realm server
-- @string key Identifier of the networked variable
-- @param value New value to assign to the networked variable
-- @tab[opt=nil] receiver The players to send the networked variable to
-- @usage client:SetNetVar("example", "Hello World!")
-- @see GetNetVar
function entityMeta:SetNetVar(key, value, receiver)
    if (CheckBadType(key, value)) then return end

    impulse.Networking.List[self] = impulse.Networking.List[self] or {}

    if (impulse.Networking.List[self][key] != value) then
        impulse.Networking.List[self][key] = value
    end

    self:SendNetVar(key, receiver)
end

--- Sends a networked variable.
-- @realm server
-- @internal
-- @string key Identifier of the networked variable
-- @tab[opt=nil] receiver The players to send the networked variable to
function entityMeta:SendNetVar(key, receiver)
    net.Start("impulseNetVarSet")
    net.WriteUInt(self:EntIndex(), 16)
    net.WriteString(key)
    net.WriteType(impulse.Networking.List[self] and impulse.Networking.List[self][key])

    if (receiver == nil) then
        net.Broadcast()
    else
        net.Send(receiver)
    end
end

--- Clears all of the networked variables.
-- @realm server
-- @internal
-- @tab[opt=nil] receiver The players to clear the networked variable for
function entityMeta:ClearNetVars(receiver)
    impulse.Networking.List[self] = nil
    impulse.Networking.Locals[self] = nil

    net.Start("impulseNetVarDelete")
    net.WriteUInt(self:EntIndex(), 16)

    if (receiver == nil) then
        net.Broadcast()
    else
        net.Send(receiver)
    end
end
