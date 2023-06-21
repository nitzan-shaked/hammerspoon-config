local Vector2 = require("geom.vector2")
local class = require("utils.class")

--[[ LOGIC ]]

---@class Point: Vector2
---@field x number
---@field y number
local Point = class("Point", {
    base_cls=Vector2,
    __vector_slots={"x", "y"},
})

--[[ MODULE ]]

return Point
