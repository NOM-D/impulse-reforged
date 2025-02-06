--- Player class methods
-- @classmod Player

--- @class Player
local PLAYER = FindMetaTable("Player")

--- Breaks a player's legs
--- 
--- This will set the player's brokenLegs netVar to true
--- @realm server
function PLAYER:BreakLegs()
    self.BrokenLegsTime = CurTime() + impulse.Config.BrokenLegsHealTime -- reset heal time

    if ( self:HasBrokenLegs() ) then return end

    self:SetNetVar("brokenLegs", true)
    self.impulseBrokenLegs = true

    self:EmitSound("impulse-reforged/bone" .. math.random(1, 3) .. ".wav")
    self:Notify("You have broken your legs!", NOTIFY_ERROR)

    hook.Run("PlayerLegsBroken", self)
end

--- Fixes a player's legs
--- 
--- This will set the player's brokenLegs netVar to false
--- @realm server
function PLAYER:FixLegs()
    self:SetNetVar("brokenLegs", false)
    self.impulseBrokenLegs = false
    self.BrokenLegsTime = nil
end