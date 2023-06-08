Point = require("point")
Segment = require("segment")

--[[ LOGIC ]]

local rawget = rawget
local rawset = rawset

local function new(cls, ...)
	return cls.new(...)
end

---@class Rect
---@field topLeft Point
---@field size Point
---@field bottomRight Point
---@field x1 number
---@field y1 number
---@field w number
---@field h number
---@field x2 number
---@field y2 number
---@field h_segment Segment
---@field v_segment Segment
local Rect = {}
setmetatable(Rect, {__call=new})

---@param t table
---@param k string
---@return any
function Rect.__index(t, k)
	local func = rawget(Rect, "get" .. k)
	return func and func(t) or rawget(Rect, k)
end

---@param t table
---@param k string
---@param v any
function Rect.__newindex(t, k, v)
	local func = rawget(Rect, "set" .. k)
	if func then
		func(t, v)
	else
		rawset(t, k, v)
	end
end

---@param topLeft Point
---@param bottomRight Point
---@return Rect
function Rect.new(topLeft, bottomRight)
	local size = bottomRight - topLeft
	assert(size.x >= 0)
	assert(size.y >= 0)
	local o = {
		_topLeft=topLeft,
		_size=size,
		_bottomRight=bottomRight,
	}
	return setmetatable(o, Rect)
end

---@return Point
function Rect:gettopLeft() return self._topLeft end

---@return Point
function Rect:getsize() return self._size end

---@return Point
function Rect:getbottomRight() return self._bottomRight end

---@param topLeft Point
function Rect:settopLeft(topLeft)
	self._topLeft = topLeft
	self._bottomRight = self._topLeft + self._size
end

---@param size Point
function Rect:setsize(size)
	assert(size.x >= 0 and size.y >= 0)
	self._size = size
	self._bottomRight = self._topLeft + size
end

---@param bottomRight Point
function Rect:setbottomRight(bottomRight)
	self.size = bottomRight - self._topLeft
end

---@return number
function Rect:getx1() return self._topLeft.x end

---@return number
function Rect:gety1() return self._topLeft.y end

---@return number
function Rect:getw() return self._size.x end

---@return number
function Rect:geth() return self._size.y end

---@return number
function Rect:getx2() return self._bottomRight.x end

---@return number
function Rect:gety2() return self._bottomRight.y end

---@param x1 number
function Rect:setx1(x1)
	self.topLeft = Point(x1, self._topLeft.y)
end

---@param y1 number
function Rect:sety1(y1)
	self.topLeft = Point(self._topLeft.x, y1)
end

---@param w number
function Rect:setw(w)
	self.size = Point(w, self._size.y)
end

---@param h number
function Rect:seth(h)
	self.size = Point(self._size.x, h)
end

---@param x2 number
function Rect:setx2(x2)
	self.bottomRight = Point(x2, self._bottomRight.y)
end

---@param y2 number
function Rect:sety2(y2)
	self.bottomRight = Point(self._bottomRight.x, y2)
end

function Rect:geth_segment()
	return Segment(self.x1, self.x2)
end

function Rect:getv_segment()
	return Segment(self.y1, self.y2)
end

---@param other Rect | Point
---@return boolean
function Rect:contains(other)
	if getmetatable(other) == Point then
		return (
			self.h_segment:contains(other.x) and
			self.v_segment:contains(other.y)
		)
	end
	return (
		self.h_segment:contains(other.h_segment) and
		self.v_segment:contains(other.v_segment)
	)
end

---@param other Rect
---@return boolean
function Rect:intersects(other)
	return (
		self.h_segment:intersects(other.h_segment) and
		self.v_segment:intersects(other.v_segment)
	)
end

---@param other Rect
---@return boolean
function Rect:__eq(other)
	return self._topLeft == other._topLeft and self._size == other._size
end

---@param offset Point
---@return Rect
function Rect:__add(offset)
	return Rect(self._topLeft + offset, self._bottomRight + offset)
end

--[[ MODULE ]]

return Rect
