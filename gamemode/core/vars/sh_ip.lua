DATA_LAST_IP = "DATA_LAST_IP"
impulse.Networking:Define(DATA_LAST_IP, {
    dataType = impulse.Networking.DataTypes.String,
    defaultValue = 0,
    scope = impulse.Networking.Enums.Scope.UnNetworkedLocal,
    storeKey = "lastIp"
})
