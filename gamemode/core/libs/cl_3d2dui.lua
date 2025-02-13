--[[
	
3D2D VGUI Wrapper
Copyright (c) 2015-2017 Alexander Overvoorde, Matt Stevens

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]--

---@class impulse.Derma.3D2D
impulse.Derma.UI3D2D = impulse.Derma.UI3D2D or {
	context = {
		---@type Vector The origin of the 3D2D context	
		origin = Vector(0, 0, 0),

		---@type Angle The angle of the 3D2D context
		angle = Angle(0, 0, 0),

		---@type Vector The normal of the 3D2D context
		normal = Vector(0, 0, 0),

		---@type number The scale of the 3D2D context
		scale = 0.1,

		---@type number The maximum range for 3D2D rendering
		maxrange = 0,

		---@type boolean Whether the player is looking at a UI element
		isLookingAtUI = false
	}
}

local ui3d2d = impulse.Derma.UI3D2D
local context = ui3d2d.context


local nextKeyPressTime = CurTime()
local keyPressHookDelay_s = 0.25

-- Input
---@type table<Panel, boolean>
local inputWindows = {}

---@type table<Panel, table?>
local usedPanel = {}

---@class Player
---@realm client
---@field _3d2dFocusedPanel Panel?


--- Get the position of the user's cursor
---@return number? posX
---@return number? posY
---@nodiscard
local function getCursorPos()
    local client = LocalPlayer()
    local eyePos = client:EyePos()
	local origin = context.origin
	local angle = context.angle
	local normal = context.normal
	local maxrange = context.maxrange

    local p = util.IntersectRayWithPlane(eyePos, client:GetAimVector(), origin, normal)

	-- if there wasn't an intersection, don't calculate anything.
	if not p then return end
	if WorldToLocal(client:GetShootPos(), Angle(0,0,0), origin, angle).z < 0 then return end

	if maxrange > 0 then
		if p:Distance(eyePos) > maxrange then
			return
		end
	end

	local pos = WorldToLocal(p, Angle(0,0,0), origin, angle)
	return pos.x, -pos.y
end

--- Get the parents of a panel
---@param pnl Panel
---@return table
---@nodiscard
local function getParents(pnl)
	local parents = {}
	local parent = pnl:GetParent()
	while parent do
		table.insert(parents, parent)
		parent = parent:GetParent()
	end
	return parents
end

--- Get the absolute position of a panel
---@param pnl Panel
---@return number x
---@return number y
---@nodiscard
local function absolutePanelPos(pnl)
	local x, y = pnl:GetPos()
	local parents = getParents(pnl)

	for _, parent in ipairs(parents) do
		local px, py = parent:GetPos()
		x = x + px
		y = y + py
	end
	
	return x, y
end

--- Check if a point is inside a panel
---@param pnl Panel
---@param x (number|unknown)?
---@param y (number|unknown)?
---@return boolean?
---@nodiscard
local function pointInsidePanel(pnl, x, y)
	local px, py = absolutePanelPos(pnl)
	local sx, sy = pnl:GetSize()
	local scale = context.scale

	if not x or not y then return end

	x = x / scale
	y = y / scale

	return pnl:IsVisible() and x >= px and y >= py and x <= px + sx and y <= py + sy
end

--- Post an event to a panel
---@param pnl Panel
---@param event string
---@param ... unknown
---@return boolean
local function postPanelEvent(pnl, event, ...)
	if not IsValid(pnl) or not pnl:IsVisible() or not pointInsidePanel(pnl, getCursorPos()) then return false end

	local handled = false

	for i, child in pairs(table.Reverse(pnl:GetChildren())) do
		if not child:IsMouseInputEnabled() then continue end

		if postPanelEvent(child, event, ...) then
			handled = true
			break
		end
	end

	if not handled and pnl[event] then
		pnl[event](pnl, ...)
		usedPanel[pnl] = {...}
		return true
	else
		return false
	end
end

--- Check if the mouse is hovering over a panel
---@param pnl Panel
---@param x number?
---@param y number?
---@param found boolean?
---@return boolean
local function checkHover(pnl, x, y, found)
    ---@class Panel
    ---@field Hovered boolean
    ---@field OnCursorEntered fun()
    ---@field OnCursorExited fun()
    local pnl = pnl
	if not (x and y) then
		x, y = getCursorPos()
	end

	local validChild = false
	for _, child in pairs(table.Reverse(pnl:GetChildren())) do
		local check = checkHover(child, x, y, found or validChild)
		if check then
			context.isLookingAtUI = true
		end

		if not child:IsMouseInputEnabled() then continue end

		if check then
			validChild = true
		end
	end

	if found then
		if pnl.Hovered then
			pnl.Hovered = false
			if pnl.OnCursorExited then pnl:OnCursorExited() end
		end
	else
		if not validChild and pointInsidePanel(pnl, x, y) then
			pnl.Hovered = true
			if pnl.OnCursorEntered then pnl:OnCursorEntered() end
			return true
		else
			pnl.Hovered = false
			if pnl.OnCursorExited then pnl:OnCursorExited() end
		end
	end

	return false
end

---@param panel Panel
---@return table panels
local function getAllInputPanels(panel)
    local panels = {}
    local stack = {panel}

    while #stack > 0 do
        local current = table.remove(stack)

        table.insert(panels, current)

        for i = 0, current:ChildCount() - 1 do
            local child = current:GetChild(i)
            table.insert(stack, child)
        end
    end

    return panels
end



--- Start a 3D2D context
---@param pos Vector
---@param ang Angle
---@param res number
function vgui.Start3D2D(pos, ang, res)
	ui3d2d.context = {
		origin = pos,
		angle = ang,
		scale = res,
		normal = ang:Up(),
		maxrange = 0
	}
	context = ui3d2d.context

	cam.Start3D2D(pos, ang, res)
end

--- End a 3D2D context
--- 
--- This is essentially a wrapper for cam.End3D2D
function vgui.End3D2D()
	cam.End3D2D()
end

--- Set the maximum range for 3D2D rendering
---@param range number
function vgui.MaxRange3D2D(range)
	context.maxrange = isnumber(range) and range or 0
end

--- Check if the mouse is hovering over a panel
---@param pnl Panel
---@return boolean?
---@nodiscard
function vgui.IsPointingPanel(pnl)
    ---@class Panel
    ---@field Origin Vector
    ---@field Scale number
    ---@field Angle Angle
    ---@field Normal Vector
    local pnl = pnl
	context.origin = pnl.Origin
	context.scale = pnl.Scale
	context.angle = pnl.Angle
	context.normal = pnl.Normal

	return pointInsidePanel(pnl, getCursorPos())
end

---@class Panel
---@field Paint3D2D fun(self: Panel)
local Panel = FindMetaTable("Panel")

---@class Player
local Player  = FindMetaTable("Player")

--- Paint a panel in 3D2D
function Panel:Paint3D2D()
	if not self:IsValid() then return end

	-- Add it to the list of windows to receive input
	inputWindows[self] = true

	-- Override gui.MouseX and gui.MouseY for certain stuff
	local oldMouseX = gui.MouseX
	local oldMouseY = gui.MouseY
	local scale = context.scale or 0.1
	local cx, cy = getCursorPos()

	function gui.MouseX()
		return (cx or 0) / scale
	end
	function gui.MouseY()
		return (cy or 0) / scale
	end

	-- Override think of DFrame's to correct the mouse pos by changing the active orientation
	if self.Think then
		if not self.OThink then
			self.OThink = self.Think

			self.Think = function()
				context.origin = self.Origin
				context.scale = self.Scale
				context.angle = self.Angle
				context.normal = self.Normal

				self:OThink()
			end
		end
	end

	---@param cmd CUserCmd
	hook.Add("InputMouseApply", "3d2dui." .. tostring(self), function(cmd, _, _, _)
		if not self:IsValid() then
			hook.Remove("InputMouseApply", "3d2dui." .. tostring(self))
			return
		end
		local scrollOffset = cmd:GetMouseWheel()
		if scrollOffset == 0 then return end

		local allPanels = getAllInputPanels(self)
		for _, pnl in ipairs(allPanels) do
			if pnl.OnMouseWheeled then
				pnl:OnMouseWheeled(scrollOffset)
			end
		end
	end)

	-- Update the hover state of controls
	checkHover(self)

	-- Store the orientation of the window to calculate the position outside the render loop
	self.Origin = context.origin
	self.Scale = context.scale
	self.Angle = context.angle
	self.Normal = context.normal

	-- Draw it manually
	self:SetPaintedManually(false)
		self:PaintManual()
	self:SetPaintedManually(true)

	gui.MouseX = oldMouseX
	gui.MouseY = oldMouseY
end

-- Mouse input
hook.Add("KeyPress", "VGUI3D2DMousePress", function(_, key)
	if key == IN_USE or key == IN_ATTACK then
		key = input.IsKeyDown(KEY_LSHIFT) and MOUSE_RIGHT or MOUSE_LEFT
		local time = CurTime()
		if time >= nextKeyPressTime then
			nextKeyPressTime = time + keyPressHookDelay_s
		else
			return
		end

		for pnl in pairs(inputWindows) do
			if IsValid(pnl) then
				context.origin = pnl.Origin
				context.scale = pnl.Scale
				context.angle = pnl.Angle
				context.normal = pnl.Normal

				postPanelEvent(pnl, "OnMousePressed", key)
			end
		end
	end
end)

hook.Add("KeyRelease", "VGUI3D2DMouseRelease", function(_, key)
	if key == IN_USE or key == IN_ATTACK then
		for pnl, key in pairs(usedPanel) do
			if IsValid(pnl) then
				context.origin = pnl.Origin
				context.scale = pnl.Scale
				context.angle = pnl.Angle
				context.normal = pnl.Normal

				if pnl["OnMouseReleased"] then
					pnl["OnMouseReleased"](pnl, key[1])
				end

				usedPanel[pnl] = nil
			end
		end
	end
end)


local cursorLength = 5
hook.Add("HUDPaint", "ui3d2d.crosshair", function()
	if inputWindows and context.isLookingAtUI then
		local x = ScrW() * 0.5
		local y = ScrH() * 0.5
		if x and y then
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawLine(x - cursorLength, y, x + cursorLength, y)
			surface.DrawLine(x, y - cursorLength, x, y + cursorLength)
		end
	end
end)

---@param name string
hook.Add("HUDShouldDraw", "ui3d2d.WeaponSwitcher", function(name)
	if inputWindows and context.isLookingAtUI and name == "CHudWeaponSelection" then
		return false
	end
end)