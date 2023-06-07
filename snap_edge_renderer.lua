--[[ CONFIG ]]

local SNAP_EDGE_THICKNESS = 2
local SNAP_EDGE_COLOR = {red=0, green=1, blue=1, alpha=0.5}

--[[ LOGIC ]]

---@class SnapEdgeRenderer
---@field screen_frame Geometry
---@field dim_name "x" | "y"
---@field value number?
---@field canvas Canvas?
local SnapEdgeRenderer = {}
SnapEdgeRenderer.__index = SnapEdgeRenderer


---@param screen_frame Geometry
---@param dim_name "x" | "y"
---@return SnapEdgeRenderer
function SnapEdgeRenderer.new(screen_frame, dim_name)
	local rect = screen_frame:copy()
	local dim_size_name = dim_name == "x" and "w" or "h"
	rect[dim_size_name] = SNAP_EDGE_THICKNESS
	local canvas = hs.canvas.new(rect)
	canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor=SNAP_EDGE_COLOR,
	})

	local self = {}
	setmetatable(self, SnapEdgeRenderer)
	self.screen_frame = screen_frame
	self.dim_name = dim_name
	self.value = nil
	self.canvas = canvas
	return self
end

---@param new_value integer?
function SnapEdgeRenderer:update(new_value)
	if new_value == self.value then
		return
	end
	assert(self.canvas)
	if new_value == nil then
		self.canvas:hide()
	else
		local p = {x=0, y=0}
		p[self.dim_name] = new_value - SNAP_EDGE_THICKNESS / 2
		if p.x < 0 then p.x = 0 end
		if p.y < 0 then p.y = 0 end
		if p.x + SNAP_EDGE_THICKNESS > self.screen_frame.x2 then
			p.x = self.screen_frame.x2 - SNAP_EDGE_THICKNESS
		end
		if p.y + SNAP_EDGE_THICKNESS > self.screen_frame.y2 then
			p.y = self.screen_frame.y2 - SNAP_EDGE_THICKNESS
		end
		self.canvas:topLeft(p)
	end
	if self.value == nil then
		self.canvas:show()
	end
	self.value = new_value
end

function SnapEdgeRenderer:delete()
	self.canvas:delete()
	self.canvas = nil
end

---@param win Window
---@return SnapEdgeRenderer, SnapEdgeRenderer
local function snap_edge_renderers_for_window(win)
	local screen = win:screen()
	local screen_frame = screen:frame()
	local snap_edge_renderer_x = SnapEdgeRenderer.new(screen_frame, "x")
	local snap_edge_renderer_y = SnapEdgeRenderer.new(screen_frame, "y")
	return snap_edge_renderer_x, snap_edge_renderer_y
end

--[[ MODULE ]]

return snap_edge_renderers_for_window
