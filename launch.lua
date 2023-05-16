--[[ STATE ]]

cls = {}

--[[ LOGIC ]]

cls.new_finder_window = function ()
	hs.osascript.applescript([[
tell application "Finder"
    make new Finder window to home
    activate
end tell]])
end

cls.new_chrome_window = function ()
	local app = hs.appfinder.appFromName("Google Chrome")
	if not app then
		hs.application.launchOrFocus("Google Chrome")
		return
	end
	if app:isRunning() then
		hs.osascript.applescript([[
tell application "Google Chrome"
    make new window
    activate
end tell]])
	end
end

cls.new_iterm2_window = function ()
	-- this is good when iTerm2 is configured with:
	--   "create window on startup?" -> No
	--   "window restoration policy" -> only restore hotkey window
	hs.osascript.applescript(
		"tell application \"iTerm\" to create window with default profile"
	)
end

cls.new_iterm2_window_ssh_foreshadow = function ()
	-- this is good when iTerm2 is configured with:
	--   "create window on startup?" -> No
	--   "window restoration policy" -> only restore hotkey window
	hs.osascript.applescript([[
tell application "iTerm"
	create window with profile "ssh_foreshadow"
end tell]])
end

cls.new_iterm2_window_tmux_foreshadow = function ()
	-- this is good when iTerm2 is configured with:
	--   "create window on startup?" -> No
	--   "window restoration policy" -> only restore hotkey window
	hs.osascript.applescript([[
tell application "iTerm"
	set existingWindows to windows whose (profile name of current session) is "foreshadow"
	if length of existingWindows is not 0 then
		select first item of existingWindows
	else
		create window with profile "foreshadow"
	end if
end tell]])
end

cls.launch_mac_pass = function ()
	hs.application.launchOrFocus("MacPass")
end

cls.launch_notes = function ()
	hs.application.launchOrFocus("Notes")
end

cls.start_screen_saver = function ()
	hs.caffeinate.startScreensaver()
end

--[[ MODULE ]]

return cls
