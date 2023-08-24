local Vector2 = require("geom.vector2")
local class = require("utils.class")

--[[ LOGIC ]]

---@class Point: Vector2
---@operator call: Point
---@field x number
---@field y number
local Point = class("Point", {
    base_cls=Vector2,
    __vector_slots={"x", "y"},
})

function Point:__tostring()
    return "(" .. self.x .. "," .. self.y .. ")"
end

---@return Point
function Point:x_axis()
	return self(1, 0)
end

---@return Point
function Point:y_axis()
	return self(0, 1)
end

--[[ MODULE ]]

return Point
