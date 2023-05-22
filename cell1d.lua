--[[ LOGIC ]]

local Cell1D = {}
Cell1D.__index = Cell1D

function Cell1D.new (x1, cell_size)
	local self = {}
	setmetatable(self, Cell1D)
	self.cell_size = cell_size
	self.x1 = x1
	self.x2 = x1 + cell_size
	return self
end

function Cell1D:prev ()
	return Cell1D.new(self.x1 - self.cell_size, self.cell_size)
end

function Cell1D:next ()
	return Cell1D.new(self.x1 + self.cell_size, self.cell_size)
end

function Cell1D:close_to_x1(x)
	return math.abs(x - self.x1) <= 1
end

function Cell1D:close_to_x2(x)
	return math.abs(x - self.x2) <= 1
end

--[[ MODULE ]]

return Cell1D
