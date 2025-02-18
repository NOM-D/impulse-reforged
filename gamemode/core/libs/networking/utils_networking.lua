local SCOPES = impulse.Networking.Enums.Scope

return {
    ---Helper function to get the real variable index if it's a string
    ---@param varId number|string
    ---@return number
    getVarIndex = function(varId)
        if (! varId) then
            impulse.Logs:Error("No key defined for network variable!")
        elseif (isstring(varId)) then
            varId = impulse.Networking.RegistryMap[varId]
        end

        return varId --[[@as number]]
    end,
    ---Helper function to get the var table from the registry
    ---@param varId number|string
    ---@return impulse.Networking.VariableObj|boolean|nil
    getVarTable = function(varId)
        return impulse.Networking.Registry[varId] ||
                impulse.Networking.Registry[impulse.Networking.RegistryMap[varId]] ||
                impulse.Logs:Error("No network variable found for key %s", varId)
    end
}
