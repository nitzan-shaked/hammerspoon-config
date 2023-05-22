local Grid1D = require("grid1d")

--[[ LOGIC ]]

local Grid2D = {}
Grid2D.__index = Grid2D

function Grid2D.new (frame, cell_size)
	local self = {}
	setmetatable(self, Grid2D)
	self.x_grid = Grid1D.new(frame.x1, frame.x2, cell_size.w)
	self.y_grid = Grid1D.new(frame.y1, frame.y2, cell_size.h)
	return self
end

function Grid2D:cell_coords_of (p)
	local gx = self.x_grid:cell_idx_of(p.x)
	local gy = self.y_grid:cell_idx_of(p.y)
	return gx, gy
end

function Grid2D:cell_bounds (gx, gy)
	local x_cell = self.x_grid:cell(gx)
	local y_cell = self.y_grid:cell(gy)
	return hs.geometry({
		x1=x_cell.x1,
		x2=x_cell.x2,
		y1=y_cell.x1,
		y2=y_cell.x2,
	})
end

function Grid2D:cell_bounds_of (p)
	local gx, dy = self:cell_coords_of(p)
	return self:cell_bounds(gx, gy)
end

function Grid2D:move_and_snap (frame, delta_cells_x, delta_cells_y)
	local p = frame.topleft
	local size = frame.wh
	return hs.geometry({
		x=self.x_grid:move_and_snap(p.x, size.w, delta_cells_x),
		y=self.y_grid:move_and_snap(p.y, size.h, delta_cells_y),
	})
end

function Grid2D:resize_and_snap (p, delta_cells_x, delta_cells_y)
	return hs.geometry({
		x=self.x_grid:resize_and_snap(p.x, delta_cells_x),
		y=self.y_grid:resize_and_snap(p.y, delta_cells_y),
	})
end

--[[ MODULE ]]

return Grid2D
