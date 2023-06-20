local anim = require("utils.animate")

--[[ CONFIG ]]

local CIRCLE_RADIUS = 35
local STROKE_WIDTH = 2
local LEFT_CLICK_STROKE_COLOR  = {red=1.0, green=1.0, blue=0.0, alpha=1.0}
local RIGHT_CLICK_STROKE_COLOR = {red=1.0, green=0.0, blue=1.0, alpha=1.0}

local ANIM_DURATION = 0.225

--[[ STATE ]]

---@type Canvas
local canvas

---@type EventTap
local mouse_click_event_tap

---@type EventTap
local mouse_move_event_tap

--[[ LOGIC ]]

local event_types = hs.eventtap.event.types

local function refresh_position()
	assert(canvas)
	local mouse_pos = hs.mouse.absolutePosition()
	canvas:topLeft({
		x=mouse_pos.x - CIRCLE_RADIUS,
		y=mouse_pos.y - CIRCLE_RADIUS,
	})
end

---@param e Event
local function handle_click_event(e)
	local t = e:getType()
	if (
		t == event_types.leftMouseDown or
		t == event_types.rightMouseDown
	) then
		refresh_position()
		canvas[1].radius = CIRCLE_RADIUS - math.ceil(STROKE_WIDTH / 2)
		canvas[1].strokeColor = (
			t == event_types.leftMouseDown
			and LEFT_CLICK_STROKE_COLOR
			or RIGHT_CLICK_STROKE_COLOR
		)
		canvas:show()
		mouse_move_event_tap:start()

	else
		---@type AnimData
		local anim_data = {
			radius={CIRCLE_RADIUS, STROKE_WIDTH},
		}

		---@param step_data AnimStepData
		local function anim_step_func(step_data)
			canvas[1].radius = step_data.radius - math.ceil(STROKE_WIDTH / 2)
		end

		local function anim_done_func()
			canvas:hide()
			mouse_move_event_tap:stop()
		end

		anim.animate(anim_data, ANIM_DURATION, anim_step_func, anim_done_func)
	end
end

local function start()
	mouse_click_event_tap:start()
end

local function stop()
	mouse_click_event_tap:stop()
	mouse_move_event_tap:stop()
	canvas:hide()
end

--[[ INIT ]]

canvas = hs.canvas.new({
	w=CIRCLE_RADIUS * 2,
	h=CIRCLE_RADIUS * 2,
})
canvas:appendElements({
	type="circle",
	radius=CIRCLE_RADIUS - math.ceil(STROKE_WIDTH / 2),
	action="stroke",
	strokeWidth=STROKE_WIDTH,
})

mouse_click_event_tap = hs.eventtap.new({
	event_types.leftMouseDown,
	event_types.leftMouseUp,
	event_types.rightMouseDown,
	event_types.rightMouseUp,
}, handle_click_event)

mouse_move_event_tap = hs.eventtap.new({
	event_types.mouseMoved,
	event_types.leftMouseDragged,
	event_types.rightMouseDragged,
}, refresh_position)

--[[ MODULE ]]

return {
	start=start,
	stop=stop,
}
