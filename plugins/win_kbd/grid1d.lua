local class = require("utils.class")
local Cell1D = require("cell1d")
local nu = require("utils.number_utils")


---@class Grid1D: Class
---@operator call: Grid1D
---@field x1 number
---@field x2 number
---@field cell_size number
local Grid1D = class.make_class("Grid1D")


---@param x1 number
---@param x2 number
---@param cell_size number
function Grid1D:__init__(x1, x2, cell_size)
	self.x1 = x1
	self.x2 = x2
	self.cell_size = cell_size
end


---@param cell_idx integer
---@return Cell1D
function Grid1D:cell(cell_idx)
	return Cell1D(
		self.x1 + cell_idx * self.cell_size,
		self.cell_size
	)
end


---@param x number
---@return integer
function Grid1D:cellIdxOf(x)
	return math.floor((x - self.x1) / self.cell_size)
end


---@param x number
---@param delta_cells integer
---@return number
function Grid1D:moveAndSnap(x, delta_cells)
	local new_x = self:_adjustAndSnap(x, delta_cells)
	return nu.clip(new_x, self.x1, self.x2)
end


---@param x number
---@param delta_cells integer
---@return number
function Grid1D:resizeAndSnap(x, delta_cells)
	return self:_adjustAndSnap(x, delta_cells)
end


---@param x number
---@param delta_cells integer
---@return number
function Grid1D:_adjustAndSnap(x, delta_cells)
	if delta_cells == nil or delta_cells == 0 then return x end
	local move_dir_sign = nu.sign(delta_cells)
	delta_cells = math.abs(delta_cells)

	local cell = self:cell(self:cellIdxOf(x))
	if cell:endpointIsCloseTo(move_dir_sign, x) then
		cell = cell:offset(move_dir_sign)
	end
	local new_cell = cell:offset(move_dir_sign * (delta_cells - 1))
	local new_x = new_cell:endpoint(move_dir_sign)
	return new_x
end


return Grid1D
