local json = require("hs.json")
local screen = require("hs.screen")
local webview = require("hs.webview")
local usercontent = require("hs.webview.usercontent")
local spoons = require("hs.spoons")


local cls = {}

cls.initialized = false
cls.plugins = {}
cls.plugin_names = {}
cls.features_section_schema = {}


function cls.init(plugins)
	assert(not cls.initialized, "already initialized")

	cls.plugins = plugins
	cls.plugin_names = {}
	for plugin_name, _ in pairs(plugins) do
		table.insert(cls.plugin_names, plugin_name)
	end
	table.sort(cls.plugin_names)

	local features_section_items = {}

	for _, plugin_name in ipairs(cls.plugin_names) do
		local plugin = cls.plugins[plugin_name]
		table.insert(features_section_items, {
			name=plugin.cfg_schema.name,
			descr=plugin.cfg_schema.title,
			control="checkbox",
			default=false,
		})
	end

	cls.features_section_schema = {
		name="features",
		title="Features",
		items=features_section_items,
	}

	cls.initialized = true
end


function cls.loadFeaturesSection()
	assert(cls.initialized, "not initialized")
	return cls.loadSection(cls.features_section_schema)
end


function cls.loadPluginSection(plugin_name)
	assert(cls.initialized, "not initialized")

	local plugin = cls.plugins[plugin_name]
	if plugin == nil then
		print("Unknown plugin: " .. plugin_name)
		return {}
	end

	local section_schema = plugin.cfg_schema
	if section_schema == nil then
		print("Plugin " .. plugin_name .. " has no configuration schema")
		return {}
	end

	return cls.loadSection(section_schema)
end


function cls.loadSection(section_schema)
	assert(cls.initialized, "not initialized")

	local s = hs.settings.get(section_schema.name) or {}
	local retval = {}
	for _, item_schema in ipairs(section_schema.items) do
		local item_name = item_schema.name
		local item_value = s[item_name]

		local is_valid = true

		if item_schema.control == "checkbox" then
			-- check that the value is a boolean
			is_valid = type(item_value) == "boolean"

		elseif item_schema.control == "number" then
			-- check that the value is an integer
			is_valid = type(item_value) == "number" and math.floor(item_value) == item_value

		elseif item_schema.control == "hotkey" then
			-- check that the value is a table
			if is_valid and type(item_value) ~= "table" then
				is_valid = false
			end
			-- check that the table keys are consecutive integers starting from 1
			if is_valid then
				for i, v in ipairs(item_value) do
					if i ~= v then
						is_valid = false
						break
					end
				end
			end
			-- check that the table values are all strings
			if is_valid then
				for _, v in ipairs(item_value) do
					if type(v) ~= "string" then
						is_valid = false
						break
					end
				end
			end

		elseif item_schema.control == "color" then
			-- check that the value is a string, that starts with "#",
			-- and is 7 or 9 chars long, all but the first hex digits
			is_valid = type(item_value) == "string"
				and item_value:sub(1, 1) == "#"
				and (#item_value == 7 or #item_value == 9)
				and item_value:sub(2):match("^%x+$")

		else
			-- unsupported control type
			is_valid = false

		end

		if not is_valid then
			item_value = item_schema.default
		end

		retval[item_name] = item_value
	end

	return retval
end


function cls.saveSection(section_name, section_values)
	assert(cls.initialized, "not initialized")
	hs.settings.set(section_name, section_values)
end


local function escape_for_js(str)
    return str:gsub("\\", "\\\\")   -- Escape backslashes
              :gsub("\"", "\\\"")   -- Escape double quotes
              :gsub("\n", "\\n")    -- Escape newlines
              :gsub("\r", "\\r")    -- Escape carriage returns
              :gsub("\t", "\\t")    -- Escape tabs
end


function cls.showDialog(reload_config_fn)
	assert(cls.initialized, "not initialized")
	local cfg_schemas = {}
	local cfg_values = {}

	table.insert(cfg_schemas, cls.features_section_schema)
	table.insert(cfg_values,  cls.loadFeaturesSection())

	for _, plugin_name in ipairs(cls.plugin_names) do
		local plugin = cls.plugins[plugin_name]
		local section_schema = plugin.cfg_schema
		if #section_schema.items > 0 then
			table.insert(cfg_schemas, section_schema)
			table.insert(cfg_values,  cls.loadPluginSection(plugin_name))
		end
	end

	local js_source=[[
		RUNNING_IN_HAMMERSPOON = true;
		CONFIG_SCHEMA = JSON.parse("]] .. escape_for_js(json.encode(cfg_schemas)) .. [[");
		CONFIG_VALUES = JSON.parse("]] .. escape_for_js(json.encode(cfg_values))  .. [[");
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
	local options = {}

	local browser = webview.new(frame, options, controller)
		:windowStyle({"titled", "closable"})
		:closeOnEscape(true)
		:deleteOnClose(true)
		:bringToFront(true)
		:allowTextEntry(true)
		:transparent(false)

	controller:setCallback(function(message)
		browser:delete()
		for section_name, section_values in pairs(message.body) do
			cls.saveSection(section_name, section_values)
		end
		reload_config_fn()
	end)

	browser:url("file://" .. spoons.scriptPath() .. "web/settings_dialog.html")
	browser:show()
end


---@param html_color string
---@return Color?
function cls.colorFromHtml(html_color)
	if html_color:sub(1, 1) ~= "#" then
		return nil
	end
	if #html_color == 7 then
		html_color = html_color .. "ff"
	end
	if #html_color ~= 9 then
		return nil
	end

	local r, g, b, a = html_color:match("#(%x%x)(%x%x)(%x%x)(%x%x)")
	return {
		red=tonumber(r, 16) / 255,
		green=tonumber(g, 16) / 255,
		blue=tonumber(b, 16) / 255,
		alpha=tonumber(a, 16) / 255,
	}
end


return cls
