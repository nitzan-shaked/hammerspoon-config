local fs = require("hs.fs")


local function is_dir(path)
	local attrs = fs.attributes(path)
	return attrs and attrs.mode == "directory"
end


local function require_module_from_dir(dir1, dir2)
	local old_package_path = package.path
	package.path = dir1 .. "/?/init.lua;" .. package.path
	package.path = dir1 .. "/?/?.lua;"    .. package.path
	package.path = dir1 .. "/" .. dir2 .. "/?.lua;" .. package.path
	local m = require(dir2)
	package.path = old_package_path
	return m
end


local function load_modules_from_dir(parent_dir)
	if not is_dir(parent_dir) then
		hs.printf("No modules directory found at %s", parent_dir)
		return {}
	end

	local modules = {}
	for module_name in fs.dir(parent_dir) do
		if module_name == "." or module_name == ".." then goto next_module end
		if not is_dir(parent_dir .. "/" .. module_name) then goto next_module end
		hs.printf("        loading module: %s", module_name)
		local module = require_module_from_dir(parent_dir, module_name)
		assert(module.name == module_name, "module name mismatch")
		modules[module.name] = module
		::next_module::
	end

	return modules
end


return {
	load_modules_from_dir = load_modules_from_dir
}