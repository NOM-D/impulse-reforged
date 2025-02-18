AddCSLuaFile("meta_networking.lua")
AddCSLuaFile("utils_networking.lua")
local NETVAR = include("meta_networking.lua")
local netUtils = include("utils_networking.lua")

--- @class Entity
local ENTITY = FindMetaTable("Entity")
local SCOPES = impulse.Networking.Enums.Scope


---Define a new networked variable
---@param varId string The unique id of the variable
---@param varTable impulse.Networking.Variable
---@return number? varId The index of the variable in the registry
function impulse.Networking:Define(varId, varTable)
    -- Ensure varTable is valid
    if ! varTable || ! istable(varTable) then
        impulse.Logs:Error("Invalid varTable passed to impulse.Networking:Define")
        return
    end

    -- Validate required fields
    if ! varTable.scope then
        impulse.Logs:Error("No scope defined for network variable %s", varId)
        return
    end

    if ! varTable.dataType then
        impulse.Logs:Error("No data type defined for network variable %s", varId)
        return
    end

    local index = self.RegistryMap[varId] || table.Count(self.RegistryMap) + 1
    varTable.id = varId
    varTable.index = index

    local varObj = NETVAR:New(varTable) --[[@as impulse.Networking.VariableObj]]
    if (! varObj.isWithinRealm) then
        varObj = false -- let's say it's there for the sake of indexing but in reality it's invisible
    end

    self.RegistryMap[varId] = index
    self.Registry[index] = varObj
    _G[varId] = index --[[@as number]] -- make it a globally accessible enum

    return index
end

---Get the networked variable for the entity
---@param varIndex number|string The varId of the variable
---@param fallbackValue any The value to return if the variable is not found
---@return any
function ENTITY:GetNetVar(varIndex, fallbackValue)
    varIndex = netUtils.getVarIndex(varIndex)

    if (! varIndex) then -- no key
        impulse.Logs:Error("No key defined for network variable!")
        return fallbackValue
    end

    local varTable = netUtils.getVarTable(varIndex)
    if (! varTable) then
        impulse.Logs:Error("No network variable found for key %s when trying to get net var for entity %s", varIndex,
            tostring(self))
        return fallbackValue
    end

    return varTable:Get(self, fallbackValue)
end

---Set the networked variable for the entity
---@param varId number|string The key of the variable
---@param value any
---@param shouldNotNetwork? boolean
function ENTITY:SetNetVar(varId, value, shouldNotNetwork)
    varId = netUtils.getVarIndex(varId)
    if (! varId) then -- no key
        impulse.Logs:Error("Couldn't set network variable, no key defined!")
        return
    end

    local varTable = netUtils.getVarTable(varId)
    if (! varTable) then
        impulse.Logs:Error("No network variable found for key %s when trying to set net var for entity %s", varId,
            tostring(self))
        return
    end

    varTable:Set(self, value)

    -- Network it if we're the server
    if (SERVER) then
        local varScope = varTable.scope
        local shouldNetwork = varScope == SCOPES.Local ||
                (varScope == SCOPES.Private && self:IsPlayer() && ! shouldNotNetwork)

        local isCorrectDataType = value != nil && varTable.dataType.validate && varTable.dataType.validate(value)
        if (! isCorrectDataType) then return end
        varTable:Save(self, value) -- Save the data if we have a saveData function or a storekey
        if (! shouldNetwork) then return end

        net.Start("impulse.net.local")
        varTable:Write(value, true)
        varTable:Network(self, value)
    end
end

---Clear the networked variables for the entity if they're networked
---@param shouldNotNetwork? boolean Whether to NOT network the clearing
function ENTITY:ClearNetVars(shouldNotNetwork)
    if (! impulse.Networking.Locals[self]) then
        return
    end
    impulse.Logs:Debug("Clearing networked variables for entity %s", tostring(ent))

    if (! IsValid(self)) then
        impulse.Logs:Error("Invalid entity when trying to clear networked variables")
        return
    end

    impulse.Networking.Locals[self] = nil
    if (SERVER && ! shouldNotNetwork) then
        net.Start("impulse.net.clear")
        net.WriteUInt(self:EntIndex(), 13)
        net.Broadcast()
    end
end

---Get a global networked variable
---@param varId number|string The key of the variable
---@param fallbackValue any The value to return if the variable is not found
---@return any The value of the variable
function impulse.Networking:GetGlobal(varId, fallbackValue)
    varId = netUtils.getVarIndex(varId)

    local varTable = netUtils.getVarTable(varId)
    if (! varTable) then
        impulse.Logs:Error("No network variable found for key %s when trying to get global net var", varId)
        return fallbackValue
    end

    local varScope = varTable.scope
    if (varScope != SCOPES.Global && varScope != SCOPES.UnNetworkedGlobal) then
        impulse.Logs:Error("Cannot get local network variable %s as global", varId)
        return fallbackValue
    end

    return varTable:Get(nil, fallbackValue)
end

---Clean up the networked variables for a removed entity
---@param ent Entity The entity that is being removed
---@param isFullUpdate boolean Whether this is being called due to a full update clientside
hook.Add("EntityRemoved", "impulse.net.clearlocal", function(ent, isFullUpdate)
    if (isFullUpdate) then return end
    if (! IsValid(ent)) then
        impulse.Logs:Error("Entity is not valid when trying to clear networked variables")
        return
    end

    ent:ClearNetVars(false) -- no need to network this, it's called on both server and client :D
end)
