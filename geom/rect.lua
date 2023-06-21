local Point = require("geom.point")
local Size = require("geom.size")
local Segment = require("geom.segment")
local class = require("utils.class")

--[[ LOGIC ]]

---@class Rect: Class
---@field x number
---@field y number
---@field w number
---@field h number
---@field x1 number
---@field y1 number
---@field x2 number
---@field y2 number
---@field size Size
---@field topLeft Point
---@field midLeft Point
---@field bottomLeft Point
---@field topCenter Point
---@field center Point
---@field bottomCenter Point
---@field topRight Point
---@field midRight Point
---@field bottomRight Point
---@field h_segment Segment
---@field v_segment Segment
local Rect = class("Rect", {
	props={
		"x1", "y1", "x2", "y2",
		"size",
		"topLeft", "midLeft", "bottomLeft",
		"topCenter", "center", "bottomCenter",
		"topRight", "midRight", "bottomRight",
		"h_segment", "v_segment",
	},
})

---@param topLeft Point
---@param size Size
function Rect:__init__(topLeft, size)
	self.x = topLeft.x
	self.y = topLeft.y
	self.w = size.w
	self.h = size.h
end

---@return number
function Rect:get_x1() return self.x end
---@return number
function Rect:get_y1() return self.y end
---@return number
function Rect:get_x2() return self.x + self.w end
---@return number
function Rect:get_y2() return self.y + self.h end

---@return Size
function Rect:get_size() return Size(self.w, self.h) end

---@return Point
function Rect:get_topLeft()      return Point(self.x,              self.y              ) end
---@return Point
function Rect:get_midLeft()      return Point(self.x,              self.y + self.h / 2) end
---@return Point
function Rect:get_bottomLeft()   return Point(self.x,              self.y + self.h    ) end

---@return Point
function Rect:get_topCenter()    return Point(self.x + self.w / 2, self.y              ) end
---@return Point
function Rect:get_center()       return Point(self.x + self.w / 2, self.y + self.h / 2) end
---@return Point
function Rect:get_bottomCenter() return Point(self.x + self.w / 2, self.y + self.h    ) end

---@return Point
function Rect:get_topRight()     return Point(self.x + self.w,     self.y              ) end
---@return Point
function Rect:get_midRight()     return Point(self.x + self.w,     self.y + self.h / 2) end
---@return Point
function Rect:get_bottomRight()  return Point(self.x + self.w,     self.y + self.h    ) end

---@return Segment
function Rect:get_h_segment() return Segment(self.x, self.w) end
---@return Segment
function Rect:get_v_segment() return Segment(self.y, self.h) end

---@param other Rect | Point
---@return boolean
function Rect:contains(other)
	if class.is_instance(other, Point) then
		return (
			self.h_segment:contains(other.x) and
			self.v_segment:contains(other.y)
		)
	else
		return (
			self.h_segment:contains(other.h_segment) and
			self.v_segment:contains(other.v_segment)
		)
	end
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
	return (
		    self.x == other.x
		and self.y == other.y
		and self.w == other.w
		and self.h == other.h
	)
end

---@param offset Point
---@return Rect
function Rect:__add(offset)
	return Rect(self.topLeft + offset, self.size)
end

--[[ MODULE ]]

return Rect
