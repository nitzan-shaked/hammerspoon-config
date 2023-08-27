local class = require("utils.class")
local u = require("utils.utils")
local Point = require("geom.point")
local Rect = require("geom.rect")


---@class Drag: Class
---@operator call: Drag
---@field _bounds Geometry
local Drag = class("Drag")

---@params bounds Geometry
function Drag:__init(bounds)
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
	local mouse_x = u.clip(mouse_pos.x, self._bounds.x1, self._bounds.x2)
	local mouse_y = u.clip(mouse_pos.y, self._bounds.y1, self._bounds.y2)

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


---@class BorderDrag: Drag
---@operator call: BorderDrag
local BorderDrag = class("BorderDrag", {base_cls=Drag})

---@param w Window
function BorderDrag:__init(w)
	local w_frame = w:frame()
	Drag.__init(self, w_frame)
	local canvas = hs.canvas.new({})
	canvas:topLeft(w_frame.topleft)
	canvas:size(w_frame.size)
	canvas:appendElements({
		id="bg",
		type="rectangle",
		action="fill",
		fillColor={red=0, green=0, blue=0, alpha=0.5},
	})
	canvas:appendElements({
		id="border",
		type="rectangle",
		action="skip",
		strokeColor={red=1, green=1, blue=1},
		strokeDashPattern={5, 2},
	})
	canvas:show()
	self._canvas = canvas
	self._border_x1 = self._initial_mouse_pos.x - w_frame.x
	self._border_y1 = self._initial_mouse_pos.y - w_frame.y
end

function BorderDrag:on_stopped()
	self._canvas:hide()
end

---@param dx integer
---@param dy integer
function BorderDrag:on_really_started(dx, dy)
	self._canvas["border"].action = "stroke"
end

---@param dx integer
---@param dy integer
function BorderDrag:on_moved(dx, dy)
	print(self._border_x1, self._border_y1, dx, dy)
	self._canvas["border"].frame = {
		x=self._border_x1,
		y=self._border_y1,
		w=dx,
		h=dy,
	}
end

return {
	BorderDrag=BorderDrag,
}
