--[[ LOGIC ]]

---@alias WhichEndpoint -1 | 1

local rawget = rawget
local rawset = rawset

local function new(cls, ...)
	return cls.new(...)
end

---@class Segment
---@field x1 number
---@field x2 number
---@field w number
local Segment = {}
setmetatable(Segment, {__call=new})

---@param t table
---@param k string
---@return any
function Segment.__index(t, k)
	local func = rawget(Segment, "get" .. k)
	return func and func(t) or rawget(Segment, k)
end

---@param t table
---@param k string
---@param v any
function Segment.__newindex(t, k, v)
	local func = rawget(Segment, "set" .. k)
	if func then
		func(t, v)
	else
		rawset(t, k, v)
	end
end

---@param x1 number
---@param x2 number
---@return Segment
function Segment.new(x1, x2)
	local o = {_x1=x1, _w=x2 - x1, _x2=x2}
	return setmetatable(o, Segment)
end

---@return number
function Segment:getx1() return self._x1 end

---@return number
function Segment:getw()  return self._w  end

---@return number
function Segment:getx2() return self._x2 end

---@param x1 number
function Segment:setx1(x1)
	self._x1 = x1
	self._x2 = x1 + self._w
end

---@param w number
function Segment:setw(w)
	assert(w >= 0)
	self._w = w
	self._x2 = self._x1 + w
end

---@param x2 number
function Segment:setx2(x2)
	assert(x2 >= self._x1)
	self._w = x2 - self._x1
	self._x2 = x2
end

---@param which_endpoint WhichEndpoint
---@return number
function Segment:endpoint(which_endpoint)
	return (
		which_endpoint == -1 and self._x1 or
		which_endpoint == 1 and self._x2 or
		error("invalid value for 'which_endpoint'")
	)
end

---@param other Segment | number
---@return boolean
function Segment:contains(other)
	if type(other) == "number" then
		return other >= self._x1 and other <= self._x2
	end
	return other._x1 >= self._x1 and other._x2 <= self._x2
end

---@param other Segment
---@return boolean
function Segment:intersects(other)
	return (
		other._x1 <= self._x1 and other._x2 >= self._x1 or
		other._x1 <= self._x2
	)
end

---@param other Segment
---@return boolean
function Segment:__eq(other)
	return self._x1 == other._x1 and self._w == other._w
end

---@param offset number
---@return Segment
function Segment:__add(offset)
	return Segment(self._x1 + offset, self._x2 + offset)
end

--[[ MODULE ]]

return Segment

--[[ TEST ]]

--[[
print("RUNNING TESTS")

local s1 = Segment(100, 120)
assert(s1.x1 == 100)
assert(s1.x2 == 120)
assert(s1.w  ==  20)

s1.x1 = 50
assert(s1.x1 == 50)
assert(s1.x2 == 70)
assert(s1.w  == 20)

s1.x2 = 60
assert(s1.x1 == 50)
assert(s1.x2 == 60)
assert(s1.w  == 10)

s1.w = 30
assert(s1.x1 == 50)
assert(s1.x2 == 80)
assert(s1.w  == 30)

local s2 = Segment.new(50, 80)
assert(s1 == s2)

local s3 = Segment.new(50, 90)
assert(s1 ~= s3)

print("TESTS DONE")
--]]
