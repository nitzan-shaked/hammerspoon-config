local Module = require("module")
local class = require("utils.class")
local nu = require("utils.number_utils")


---@class DarkBg: Module
local DarkBg = class.make_class("DarkBg", Module)


function DarkBg:__init__()
	Module.__init__(
		self,
		"dark_bg",
		"Dark Background",
		"Darken the desktop background to reduce eye strain.",
		{},
		{{
			name="darker",
			title="Darker",
			descr="Make the desktop background darker.",
			fn=function() self:darker() end,
			default={"ctrl", "cmd", "-"},
		}, {
			name="lighter",
			title="Lighter",
			descr="Make the desktop background lighter.",
			fn=function() self:lighter() end,
			default={"ctrl", "cmd", "="},
		}}
	)

	---@type number
	self._light_level = nil
	---@type Canvas
	self._canvas = nil
	---@type Watcher
	self._screen_watcher = nil
	---@type Watcher
	self._system_watcher = nil
end


function DarkBg:loadImpl()
	self._light_level = hs.settings.get(self.name .. ".light_level") or 1

	self._canvas = hs.canvas.new({})
	self._canvas:level(hs.canvas.windowLevels.desktop)
	self._canvas:_accessibilitySubrole("dark_bg")
	self._canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor={red=0, green=0, blue=0},
	})

	self._screen_watcher = hs.screen.watcher.new(function() self:_refresh_canvas_geometry() end)

	self._system_watcher = hs.caffeinate.watcher.new(function (ev_type)
		if (
			ev_type == hs.caffeinate.watcher.screensaverDidStop
			or ev_type == hs.caffeinate.watcher.screensDidUnlock
			or ev_type == hs.caffeinate.watcher.screensDidWake
			or ev_type == hs.caffeinate.watcher.sessionDidBecomeActive
			or ev_type == hs.caffeinate.watcher.didWake
		) then
			self:_refresh_canvas_geometry()
		end
	end)
end


function DarkBg:startImpl()
	self:_refresh_canvas_geometry()
	self._screen_watcher:start()
	self._system_watcher:start()
end


function DarkBg:didStart()
	self:setLightLevel(self._light_level)
end


function DarkBg:stopImpl()
	self._canvas:hide()
	self._screen_watcher:stop()
	self._system_watcher:stop()
end


function DarkBg:unloadImpl()
	self._canvas:delete()
	self._canvas = nil
	self._screen_watcher = nil
	self._system_watcher = nil
end


---@param new_light_level number
function DarkBg:setLightLevel(new_light_level)
	self:_check_loaded_and_started()
	self._light_level = nu.clip(new_light_level, 0, 1)
	self._canvas:alpha(1 - self._light_level)
	if self._light_level == 1 then
		self._canvas:hide()
	else
		self._canvas:show()
	end
	hs.settings.set(self.name .. ".light_level", self._light_level)
end


function DarkBg:darker()
	self:_check_loaded_and_started()
	self:setLightLevel(self._light_level - 0.1)
end


function DarkBg:lighter()
	self:_check_loaded_and_started()
	self:setLightLevel(self._light_level + 0.1)
end


function DarkBg:_refresh_canvas_geometry()
	self._canvas:frame(hs.screen.mainScreen():fullFrame())
end


return DarkBg()
