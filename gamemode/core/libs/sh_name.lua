---@class Player
local PLAYER = FindMetaTable("Player")

if ( SERVER ) then
    ---Set the roleplay name for the player and save it to the database if necessary.
    ---@param name string
    ---@param save? boolean
    function PLAYER:SetRPName(name, save)
        if save then
            self:SetSavedRPName(name, self:Team())
        end

        hook.Run("PlayerRPNameChanged", self, self:Name(), name)

        self:SetNetVar("roleplayName", name)
    end

    --- Set the roleplay name for the player's team and save it to the database.
    --- @param name string
    --- @param teamId? number
    function PLAYER:SetSavedRPName(name, teamId)
        if not teamId then
            teamId = self:Team()
        end

        impulse.Logs:Database("Player " .. self:SteamName() .. " set their RP name to " .. name .. " for team " .. teamId)
        local data = self:GetData("rp_names", {})
        data[teamId] = name
        self:SetData("rp_names", data)
    end

    --- Get the roleplay name for the player for the specified team.
    --- @param teamId? number
    --- @return string name The roleplay name we save for the player in the database
    function PLAYER:GetSavedRPName(teamId)
        if not teamId then
            teamId = self:Team()
        end
        return self:GetData("rp_names", {})[teamId]
    end
end

--- Table of blacklisted roleplay names
local blacklistNames = {
    ["ooc"] = true,
    ["shared"] = true,
    ["world"] = true,
    ["world prop"] = true,
    ["blocked"] = true,
    ["admin"] = true,
    ["server admin"] = true,
    ["mod"] = true,
    ["game moderator"] = true,
    ["adolf hitler"] = true,
    ["masked person"] = true,
    ["masked player"] = true,
    ["unknown"] = true,
    ["nigger"] = true,
    ["tyrone jenson"] = true
}

--- Check whether a roleplay name is usable
---@param name string
---@return boolean isAllowed
---@return string? reason
function impulse.CanUseName(name)
    if name:len() >= 24 then
        return false, "Name too long. (max. 24)"
    end

    name = name:Trim()
    name = impulse.Util:SafeString(name)

    if name:len() <= 6 then
        return false, "Name too short. (min. 6)"
    end

    if name == "" then
        return false, "No name was provided."
    end


    local numFound = string.match(name, "%d") -- no numerics

    if numFound then
        return false, "Name contains numbers."
    end
    
    if blacklistNames[name:lower()] then
        return false, "Blacklisted/reserved name."    
    end

    return true, name
end

PLAYER.steamName = PLAYER.steamName or PLAYER.Name
function PLAYER:SteamName()
    return self.steamName(self)
end

--- Get the player's roleplay name
---@return string roleplayName
function PLAYER:Name()
    return self:GetNetVar("roleplayName", self:SteamName())
end

--- Get the player's known name.
--- 
--- This is the name that is displayed to other players.
--- 
--- Known name can be changed by the player.
--- 
--- If the player has set a name, it will return the player's set roleplay name.
--- 
--- If the player has not set a roleplay name, it will return the player's Steam name.
---@return string knownName
function PLAYER:KnownName()
    local custom = hook.Run("PlayerGetKnownName", self)
    return custom or self:GetNetVar("roleplayName", self:SteamName())
end

PLAYER.GetName = PLAYER.Name
PLAYER.Nick = PLAYER.Name