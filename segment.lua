--[[ LOGIC ]]

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

---@param x1 number
---@param x2 number
---@return Segment
function Segment.new(x1, x2)
	local o = {
		_x1=x1,
		_w=x2 - x1,
	}
	return setmetatable(o, Segment)
end

---@return number
function Segment:getx1() return self._x1 end

---@return number
function Segment:getw()  return self._w  end

---@return number
function Segment:getx2() return self._x1 + self._w end

---@param x1 number
function Segment:setx1(x1) self._x1 = x1 end

---@param w number
function Segment:setw(w)
	assert(w >= 0, "w must be >= 0")
	self._w = w
end

---@param x2 number
function Segment:setx2(x2)
	assert(x2 >= self._x1, "x2 must be >= x1")
	self._w = x2 - self._x1
end

---@param which_endpoint number
---@return number
function Segment:endpoint(which_endpoint)
	return (
		which_endpoint == -1 and self.x1
		or which_endpoint == 1 and self.x2
		or error("invalid value for 'which_endpoint'")
	)
end

function Segment.__index(t, k)
	local func = rawget(Segment, "get" .. k)
	return func and func(t) or rawget(Segment, k)
end

function Segment.__newindex(t, k, v)
	local func = rawget(Segment, "set" .. k)
	if func then
		func(t, v)
	else
		rawset(t, k, v)
	end
end

function Segment:__eq(other)
	return (
		getmetatable(other) == getmetatable(Segment)
		and self.x1 == other.x1
		and self.w == other.w
	)
end


--[[ MODULE ]]

return Segment

--[[ TEST ]]

--[[
print("RUNNING TESTS")

s1 = Segment(100, 120)
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

s2 = Segment.new(50, 80)
assert(s1 == s2)

s3 = Segment.new(50, 90)
assert(s1 ~= s3)
]]
