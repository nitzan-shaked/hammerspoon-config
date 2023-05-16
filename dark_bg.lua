--[[ STATE ]]

local SETTINGS_KEY = "dark_bg"

local light_level = hs.settings.get(SETTINGS_KEY .. ".light_level") or 1
local canvas = nil

--[[ LOGIC ]]

local function init_canvas ()
	canvas = hs.canvas.new({})
	canvas:level(hs.canvas.windowLevels.desktop)
	canvas:_accessibilitySubrole("dark_bg")
	canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor={red=0, green=0, blue=0},
	})
end

local function refresh_canvas_layout ()
	canvas:frame(hs.screen.mainScreen():frame())
end

local function set_light_level (new_light_level)
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

local function darker ()
	set_light_level(light_level - 0.1)
end

local function lighter ()
	set_light_level(light_level + 0.1)
end

--[[ INIT ]]

init_canvas()
refresh_canvas_layout()
set_light_level(light_level)

local watcher = hs.screen.watcher.new(refresh_canvas_layout)

--[[ MODULE ]]

return {
	set_light_level=set_light_level,
	darker=darker,
	lighter=lighter,
}
