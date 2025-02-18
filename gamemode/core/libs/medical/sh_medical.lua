--- Player class methods
-- @classmod Player

--- @class Player
local PLAYER = FindMetaTable("Player")

--- Returns whether a player has broken legs
-- @realm shared
function PLAYER:HasBrokenLegs()
    return tobool(self:GetNetVar(NET_HAS_BROKEN_LEGS, false))
end
