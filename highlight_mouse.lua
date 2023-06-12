--[[ CONFIG ]]

local CIRCLE_RADIUS = 30
local STROKE_WIDTH = 5
local STROKE_COLOR = {red=1.0, alpha=1.0}
local FILL_COLOR = {red=1.0, alpha=0.3}

--[[ STATE ]]

---@type Canvas
local canvas

---@type EventTap
local mouse_move_event_tap

---@type Timer?
local timer = nil

---@type Hotkey?
local hotkey = nil

--[[ LOGIC ]]

local function refresh_position()
	local mouse_pos = hs.mouse.absolutePosition()
	canvas:topLeft({
		x=mouse_pos.x - CIRCLE_RADIUS,
		y=mouse_pos.y - CIRCLE_RADIUS,
	})
end

local function start()
	refresh_position()
	canvas:show()
	mouse_move_event_tap:start()
end

local function stop()
	mouse_move_event_tap:stop()
	canvas:hide()
end

local function start_timed()
	if timer then
		timer:stop()
		timer = nil
	end
	start()
	timer = hs.timer.doAfter(3, stop)
end

---@param mods string[]
---@param key string
local function bind_hotkey(mods, key)
	if hotkey then
		hotkey:delete()
	end
	hotkey = hs.hotkey.bind(mods, key, start_timed)
end

--[[ INIT ]]

canvas = hs.canvas.new({
	w=CIRCLE_RADIUS * 2,
	h=CIRCLE_RADIUS * 2,
})
canvas:appendElements({
	type="circle",
	radius=CIRCLE_RADIUS - math.ceil(STROKE_WIDTH / 2),
	action="strokeAndFill",
	strokeColor=STROKE_COLOR,
	fillColor=FILL_COLOR,
	strokeWidth=STROKE_WIDTH,
})

mouse_move_event_tap = hs.eventtap.new(
	{hs.eventtap.event.types.mouseMoved},
	refresh_position
)

--[[ MODULE ]]

return {
	start=start,
	stop=stop,
	bind_hotkey=bind_hotkey,
}
