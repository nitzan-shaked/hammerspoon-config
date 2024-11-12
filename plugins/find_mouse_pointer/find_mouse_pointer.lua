local Module = require("module")
local class = require("utils.class")


---@class FindMousePointer: Module
local FindMousePointer = class.make_class("FindMousePointer", Module)


function FindMousePointer:__init__()
	Module.__init__(
		self,
		"find_mouse_pointer",
		"Find Mouse Pointer",
		"Highlight the mouse pointer for a short duration.",
		{{
			name="highlight_duration",
			title="Highlight Duration",
			descr="Duration of the highlight in milliseconds.",
			control="number",
			default=3000,
		}, {
			name="circle_radius",
			title="Circle Radius",
			descr="Radius of the highlight circle in pixels.",
			control="number",
			default=30,
		}, {
			name="stroke_width",
			title="Stroke Width",
			descr="Width of the circle's circumference in pixels.",
			control="number",
			default=5,
		}, {
			name="stroke_color",
			title="Stroke Color",
			descr="Color of the circle's circumference.",
			control="color",
			default="#ff0000",
		}, {
			name="fill_color",
			title="Fill Color",
			descr="Color of the circle's interior.",
			control="color",
			default="#ff00004c",
		}},
		{{
			name="highlight",
			title="Highlight Mouse Pointer",
			descr="Highlight the mouse pointer for a short duration.",
			fn=function() self:startTimedHighlight() end,
			default={"ctrl", "cmd", "m"},
		}}
	)

	---@type Canvas
	self._canvas = nil
	---@type EventTap
	self._mouse_move_event_tap = nil
	---@type Timer?
	self._timer = nil
end


function FindMousePointer:loadImpl(settings)
	self._highlight_duration = settings.highlight_duration / 1000
	self._circle_radius = settings.circle_radius
	self._stroke_width = settings.stroke_width
	self._stroke_color = settings.stroke_color
	self._fill_color = settings.fill_color

	self._canvas = hs.canvas.new({
		w=self._circle_radius * 2,
		h=self._circle_radius * 2,
	})
	self._canvas:appendElements({
		type="circle",
		radius=self._circle_radius - math.ceil(self._stroke_width / 2),
		action="strokeAndFill",
		strokeColor=self._stroke_color,
		fillColor=self._fill_color,
		strokeWidth=self._stroke_width,
	})

	self._mouse_move_event_tap = hs.eventtap.new(
		{hs.eventtap.event.types.mouseMoved},
		function() self:_refresh_canvas_geometry() end
	)
end


function FindMousePointer:unloadImpl()
	self._mouse_move_event_tap:stop()
	self._mouse_move_event_tap = nil
	self._canvas:delete()
	self._canvas = nil
end


function FindMousePointer:startTimedHighlight()
	self:_check_loaded_and_started()
	self:_stop_highlight()
	self:_start_highlight()
	self._timer = hs.timer.doAfter(
		self._highlight_duration,
		function() self:_stop_highlight() end
)
end


function FindMousePointer:_start_highlight()
	self:_refresh_canvas_geometry()
	self._canvas:show()
	self._mouse_move_event_tap:start()
end


function FindMousePointer:_stop_highlight()
	if self._timer then
		self._timer:stop()
		self._timer = nil
	end
	self._mouse_move_event_tap:stop()
	self._canvas:hide()
end


function FindMousePointer:_refresh_canvas_geometry()
	local mouse_pos = hs.mouse.absolutePosition()
	self._canvas:topLeft({
		x=mouse_pos.x - self._circle_radius,
		y=mouse_pos.y - self._circle_radius,
	})
end


return FindMousePointer()
