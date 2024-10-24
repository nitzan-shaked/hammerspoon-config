local class = require("utils.class")
local Drag = require("drag")


---@class BorderDrag: Drag
---@operator call: BorderDrag
local BorderDrag = class("BorderDrag", {base_cls=Drag})


---@param w Window
function BorderDrag:__init__(w)
	local w_frame = w:frame()
	Drag.__init__(self, w_frame)
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


return BorderDrag