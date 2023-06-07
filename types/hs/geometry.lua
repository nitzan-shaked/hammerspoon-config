---@meta "hs.geometry"

---@class Geometry
---@field x number
---@field y number
---@field w number
---@field h number
---@field x1 number
---@field y1 number
---@field x2 number
---@field y2 number
---@field x1y1 Geometry
---@field x2y2 Geometry
---@field topLeft Geometry
---@field bottomRight Geometry
---@field center Geometry
local Geometry = {}

---@return Geometry
function Geometry.new() end

---@param other Geometry
---@return boolean
function Geometry:inside(other) end

---@class hs.geometry
---@operator call:Geometry
local module = {}

---@param w number
---@param h number
---@return Geometry
function module.size(w, h) end

return module
