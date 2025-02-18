NET_USERGROUP = "NET_USERGROUP"
impulse.Networking:Define(NET_USERGROUP, {
    dataType = impulse.Networking.DataTypes.String,
    defaultValue = 0,
    scope = impulse.Networking.Enums.Scope.UnNetworkedLocal,
    storeKey = "group",
    ---@param dataTable impulse.DataModels.Player
    storeAccessor = function(dataTable)
        return tonumber(dataTable.group)
    end,
    ---@param group string
    saveData = function(ply, group)
        local queryGroup = mysql:Update("impulse_players")
        queryGroup:Update("group", group)
        queryGroup:Where("steamid", ply:SteamID64())
        queryGroup:Execute()
    end
})
