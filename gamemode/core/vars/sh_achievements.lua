NET_ACHIEVEMENTS = "NET_ACHIEVEMENTS"
impulse.Networking:Define(NET_ACHIEVEMENTS, {
    dataType = impulse.Networking.DataTypes.Table,
    defaultValue = {},
    scope = impulse.Networking.Enums.Scope.Private,
    storeKey = "achievements"
})

NET_ACHIEVEMENT_POINTS = "NET_ACHIEVEMENT_POINTS"
impulse.Networking:Define(NET_ACHIEVEMENT_POINTS, {
    dataType = impulse.Networking.DataTypes.UInt32,
    scope = impulse.Networking.Enums.Scope.Local
})
