---@module "hs"

hs.console.clearConsole()

--[[ CONFIG ]]

hs.window.animationDuration = 0


--[[ CORE FUNCTIONALITY ]]

local modules_loader = require("modules_loader")

print("-- Loading CORE modules")
local core = modules_loader.load_modules_from_dir("core")
for _, core_module in pairs(core) do
	core_module.init()
end
local hyper = core.hyper_or_esc


--[[ PLUGINS ]]

print("-- Loading plugins")
local plugins = modules_loader.load_modules_from_dir("plugins")

local settings = require("settings")
settings.init(plugins)


--[[ HOTKEYS FOR PLUGINS ]]

---@type table<string, table<string, Hotkey>>
local plugin_hotkeys = {}
---@type table<string, table<string, boolean>>
local plugin_hyper_keys = {}

---@param plugin_name string
---@param mods string[]
---@param key string
---@param fn fun()
local function bind_plugin_hotkey(plugin_name, mods, key, fn)
	if not plugin_hotkeys[plugin_name] then
		plugin_hotkeys[plugin_name] = {}
	end
	local hotkey = hs.hotkey.bind(mods, key, fn)
	table.insert(plugin_hotkeys[plugin_name], hotkey)
end

---@param plugin_name string
---@param key string
---@param fn fun()
local function bind_plugin_hyper_key(plugin_name, key, fn, with_repeat)
	if not plugin_hyper_keys[plugin_name] then
		plugin_hyper_keys[plugin_name] = {}
	end
	hyper.bind(key, fn, with_repeat)
	plugin_hyper_keys[plugin_name][key] = true
end

---@param plugin_name string
local function clear_plugin_hotkeys(plugin_name)
	for _, hotkey in ipairs(plugin_hotkeys[plugin_name] or {}) do
		hotkey:disable()
		hotkey:delete()
	end
	plugin_hotkeys[plugin_name] = nil
	for key, _ in pairs(plugin_hyper_keys[plugin_name] or {}) do
		hyper.unbind(key)
	end
	plugin_hyper_keys[plugin_name] = nil
end


local function reload_config()
	local enabled_features_map = settings.loadFeaturesSection()
	local newly_initialized_plugins = {}

	for plugin_name, plugin in pairs(plugins) do
		-- if plugin.isInitialized() and not enabled_features_map[plugin_name] then
		if plugin.isInitialized() then
			plugin.unload()
			clear_plugin_hotkeys(plugin_name)
		end
		if enabled_features_map[plugin_name] and not plugin.isInitialized() then
			plugin.init()
			newly_initialized_plugins[plugin_name] = true
		end
	end

	local KBD_WIN_PLACE			= {"ctrl", "cmd"}
	local KBD_WIN_MOVE			= {"ctrl", "cmd"}
	local KBD_WIN_RESIZE		= {"ctrl", "alt"}
	local KBD_DRAG_LIMIT_AXIS	= {"shift"}

	--[[ HYPER-LAUNCH ]]
	if newly_initialized_plugins.launch then
		local launch = plugins.launch
		bind_plugin_hyper_key("launch", "f", launch.newFinderWindow)
		bind_plugin_hyper_key("launch", "b", launch.newChromeWindow)
		bind_plugin_hyper_key("launch", "t", launch.newIterm2Window)
		bind_plugin_hyper_key("launch", "k", launch.launchMacPass)
		bind_plugin_hyper_key("launch", "n", launch.launchNotes)
		bind_plugin_hyper_key("launch", "l", launch.startScreenSaver)
	end

	--[[ WIN-MOUSE ]]
	if newly_initialized_plugins.win_mouse then
		local win_mouse = plugins.win_mouse
		win_mouse.setKbdMods(KBD_WIN_MOVE, KBD_WIN_RESIZE, KBD_DRAG_LIMIT_AXIS)
	end

	--[[ WIN-KBD ]]
	if newly_initialized_plugins.win_kbd then
		local win_kbd = plugins.win_kbd
		win_kbd.bindHotkeys(KBD_WIN_PLACE, KBD_WIN_MOVE, KBD_WIN_RESIZE)
	end

	--[[ DARK-BG ]]
	if newly_initialized_plugins.dark_bg then
		local dark_bg = plugins.dark_bg
		bind_plugin_hyper_key("dark_bg", "-", dark_bg.darker, true)
		bind_plugin_hyper_key("dark_bg", "=", dark_bg.lighter, true)
	end

	--[[ FIND-MOUSE-CURSOR ]]
	if newly_initialized_plugins.find_mouse_cursor then
		local find_mouse_cursor = plugins.find_mouse_cursor
		bind_plugin_hotkey("find_mouse_cursor", KBD_WIN_MOVE, "m", find_mouse_cursor.startTimedHighlight)
	end

	--[[ VIZ-MOUSE-CLICKS ]]
	if newly_initialized_plugins.viz_mouse_clicks then
		local viz_mouse_clicks = plugins.viz_mouse_clicks
		viz_mouse_clicks.start()
	end

	--[[ VIZ-MOUSE-CLICKS ]]
	if newly_initialized_plugins.viz_key_strokes then
		local viz_key_strokes = plugins.viz_key_strokes
		viz_key_strokes.start()
	end

end

hyper.bind(",", function() settings.showDialog(reload_config) end)
hyper.bind("y", hs.toggleConsole)

reload_config()
