---@class Player
---@field Whitelists table<string, number> A table of whitelists for the player
local PLAYER = FindMetaTable("Player")

function impulse.Teams.WhitelistSetup(steamid)
    local query = mysql:Insert("impulse_whitelists")
    query:Insert("steamid")
end

---Whitelist a steamID64 for a team
---@param steamid string
---@param team string
---@param level number
function impulse.Teams.SetWhitelist(steamid, team, level)
    impulse.Teams.GetWhitelist(steamid, team, function(exists)
        if exists then
            local query = mysql:Update("impulse_whitelists")
            query:Update("level", level)
            query:Where("team", team)
            query:Where("steamid", steamid)
            query:Execute()
        else
            local query = mysql:Insert("impulse_whitelists")
            query:Insert("level", level)
            query:Insert("team", team)
            query:Insert("steamid", steamid)
            query:Execute()
        end
    end)

    local ply = player.GetBySteamID64(steamid)
    if IsValid(ply) then
        local teamTable = impulse.Teams:FindTeam(team)
        if not teamTable then return end
        impulse.Logs:Debug("Setting whitelist for " .. ply:Nick() .. " to " .. team .. " with level " .. level)
        ply.Whitelists = ply.Whitelists or {}
        ply.Whitelists[team] = level
    end
end

---Get all whitelists for a team
---@param team string
---@param callback fun(result: impulse.Teams.WhitelistDBEntry[])
function impulse.Teams.GetAllWhitelists(team, callback)
    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Select("steamid")
    query:Where("team", team)
    query:Callback(function(result)
        if type(result) == "table" and #result > 0 and callback then -- if player exists in db
            callback(result)
        end
    end)
    query:Execute()
end

---Get all whitelists for a player
---@param steamid string
---@param callback fun(result: impulse.Teams.WhitelistDBEntry[])
function impulse.Teams.GetAllWhitelistsPlayer(steamid, callback)
    impulse.Logs:Debug("Getting all whitelists for " .. steamid)
    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Select("team")
    query:Where("steamid", steamid)
    query:Callback(function(result)
        if (type(result) == "table" and #result > 0) and callback then -- if player exists in db
            callback(result)
        end
    end)
    query:Execute()
end


---Get a whitelist for a player
---@param steamid string The steamid64 of the player
---@param team string The team name
---@param callback fun(level?: number)
function impulse.Teams.GetWhitelist(steamid, team, callback)
    local query = mysql:Select("impulse_whitelists")
    query:Select("level")
    query:Where("team", team)
    query:Where("steamid", steamid)
    query:Callback(function(result)
        if type(result) == "table" and #result > 0 and callback then -- if player exists in db
            callback(result[1].level)
        else
            callback()
        end
    end)
    query:Execute()
end

---Checks if a player has a whitelist for a team
---@param team string
---@param level number
---@return boolean hasWhitelist
function PLAYER:HasTeamWhitelist(team, level)
    if not self.Whitelists then return false end

    local teamTable = impulse.Teams:FindTeam(team)
    if teamTable then
        team = teamTable.name
    end

    ---@type number?
    local whitelist = self.Whitelists[team]
    if whitelist then
        if level then
            return whitelist >= level
        else
            return true
        end
    end

    return false
end

---Set up team and class whitelists for a player
function PLAYER:SetupWhitelists()
    self.Whitelists = {}

    impulse.Teams.GetAllWhitelistsPlayer(self:SteamID64(), function(result)
        impulse.Logs:Debug("Setting up whitelists for " .. self:Nick() .. ", found " .. #result .. " entries")
        if not result or not IsValid(self) then return end
        for _, whitelistData in pairs(result) do
            local teamName = whitelistData.team
            local level = whitelistData.level
            local teamTable = impulse.Teams:FindTeam(teamName)

            impulse.Logs:Debug("Setting whitelist for " .. self:Nick() .. " to " .. teamName .. " with level " .. level)
            self.Whitelists[(teamTable and teamTable.name) or teamName] = tonumber(level)
        end
    end)
end