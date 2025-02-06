impulse.Version = "2.0"

-- Define gamemode information.
GM.Name = "impulse"
GM.Author = "vin, Riggs"
GM.Website = "https://impulse.minerva-servers.com"
GM.Version = impulse.Version

if ( SERVER ) then
    concommand.Remove("gm_save")
    concommand.Remove("gmod_admin_cleanup")

    RunConsoleCommand("sv_defaultdeployspeed", 1)
end

--- disable widgets cause it uses like 30% server cpu lol
---@deprecated
---@return nil
function widgets.PlayerTick()
end

hook.Remove("PlayerTick", "TickWidgets")

local install = "https://github.com/riggs9162/impulse-reforged/archive/refs/heads/main.zip"
function impulse:CheckVersion()
    http.Fetch("https://raw.githubusercontent.com/riggs9162/impulse-reforged/main/version.txt", function(body)
        if body == impulse.Version then
            MsgC(Color(0, 255, 0), "[impulse-reforged] You are running the latest version of impulse-reforged.\n")
        else
            MsgC(Color(255, 0, 0), "[impulse-reforged] You are running an outdated version of impulse-reforged! Please update to the latest version: " .. body .. "\n")
            MsgC(Color(255, 0, 0), "[impulse-reforged] Download the latest version here: " .. install .. "\n")
        end
    end, function(err)
        MsgC(Color(255, 0, 0), "[impulse-reforged] Error checking for updates: " .. err .. "\n")
    end)
end

-- Create impulse data folder
file.CreateDir("impulse-reforged")

-- Load config
---@class impulse.Config
---@field YML table
---@field MapWorkshopID string?
---@field MenuCamPos Vector?
---@field MenuCamAng Angle?
---@field BroadcastPos Vector?
---@field BroadcastDistance number?
---@field BlacklistEnts table
---@field Zones table
---@field IntroScenes table
---@field PrisonAngle Angle?
---@field PrisonCells table
---@field Buttons table
---@field ApartmentBlocks table
---@field LoadScript function?
---@field JumpPower number The jump power of players
---@field CityName string? The name of the city (e.g. "City 17")
impulse.Config = impulse.Config or {}

-- Include thirdparty libraries
impulse.Util:IncludeDir("core/thirdparty")

-- Attempt to connect to a database if we have the details
impulse.Config.YML = impulse.Yaml.Read("data/impulse-reforged/config.yml") or {}

-- Load the rest of the gamemode
impulse.Util:IncludeDir("core/libs", nil, true)
impulse.Util:IncludeDir("core/meta")
impulse.Util:IncludeDir("core/derma")
impulse.Util:IncludeDir("core/hooks")

function GM:Initialize()
    impulse:CheckVersion()
    impulse.Plugins:Load()
    impulse.Schema:Load()
end

---@type boolean Whether the gamemode has been just reloaded
impulse_reloaded = false
---@type number The number of Lua reloads that have occurred
impulse_reloads = impulse_reloads or 0
---@type number The time the last reload took
impulse_reload_time = SysTime()

function GM:OnReloaded()
    if ( impulse_reloaded ) then return end

    GM = GM or GAMEMODE

    impulse.Plugins:Load()
    impulse.Schema:Load()

    impulse_reloads = impulse_reloads + 1
    impulse_reload_time = math.Round(SysTime() - impulse_reload_time, 2)

    impulse.Logs:Success("Reloaded in " .. impulse_reload_time .. "s. (" .. impulse_reloads .. " total reloads)")
    GM = nil
end

local isPreview = CreateConVar("impulse_preview", 0, FCVAR_REPLICATED, "If the current build is in preview mode.")