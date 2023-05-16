--[[ STATE ]]

cls = {
	watcher=nil,
}

--[[ LOGIC ]]

cls.start = function ()
	if cls.watcher then return end
	cls.watcher = hs.pathwatcher.new(hs.configdir, function ()
		hs.timer.doAfter(0.25, hs.reload)
	end)
	cls.watcher:start()
end

cls.stop = function ()
	if not cls.watcher then return end
	cls.watcher.stop()
	cls.watcher = nil
end

--[[ MODULE ]]

return cls
