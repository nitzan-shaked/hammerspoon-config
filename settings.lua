local json = require("hs.json")
local screen = require("hs.screen")
local webview = require("hs.webview")
local usercontent = require("hs.webview.usercontent")
local spoons = require("hs.spoons")

local WebServer = require("web_server")


local cls = {}
cls._initialized = false
cls._plugins = {}
cls._plugin_names = {}
cls._enabled_plugins_section_schema = {}
cls._plugin_hotkeys_section_schema = {}


---@param plugins table<string, Module>
---@param reload_settings_fn function
function cls.init(plugins, reload_settings_fn)
	assert(not cls._initialized, "already initialized")

	cls._plugins = plugins
	cls._reload_settings_fn = reload_settings_fn

	cls._plugin_names = {}
	for plugin_name, _ in pairs(plugins) do
		table.insert(cls._plugin_names, plugin_name)
	end
	table.sort(cls._plugin_names)

	for _, plugin_name in ipairs(cls._plugin_names) do
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
				default=nil,
			})
		end
		cls._plugin_hotkeys_section_schema[plugin_name] = plugin_hotkeys_schema
	end

	local enabled_plugins_section_items = {}
	for _, plugin_name in ipairs(cls._plugin_names) do
		local plugin = cls._plugins[plugin_name]
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

	cls._initialized = true
end


---@return table<string, Module>
function cls.get_plugins()
	return cls._plugins
end


---@return string[]
function cls.get_sorted_plugin_names()
	return cls._plugin_names
end


function cls.loadEnabledPluginsSetting()
	assert(cls._initialized, "not initialized")
	return cls._load_settings(cls._enabled_plugins_section_schema)
end


function cls.saveEnabledPluginsSetting(enabled_plugins_values)
	assert(cls._initialized, "not initialized")
	cls._save_settings(cls._enabled_plugins_section_schema.name, enabled_plugins_values)
	cls._reload_settings_fn()
end


function cls.loadPluginSettings(plugin_name)
	assert(cls._initialized, "not initialized")

	local plugin = cls._plugins[plugin_name]
	if plugin == nil then
		print("Unknown plugin: " .. plugin_name)
		return {}
	end

	local section_schema = plugin.settings_schema
	if section_schema == nil then
		print("Plugin " .. plugin_name .. " has no settings schema")
		return {}
	end

	return cls._load_settings(section_schema)
end


function cls.loadPluginHotkeys(plugin_name)
	assert(cls._initialized, "not initialized")

	local plugin = cls._plugins[plugin_name]
	if plugin == nil then
		print("Unknown plugin: " .. plugin_name)
		return {}
	end

	local plugin_hotkeys_schema = cls._plugin_hotkeys_section_schema[plugin_name]
	if plugin_hotkeys_schema == nil then
		print("Plugin has no actions: " .. plugin_name)
		return {}
	end

	return cls._load_settings(plugin_hotkeys_schema)
end


local web_server = WebServer(spoons.scriptPath() .. "web")


---@param show_enabled_plugins_section boolean
---@param show_plugins_settings boolean
---@param show_plugins_hotkeys boolean
function cls.showSettingsDialog(
	show_enabled_plugins_section,
	show_plugins_settings,
	show_plugins_hotkeys
)
	assert(cls._initialized, "not initialized")
	local sections_schemas = {}
	local sections_values = {}

	if show_enabled_plugins_section then
		table.insert(sections_schemas, cls._enabled_plugins_section_schema)
		table.insert(sections_values,  cls.loadEnabledPluginsSetting())
	end

	for _, plugin_name in ipairs(cls._plugin_names) do
		local plugin = cls._plugins[plugin_name]

		local plugin_settings_schema = plugin.settings_schema
		if show_plugins_settings and #plugin_settings_schema.items > 0 then
			table.insert(sections_schemas, plugin_settings_schema)
			table.insert(sections_values,  cls.loadPluginSettings(plugin_name))
		end

		local plugin_hotkeys_schema = cls._plugin_hotkeys_section_schema[plugin_name]
		if show_plugins_hotkeys and #plugin_hotkeys_schema.items > 0 then
			table.insert(sections_schemas, plugin_hotkeys_schema)
			table.insert(sections_values,  cls.loadPluginHotkeys(plugin_name))
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
		web_server:stop()
		for section_name, section_values in pairs(message.body) do
			cls._save_settings(section_name, section_values)
		end
		cls._reload_settings_fn()
	end)

	web_server:start()
	browser:url(web_server:getBaseUrl() .. "/settings_dialog.html")
	browser:show()
end


local function is_string(value)
	return type(value) == "string"
end


local function is_boolean(value)
	return type(value) == "boolean"
end


local function is_integer(value)
	return type(value) == "number" and math.floor(value) == value
end


local function is_array_of_strings(value)
	if type(value) ~= "table" then
		return false
	end
	-- all indices are integers
	for k, _ in pairs(value) do
		if type(k) ~= "number" or math.floor(k) ~= k then
			return false
		end
	end
	-- indices start at 1 and are contiguous,
	-- and all values are strings
	local i = 1
	while value[i] ~= nil do
		if type(value[i]) ~= "string" then
			return false
		end
		i = i + 1
	end
	return true
end


local function is_valid_hotkey_value(value)
	return is_array_of_strings(value)
end


local function is_valid_key_value(value)
	return is_string(value)
end


local function is_valid_mods_value(value)
	return is_array_of_strings(value)
end


local function is_valid_color_value(value)
	return is_string(value)
		and value:sub(1, 1) == "#"
		and (#value == 7 or #value == 9)
		and value:sub(2):match("^%x+$")
end


function cls._load_settings(section_schema)
	local s = hs.settings.get(section_schema.name) or {}
	local retval = {}
	for _, item_schema in ipairs(section_schema.items) do
		local item_name = item_schema.name
		local item_value = s[item_name]

		local is_valid = true

		if item_schema.control == "checkbox" then
			is_valid = is_boolean(item_value)

		elseif item_schema.control == "number" then
			is_valid = is_integer(item_value)

		elseif item_schema.control == "hotkey" then
			is_valid = is_valid_hotkey_value(item_value)

		elseif item_schema.control == "mods" then
			is_valid = is_valid_mods_value(item_value)

		elseif item_schema.control == "key" then
			is_valid = is_valid_key_value(item_value)

		elseif item_schema.control == "color" then
			is_valid = is_valid_color_value(item_value)

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


function cls._save_settings(section_name, section_values)
	hs.settings.set(section_name, section_values)
end


return cls
