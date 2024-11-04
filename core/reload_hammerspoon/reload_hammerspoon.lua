local Module = require("module")
local class = require("utils.class")


---@class Reload: Module
local ReloadHammerspoon = class.make_class("ReloadHammerspoon", Module)



function ReloadHammerspoon:__init__()
	Module.__init__(
		self,
		"reload_hammerspoon",
		"Reload Hammerspoon",
		"Reload Hammerspoon when ~/.hammerspoon changes.",
		{},
		{}
	)

	---@type PathWatcher
	self._watcher = nil
end


function ReloadHammerspoon:loadImpl()
	self._watcher = hs.pathwatcher.new(hs.configdir, function ()
		hs.timer.doAfter(0.25, hs.reload)
	end)
end


function ReloadHammerspoon:startImpl()
	self._watcher:start()
end


function ReloadHammerspoon:stopImpl()
	self._watcher:stop()
end


function ReloadHammerspoon:unloadImpl()
	self._watcher = nil
end


return ReloadHammerspoon()
