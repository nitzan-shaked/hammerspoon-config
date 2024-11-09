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
core_modules.hyper:bind(",", function() settings.showSettingsDialog(true,  true,  false) end)
core_modules.hyper:bind(".", function() settings.showSettingsDialog(false, false, true ) end)
core_modules.hyper:bind("y", hs.toggleConsole)


local function bind_plugin_hotkeys_from_settings(plugin)
	local actions = plugin.actions
	local plugin_hotkeys = settings.loadPluginHotkeys(plugin.name)
	local spec = {}
	local n_specs = 0
	for _, action in ipairs(actions) do
		local phk = plugin_hotkeys[action.name]
		if phk == nil then goto next_action end
		local mods = phk[1]
		local key = phk[2]
		if mods == nil or #mods == 0 or key == nil then goto next_action end
		spec[action.name] = {mods, key}
		n_specs = n_specs + 1
		::next_action::
	end
	if n_specs > 0 then
		plugin:bindActionsHotkeys(spec)
	end
end


local function reload_settings()
	-- unload all plugins
	for _, plugin in pairs(plugins) do
		if plugin.loaded then plugin:unload() end
	end

	-- load all enabled plugins, bind their action hotkeys and start them
	local enabled_plugins = settings.loadEnabledPlugins()

	for plugin_name, plugin in pairs(plugins) do
		if not enabled_plugins[plugin_name] then goto next_plugin end
		plugin:load()
		bind_plugin_hotkeys_from_settings(plugin)
		plugin:start()
		::next_plugin::
	end

	--[[ HYPER-LAUNCH ]]
	if enabled_plugins.launch then
		plugins.launch:bindActionsHotkeys({
			newFinderWindow	 = {{"hyper"}, "f"},
			newChromeWindow	 = {{"hyper"}, "b"},
			newIterm2Window	 = {{"hyper"}, "t"},
			launchMacPass	 = {{"hyper"}, "k"},
			launchNotes		 = {{"hyper"}, "n"},
			startScreenSaver = {{"hyper"}, "l"},
		})
	end
end

settings.init(plugins, reload_settings)
reload_settings()
