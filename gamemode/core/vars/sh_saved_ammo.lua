NET_SAVED_AMMO = "NET_SAVED_AMMO"
impulse.Networking:Define(NET_SAVED_AMMO, {
    dataType = impulse.Networking.DataTypes.Table,
    defaultValue = 0,
    scope = impulse.Networking.Enums.Scope.Private,
    storeKey = "ammo",
    ---@param dataTable impulse.DataModels.Player
    storeAccessor = function(dataTable)
        return tonumber(dataTable.ammo)
    end,
    ---@param ammoTable number[]
    saveData = function(ply, ammoTable)
        local query = mysql:Update("impulse_players")
        query:Update("ammo", util.TableToJSON(ammoTable))
        query:Where("steamid", ply:SteamID64())
        query:Execute()
    end
})
