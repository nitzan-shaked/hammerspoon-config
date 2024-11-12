local json = require("hs.json")
local screen = require("hs.screen")
local webview = require("hs.webview")
local usercontent = require("hs.webview.usercontent")
local spoons = require("hs.spoons")

local class = require("utils.class")
local WebServer = require("utils.web_server")
local su = require("utils.settings_utils")


---@alias SectionSchema {name: string, title: string, descr: string, items: SettingsItem[]}
---@alias SectionValues table<string, any>


---@class SettingsManager: Class
local cls = class.make_class("SettingsManager")
cls._initialized = false


---@param plugins table<string, Module>
function cls.init(plugins)
	assert(not cls._initialized, "SettingsManager is already initialized")
	cls._plugins = plugins

	cls._plugins_order = {}
	for plugin_name, _ in pairs(plugins) do
		table.insert(cls._plugins_order, plugin_name)
	end
	table.sort(cls._plugins_order)

	local enabled_plugins_section_items = {}
	for plugin_name, plugin in pairs(cls._plugins) do
		local plugin_title = plugin.settings_schema.title
		table.insert(enabled_plugins_section_items, {
			name=plugin_name,
			descr=plugin_title,
			control="checkbox",
			default=false,
		})
	end
	cls._enabled_plugins_section_schema = {
		name="plugins",
		title="Plugins",
		items=enabled_plugins_section_items,
	}

	---@type table<string, SectionSchema>
	cls._plugin_hotkeys_section_schema = {}
	for _, plugin_name in ipairs(cls._plugins_order) do
		local plugin = cls._plugins[plugin_name]
		local plugin_title = plugin.settings_schema.title
		local plugin_hotkeys_schema = {
			name=plugin_name .. ".hotkeys",
			title=plugin_title .. ": Hotkeys",
			items={},
		}
		for _, action in ipairs(plugin.actions) do
			table.insert(plugin_hotkeys_schema.items, {
				name=action.name,
				title=action.title,
				descr=action.descr,
				control="hotkey",
				default=action.default or {},
			})
		end
		cls._plugin_hotkeys_section_schema[plugin_name] = plugin_hotkeys_schema
	end

	cls._web_server = WebServer(spoons.scriptPath() .. "web")
	cls._initialized = true
end


function cls.pluginsOrder()
	assert(cls._initialized, "SettingsManager is not initialized")
	return cls._plugins_order
end


---@return SectionValues
function cls.loadEnabledPlugins()
	assert(cls._initialized, "SettingsManager is not initialized")
	return cls._load_settings(
		cls._enabled_plugins_section_schema
	)
end


---@param enabled_plugins_values SectionValues
function cls.saveEnabledPlugins(enabled_plugins_values)
	assert(cls._initialized, "SettingsManager is not initialized")
	cls._save_settings(
		cls._enabled_plugins_section_schema.name,
		enabled_plugins_values
	)
	cls.reloadSettings()
end


---@param plugin_name string
---@return SectionValues
function cls.loadPluginSettings(plugin_name)
	assert(cls._initialized, "SettingsManager is not initialized")
	local retval = cls._load_plugin_settings(plugin_name)
	return cls._xlat_html_values_to_lua(
		cls._plugins[plugin_name].settings_schema,
		retval
	)
end


---@param plugin_name string
---@return SectionValues
function cls.loadPluginHotkeys(plugin_name)
	assert(cls._initialized, "SettingsManager is not initialized")
	local retval = cls._load_plugin_hotkeys(plugin_name)
	return cls._xlat_html_values_to_lua(
		cls._plugin_hotkeys_section_schema[plugin_name],
		retval
	)
end


function cls.reloadSettings()
	-- unload all plugins
	for _, plugin in pairs(cls._plugins) do
		if plugin.loaded then plugin:unload() end
	end

	-- load all enabled plugins, bind their action hotkeys and start them
	local enabled_plugins = cls.loadEnabledPlugins()
	for plugin_name, plugin in pairs(cls._plugins) do
		if not enabled_plugins[plugin_name] then goto next_plugin end
		plugin:load(cls.loadPluginSettings(plugin_name))
		plugin:bindActionsHotkeys(cls.loadPluginHotkeys(plugin_name))
		plugin:start()
		::next_plugin::
	end
end


