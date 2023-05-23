local Cell1D = require("cell1d")
local u = require("utils")

--[[ LOGIC ]]

local Grid1D = {}
Grid1D.__index = Grid1D

function Grid1D.new (x1, x2, cell_size)
	local self = {}
	setmetatable(self, Grid1D)
	self.x1 = x1
	self.x2 = x2
	self.cell_size = cell_size
	return self
end

function Grid1D:cell_idx_of (x)
	return math.floor((x - self.x1) / self.cell_size)
end

function Grid1D:cell (cell_idx)
	local cell_x1 = self.x1 + cell_idx * self.cell_size
	return Cell1D.new(cell_x1, self.cell_size)
end

function Grid1D:cell_of (x)
	return self:cell(self:cell_idx_of(x))
end

function Grid1D:move_and_snap (x, w, delta_cells)
	if delta_cells == nil or delta_cells == 0 then
		return x
	end
	local cell = self:cell_of(x)
	local move_dir = u.sign(delta_cells)
	delta_cells = math.abs(delta_cells)

	if cell:edge_is_close_to(move_dir, x) then
		cell = cell:skip(move_dir)
	end
	local new_cell = cell:skip(move_dir * (delta_cells - 1))
	local new_x = new_cell:edge(move_dir)
	return u.clip(new_x, self.x1, self.x2 - w)
end

function Grid1D:resize_and_snap (x, delta_cells)
	return self:move_and_snap(x, 0, delta_cells)
end

--[[ MODULE ]]

return Grid1D
