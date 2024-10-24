local class = require("utils.class")
local Vector2 = require("geom.vector2")


---@class Point: Vector2
---@operator call: Point
---@field x number
---@field y number
local Point = class.make_class("Point", Vector2, {"x", "y"})
Point.__vector_slots = {"x", "y"}


---@return number
function Point:get_x() return self[1] end

---@return number
function Point:get_y() return self[2] end

---@return string
function Point:__tostring()
    return "(" .. self.x .. "," .. self.y .. ")"
end

---@return Point
function Point.x_axis() return Point(1, 0) end

---@return Point
function Point.y_axis() return Point(0, 1) end


return Point
