--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

---@class Player
---@field impulseData? impulse.DataModels.Player.Data
---@field impulsePlayTime number

--- @class Player
local PLAYER = FindMetaTable("Entity")

util.AddNetworkString("impulseDataSync")

--- Set up the player's data in the database, assuming they don't have anything
function PLAYER:CreateInitialData()
    local name = self:SteamName()
    local steamID64 = self:SteamID64()
    local timestamp = math.floor(os.time())
    local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

    local insertQuery = mysql:Insert("impulse_players")
    insertQuery:Insert("steamid", steamID64)
    insertQuery:Insert("steamname", name)
    insertQuery:Insert("group", "user")
    insertQuery:Insert("rpgroup", 0)
    insertQuery:Insert("rpgrouprank", "")
    insertQuery:Insert("xp", 0)
    insertQuery:Insert("money", 0)
    insertQuery:Insert("bankmoney", 0)
    insertQuery:Insert("skills", "")
    insertQuery:Insert("ammo", "")
    insertQuery:Insert("model", "")
    insertQuery:Insert("skin", 0)
    insertQuery:Insert("cosmetic", "")
    insertQuery:Insert("data", util.TableToJSON({}))
    insertQuery:Insert("firstjoin", timestamp)
    insertQuery:Insert("lastjoin", timestamp)
    insertQuery:Insert("address", ip)
    insertQuery:Insert("playtime", 0)
    insertQuery:Execute()

    self.impulseData = {}
end

function PLAYER:SaveData()
    if (self:IsBot()) then return end
    if (! self.impulseData) then
        impulse.Logs:Error("Player data not saved for %s", self:SteamName())
        return
    end

    local name = self:SteamName()
    local steamID64 = self:SteamID64()

    local query = mysql:Update("impulse_players")
    query:Update("steamname", name)
    query:Update("playtime", math.floor((self.impulsePlayTime or 0) + (RealTime() - (RealTime() - 1))))
    query:Update("data", util.TableToJSON(self.impulseData))
    query:Where("steamid", steamID64)
    query:Execute()

    hook.Run("PlayerDataSaved", self)
end

---Load the player's data from the database
---@realm server
---@param callback fun(data: impulse.DataModels.Player) The function to call when we're done fetching the player's data
function PLAYER:LoadDataFromDatabase(callback)
    hook.Run("PrePlayerDataLoaded", self)

    self.impulseData = self.impulseData or {}

    local query = mysql:Select("impulse_players")
    query:Select("id")
    query:Select("group")
    query:Select("rpgroup")
    query:Select("rpgrouprank")
    query:Select("xp")
    query:Select("money")
    query:Select("bankmoney")
    query:Select("model")
    query:Select("skin")
    query:Select("data")
    query:Select("skills")
    query:Select("ammo")
    query:Select("firstjoin")
    query:Select("lastjoin")
    query:Select("address")
    query:Select("playtime")
    query:Where("steamid", self:SteamID64())
    ---@param result impulse.DataModels.Player[]
    query:Callback(function(result)
        if (! IsValid(self)) then
            impulse.Logs:Error("Failed to load data for player %s", IsValid(self) && self:SteamName() || "unknown player")
            return
        end
        if (istable(result) && result[1]) then -- Return the player's data
            local data = result[1]
            data.data = data.data && util.JSONToTable(data.data) or {}
            data.skills = data.skills && util.JSONToTable(data.skills) or {}
            data.ammo = data.ammo && util.JSONToTable(data.ammo) or {}

            impulse.Logs:Debug("Loading existing data for player %s", self:SteamName())
            hook.Run("PostPlayerDataLoaded", self)
            callback(data)
        else
            impulse.Logs:Debug("Setting up data for new player %s", self:SteamName())
            self:CreateInitialData() -- Set up the player's database data
            callback({
                id = 0,
                steamid = self:SteamID64(),
                steamname = self:SteamName(),
                group = "user",
                rpgroup = 0,
                rpgrouprank = "",
                xp = 0,
                money = 0,
                bankmoney = 0,
                model = "",
                skin = 0,
                data = {},
                skills = {},
                ammo = {},
                firstjoin = os.time(),
                lastjoin = os.time(),
                address = self:IPAddress():match("%d+%.%d+%.%d+%.%d+"),
                playtime = 0
            })
        end
    end)
    query:Execute()
    hook.Run("PlayerDataLoaded", self)
end

--- Allows the player to control the PVS of the scene
--- @param bool boolean Allow PVS control
function PLAYER:AllowScenePVSControl(bool)
    self.allowPVS = bool

    if (! bool) then
        self.extraPVS = nil
        self.extraPVS2 = nil
    end
end

function PLAYER:UpdateDefaultModelSkin()
    net.Start("impulseUpdateDefaultModelSkin")
    net.WriteString(self.impulseDefaultModel)
    net.WriteUInt(self.impulseDefaultSkin, 8)
    net.Send(self)
end

function PLAYER:GetPropCount(skip)
    if (! self:IsValid()) then return end

    local key = self:UniqueID()
    local tab = g_SBoxObjects[key]

    if (! tab or ! tab["props"]) then
        return 0
    end

    local c = 0

    for k, v in pairs(tab["props"]) do
        if (IsValid(v) and ! v:IsMarkedForDeletion()) then
            c = c + 1
        else
            tab["props"][k] = nil
        end
    end

    if not skip then
        self:SetNetVar(NET_PLAYER_PROP_COUNT, c)
    end

    return c
end

function PLAYER:AddPropCount(ent)
    local key = self:UniqueID()
    g_SBoxObjects[key] = g_SBoxObjects[key] or {}
    g_SBoxObjects[key]["props"] = g_SBoxObjects[key]["props"] or {}

    local tab = g_SBoxObjects[key]["props"]

    table.insert(tab, ent)

    self:GetPropCount()

    ent:CallOnRemove("GetPropCountUpdate", function(ent, ply) ply:GetPropCount() end, self)
end

function PLAYER:ResetSubMaterials()
    if (! self.SetSubMats) then return end

    for v, k in pairs(self.SetSubMats) do
        self:SetSubMaterial(v - 1, nil)
    end

    self.SetSubMats = nil
end

function PLAYER:ClearWorkbar()
    net.Start("impulseClearWorkbar")
    net.Send(self)
end

function PLAYER:MakeWorkbar(time, text, onDone, popup)
    self:ClearWorkbar()

    if (! time) then
        net.Start("impulseMakeWorkbar")
        net.Send(self)

        return
    end

    net.Start("impulseMakeWorkbar")
    net.WriteUInt(time, 6)
    net.WriteString(text)
    net.WriteBool(popup)
    net.Send(self)

    if (time and onDone) then
        timer.Simple(time, function()
            if (! IsValid(self)) then return end

            onDone()
        end)
    end
end
