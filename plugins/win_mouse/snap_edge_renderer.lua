local class = require("utils.class")
local nu = require("utils.number_utils")


---@class SnapEdgeRenderer: Class
---@operator call: SnapEdgeRenderer
---@field screen_frame Geometry
---@field dim_name "x" | "y"
---@field edge_thickness integer
---@field curr_value number?
---@field canvas Canvas?
local SnapEdgeRenderer = class.make_class("SnapEdgeRenderer")


---@param screen_frame Geometry
---@param dim_name "x" | "y"
---@param edge_thickness integer
---@param edge_color table<string, number>
function SnapEdgeRenderer:__init__(screen_frame, dim_name, edge_thickness, edge_color)
	local rect = screen_frame:copy()
	local dim_size_name = dim_name == "x" and "w" or "h"
	rect[dim_size_name] = edge_thickness
	local canvas = hs.canvas.new(rect)
	canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor=edge_color,
	})

	self.screen_frame = screen_frame
	self.dim_name = dim_name
	self.edge_thickness = edge_thickness
	self.curr_value = nil
	self.canvas = canvas
end


---@param new_value integer?
function SnapEdgeRenderer:update(new_value)
	if new_value == self.curr_value then
		return
	end
	local canvas = assert(self.canvas)
	if new_value == nil then
		canvas:hide()
	else
		local p = {x=0, y=0}
		p[self.dim_name] = new_value - self.edge_thickness / 2
		p.x = nu.clip(p.x, 0, self.screen_frame.x2 - self.edge_thickness)
		p.y = nu.clip(p.y, 0, self.screen_frame.y2 - self.edge_thickness)
		canvas:topLeft(p)
	end
	if self.curr_value == nil then
		canvas:show()
	end
	self.curr_value = new_value
end


function SnapEdgeRenderer:delete()
	local canvas = assert(self.canvas)
	canvas:hide()
	self.canvas = nil
end


return SnapEdgeRenderer