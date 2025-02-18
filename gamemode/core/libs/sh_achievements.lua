--[[
    Helper functions for achievements

    These functions are used to give, take, check and calculate achievement points for players
]]

--- @class impulse.Achievements
impulse.Achievements = impulse.Achievements or {}

---@class Player
local PLAYER = FindMetaTable("Player")

if (SERVER) then
    --- Player class methods
    -- @classmod Player

    --- Gives an achievement to a player
    -- @realm server
    -- @string class Achievement class
    -- @bool[opt=false] skipPoints Wether to skip calculating the points from this achievement
    function PLAYER:AchievementGive(class, skipPoints)
        if not self.impulseData then return end

        local achievements = self:GetNetVar(NET_ACHIEVEMENTS, {})
        if achievements[class] then return end
        achievements[class] = math.floor(os.time())
        self:SetNetVar(NET_ACHIEVEMENTS, achievements)
    end

    --- Takes an achievement from a player
    -- @realm server
    -- @string class Achievement class
    function PLAYER:AchievementTake(class)
        local achievements = self:GetNetVar(NET_ACHIEVEMENTS, {})
        achievements[class] = nil
        self:SetNetVar(NET_ACHIEVEMENTS, achievements)
    end

    --- Returns if a player has an achievement
    -- @realm server
    -- @string class Achievement class
    -- @treturn bool Has achievement
    function PLAYER:AchievementHas(class)
        local achievements = self:GetNetVar(NET_ACHIEVEMENTS, {})
        if achievements[class] then
            return true
        end

        return false
    end

    --- Runs the achievement's check function and if it returns true, awards the achievement
    -- @realm server
    -- @string class Achievement class
    function PLAYER:AchievementCheck(class)
        local ach = impulse.Config.Achievements[class]
        if ach.OnJoin and ach.Check and ! self:AchievementHas(class) and ach.Check(self) then
            self:AchievementGive(class)
        end
    end

    --- Calculates the achievement points and stores them in the NET_ACHIEVEMENT_POINTS SyncVar on the player
    -- @realm server
    -- @treturn int Achievement points
    function PLAYER:CalculateAchievementPoints()
        local achievements = self:GetNetVar(NET_ACHIEVEMENTS, {})
        local val = 0
        for _ = 1, table.Count(achievements) do
            val = val + 60
        end

        return val
    end
end
