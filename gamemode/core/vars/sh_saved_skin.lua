NET_SAVED_SKIN = "NET_SAVED_SKIN"
impulse.Networking:Define(NET_SAVED_SKIN, {
    dataType = impulse.Networking.DataTypes.UInt8,
    scope = impulse.Networking.Enums.Scope.Private,
    storeKey = "skin",
    ---@param dataTable impulse.DataModels.Player
    storeAccessor = function(dataTable)
        return tonumber(dataTable.skin)
    end,
    ---@param newSkin number
    saveData = function(ply, newSkin)
        local query = mysql:Update("impulse_players")
        query:Update("skin", newSkin)
        query:Where("steamid", ply:SteamID64())
        query:Execute()
    end
})
