local net = net

local SCOPES = impulse.Networking.Enums.Scope

---@type impulse.Networking.VariableObj
local NETVAR = {} --[[@as any]]

---@param varTable impulse.Networking.Variable
---@return impulse.Networking.VariableObj
function NETVAR:New(varTable)
    local varObj = setmetatable(varTable, { __index = self }) --[[@as impulse.Networking.VariableObj]]
    varObj.index = varTable.index
    varObj.dataType = varTable.dataType
    varObj.scope = varTable.scope
    varObj.storeKey = varTable.storeKey
    varObj.isGlobal = varObj.scope == SCOPES.Global || varTable.scope == SCOPES.UnNetworkedGlobal
    varObj.isWithinRealm = (CLIENT &&                    -- client doesn't need to even know the var definitions for unnetworked vars
        varObj.scope != SCOPES.UnNetworkedGlobal &&
        varObj.scope != SCOPES.UnNetworkedLocal) || true -- server can see everything

    return varObj
end

---Get the value of the network variable for the given entity if applicable
function NETVAR:Get(ent, fallbackValue)
    if (self.isGlobal) then
        return impulse.Networking.Globals[self.index] || fallbackValue
    end

    if (! IsValid(ent)) then
        impulse.Logs:Error("Attempted to get a scoped network variable on an invalid entity!")
        return fallbackValue
    end

    local entLocals = impulse.Networking.Locals[ent]
    if (! entLocals) then
        return fallbackValue
    end

    return entLocals[self.index] || fallbackValue
end

function NETVAR:Set(ent, value)
    if (value != nil && self.dataType.validate && ! self.dataType.validate(value)) then
        return
    end

    if (self.isGlobal) then
        impulse.Networking.Globals[self.index] = value
    else
        if (! IsValid(ent)) then
            impulse.Logs:Error("Attempted to set a scoped network variable on an invalid entity!")
            return
        end

        local entLocals = impulse.Networking.Locals[ent]
        if (! entLocals) then
            entLocals = {}
            impulse.Networking.Locals[ent] = entLocals
        end
        entLocals[self.index] = value
    end

    if (self.onSet) then
        self.onSet(ent, value)
    end
end

function NETVAR:Network(ent)
    if (self.scope == SCOPES.Local || self.scope == SCOPES.Global) then
        if (self.scope == SCOPES.Local) then
            net.WriteUInt(ent:EntIndex(), 13) -- write entity index
        end
        return net.Broadcast()
    elseif (self.scope == SCOPES.Private) then
        return net.Send(ent)
    end
end

function NETVAR:Save(ent, value)
    if (! SERVER || ! ent || ! ent:IsPlayer()) then return end
    ent = ent --[[@as Player]]

    if (isfunction(self.saveData)) then
        local wasSuccess, saveDataResult = pcall(self.saveData, ent, value) -- the saving logic was defined in the callback
        if (! wasSuccess) then
            impulse.Logs:Error("Error saving data for network variable %s: %s", varId, saveDataResult)
            return
        end

        if (istable(saveDataResult)) then -- we got a structure of what to save relative to ply.impulseData
            for k, v in pairs(saveDataResult) do
                ent.impulseData[k] = v
            end
        end
    elseif isstring(self.storeKey) then
        ent.impulseData[self.storeKey] = value -- store it in the player's data table
    end
end

function NETVAR:Read()
    local value = nil

    if (net.ReadBool()) then
        value = self.dataType.read()
    end

    return value
end

function NETVAR:ReadTargetIndex()
    if (self.scope == SCOPES.Global) then -- global variables don't have a target
        impulse.Logs:Error("Attempted to read target index for a global network variable!")
        return
    end

    if (self.scope == SCOPES.Private) then -- private variables are always sent to a specific player, so it means the target is the LocalPlayer
        if (SERVER) then
            impulse.Logs:Error("Attempted to read target index for a private network variable!")
        end
        return
    end

    return net.ReadUInt(13)
end

function NETVAR:Write(value, noValidate)
    if (value != nil && ! noValidate && self.dataType.validate && ! self.dataType.validate(value)) then
        return
    end

    net.WriteUInt(self.index, impulse.Networking.BitCount) -- varIndex
    net.WriteBool(value != nil)                            -- value isValid

    if value != nil then
        self.dataType.write(value)
    end
end

return NETVAR
