local Grid1D = require("grid1d")

--[[ LOGIC ]]

---@class Grid2D
---@field x_grid Grid1D
---@field y_grid Grid1D
local Grid2D = {}
Grid2D.__index = Grid2D

---@param frame any
---@param cell_size Geometry
---@return Grid2D
function Grid2D.new(frame, cell_size)
	local self = {}
	setmetatable(self, Grid2D)
	self.x_grid = Grid1D.new(frame.x1, frame.x2, cell_size.w)
	self.y_grid = Grid1D.new(frame.y1, frame.y2, cell_size.h)
	return self
end

---@param p any
---@return integer, integer
function Grid2D:cell_coords_of(p)
	local gx = self.x_grid:cell_idx_of(p.x)
	local gy = self.y_grid:cell_idx_of(p.y)
	return gx, gy
end

---@param gx integer
---@param gy integer
---@return unknown
function Grid2D:cell(gx, gy)
	local x_cell = self.x_grid:cell(gx)
	local y_cell = self.y_grid:cell(gy)
	return hs.geometry({
		x1=x_cell.x1,
		x2=x_cell.x2,
		y1=y_cell.x1,
		y2=y_cell.x2,
	})
end

---@param p Geometry
---@return unknown
function Grid2D:cell_of(p)
	return self:cell(self:cell_coords_of(p))
end

---@param frame any
---@param delta_gx integer
---@param delta_gy integer
---@return unknown
function Grid2D:move_and_snap(frame, delta_gx, delta_gy)
	return hs.geometry({
		x=self.x_grid:move_and_snap(frame.x1, frame.w, delta_gx),
		y=self.y_grid:move_and_snap(frame.y1, frame.h, delta_gy),
	})
end

---@param frame any
---@param delta_gx integer
---@param delta_gy integer
---@return unknown
function Grid2D:resize_and_snap(frame, delta_gx, delta_gy)
	return self:move_and_snap(
		hs.geometry(frame.bottomright, {w=0, h=0}),
		delta_gx,
		delta_gy
	)
end

--[[ MODULE ]]

return Grid2D
