
local cls = {}


---@return boolean
function cls.isString(value)
	return type(value) == "string"
end


---@return boolean
function cls.isBoolean(value)
	return type(value) == "boolean"
end


---@return boolean
function cls.isInteger(value)
	return type(value) == "number" and math.floor(value) == value
end


---@return boolean
function cls.isArrayOfStrings(value)
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


---@return boolean
function cls.isValidHtmlColor(value)
	return cls.isString(value)
		and value:sub(1, 1) == "#"
		and (#value == 7 or #value == 9)
		and value:sub(2):match("^%x+$")
end


---@param html_color string
---@return Color?
function cls.colorFromHtml(html_color)
	assert(cls.isValidHtmlColor(html_color), "Invalid HTML color value")
	if #html_color == 7 then
		html_color = html_color .. "ff"
	end
	local r, g, b, a = html_color:match("#(%x%x)(%x%x)(%x%x)(%x%x)")
	return {
		red=tonumber(r, 16) / 255,
		green=tonumber(g, 16) / 255,
		blue=tonumber(b, 16) / 255,
		alpha=tonumber(a, 16) / 255,
	}
end


---@return boolean
function cls.isValidHtmlMods(value)
	if not cls.isArrayOfStrings(value) then return false end
	local mods = {
		ctrl = true,
		alt = true,
		option = true,
		cmd = true,
		shift = true,
	}
	for _, mod in ipairs(value) do
		if not mods[mod] then return false end
	end
	return true
end


---@param html_mods string[]
---@return string[]
function cls.modsFromHtml(html_mods)
	assert(cls.isValidHtmlMods(html_mods), "Invalid HTML mods value")
	local retval = {}
	for _, key_name in ipairs(html_mods) do
		if key_name == "option" then
			key_name = "alt"
		end
		table.insert(retval, key_name)
	end
	return retval
end


---@return boolean
function cls.isValidHtmlKey(value)
	if not cls.isArrayOfStrings(value) then return false end
	if #value == 0 then return true end
	if #value ~= 1 then return false end
	local key = value[1]
	if #key ~= 1 then return false end
	return true
end


---@return string?
function cls.keyFromHtml(html_key)
	assert(cls.isValidHtmlKey(html_key), "Invalid HTML key value")
	if #html_key == 0 then return nil end
	return html_key[1]
end


---@return boolean
function cls.isValidHtmlHotkey(value)
	if not cls.isArrayOfStrings(value) then return false end
	local n_keys = #value
	if n_keys == 0 then return true end
	if n_keys == 1 then return cls.isValidHtmlKey(value) end
	local keys = {table.unpack(value)}  -- create a copy of the array
	local key = value[n_keys]
	table.remove(keys, n_keys)
	local mods = keys
	if not cls.isValidHtmlMods(mods) then return false end
	if not cls.isValidHtmlKey({key}) then return false end
	return true
end


---@param html_hotkey string[]
---@return [string[], string]
function cls.hotkeyFromHtml(html_hotkey)
	assert(cls.isValidHtmlHotkey(html_hotkey), "Invalid HTML hotkey value")
	local keys = {table.unpack(html_hotkey)}  -- create a copy of the array
	local n_keys = #keys
	if n_keys == 0 then return {{}, nil} end
	local key = keys[n_keys]
	table.remove(keys, n_keys)
	local mods = keys
	return {
		cls.modsFromHtml(mods),
		cls.keyFromHtml({key})
	}
end


return cls
