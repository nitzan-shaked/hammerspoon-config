local settings = require("settings")


--[[ MODULE ]]

local cls = {}

cls.name = "find_mouse_cursor"


--[[ CONFIG ]]

cls.cfg_schema = {
	name=cls.name,
	title="Find Mouse Cursor",
	descr="Highlight the mouse cursor for a short duration.",
	items={{
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
}


--[[ STATE ]]

cls.initialized = false
cls.started = false

cls.highlighting = false
---@type Canvas
cls.canvas = nil
---@type EventTap
cls.mouse_move_event_tap = nil
---@type Timer?
cls.timer = nil


--[[ LOGIC ]]

function cls.isInitialized()
	return cls.initialized
end


function cls.init()
	assert(not cls.initialized, "already initialized")

	local cfg = settings.loadPluginSection(cls.name)
	cls.highlight_duration = cfg.highlight_duration / 1000
	cls.circle_radius = cfg.circle_radius
	cls.stroke_width = cfg.stroke_width
	cls.stroke_color = settings.colorFromHtml(cfg.stroke_color)
	cls.fill_color = settings.colorFromHtml(cfg.fill_color)

	cls.canvas = hs.canvas.new({
		w=cls.circle_radius * 2,
		h=cls.circle_radius * 2,
	})
	cls.canvas:appendElements({
		type="circle",
		radius=cls.circle_radius - math.ceil(cls.stroke_width / 2),
		action="strokeAndFill",
		strokeColor=cls.stroke_color,
		fillColor=cls.fill_color,
		strokeWidth=cls.stroke_width,
	})

	cls.mouse_move_event_tap = hs.eventtap.new(
		{hs.eventtap.event.types.mouseMoved},
		cls._refresh_canvas_geometry
	)
	cls.started = false
	cls.initialized = true
	cls.start()
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	cls.started = true
end


function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	cls.started = false
end


function cls.unload()
	if not cls.initialized then return end
	cls.stop()
	if cls.hotkey then
		cls.hotkey:delete()
		cls.hotkey = nil
	end
	cls.mouse_move_event_tap:stop()
	cls.mouse_move_event_tap = nil
	cls.canvas:delete()
	cls.canvas = nil
	cls.initialized = false
end


function cls.startTimedHighlight()
	assert(cls.initialized, "not initialized")
	cls._stop_highlight()
	cls._start_highlight()
	cls.timer = hs.timer.doAfter(
		cls.highlight_duration,
		cls._stop_highlight
)
end


function cls._start_highlight()
	cls._refresh_canvas_geometry()
	cls.canvas:show()
	cls.mouse_move_event_tap:start()
end


function cls._stop_highlight()
	if cls.timer then
		cls.timer:stop()
		cls.timer = nil
	end
	cls.mouse_move_event_tap:stop()
	cls.canvas:hide()
end


function cls._refresh_canvas_geometry()
	local mouse_pos = hs.mouse.absolutePosition()
	cls.canvas:topLeft({
		x=mouse_pos.x - cls.circle_radius,
		y=mouse_pos.y - cls.circle_radius,
	})
end


--[[ MODULE ]]

return cls
