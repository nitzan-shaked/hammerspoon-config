local Vector2 = require("geom.vector2")
local class = require("utils.class")

--[[ LOGIC ]]

---@class Size: Vector2
---@operator call: Size
---@field w number
---@field h number
local Size = class("Size", {
    base_cls=Vector2,
    __vector_slots={"w", "h"},
})

function Size:__tostring()
    return self.w .. "x" .. self.h
end

---@return Size
function Size:w_axis()
	return self(1, 0)
end

---@return Size
function Size:h_axis()
	return self(0, 1)
end

--[[ MODULE ]]

return Size
