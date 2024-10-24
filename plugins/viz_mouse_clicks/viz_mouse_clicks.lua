local event_types = hs.eventtap.event.types

local anim = require("utils.animate")
local settings = require("settings")


--[[ MODULE ]]

local cls = {}

cls.name = "viz_mouse_clicks"


--[[ CONFIG ]]

cls.cfg_schema = {
	name=cls.name,
	title="Visualize Mouse Clicks",
	descr="Visualize mouse clicks with a short animation around the mouse cursor.",
	items={{
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
}


--[[ STATE ]]

cls.initialized = false
cls.started = false

---@type Canvas
cls.canvas = nil
---@type EventTap
cls.mouse_click_event_tap = nil
---@type EventTap
cls.mouse_move_event_tap = nil


--[[ LOGIC ]]

function cls.isInitialized()
	return cls.initialized
end


function cls.init()
	assert(not cls.initialized, "already initialized")

	local cfg = settings.loadPluginSection(cls.name)
	cls.circle_radius = cfg.circle_radius
	cls.stroke_width = cfg.stroke_width
	cls.left_click_stroke_color = settings.colorFromHtml(cfg.left_click_stroke_color)
	cls.right_click_stroke_color = settings.colorFromHtml(cfg.right_click_stroke_color)
	cls.anim_duration = cfg.anim_duration / 1000

	cls.canvas = hs.canvas.new({
		w=cls.circle_radius * 2,
		h=cls.circle_radius * 2,
	})
	cls.canvas:appendElements({
		type="circle",
		radius=cls.circle_radius - math.ceil(cls.stroke_width / 2),
		action="stroke",
		strokeWidth=cls.stroke_width,
	})

	cls.mouse_click_event_tap = hs.eventtap.new({
		event_types.leftMouseDown,
		event_types.leftMouseUp,
		event_types.rightMouseDown,
		event_types.rightMouseUp,
	}, cls._handle_click_event)

	cls.mouse_move_event_tap = hs.eventtap.new({
		event_types.mouseMoved,
		event_types.leftMouseDragged,
		event_types.rightMouseDragged,
	}, cls._refresh_canvas_geometry)

	cls.started = false
	cls.initialized = true
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	cls.mouse_click_event_tap:start()
	cls.started = true
end


function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	cls.mouse_click_event_tap:stop()
	cls.mouse_move_event_tap:stop()
	cls.canvas:hide()
	cls.started = false
end


function cls.unload()
	if not cls.initialized then return end
	cls.stop()
	cls.mouse_click_event_tap = nil
	cls.mouse_move_event_tap = nil
	cls.canvas:delete()
	cls.canvas = nil
	cls.initialized = false
end


function cls._refresh_canvas_geometry()
	local mouse_pos = hs.mouse.absolutePosition()
	cls.canvas:topLeft({
		x=mouse_pos.x - cls.circle_radius,
		y=mouse_pos.y - cls.circle_radius,
	})
end

---@param e Event
function cls._handle_click_event(e)
	local t = e:getType()
	if (
		t == event_types.leftMouseDown or
		t == event_types.rightMouseDown
	) then
		cls._refresh_canvas_geometry()
		cls.canvas[1].radius = cls.circle_radius - math.ceil(cls.stroke_width / 2)
		cls.canvas[1].strokeColor = (
			t == event_types.leftMouseDown
			and cls.left_click_stroke_color
			or cls.right_click_stroke_color
		)
		cls.canvas:show()
		cls.mouse_move_event_tap:start()

	else
		---@type AnimData
		local anim_data = {
			radius={cls.circle_radius, cls.stroke_width},
		}

		---@param step_data AnimStepData
		local function anim_step_func(step_data)
			if not (cls.initialized and cls.started) then return end
			cls.canvas[1].radius = step_data.radius - math.ceil(cls.stroke_width / 2)
		end

		local function anim_done_func()
			if not (cls.initialized and cls.started) then return end
			cls.canvas:hide()
			cls.mouse_move_event_tap:stop()
		end

		anim.animate(anim_data, cls.anim_duration, anim_step_func, anim_done_func)
	end
end


--[[ MODULE ]]

return cls