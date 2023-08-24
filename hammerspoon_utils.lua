
--[[ STATE ]]

local hammerspoon_app_bundle_id = "org.hammerspoon.Hammerspoon"
local hammerspoon_app = assert(hs.application.get(hammerspoon_app_bundle_id))

--[[ LOGIC ]]

local function open_debug_console()
	hs.console.toolbar(nil)
	hs.console.level(hs.canvas.windowLevels.floating)
	hs.console.alpha(0.9)
	local console_font = hs.console.consoleFont()
	console_font.size = 8
	hs.console.consoleFont(console_font)

	hs.openConsole()
	local console_window = hs.console.hswindow()
	local console_screen = console_window:screen()
	console_window:setSize(hs.geometry.size(300, 500))
	console_window:setTopLeft(hs.geometry(
		console_screen:frame().x2 - console_window:frame().w,
		console_screen:frame().y1
	))

	hs.timer.doAfter(0, hs.console.clearConsole)
	hs.timer.usleep(1)
end

--[[ MODULE ]]

return {
	hammerspoon_app=hammerspoon_app,
	hammerspoon_app_bundle_id=hammerspoon_app_bundle_id,
	open_debug_console=open_debug_console,
}
