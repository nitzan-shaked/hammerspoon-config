local fs = require("hs.fs")


local function is_dir(path)
	local attrs = fs.attributes(path)
	return attrs and attrs.mode == "directory"
end


local function require_plugin_from_dir(dir1, dir2)
	local old_package_path = package.path
	package.path = dir1 .. "/?/init.lua;" .. package.path
	package.path = dir1 .. "/?/?.lua;"    .. package.path
	package.path = dir1 .. "/" .. dir2 .. "/?.lua;" .. package.path
	local m = require(dir2)
	package.path = old_package_path
	return m
end


local function load_plugins_from_dir(parent_dir)
	if not is_dir(parent_dir) then
		hs.printf("No plugins directory found at %s", parent_dir)
		return {}
	end

	local plugins = {}
	for plugin_name in fs.dir(parent_dir) do
		if plugin_name == "." or plugin_name == ".." then goto next_plugin end
		if not is_dir(parent_dir .. "/" .. plugin_name) then goto next_plugin end
		hs.printf("        loading plugin: %s", plugin_name)
		local plugin = require_plugin_from_dir(parent_dir, plugin_name)
		assert(plugin.name == plugin_name, "plugin name mismatch")
		plugins[plugin.name] = plugin
		::next_plugin::
	end

	return plugins
end


return {
	load_plugins_from_dir = load_plugins_from_dir
}