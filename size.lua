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

--[[ MODULE ]]

return Size
