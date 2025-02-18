---@class impulse.Networking The module in charge of networking in the framework

impulse.Networking = impulse.Networking || {
    ---The bit count for the amount of variables in a bulk message
    VarCountBits = 13,
    ---The amount of entities whose local variables to sync per net message
    SyncChunkSize = 10,
    ---The bit count for networked variables
    BitCount = 8,
    ---@type table<number, table<number, any>> networked variables for entities
    Locals = {},
    ---@type table<number, any> global key-value store
    Globals = {},
    ---@type impulse.Networking.VariableObj|boolean[] The registry of networked variables
    Registry = {},
    ---@type table<string, number>
    RegistryMap = {},
    DataTypes = {
        --- Unsigned 8-bit integer, min: 0, max: 255
        UInt8 = {
            read = function() return net.ReadUInt(8) end,
            write = function(value) net.WriteUInt(value, 8) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("UInt8 value %s is not a number", value)
                    return false
                elseif (value < 0 || value > 255) then
                    impulse.Logs:Error("UInt8 value %s is out of range", value)
                    return false
                end
                return true
            end
        },
        --- Unsigned 16-bit integer, min: 0, max: 65535
        UInt16 = {
            read = function() return net.ReadUInt(16) end,
            write = function(value) net.WriteUInt(value, 16) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("UInt16 value %s is not a number", value)
                    return false
                elseif (value < 0 || value > 65535) then
                    impulse.Logs:Error("UInt16 value %s is out of range", value)
                    return false
                end
                return true
            end
        },
        --- Unsigned 32-bit integer, min: 0, max: 4294967295
        UInt32 = {
            read = function() return net.ReadUInt(32) end,
            write = function(value) net.WriteUInt(value, 32) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("UInt32 value %s is not a number", value)
                    return false
                elseif (value < 0 || value > 4294967295) then
                    impulse.Logs:Error("UInt32 value %s is out of range", value)
                    return false
                end
                return true
            end
        },
        --- Unsigned 64-bit integer, min: 0, max: 18446744073709551615
        UInt64 = {
            read = function() return net.ReadUInt64() end,
            write = function(value) net.WriteUInt64(value) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("UInt64 value %s is not a number", value)
                    return false
                elseif (value < 0 || value > 18446744073709551615) then
                    impulse.Logs:Error("UInt64 value %s is out of range", value)
                    return false
                end
                return true
            end
        },
        --- Signed 8-bit integer, min: -128, max: 127
        Int8 = {
            read = function() return net.ReadInt(8) end,
            write = function(value) net.WriteInt(value, 8) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("Int8 value %s is not a number", value)
                    return false
                elseif (value < -128 || value > 127) then
                    impulse.Logs:Error("Int8 value %s is out of range", value)
                    return false
                end
            end
        },
        --- Signed 16-bit integer, min: -32768, max: 32767
        Int16 = {
            read = function() return net.ReadInt(16) end,
            write = function(value) net.WriteInt(value, 16) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("Int16 value %s is not a number", value)
                    return false
                elseif (value < -32768 || value > 32767) then
                    impulse.Logs:Error("Int16 value %s is out of range", value)
                    return false
                end
                return true
            end
        },
        --- Signed 32-bit integer, min: -2147483648, max: 2147483647
        Int32 = {
            read = function() return net.ReadInt(32) end,
            write = function(value) net.WriteInt(value, 32) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("Int32 value %s is not a number", value)
                    return false
                elseif (value < -2147483648 || value > 2147483647) then
                    impulse.Logs:Error("Int32 value %s is out of range", value)
                    return false
                end
                return true
            end
        },
        --- Signed 64-bit integer, min: -9223372036854775808, max: 9223372036854775807
        Int64 = {
            read = function() return net.ReadInt64() end,
            write = function(value) net.WriteInt64(value) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("Int64 value %s is not a number", value)
                    return false
                elseif (value < -9223372036854775808 || value > 9223372036854775807) then
                    impulse.Logs:Error("Int64 value %s is out of range", value)
                    return false
                end
                return true
            end
        },
        --- Floating point number
        Float = {
            read = function() return net.ReadFloat() end,
            write = function(value) net.WriteFloat(value) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("Float value %s is not a number", value)
                    return false
                end
                return true
            end
        },
        --- Double precision floating point number
        Double = {
            read = function() return net.ReadDouble() end,
            write = function(value) net.WriteDouble(value) end,
            validate = function(value)
                if (type(value) != "number") then
                    impulse.Logs:Error("Double value %s is not a number", value)
                    return false
                end
                return true
            end
        },
        String = {
            read = function() return net.ReadString() end,
            write = function(value) net.WriteString(value) end,
            validate = function(value)
                if (type(value) != "string") then
                    impulse.Logs:Error("String value %s is not a string", value)
                    return false
                end
                return true
            end
        },
        Table = {
            read = function() return net.ReadTable() end,
            write = function(value) net.WriteTable(value) end,
            validate = function(value)
                if (type(value) != "table") then
                    impulse.Logs:Error("Table value %s is not a table", value)
                    return false
                end
                return true
            end
        },
        Bool = {
            read = function() return net.ReadBool() end,
            write = function(value) net.WriteBool(value) end,
            validate = function(value)
                if (type(value) != "boolean") then
                    impulse.Logs:Error("Bool value %s is not a boolean", value)
                    return false
                end
                return true
            end
        },
        Entity = {
            read = function() return net.ReadEntity() end,
            write = function(value) net.WriteEntity(value) end,
            validate = function(value)
                if (! IsValid(value)) then
                    impulse.Logs:Error("Entity value %s is not valid", tostring(value))
                    return false
                end
                return true
            end
        },
        Vector = {
            read = function() return net.ReadVector() end,
            write = function(value) net.WriteVector(value) end,
            validate = function(value)
                if (type(value) != "Vector") then
                    impulse.Logs:Error("Vector value %s is not a Vector", value)
                    return false
                end
                return true
            end
        },
        Angle = {
            read = function() return net.ReadAngle() end,
            write = function(value) net.WriteAngle(value) end,
            validate = function(value)
                if (type(value) != "Angle") then
                    impulse.Logs:Error("Angle value %s is not an Angle", value)
                    return false
                end
                return true
            end
        },
        Color = {
            read = function() return net.ReadColor() end,
            write = function(value) net.WriteColor(value) end,
            validate = function(value)
                if (type(value) != "Color") then
                    impulse.Logs:Error("Color value %s is not a Color", value)
                    return false
                end
                return true
            end
        }
    },
    Enums = {
        Scope = {
            ---Local scope, all entities can see this variable but it is assigned to a specific entity
            Local = 1,
            ---Global scope, all entities can see this variable and it is not assigned to a specific entity
            Global = 2,
            ---Private scope, only the PLAYER can see this variable
            Private = 3,
            ---Unnetworked local scope, server can see this variable attached to an entity but it is not networked
            UnNetworkedLocal = 4,
            ---Unnetworked global scope, server can see this variable but it is not networked
            UnNetworkedGlobal = 5
        }
    }
}
