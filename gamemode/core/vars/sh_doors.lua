NET_DOOR_NAME = "NET_DOOR_NAME"
impulse.Networking:Define(NET_DOOR_NAME, {
    dataType = impulse.Networking.DataTypes.String,
    defaultValue = "",
    scope = impulse.Networking.Enums.Scope.Local
})

NET_DOOR_GROUP = "NET_DOOR_GROUP"
impulse.Networking:Define(NET_DOOR_GROUP, {
    dataType = impulse.Networking.DataTypes.Int16,
    scope = impulse.Networking.Enums.Scope.Local
})

NET_IS_DOOR_BUYABLE = "NET_IS_DOOR_BUYABLE"
impulse.Networking:Define(NET_IS_DOOR_BUYABLE, {
    dataType = impulse.Networking.DataTypes.Bool,
    scope = impulse.Networking.Enums.Scope.Local
})

NET_DOOR_NAME = "NET_DOOR_NAME"
impulse.Networking:Define(NET_DOOR_NAME, {
    dataType = impulse.Networking.DataTypes.String,
    scope = impulse.Networking.Enums.Scope.Local
})

NET_DOOR_OWNERS = "NET_DOOR_OWNERS"
impulse.Networking:Define(NET_DOOR_OWNERS, {
    dataType = impulse.Networking.DataTypes.Table,
    scope = impulse.Networking.Enums.Scope.Local
})
