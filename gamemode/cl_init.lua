local ply
local _LocalPlayer = LocalPlayer
function LocalPlayer()
    ply = _LocalPlayer()
    if IsValid(pl) then LocalPlayer = function() return ply end end
    return ply
end

DeriveGamemode("sandbox")
MsgC(Color(83, 143, 239), "[impulse-reforged] Starting client load...\n")
impulse = impulse or {
    Derma = {}
}

include("core/util/sh_logs.lua")
include("core/util/cl_util.lua")
include("core/util/sh_util.lua")
include("core/util/sv_util.lua")
include("shared.lua")
timer.Remove("HintSystem_OpeningMenu")
timer.Remove("HintSystem_Annoy1")
timer.Remove("HintSystem_Annoy2")
hook.Add("PreDrawHalos", "PropertiesHover", function()
    -- overwrite exploitable context menu shit
    if not IsValid(vgui.GetHoveredPanel()) or not vgui.GetHoveredPanel():IsWorldClicker() then return end
    local ent = properties.GetHovered(EyePos(), LocalPlayer():GetAimVector())
    if not IsValid(ent) then return end
    if ent:GetNoDraw() then return end
    local c = Color(255, 255, 255, 255)
    c.r = 200 + math.sin(RealTime() * 50) * 55
    c.g = 200 + math.sin(RealTime() * 20) * 55
    c.b = 200 + math.cos(RealTime() * 60) * 55
    local t = { ent }
    if ent.GetActiveWeapon and IsValid(ent:GetActiveWeapon()) then table.insert(t, ent:GetActiveWeapon()) end
    halo.Add(t, c, 2, 2, 2, true, false)
end)

RunConsoleCommand("cl_showhints", "0") -- disable annoying gmod hints by default

MsgC(Color(0, 255, 0), "[impulse-reforged] Completed client load...\n")
