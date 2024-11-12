
---@param x number
---@return integer
local function sign(x)
	return x > 0 and 1 or x < 0 and -1 or 0
end


---@param x number
---@param x1 number?
---@param x2 number?
---@return number
local function clip(x, x1, x2)
	return (x1 ~= nil and x < x1) and x1 or (x2 ~= nil and x > x2) and x2 or x
end


---@param x number
---@param x1 number
---@return number
local function no_less(x, x1)
	return x < x1 and x1 or x
end


---@param x number
---@param x2 number
---@return number
local function no_more(x, x2)
	return x > x2 and x2 or x
end


---@param x1 number
---@param x2 number
---@param s number
---@return number
local function interpolate(x1, x2, s)
	return x1 + (x2 - x1) * s
end


return {
	sign=sign,
	clip=clip,
	cap_below=no_less,
	cap_above=no_more,
	interpolate=interpolate,
}
