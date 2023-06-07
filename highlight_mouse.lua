--[[ CONFIG ]]

local CIRCLE_RADIUS = 30
local STROKE_WIDTH = 5

--[[ STATE ]]

---@type Canvas?
local canvas = nil

---@type Timer?
local timer = nil

---@type EventTap?
local mouse_event_tap = nil

---@type Hotkey?
local hotkey = nil

--[[ LOGIC ]]

local function stop()
	if mouse_event_tap then
		mouse_event_tap:stop()
		mouse_event_tap = nil
	end
	if timer then
		timer:stop()
		timer = nil
	end
	if canvas then
		canvas:delete()
		canvas = nil
	end
end

local function refresh_position()
	if not canvas then
		stop()
		return
	end
	local mouse_pos = hs.mouse.absolutePosition()
	canvas:topLeft({
		x=mouse_pos.x - CIRCLE_RADIUS,
		y=mouse_pos.y - CIRCLE_RADIUS,
	})
end

local function show()
	if not canvas then
		canvas = hs.canvas.new({
			w=CIRCLE_RADIUS * 2,
			h=CIRCLE_RADIUS * 2,
		})
		canvas:appendElements({
			type="circle",
			center={x=CIRCLE_RADIUS, y=CIRCLE_RADIUS},
			radius=CIRCLE_RADIUS - math.ceil(STROKE_WIDTH / 2),
			action="strokeAndFill",
			strokeColor={red=1.0, alpha=1.0},
			fillColor={red=1.0, alpha=0.3},
			strokeWidth=STROKE_WIDTH,
		})
	end
	refresh_position()
	canvas:show()

	if not mouse_event_tap then
		mouse_event_tap = hs.eventtap.new(
			{hs.eventtap.event.types.mouseMoved},
			refresh_position
		)
		mouse_event_tap:start()
	end

	if timer then
		timer:stop()
	end
	timer = hs.timer.doAfter(3, stop)
end

---@param mods string[]
---@param key string
local function bind_hotkey(mods, key)
	if hotkey then
		hotkey:delete()
	end
	hotkey = hs.hotkey.bind(mods, key, show)
end

--[[ MODULE ]]

return {
	show=show,
	bind_hotkey=bind_hotkey,
}
