DATA_SAVED_RP_NAMES = "DATA_SAVED_RP_NAMES"
impulse.Networking:Define(DATA_SAVED_RP_NAMES, {
    dataType = impulse.Networking.DataTypes.Table,
    defaultValue = {},
    scope = impulse.Networking.Enums.Scope.UnNetworkedLocal,
    storeKey = "rp_names"
})
