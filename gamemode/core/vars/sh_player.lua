NET_IS_WEAPON_RAISED = "NET_IS_WEAPON_RAISED"
impulse.Networking:Define(NET_IS_WEAPON_RAISED, {
    dataType = impulse.Networking.DataTypes.Bool,
    scope = impulse.Networking.Enums.Scope.Local
})

NET_IS_INCOGNITO = "NET_IS_INCOGNITO"
impulse.Networking:Define(NET_IS_INCOGNITO, {
    dataType = impulse.Networking.DataTypes.Bool,
    defaultValue = false,
    scope = impulse.Networking.Enums.Scope.Local
})

NET_MONEY = "NET_MONEY"
impulse.Networking:Define(NET_MONEY, {
    dataType = impulse.Networking.DataTypes.Int32,
    defaultValue = 0,
    scope = impulse.Networking.Enums.Scope.Private,
    storeKey = "money",
    storeAccessor = function(dataTable)
        return tonumber(dataTable.money)
    end,
    saveData = function(ply, amount)
        local query = mysql:Update("impulse_players")
        query:Update("money", amount)
        query:Where("steamid", ply:SteamID64())
        query:Execute()
    end
})

NET_BANK_MONEY = "NET_BANK_MONEY"
impulse.Networking:Define(NET_BANK_MONEY, {
    dataType = impulse.Networking.DataTypes.Int32,
    defaultValue = 0,
    scope = impulse.Networking.Enums.Scope.Private,
    storeKey = "bankmoney",
    storeAccessor = function(dataTable)
        return tonumber(dataTable.bankmoney)
    end,
    saveData = function(ply, amount)
        local query = mysql:Update("impulse_players")
        query:Update("bankmoney", amount)
        query:Where("steamid", ply:SteamID64())
        query:Execute()
    end
})

NET_PLAYER_PROP_COUNT = "NET_PLAYER_PROP_COUNT"
impulse.Networking:Define(NET_PLAYER_PROP_COUNT, {
    dataType = impulse.Networking.DataTypes.Int32,
    scope = impulse.Networking.Enums.Scope.Local
})

NET_HUNGER = "NET_HUNGER"
impulse.Networking:Define(NET_HUNGER, {
    dataType = impulse.Networking.DataTypes.UInt16,
    scope = impulse.Networking.Enums.Scope.Local
})
