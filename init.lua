---@module "hs"

hs.console.clearConsole()

--[[ HS CONFIG ]]

hs.window.animationDuration = 0

--[[ CORE FUNCTIONALITY ]]

local core_modules = require("core_modules")
for _, core_module in pairs(core_modules) do
	core_module:load()
	core_module:start()
end

--[[ PLUGINS ]]

print("-- Loading plugins")
local plugins_loader = require("plugins_loader")
local plugins = plugins_loader.load_plugins_from_dir("plugins")

--[[ SETTINGS ]]

local settings = require("settings")
core_modules.hyper:bind(",", function() settings.showSettingsDialog(true, true, true) end)
core_modules.hyper:bind("y", hs.toggleConsole)


local function reload_settings()
	-- unload all plugins
	for _, plugin in pairs(plugins) do
		if plugin.loaded then plugin:unload() end
	end

	-- load all enabled plugins
	local enabled_plugins = settings.loadEnabledPluginsSetting()

	for plugin_name, plugin in pairs(plugins) do
		if enabled_plugins[plugin_name] then
			plugin:load()
		end
	end

	local KBD_WIN_MOVE			= {"ctrl", "cmd"}
	local KBD_WIN_RESIZE		= {"ctrl", "alt"}
	local KBD_DRAG_LIMIT_AXIS	= {"shift"}

	--[[ HYPER-LAUNCH ]]
	if enabled_plugins.launch then
		plugins.launch:start()
		plugins.launch:bindActionsHotkeys({
			newFinderWindow	 = {{"hyper"}, "f"},
			newChromeWindow	 = {{"hyper"}, "b"},
			newIterm2Window	 = {{"hyper"}, "t"},
			launchMacPass	 = {{"hyper"}, "k"},
			launchNotes		 = {{"hyper"}, "n"},
			startScreenSaver = {{"hyper"}, "l"},
		})
	end

	--[[ WIN-MOUSE ]]
	if enabled_plugins.win_mouse then
		plugins.win_mouse:start()
		plugins.win_mouse:setKbdMods(KBD_WIN_MOVE, KBD_WIN_RESIZE, KBD_DRAG_LIMIT_AXIS)
	end

	--[[ WIN-KBD ]]
	if enabled_plugins.win_kbd then
		plugins.win_kbd:start()
		plugins.win_kbd:setKbdMods(KBD_WIN_MOVE, KBD_WIN_RESIZE)
	end

	--[[ DARK-BG ]]
	if enabled_plugins.dark_bg then
		plugins.dark_bg:start()
		plugins.dark_bg:bindActionsHotkeys({
			darker  = {KBD_WIN_MOVE, "-"},
			lighter = {KBD_WIN_MOVE, "="},
		})
	end

	--[[ FIND-MOUSE-CURSOR ]]
	if enabled_plugins.find_mouse_cursor then
		plugins.find_mouse_cursor:start()
		plugins.find_mouse_cursor:bindActionsHotkeys({
			highlight = {KBD_WIN_MOVE, "m"},
		})
	end

	--[[ VIZ-MOUSE-CLICKS ]]
	if enabled_plugins.viz_mouse_clicks then
		plugins.viz_mouse_clicks:start()
	end

	--[[ VIZ-MOUSE-CLICKS ]]
	if enabled_plugins.viz_key_strokes then
		plugins.viz_key_strokes:start()
	end

end

settings.init(plugins, reload_settings)
reload_settings()
