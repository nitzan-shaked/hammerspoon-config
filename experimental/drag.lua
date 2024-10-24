local class = require("utils.class")
local nu = require("utils.number_utils")


---@class Drag: Class
---@operator call: Drag
---@field _bounds Geometry
local Drag = class("Drag")


---@params bounds Geometry
function Drag:__init__(bounds)
	self._bounds = bounds
	self._really_started = false
	self._initial_mouse_pos = hs.mouse.absolutePosition()
	self._event_tap = hs.eventtap.new(
		{hs.eventtap.event.types.mouseMoved},
		function () self:_event_handler() end
	)
	self._event_tap:start()
end


---@params bounds Geometry
function Drag:stop()
	self._event_tap:stop()
	self._really_started = false
	self:on_stopped()
end


function Drag:_event_handler()
	local mouse_pos = hs.mouse.absolutePosition()
	local mouse_x = nu.clip(mouse_pos.x, self._bounds.x1, self._bounds.x2)
	local mouse_y = nu.clip(mouse_pos.y, self._bounds.y1, self._bounds.y2)

	local dx = mouse_x - self._initial_mouse_pos.x
	local dy = mouse_y - self._initial_mouse_pos.y

	-- TODO: modify dx and dy for "single axis only"
	-- TODO: modify dx and dy for "keep aspect ratio"

	-- TODO: add "manually cancel" support

	if not self._really_started then
		if not (math.abs(dx) >= 3 or math.abs(dy) >= 3) then return end
		self._really_started = true
		self:on_really_started(dx, dy)
	end

	-- TODO: only invoke "on_moved" if dx,dy is different than last_dx,last_dy
	self:on_moved(dx, dy)
end


---@param dx integer
---@param dy integer
function Drag:on_really_started(dx, dy)
end


---@param dx integer
---@param dy integer
function Drag:on_moved(dx, dy)
end


function Drag:on_stopped()
end


return Drag
