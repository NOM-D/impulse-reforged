NET_XP = "NET_XP"
impulse.Networking:Define(NET_XP, {
    dataType = impulse.Networking.DataTypes.UInt32,
    defaultValue = 0,
    scope = impulse.Networking.Enums.Scope.Private,
    storeKey = "xp",
    ---@param dataTable impulse.DataModels.Player
    storeAccessor = function(dataTable)
        return tonumber(dataTable.xp)
    end,
    saveData = function(ply, amount)
        local query = mysql:Update("impulse_players")
        query:Update("xp", amount)
        query:Where("steamid", ply:SteamID64())
        query:Execute()
    end,
})
