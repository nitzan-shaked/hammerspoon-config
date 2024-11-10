---@module "hs"

hs.console.clearConsole()

--[[ HS CONFIG ]]

hs.window.animationDuration = 0

--[[ CORE FUNCTIONALITY ]]

local core_modules = require("core_modules")
for _, core_module in pairs(core_modules) do
	core_module:load({})
	core_module:start()
end

--[[ DEBUG ]]

core_modules.hyper:bind("y", hs.toggleConsole)

--[[ PLUGINS ]]

print("-- Loading plugins")
local PluginsManager = require("plugins_manager")
PluginsManager.init("plugins")

--[[ SETTINGS ]]

local SettingsManager = require("settings_manager")
SettingsManager.init(PluginsManager.getPluginsMap())
SettingsManager.reloadSettings()

core_modules.hyper:bind(",", function() SettingsManager.showSettingsDialog(true,  true,  false) end)
core_modules.hyper:bind(".", function() SettingsManager.showSettingsDialog(false, false, true ) end)
