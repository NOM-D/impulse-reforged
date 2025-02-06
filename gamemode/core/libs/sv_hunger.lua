--- Helper functions for the players hunger
-- @module impulse.Hunger

impulse.Hunger = impulse.Hunger or {}

--- Set the hunger amount of a player
-- @realm server
-- @player ply Player to set hunger
-- @int amount Amount of hunger (0-100)
function impulse.Hunger:SetHunger(ply, amount)
    ply:SetHunger(amount)
end

--- Feed's the player the amount of hunger
-- @realm server
-- @player ply Player to feed hunger
-- @int amount Amount of hunger (0-100)
function impulse.Hunger:FeedHunger(ply, amount)
    ply:FeedHunger(amount)
end

--- Player class methods
---@class Player
local PLAYER = FindMetaTable("Player")

--- Set the hunger amount of a player
-- @realm server
-- @int amount Amount of hunger (0-100)
-- @treturn int The new hunger amount
function PLAYER:SetHunger(amount)
    return self:SetLocalVar("hunger", math.Clamp(amount, 0, 100))
end

--- Gives the player the amount of hunger
-- @realm server
-- @int amount Amount of hunger (0-100)
-- @treturn int The new hunger amount
function PLAYER:FeedHunger(amount)
    return self:SetHunger(amount + self:GetLocalVar("hunger", 100))
end

--- Takes the amount of hunger from the player
-- @realm server
-- @int amount Amount of hunger (0-100)
-- @treturn int The new hunger amount
function PLAYER:TakeHunger(amount)
    return self:SetHunger(self:GetLocalVar("hunger", 100) - amount)
end