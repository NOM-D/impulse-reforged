---@type string The default name group
NAMEGROUP_DEFAULT = "default"

NET_GROUP_RANK = "NET_GROUP_RANK"
impulse.Networking:Define(NET_GROUP_RANK, {
    dataType = impulse.Networking.DataTypes.String,
    scope = impulse.Networking.Enums.Scope.Local
})

NET_GROUP_NAME = "NET_GROUP_NAME"
impulse.Networking:Define(NET_GROUP_NAME, {
    dataType = impulse.Networking.DataTypes.String,
    scope = impulse.Networking.Enums.Scope.Local
})

NET_RP_NAME = "NET_RP_NAME"
impulse.Networking:Define(NET_RP_NAME, {
    dataType = impulse.Networking.DataTypes.String,
    scope = impulse.Networking.Enums.Scope.Local
})
