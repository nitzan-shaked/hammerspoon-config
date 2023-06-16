local Vector2 = require("vector2")
local class = require("class")

--[[ LOGIC ]]

---@class Size: Vector2
---@field w number
---@field h number
local Size = class("Size", {
    base_cls=Vector2,
    slots={"w", "h"},
})

---@param w number
---@param h number
function Size:__init__(w, h)
    assert(w >= 0 and h >= 0)
    Vector2.__init__(self, w, h)
end

---@return number
function Size:get_w() return self.x end
---@return number
function Size:get_h() return self.y end

--[[ MODULE ]]

return Size
