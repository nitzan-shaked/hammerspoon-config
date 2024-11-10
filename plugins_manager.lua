local lfs = require("hs.fs")

local class = require("utils.class")


---@class PluginsManager: Class
local cls = class.make_class("PluginsManager")
cls._initialized = false


---@return boolean
local function is_dir(path)
	local attrs = lfs.attributes(path)
	return attrs and attrs.mode == "directory"
end


---@param parent_dir string
---@param plugin_name string
---@return Module
local function require_plugin_from_dir(parent_dir, plugin_name)
	local old_package_path = package.path
	package.path = parent_dir .. "/?/init.lua;" .. package.path
	package.path = parent_dir .. "/?/?.lua;"    .. package.path
	package.path = parent_dir .. "/" .. plugin_name .. "/?.lua;" .. package.path
	local m = require(plugin_name)
	package.path = old_package_path
	return m
end


---@param parent_dir string
function cls.init(parent_dir)
	assert(not cls._initialized, "PluginsManager already initialized")

	if not is_dir(parent_dir) then
		error("No plugins directory found at" .. parent_dir)
	end

	---@type table<string, Module>
	cls._plugins = {}
	for subdir_name in lfs.dir(parent_dir) do
		if subdir_name == "." or subdir_name == ".." then goto next_plugin end
		if not is_dir(parent_dir .. "/" .. subdir_name) then goto next_plugin end

		local plugin_name = subdir_name
		hs.printf("        loading plugin: %s", plugin_name)
		local plugin = require_plugin_from_dir(parent_dir, plugin_name)
		assert(plugin.name == plugin_name, "plugin name mismatch")
		cls._plugins[plugin_name] = plugin

		::next_plugin::
	end

	cls._initialized = true
end

---@return table<string, Module>
function cls.getPluginsMap()
	assert(cls._initialized, "PluginsManager is not initialized")
	return cls._plugins
end


return cls
