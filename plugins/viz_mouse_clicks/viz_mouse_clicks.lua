local event_types = hs.eventtap.event.types

local Module = require("module")
local class = require("utils.class")
local animate = require("utils.animate")
local nu = require("utils.number_utils")


---@class VizMouseClicks: Module
local VizMouseClicks = class.make_class("VizMouseClicks", Module)


local _CFG_DURATION = {
	name="duration",
	title="Animation Duration (ms)",
	descr="Duration of click animation, in milliseconds.",
	control="number",
	default=225,
}
local _CFG_RADIUS = {
	name="radius",
	title="Circle Radius (px)",
	descr="Radius of the circle drawn around the mouse pointer, in pixels.",
	control="number",
	default=35,
}
local _CFG_STROKE_WIDTH = {
	name="stroke_width",
	title="Stroke Width (px)",
	descr="Width of the circle's perimeter, in pixels.",
	control="number",
	default=2,
}
local _CFG_LEFT_CLICK_STROKE_COLOR = {
	name="left_click_stroke_color",
	title="Left Click Stroke Color",
	descr="Circle color when when left-clicking.",
	control="color",
	default="#ffff00",
}
local _CFG_RIGHT_CLICK_STROKE_COLOR = {
	name="right_click_stroke_color",
	title="Right Click Stroke Color",
	descr="Circle color when right-clicking.",
	control="color",
	default="#ff00ff",
}


function VizMouseClicks:__init__()
	Module.__init__(
		self,
		"viz_mouse_clicks",
		"Visualize Mouse Clicks",
		"Visualize mouse clicks with a short animation around the mouse pointer.",
		{
			_CFG_DURATION,
			_CFG_RADIUS,
			_CFG_STROKE_WIDTH,
			_CFG_LEFT_CLICK_STROKE_COLOR,
			_CFG_RIGHT_CLICK_STROKE_COLOR,
		},
		{}
	)
end


function VizMouseClicks:loadImpl(settings)
	self._duration = settings.duration / 1000
	self._radius = settings.radius
	self._stroke_width = settings.stroke_width
	self._left_click_stroke_color = settings.left_click_stroke_color
	self._right_click_stroke_color = settings.right_click_stroke_color

	self._canvas = hs.canvas.new({
		w=self._radius * 2,
		h=self._radius * 2,
	})
	self._canvas:appendElements({
		type="circle",
		radius=self._radius - math.ceil(self._stroke_width / 2),
		action="stroke",
		strokeWidth=self._stroke_width,
	})

	self._mouse_click_event_tap = hs.eventtap.new({
		event_types.leftMouseDown,
		event_types.leftMouseUp,
		event_types.rightMouseDown,
		event_types.rightMouseUp,
	}, function(e) self:_handle_click_event(e) end)

	self._mouse_move_event_tap = hs.eventtap.new({
		event_types.mouseMoved,
		event_types.leftMouseDragged,
		event_types.rightMouseDragged,
	}, function() self:_refresh_canvas_geometry() end)
end


function VizMouseClicks:startImpl()
	self._mouse_click_event_tap:start()
end


function VizMouseClicks:stopImpl()
	self._mouse_click_event_tap:stop()
	self._mouse_move_event_tap:stop()
	self._canvas:hide()
end


function VizMouseClicks:unloadImpl()
	self._mouse_click_event_tap = nil
	self._mouse_move_event_tap = nil
	self._canvas:delete()
	self._canvas = nil
end


function VizMouseClicks:_refresh_canvas_geometry()
	local mouse_pos = hs.mouse.absolutePosition()
	self._canvas:topLeft({
		x=mouse_pos.x - self._radius,
		y=mouse_pos.y - self._radius,
	})
end


---@param e Event
function VizMouseClicks:_handle_click_event(e)
	local t = e:getType()
	if (
		t == event_types.leftMouseDown or
		t == event_types.rightMouseDown
	) then
		self:_refresh_canvas_geometry()
		self._canvas[1].radius = self._radius - math.ceil(self._stroke_width / 2)
		self._canvas[1].strokeColor = (
			t == event_types.leftMouseDown
			and self._left_click_stroke_color
			or self._right_click_stroke_color
		)
		self._canvas:show()
		self._mouse_move_event_tap:start()

	else
		---@param s number
		local function frame_func(s)
			if not (self.loaded and self.started) then return end
			self._canvas[1].radius = nu.interpolate(
				self._radius,
				self._stroke_width,
				s
			) - math.ceil(self._stroke_width / 2)
		end

		local function end_func()
			if not (self.loaded and self.started) then return end
			self._canvas:hide()
			self._mouse_move_event_tap:stop()
		end

		animate.Animation(self._duration, frame_func, end_func):start()
	end
end


return VizMouseClicks()