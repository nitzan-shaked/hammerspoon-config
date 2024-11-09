local event_types = hs.eventtap.event.types

local Module = require("module")
local class = require("utils.class")
local settings = require("settings")
local anim = require("utils.animate")


---@class VizMouseClicks: Module
local VizMouseClicks = class.make_class("VizMouseClicks", Module)


function VizMouseClicks:__init__()
	Module.__init__(
		self,
		"viz_mouse_clicks",
		"Visualize Mouse Clicks",
		"Visualize mouse clicks with a short animation around the mouse cursor.",
		{{
			name="circle_radius",
			title="Circle Radius",
			descr="The radius of the circle drawn around the mouse cursor.",
			control="number",
			default=35,
		}, {
			name="stroke_width",
			title="Stroke Width",
			descr="The width of the circle's stroke.",
			control="number",
			default=2,
		}, {
			name="left_click_stroke_color",
			title="Left Click Stroke Color",
			descr="The color of the circle's stroke when left-clicking.",
			control="color",
			default="#ffff00",
		}, {
			name="right_click_stroke_color",
			title="Right Click Stroke Color",
			descr="The color of the circle's stroke when right-clicking.",
			control="color",
			default="#ff00ff",
		}, {
			name="anim_duration",
			title="Animation Duration",
			descr="The duration of the circle's animation when clicking, in milliseconds.",
			control="number",
			default=225,
		}},
		{}
	)

	---@type Canvas
	self._canvas = nil
	---@type EventTap
	self._mouse_click_event_tap = nil
	---@type EventTap
	self._mouse_move_event_tap = nil
end


function VizMouseClicks:loadImpl()
	local cfg = settings.loadPluginSettings(self.name)
	self._circle_radius = cfg.circle_radius
	self._stroke_width = cfg.stroke_width
	self._left_click_stroke_color = cfg.left_click_stroke_color
	self._right_click_stroke_color = cfg.right_click_stroke_color
	self._anim_duration = cfg.anim_duration / 1000

	self._canvas = hs.canvas.new({
		w=self._circle_radius * 2,
		h=self._circle_radius * 2,
	})
	self._canvas:appendElements({
		type="circle",
		radius=self._circle_radius - math.ceil(self._stroke_width / 2),
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
		x=mouse_pos.x - self._circle_radius,
		y=mouse_pos.y - self._circle_radius,
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
		self._canvas[1].radius = self._circle_radius - math.ceil(self._stroke_width / 2)
		self._canvas[1].strokeColor = (
			t == event_types.leftMouseDown
			and self._left_click_stroke_color
			or self._right_click_stroke_color
		)
		self._canvas:show()
		self._mouse_move_event_tap:start()

	else
		---@type AnimData
		local anim_data = {
			radius={self._circle_radius, self._stroke_width},
		}

		---@param step_data AnimStepData
		local function anim_step_func(step_data)
			if not (self.loaded and self.started) then return end
			self._canvas[1].radius = step_data.radius - math.ceil(self._stroke_width / 2)
		end

		local function anim_done_func()
			if not (self.loaded and self.started) then return end
			self._canvas:hide()
			self._mouse_move_event_tap:stop()
		end

		anim.animate(anim_data, self._anim_duration, anim_step_func, anim_done_func)
	end
end


return VizMouseClicks()