---@param show_enabled_plugins_section boolean
---@param show_plugins_settings boolean
---@param show_plugins_hotkeys boolean
function cls.showSettingsDialog(
	show_enabled_plugins_section,
	show_plugins_settings,
	show_plugins_hotkeys
)
	assert(cls._initialized, "SettingsManager is not initialized")
	local sections_schemas = {}
	local sections_values = {}

	if show_enabled_plugins_section then
		table.insert(sections_schemas, cls._enabled_plugins_section_schema)
		table.insert(sections_values,  cls.loadEnabledPlugins())
	end

	for _, plugin_name in ipairs(cls._plugins_order) do
		local plugin = cls._plugins[plugin_name]

		local plugin_settings_schema = plugin.settings_schema
		if show_plugins_settings and #plugin_settings_schema.items > 0 then
			table.insert(sections_schemas, plugin_settings_schema)
			table.insert(sections_values,  cls._load_plugin_settings(plugin_name))
		end

		local plugin_hotkeys_schema = cls._plugin_hotkeys_section_schema[plugin_name]
		if show_plugins_hotkeys and #plugin_hotkeys_schema.items > 0 then
			table.insert(sections_schemas, plugin_hotkeys_schema)
			table.insert(sections_values,  cls._load_plugin_hotkeys(plugin_name))
		end
	end

	local function escape_for_js(str)
		return str:gsub("\\", "\\\\")   -- Escape backslashes
				  :gsub("\"", "\\\"")   -- Escape double quotes
				  :gsub("\n", "\\n")    -- Escape newlines
				  :gsub("\r", "\\r")    -- Escape carriage returns
				  :gsub("\t", "\\t")    -- Escape tabs
	end

	local js_source=[[
		window.RUNNING_IN_HAMMERSPOON = true;
		window.SECTIONS_SCHEMAS = JSON.parse("]] .. escape_for_js(json.encode(sections_schemas)) .. [[");
		window.SECTIONS_VALUES  = JSON.parse("]] .. escape_for_js(json.encode(sections_values))  .. [[");
	]]
	-- print(js_source)

	local controller = usercontent.new("settings_dialog")
	controller:injectScript({
		source=js_source,
		injectionTime="documentStart",
	})

	local frame = screen:primaryScreen():frame():copy()
	frame.w = 600
	frame.h = frame.h * 3 / 4
	frame.center = screen:primaryScreen():frame().center
	local options = {
		developerExtrasEnabled=true,
	}

	local drawing = require("hs.drawing")
	local browser = webview.new(frame, options, controller)
		:windowStyle({"titled", "closable", "nonactivating"})
		:behavior(drawing.windowBehaviors.managed)
		:closeOnEscape(true)
		:deleteOnClose(true)
		:bringToFront(true)
		:allowTextEntry(true)
		:transparent(false)

	controller:setCallback(function(message)
		browser:delete()
		cls._web_server:stop()
		for section_name, section_values in pairs(message.body) do
			cls._save_settings(section_name, section_values)
		end
		cls.reloadSettings()
	end)

	if not cls._web_server:started() then
		cls._web_server:start()
	end
	browser:url(cls._web_server:getBaseUrl() .. "/settings_dialog.html")
	browser:show()
end


function cls._load_plugin_settings(plugin_name)
	local plugin = cls._plugins[plugin_name]
	assert(plugin ~= nil, "Unknown plugin: " .. plugin_name)
	local section_schema = plugin.settings_schema
	if section_schema == nil then return {} end
	return cls._load_settings(section_schema)
end


function cls._load_plugin_hotkeys(plugin_name)
	local plugin = cls._plugins[plugin_name]
	assert(plugin ~= nil, "Unknown plugin: " .. plugin_name)
	local plugin_hotkeys_schema = cls._plugin_hotkeys_section_schema[plugin_name]
	if plugin_hotkeys_schema == nil then return {} end
	return cls._load_settings(plugin_hotkeys_schema)
end


---@param section_schema SectionSchema
---@param section_values SectionValues
---@return SectionValues
function cls._xlat_html_values_to_lua(section_schema, section_values)
	local retval = {}
	for _, item_schema in ipairs(section_schema.items) do
		local item_name = item_schema.name
		local item_value = section_values[item_name]

		if item_schema.control == "color" then
			item_value = su.colorFromHtml(item_value)
		elseif item_schema.control == "mods" then
			item_value = su.modsFromHtml(item_value)
		elseif item_schema.control == "key" then
			item_value = su.keyFromHtml(item_value)
		elseif item_schema.control == "hotkey" then
			item_value = su.hotkeyFromHtml(item_value)
		end

		retval[item_name] = item_value
	end

	return retval
end


---@param section_schema SectionSchema
---@return SectionValues
function cls._load_settings(section_schema)
	local s = hs.settings.get(section_schema.name) or {}
	local retval = {}
	for _, item_schema in ipairs(section_schema.items) do
		local item_name = item_schema.name
		local item_value = s[item_name]

		local is_valid = true

		if item_schema.control == "checkbox" then
			is_valid = su.isBoolean(item_value)
		elseif item_schema.control == "number" then
			is_valid = su.isInteger(item_value)
		elseif item_schema.control == "color" then
			is_valid = su.isValidHtmlColor(item_value)
		elseif item_schema.control == "mods" then
			is_valid = su.isValidHtmlMods(item_value)
		elseif item_schema.control == "key" then
			is_valid = su.isValidHtmlKey(item_value)
		elseif item_schema.control == "hotkey" then
			is_valid = su.isValidHtmlHotkey(item_value)
		else
			is_valid = false
		end

		if not is_valid then
			item_value = item_schema.default
		end

		retval[item_name] = item_value
	end

	return retval
end


---@param section_name string
---@param section_values SectionValues
function cls._save_settings(section_name, section_values)
	hs.settings.set(section_name, section_values)
end


return cls
