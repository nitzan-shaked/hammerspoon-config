local Module = require("module")
local class = require("utils.class")
local PluginsManager = require("plugins_manager")
local SettingsManager = require("settings_manager")


---@class FenstrMenubarWidget: Module
local FenstrMenubarWidget = class.make_class("FenstrMenubarWidget", Module)


function FenstrMenubarWidget:__init__()
	Module.__init__(
		self,
		"fenstr_menubar_widget",
		"Menubar Widget",
		"A menubar widget for controlling Fenstr.",
		{},
		{}
	)
end


function FenstrMenubarWidget:loadImpl()
    self._menubar_item = hs.menubar.new(true, "fenstr_menubar_widget")
    self._menubar_item:setTitle(hs.styledtext.new(
        "F",
        {
            font={name="Academy Engraved LET", size=20},
            baselineOffset=-2.0,
        }
    ))
    self._menubar_item:setIcon([[ASCII:
. . . . . . . . . . . . . . . . . .
. 1 # # # # # # # 5 # # # # # # 1 .
. 4 . . . . . . . # . . . . . . 2 .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . 6 # # # # # # 6 .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. # . . . . . . . # . . . . . . # .
. 4 . . . . . . . # . . . . . . 2 .
. 3 # # # # # # # 5 # # # # # # 3 .
. . . . . . . . . . . . . . . . . .
]])
    self._menubar_item:setTooltip("Fenstr")
    self._menubar_item:setMenu(function() return self:_create_menu() end)
end


function FenstrMenubarWidget:_create_menu()
    local items = {{
        title = "Fenster",
        disabled = true,
    }, {
        title = "-",
        disabled = true,
    }}

    local plugins = PluginsManager.getPluginsMap()
    local enabled_plugins = SettingsManager.loadEnabledPlugins()

    for _, plugin_name in ipairs(SettingsManager.pluginsOrder()) do
        local plugin = plugins[plugin_name]
        local plugin_enabled = enabled_plugins[plugin_name]

        local function on_click()
            enabled_plugins[plugin_name] = not enabled_plugins[plugin_name]
            SettingsManager.saveEnabledPlugins(enabled_plugins)
        end

        table.insert(items, {
            title = plugin.title,
            checked = true,
            state = plugin_enabled and "on" or "off",
            fn = on_click,
        })
    end

    table.insert(items, {
        title = "-",
        disabled = true,
    })
    table.insert(items, {
        title = "Settings...",
        fn = function() SettingsManager.showSettingsDialog(false, true, false) end,
    })
    table.insert(items, {
        title = "Hotkeys...",
        fn = function() SettingsManager.showSettingsDialog(false, false, true) end,
    })

    return items
end


function FenstrMenubarWidget:startImpl()
    self._menubar_item:returnToMenuBar()
end


function FenstrMenubarWidget:stopImpl()
    self._menubar_item:removeFromMenuBar()
end


function FenstrMenubarWidget:unloadImpl()
	self._menubar_item:delete()
	self._menubar_item = nil
end


return FenstrMenubarWidget()
