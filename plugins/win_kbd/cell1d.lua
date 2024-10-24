local class = require("utils.class")
local Segment = require("geom.segment")


---@class Cell1D: Segment
---@operator call: Cell1D
local Cell1D = class.make_class("Cell1D", Segment)


---@param which_endpoint WhichEndpoint
---@param x number
---@return boolean
function Cell1D:endpointIsCloseTo(which_endpoint, x)
	return math.abs(self:endpoint(which_endpoint) - x) <= 1
end


---@param delta_cells number
---@return Cell1D
function Cell1D:offset(delta_cells)
	return Cell1D(
		self.x + delta_cells * self.w,
		self.w
	)
end


return Cell1D
