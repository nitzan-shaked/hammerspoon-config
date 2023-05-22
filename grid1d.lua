local Cell1D = require("cell1d")

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
	local move_dir = delta_cells > 0 and 1 or -1
	delta_cells = math.abs(delta_cells)

	if move_dir > 0 and cell:close_to_x2(x) then
		cell = cell:next()
	elseif move_dir < 0 and cell:close_to_x1(x) then
		cell = cell:prev()
	end

	x = move_dir > 0 and cell.x2 or cell.x1
	x = x + (delta_cells - 1) * self.cell_size
	if x < self.x1 then
		x = self.x1
	elseif x + w >= self.x2 then
		x = self.x2 - w
	end
	return x
end

function Grid1D:resize_and_snap (x, delta_cells)
	return self:move_and_snap(x, 0, delta_cells)
end

--[[ MODULE ]]

return Grid1D
