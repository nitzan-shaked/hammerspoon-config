local Module = require("module")
local class = require("utils.class")
local settings = require("settings")


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

    ---@type MenuBar
    self._menubar_item = nil
end


function FenstrMenubarWidget:loadImpl()
    self._menubar_item = hs.menubar.new(true, "fenstr_menubar_widget")
    self._menubar_item:setTitle("F")
    self._menubar_item:setTooltip("Fenstr")
    self._menubar_item:setMenu(function() return self:_create_menu() end)
    self._menubar_item:setIcon([[ASCII:
. . . . . . . . . . . . . . . . . .
. 1 . . . . . . . 5 . . . . . . 1 .
. 4 . . . . . . . . . . . . . . 2 .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . 6 . . . . . . 6 .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . .
. 4 . . . . . . . . . . . . . . 2 .
. 3 . . . . . . . 5 . . . . . . 3 .
. . . . . . . . . . . . . . . . . .
]])
end


function FenstrMenubarWidget:_create_menu()
    local items = {{
        title = "Plugins",
        disabled = true,
    }, {
        title = "-",
        disabled = true,
    }}

    local plugin_names = settings.plugin_names
    local plugins = settings.plugins
    local enabled_plugins = settings.loadEnabledPluginsSetting()

    for _, plugin_name in ipairs(plugin_names) do
        local plugin = plugins[plugin_name]
        local plugin_enabled = enabled_plugins[plugin_name]

        local function on_click()
            enabled_plugins[plugin_name] = not enabled_plugins[plugin_name]
            settings.saveSettings(settings.enabled_plugins_section_schema.name, enabled_plugins)
            settings._reload_settings_fn()
        end

        table.insert(items, {
            title = plugin.title,
            checked = true,
            state = plugin_enabled and "on" or "off",
            fn = on_click,
        })
    end

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
