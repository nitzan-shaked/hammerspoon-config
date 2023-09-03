--[[ LOGIC ]]

local function new_finder_window()
	hs.osascript.applescript([[
		tell application "Finder"
			make new Finder window to home
			activate
		end tell
	]])
end

local function new_chrome_window()
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

local function new_iterm2_window()
	-- this is good when iTerm2 is configured with:
	--   "create window on startup?" -> No
	--   "window restoration policy" -> only restore hotkey window
	hs.osascript.applescript([[
		tell application "iTerm" to create window with default profile
	]])
end

local function new_wezterm_window()
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

local function launch_mac_pass()
	hs.application.launchOrFocus("MacPass")
end

local function launch_notes()
	hs.application.launchOrFocus("Notes")
end

local function start_screen_saver()
	hs.caffeinate.startScreensaver()
end

local function focus_available_app()
	return
end
--[[ MODULE ]]

return {
	new_finder_window=new_finder_window,
	new_chrome_window=new_chrome_window,
	new_iterm2_window=new_iterm2_window,
	new_wezterm_window=new_wezterm_window,
	launch_mac_pass=launch_mac_pass,
	launch_notes=launch_notes,
	start_screen_saver=start_screen_saver,
}
