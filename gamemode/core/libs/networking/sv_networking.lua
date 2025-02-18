local SCOPES = impulse.Networking.Enums.Scope
local netUtils = include("utils_networking.lua")

util.AddNetworkString("impulse.net.local")
util.AddNetworkString("impulse.net.global")
util.AddNetworkString("impulse.net.sync.local")
util.AddNetworkString("impulse.net.sync.global")
util.AddNetworkString("impulse.net.clear")


---Set a global networked variable
---@realm server
---@param varId number|string The key of the variable
---@param value any The value to set
---@param shouldNotNetwork? boolean Whether to NOT network the variable
function impulse.Networking:SetGlobal(varId, value, shouldNotNetwork)
    if (! varId) then
        impulse.Logs:Error("No key defined for global network variable! Value is %s", tostring(value))
        return
    end

    local varTable = netUtils.getVarTable(varId)
    if (! varTable) then -- undefined variable
        impulse.Logs:Error("No network variable found for key %s when trying to set global net var", varId)
        return
    end

    varTable:Set(nil, value)
    if (! shouldNotNetwork) then -- network it if we're the server
        local shouldNetwork = varTable.scope == SCOPES.Global
        if (! shouldNetwork) then return end

        net.Start("impulse.net.global")
        varTable:Write(value)
        net.Broadcast()
    end
end

---@class Player
local PLAYER = FindMetaTable("Player")

---Sync all networked vars for the player
function PLAYER:SyncNetVars()
    impulse.Logs:Debug("Syncing network variables for %s with ent index %s", self:Name(), self:EntIndex())
    -- clean up locals
    local globalVars = table.Copy(impulse.Networking.Globals)
    local localVars = table.Copy(impulse.Networking.Locals)
    for ent, vars in pairs(localVars) do
        for varId, _ in pairs(vars) do
            local varTable = netUtils.getVarTable(varId)
            if ((varTable.scope == SCOPES.Private && ent:EntIndex() != self:EntIndex()) && varTable.scope != SCOPES.Local) then
                localVars[ent][varId] = nil
            end
        end
    end

    -- clean up globals
    for varId, _ in pairs(globalVars) do
        local varTable = netUtils.getVarTable(varId)
        if (varTable.scope != SCOPES.Global) then
            globalVars[varId] = nil
        end
    end

    -- send globals
    net.Start("impulse.net.sync.global")
    local data = util.Compress(util.TableToJSON(globalVars))
    net.WriteUInt(#data, 16)
    net.WriteData(data)
    net.Send(self)

    -- sync locals
    local count = 0
    local maxEnts = impulse.Networking.SyncChunkSize
    impulse.Logs:Debug("Syncing net vars %s", table.ToString(localVars))

    -- Send the locals in chunks because we know they could get quite big
    while (! table.IsEmpty(localVars)) do
        net.Start("impulse.net.sync.local")
        for ent, entVars in pairs(localVars) do
            if count >= maxEnts then -- end of chunk
                break
            end

            if (! IsValid(ent)) then
                impulse.Logs:Warning("Invalid entity in local net var sync: %s", tostring(ent))
                localVars[ent] = nil
                continue
            end

            net.WriteUInt(ent:EntIndex(), 13)
            local data = util.Compress(util.TableToJSON(entVars))
            net.WriteUInt(#data, 16)
            net.WriteData(data)
            count = count + 1
            localVars[ent] = nil
        end

        net.Send(self)
    end
end

---Load the player's networked variables from a store table
---
---This is internally used to load the player's networked variables from their impulseData table
---
---NOTE: This doesn't do networking.
---@param dataTable table
function PLAYER:LoadNetVarsFromStore(dataTable)
    if (! istable(dataTable)) then
        impulse.Logs:Error("LoadNetvars expected table, got %s", type(dataTable))
        return
    end

    impulse.Logs:Debug("Loading networked variables for %s from data store! %s", self:Name(), table.ToString(dataTable))

    for _, varTable in ipairs(impulse.Networking.Registry) do
        if (varTable.scope != SCOPES.Local && varTable.scope != SCOPES.Private) then
            continue
        end

        if (varTable.storeKey || varTable.storeAccessor) then
            local value = (varTable.storeAccessor && varTable.storeAccessor(dataTable)) || dataTable[varTable.storeKey]
            varTable:Set(self, value)
        end
    end
end
