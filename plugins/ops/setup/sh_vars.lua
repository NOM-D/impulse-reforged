NET_SHOULD_HIDE_OBSERVER = "NET_SHOULD_HIDE_OBSERVER"
impulse.Networking:Define(NET_SHOULD_HIDE_OBSERVER, {
    dataType = impulse.Networking.DataTypes.Bool,
    defaultValue = true,
    scope = impulse.Networking.Enums.Scope.Local
})

DATA_COMBINE_BAN_END_TIME = "DATA_COMBINE_BAN_END_TIME"
impulse.Networking:Define(DATA_COMBINE_BAN_END_TIME, {
    dataType = impulse.Networking.DataTypes.UInt64,
    scope = impulse.Networking.Enums.Scope.UnNetworkedLocal,
    storeKey = "combine_ban_end"
})
