--[[ CONFIG ]]

local SETTINGS_KEY = "dark_bg"

--[[ STATE ]]

---@type number
local light_level = hs.settings.get(SETTINGS_KEY .. ".light_level") or 1

---@type Canvas?
local canvas = nil

--[[ LOGIC ]]

local function init_canvas()
	assert(canvas == nil)
	canvas = hs.canvas.new({})
	canvas:level(hs.canvas.windowLevels.desktop)
	canvas:_accessibilitySubrole("dark_bg")
	canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor={red=0, green=0, blue=0},
	})
end

local function refresh_canvas_layout()
	assert(canvas)
	canvas:frame(hs.screen.mainScreen():frame())
end

---@param new_light_level number
local function set_light_level(new_light_level)
	assert(canvas)

	light_level = (
		new_light_level < 0 and 0
		or new_light_level > 1 and 1
		or new_light_level
	)

	canvas:alpha(1 - light_level)
	if light_level == 1 then
		canvas:hide()
	else
		canvas:show()
	end
	hs.settings.set(SETTINGS_KEY .. ".light_level", light_level)
end

local function darker()
	set_light_level(light_level - 0.1)
end

local function lighter()
	set_light_level(light_level + 0.1)
end

--[[ INIT ]]

init_canvas()
refresh_canvas_layout()
set_light_level(light_level)

local screen_watcher = hs.screen.watcher.new(refresh_canvas_layout)
screen_watcher:start()

local system_watcher = hs.caffeinate.watcher.new(function (ev_type)
	if (
		ev_type == hs.caffeinate.watcher.screensaverDidStop
		or ev_type == hs.caffeinate.watcher.screensDidUnlock
		or ev_type == hs.caffeinate.watcher.screensDidWake
		or ev_type == hs.caffeinate.watcher.sessionDidBecomeActive
		or ev_type == hs.caffeinate.watcher.didWake
	) then
		refresh_canvas_layout()
	end
end)
system_watcher:start()

--[[ MODULE ]]

return {
	watchers={screen_watcher, system_watcher},
	set_light_level=set_light_level,
	darker=darker,
	lighter=lighter,
}
