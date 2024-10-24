--[[ MODULE ]]

local cls = {}

cls.name = "reload"


--[[ CONFIG ]]

cls.cfg_schema = nil


--[[ STATE ]]

cls.initialized = false
cls.started = false

---@type PathWatcher
cls.watcher = nil


--[[ LOGIC ]]

function cls.init()
	assert(not cls.initialized, "already initialized")
	cls.watcher = hs.pathwatcher.new(hs.configdir, function ()
		hs.timer.doAfter(0.25, hs.reload)
	end)
	cls.started = false
	cls.initialized = true
	cls.start()
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	cls.watcher:start()
	cls.started = true
end


function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	cls.watcher:stop()
	cls.started = false
end


function cls.unload()
	assert(cls.initialized, "not initialized")
	cls.stop()
	cls.watcher = nil
	cls.initialized = false
end


--[[ MODULE ]]

return cls
