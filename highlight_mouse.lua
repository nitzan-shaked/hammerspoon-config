--[[ CONFIG ]]

local CIRCLE_RADIUS = 30
local STROKE_WIDTH = 5

--[[ STATE ]]

local cls = {
	canvas=nil,
	timer=nil,
	mouse_event_tap=nil,
	hotkey=nil,
}

--[[ LOGIC ]]

cls.stop = function ()
	if cls.mouse_event_tap then
		cls.mouse_event_tap:stop()
		cls.mouse_event_tap = nil
	end
	if cls.timer then
		cls.timer:stop()
		cls.timer = nil
	end
	if cls.canvas then
		cls.canvas:delete()
		cls.canvas = nil
	end
end

cls.refresh_position = function ()
	if not cls.canvas then
		cls.stop()
		return
	end
	local mouse_pos = hs.mouse.getAbsolutePosition()
	cls.canvas:topLeft({
		x=mouse_pos.x - CIRCLE_RADIUS,
		y=mouse_pos.y - CIRCLE_RADIUS,
	})
end

cls.show = function ()
	if not cls.canvas then
		cls.canvas = hs.canvas.new({
			w=CIRCLE_RADIUS * 2,
			h=CIRCLE_RADIUS * 2,
		})
		cls.canvas:appendElements({
			type="circle",
			center={x=CIRCLE_RADIUS, y=CIRCLE_RADIUS},
			radius=CIRCLE_RADIUS - math.ceil(STROKE_WIDTH / 2),
			action="strokeAndFill",
			strokeColor={red=1.0, alpha=1.0},
			fillColor={red=1.0, alpha=0.3},
			strokeWidth=STROKE_WIDTH,
		})
	end
	cls.refresh_position()
	cls.canvas:show()

	if not cls.mouse_event_tap then
		cls.mouse_event_tap = hs.eventtap.new(
			{hs.eventtap.event.types.mouseMoved},
			cls.refresh_position
		)
		cls.mouse_event_tap:start()
	end

	if cls.timer then
		cls.timer:stop()
	end
	cls.timer = hs.timer.doAfter(3, cls.stop)
end

cls.bind_hotkey = function (mods, key)
	if cls.hotkey then
		cls.hotkey:delete()
	end
	cls.hotkey = hs.hotkey.bind(mods, key, cls.show)
end

--[[ MODULE ]]

return cls
