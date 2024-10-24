local nu = require("utils.number_utils")


--[[ MODULE ]]

local cls = {}

cls.name = "dark_bg"


--[[ CONFIG ]]

cls.cfg_schema = {
	name=cls.name,
	title="Dark Background",
	descr="Darken the screen background to reduce eye strain.",
	items={},
}


--[[ STATE ]]

cls.initialized = false
cls.started = false

---@type number
cls.light_level = nil
---@type Canvas
cls.canvas = nil
---@type Watcher
cls.screen_watcher = nil
---@type Watcher
cls.system_watcher = nil


--[[ LOGIC ]]

function cls.isInitialized()
	return cls.initialized
end


function cls.init()
	assert(not cls.initialized, "already initialized")

	cls.light_level = hs.settings.get(cls.name .. ".light_level") or 1

	cls.canvas = hs.canvas.new({})
	cls.canvas:level(hs.canvas.windowLevels.desktop)
	cls.canvas:_accessibilitySubrole("dark_bg")
	cls.canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor={red=0, green=0, blue=0},
	})

	cls.screen_watcher = hs.screen.watcher.new(cls._refresh_canvas_geometry)

	cls.system_watcher = hs.caffeinate.watcher.new(function (ev_type)
		if (
			ev_type == hs.caffeinate.watcher.screensaverDidStop
			or ev_type == hs.caffeinate.watcher.screensDidUnlock
			or ev_type == hs.caffeinate.watcher.screensDidWake
			or ev_type == hs.caffeinate.watcher.sessionDidBecomeActive
			or ev_type == hs.caffeinate.watcher.didWake
		) then
			cls._refresh_canvas_geometry()
		end
	end)

	cls.started = false
	cls.initialized = true
	cls.start()
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	cls._refresh_canvas_geometry()
	cls.setLightLevel(cls.light_level)
	cls.screen_watcher:start()
	cls.system_watcher:start()
	cls.started = true
end


function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	cls.canvas:hide()
	cls.screen_watcher:stop()
	cls.system_watcher:stop()
	cls.started = false
end


function cls.unload()
	if not cls.initialized then return end
	cls.stop()
	cls.canvas:delete()
	cls.canvas = nil
	cls.screen_watcher = nil
	cls.system_watcher = nil
	cls.initialized = false
end


---@param new_light_level number
function cls.setLightLevel(new_light_level)
	assert(cls.initialized, "not initialized")
	cls.light_level = nu.clip(new_light_level, 0, 1)
	cls.canvas:alpha(1 - cls.light_level)
	if cls.light_level == 1 then
		cls.canvas:hide()
	else
		cls.canvas:show()
	end
	hs.settings.set(cls.name .. ".light_level", cls.light_level)
end


function cls.darker()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	cls.setLightLevel(cls.light_level - 0.1)
end


function cls.lighter()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	cls.setLightLevel(cls.light_level + 0.1)
end


function cls._refresh_canvas_geometry()
	cls.canvas:frame(hs.screen.mainScreen():fullFrame())
end


--[[ MODULE ]]

return cls