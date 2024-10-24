local class = require("utils.class")
local Point = require("geom.point")
local Size = require("geom.size")
local Rect = require("geom.rect")
local Grid1D = require("grid1d")


---@class Grid2D: Class
---@operator call: Grid2D
---@field x_grid Grid1D
---@field y_grid Grid1D
local Grid2D = class.make_class("Grid2D")


---@param frame Geometry
---@param cell_size Size
function Grid2D:__init__(frame, cell_size)
	self.x_grid = Grid1D(frame.x1, frame.x2, cell_size.w)
	self.y_grid = Grid1D(frame.y1, frame.y2, cell_size.h)
end


---@param g Point
---@return Rect
function Grid2D:cell(g)
	local x_cell = self.x_grid:cell(g.x)
	local y_cell = self.y_grid:cell(g.y)
	return Rect(
		Point(x_cell.x, y_cell.x),
		Size(x_cell.w, y_cell.w)
	)
end


---@param p Point
---@return Point
function Grid2D:cellIdxOf(p)
	return Point(
		self.x_grid:cellIdxOf(p.x),
		self.y_grid:cellIdxOf(p.y)
	)
end


---@param frame Geometry
---@param delta_g Point
---@return Point
function Grid2D:moveAndSnap(frame, delta_g)
	return Point(
		self.x_grid:moveAndSnap(frame.x1, delta_g.x),
		self.y_grid:moveAndSnap(frame.y1, delta_g.y)
	)
end


---@param frame Geometry
---@param delta_g Point
---@return Point
function Grid2D:resizeAndSnap(frame, delta_g)
	return Point(
		self.x_grid:resizeAndSnap(frame.x2, delta_g.x),
		self.y_grid:resizeAndSnap(frame.y2, delta_g.y)
	)
end


return Grid2D
