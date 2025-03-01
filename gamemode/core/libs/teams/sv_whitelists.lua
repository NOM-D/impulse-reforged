---@class Player
---@field Whitelists table<string, number> A table of whitelists for the player
local PLAYER = FindMetaTable("Player")

function impulse.Teams.WhitelistSetup(steamid)
    local query = mysql:Insert("impulse_whitelists")
    query:Insert("steamid")
end

---Whitelist a steamID64 for a team
---@param steamid string
---@param teamTable impulse.Teams.TeamData
---@param level number
function impulse.Teams.SetWhitelist(steamid, teamTable, level)
    if (! teamTable) then
        impulse.Logs:Error("Attempted to set whitelist for invalid team %s", tostring(teamTable))
        return
    end

    impulse.Teams.GetWhitelist(steamid, teamTable, function(whitelistExists)
        local teamId = teamTable.id
        if (whitelistExists) then
            local query = mysql:Update("impulse_whitelists")
            query:Update("level", level)
            query:Where("teamid", teamId)
            query:Where("steamid", steamid)
            query:Execute()
        else
            local query = mysql:Insert("impulse_whitelists")
            query:Insert("level", level)
            query:Insert("teamid", teamId)
            query:Insert("steamid", steamid)
            query:Execute()
        end
    end)

    local ply = player.GetBySteamID64(steamid)
    if (IsValid(ply)) then
        ply = ply --[[@as Player]]

        impulse.Logs:Debug("Setting whitelist for " .. ply:Nick() .. " to " .. team .. " with level " .. level)
        ply.Whitelists = ply.Whitelists || {}
        ply.Whitelists[team] = level
    end
end

---Get all whitelists for a team
---@param teamTable impulse.Teams.TeamData
---@param callback fun(result: impulse.Teams.WhitelistDBEntry[]) The callback to run when the query is complete and the result isn't empty
function impulse.Teams.GetAllWhitelists(teamTable, callback)
    if (! teamTable) then
        impulse.Logs:Error("Attempted to get all whitelists for invalid team %s", teamTable)
        return
    end

    -- get all team whitelist levels for a player
    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Select("steamid")
    query:Where("teamid", teamTable)
    if (callback) then -- only add a callback if we need to
        ---@param whitelists impulse.Teams.TeamData.Rank[]
        query:Callback(function(whitelists)
            if (type(whitelists) == "table" && whitelists[1] != nil) then
                callback(whitelists)
            end
        end)
    end
    query:Execute() -- execute the query
end

---Get all whitelists for a player
---@param steamid64 string The steamid64 of the player
---@param callback fun(result: impulse.Teams.WhitelistDBEntry[]) The callback to run when the query is complete and the result isn't empty
function impulse.Teams.GetAllWhitelistsPlayer(steamid64, callback)
    impulse.Logs:Debug("Getting all whitelists for " .. steamid64)
    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Select("teamid")
    query:Where("steamid", steamid64)
    if (callback) then -- only add a callback if we need to
        query:Callback(function(result)
            if (type(result) == "table" && result[1] != nil) then
                callback(result)
            end
        end)
    end
    query:Execute()
end

---Get a whitelist for a player
---@param steamid string The steamid64 of the player
---@param teamTable impulse.Teams.TeamData
---@param callback fun(level?: number)
function impulse.Teams.GetWhitelist(steamid, teamTable, callback)
    if (! teamTable) then
        impulse.Logs:Error("Attempted to get whitelist for invalid team %s", tostring(teamTable))
        return
    end

    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Where("teamid", teamTable.id)
    query:Where("steamid", steamid)
    query:Callback(function(result)
        if type(result) == "table" && result[1] != nil && callback then -- if player exists in db
            callback(result[1].level)
        else
            callback()
        end
    end)
    query:Execute()
end

---Checks if a player has a whitelist for a team
---@param teamTable impulse.Teams.TeamData
---@param level number
---@return boolean hasWhitelist
function PLAYER:HasTeamWhitelist(teamTable, level)
    if (! teamTable) then
        impulse.Logs:Error("Attempted to check whitelist for invalid team %s", teamTable)
        return false
    end
    if (! self.Whitelists) then return false end

    ---@type number?
    local teamWhitelistLevel = self.Whitelists[teamTable]
    if (teamWhitelistLevel) then
        if (level) then
            return teamWhitelistLevel >= level
        else
            return true
        end
    end

    return false
end

---Set up team and class whitelists for a player
---
---In theory this should only be called once because their whitelists will be entirely reloaded
function PLAYER:SetupWhitelists()
    self.Whitelists = {}

    impulse.Teams.GetAllWhitelistsPlayer(self:SteamID64(), function(whitelists)
        impulse.Logs:Debug("Setting up whitelists for " .. self:Nick() .. ", found " .. #whitelists .. " entries")
        if (! whitelists || ! IsValid(self)) then return end
        for _, whitelistData in pairs(whitelists) do
            local teamId = whitelistData.teamId
            local level = whitelistData.level

            impulse.Logs:Debug("Setting whitelist for " .. self:Nick() .. " to " .. teamid .. " with level " .. level)
            self.Whitelists[teamId] = tonumber(level)
        end
    end)
end
