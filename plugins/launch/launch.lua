--[[ MODULE ]]

local cls = {}

cls.name = "launch"


--[[ CONFIG ]]

cls.cfg_schema = {
	name=cls.name,
	title="Launch",
	descr="Launch applications and perform actions.",
	items={},
}


--[[ STATE ]]

cls.initialized = false
cls.started = false


--[[ LOGIC ]]

function cls.isInitialized()
	return cls.initialized
end


function cls.init()
	assert(not cls.initialized, "already initialized")
	cls.started = false
	cls.initialized = true
	cls.start()
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	cls.started = true
end


function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	cls.started = false
end


function cls.unload()
	if not cls.initialized then return end
	cls.stop()
	cls.initialized = false
end


function cls.newFinderWindow()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	hs.osascript.applescript([[
		tell application "Finder"
			make new Finder window to home
			activate
		end tell
	]])
end


function cls.newChromeWindow()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	local app = hs.appfinder.appFromName("Google Chrome")
	if not app then
		hs.application.launchOrFocus("Google Chrome")
		return
	end
	if not app:isRunning() then
		return
	end
	hs.osascript.applescript([[
		tell application "Google Chrome"
			make new window
			activate
		end tell
	]])
end


function cls.newIterm2Window()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	-- this is good when iTerm2 is configured with:
	--   "create window on startup?" -> No
	--   "window restoration policy" -> only restore hotkey window
	hs.osascript.applescript([[
		tell application "iTerm"
			create window with default profile
			activate
		end tell
	]])
end


function cls.newWeztermWindow()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	local app = hs.appfinder.appFromName("wezterm")
	if not app then
		hs.application.launchOrFocus("wezterm")
		return
	end
	if not app:isRunning() then
		return
	end
	app:selectMenuItem("New Window")
end


function cls.launchMacPass()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	hs.application.launchOrFocus("MacPass")
end


function cls.launchNotes()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	hs.application.launchOrFocus("Notes")
end


function cls.startScreenSaver()
	assert(cls.initialized, "not initialized")
	assert(cls.started, "not started")
	hs.caffeinate.startScreensaver()
end


--[[ MODULE ]]

return cls
