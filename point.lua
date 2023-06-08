--[[ LOGIC ]]

local function new(cls, ...)
	return cls.new(...)
end

---@class Point
---@field x number
---@field y number
local Point = {}
setmetatable(Point, {__call=new})

---@param x number
---@param y number
---@return Point
function Point.new(x, y)
	local o = {x=x, y=y}
	setmetatable(o, Point)
	return o
end

---@param other any
---@return boolean
function Point:__eq(other)
	return (
		getmetatable(other) == Point
		and self.x == other.x
		and self.y == other.y
	)
end

---@param p Point
---@return Point
function Point:__add(p)
	return Point(self.x + p.x, self.y + p.y)
end

---@param p Point
---@return Point
function Point:__sub(p)
	return Point(self.x - p.x, self.y - p.y)
end

---@param k number
---@return Point
function Point:__mul(k)
	return Point(self.x * k, self.y * k)
end

---@return Point
function Point:__unm()
	return Point(-self.x, -self.y)
end

--[[ MODULE ]]

return Point
