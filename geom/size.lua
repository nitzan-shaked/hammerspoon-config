local Vector2 = require("geom.vector2")
local class = require("utils.class")


---@class Size: Vector2
---@operator call: Size
---@field w number
---@field h number
local Size = class.make_class("Size", Vector2, {"w", "h"})
Size.__vector_slots = {"w", "h"}


---@return number
function Size:get_w() return self[1] end

---@return number
function Size:get_h() return self[2] end

---@return string
function Size:__tostring()
    return self.w .. "x" .. self.h
end

---@return Size
function Size:w_axis() return self(1, 0) end

---@return Size
function Size:h_axis() return self(0, 1) end


return Size
