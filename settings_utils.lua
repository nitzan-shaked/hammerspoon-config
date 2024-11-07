
local cls = {}


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



---@param html_mods string[]
---@return string[]
function cls.modsFromHtml(html_mods)
	local retval = {}
	for _, key_name in ipairs(html_mods) do
		if key_name == "option" then
			key_name = "alt"
		end
		table.insert(retval, key_name)
	end

	return retval
end


return cls
