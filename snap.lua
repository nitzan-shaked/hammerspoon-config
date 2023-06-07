local fn = require("hs.fnutils")
local wu = require("win_utils")

--[[ CONFIG ]]

local SNAP_THRESHOLD  = 25
local SNAP_EDGE_WIDTH = 1
local SNAP_EDGE_COLOR = {red=0, green=1, blue=1, alpha=0.5}

--[[ LOGIC ]]

---@alias DimName "x" | "y"
---@alias Bucket table<integer, boolean>
---@alias BucketMap table<integer, Bucket>
---@alias QueryResult {dim: DimName, value: integer?, delta: integer?}

---@class Snap
---@field screen_frame Geometry
---@field bucket_maps {x: BucketMap, y: BucketMap}
---@field edge_canvas table<string, Canvas>
local Snap = {}
Snap.__index = Snap


---@param win Window
---@return Snap
function Snap.new(win)
	local screen = win:screen()
	local screen_frame = screen:frame()

	local bucket_maps = {x={}, y={}}

	---@param dim "x" | "y"
	---@param value number
	---@param min_value number
	---@param max_value number
	local function add_snap_value(dim, value, min_value, max_value)
		if value < min_value then return end
		if value > max_value then return end
		local buckets = bucket_maps[dim]
		local mid_bucket = math.floor(value / SNAP_THRESHOLD)
		for b = mid_bucket - 1, mid_bucket + 1 do
			if not buckets[b] then buckets[b] = {} end
			buckets[b][value] = true
		end
	end

	---@param value number
	local function add_x_snap_value(value)
		add_snap_value("x", value, screen_frame.x1, screen_frame.x2)
	end

	---@param value number
	local function add_y_snap_value(value)
		add_snap_value("y", value, screen_frame.y1, screen_frame.y2)
	end

	-- screen edges
	add_x_snap_value(screen_frame.x1)
	add_x_snap_value(screen_frame.x2)
	add_x_snap_value(screen_frame.center.x)
	add_y_snap_value(screen_frame.y1)
	add_y_snap_value(screen_frame.y2)
	add_y_snap_value(screen_frame.center.y)

	-- edges of other on-screen windows
	fn.each(wu.my_visibleWindows(), function (w)
		if w:screen() ~= screen then return end
		if not w:isStandard() then return end
		if w == win then return end
		local win_frame = w:frame()
		add_x_snap_value(win_frame.x1)
		add_x_snap_value(win_frame.x2)
		add_y_snap_value(win_frame.y1)
		add_y_snap_value(win_frame.y2)
	end)

	local self = {}
	setmetatable(self, Snap)
	self.screen_frame = screen_frame
	self.bucket_maps = bucket_maps
	self.edge_canvas = {}
	return self
end

---@param dim DimName
---@param q integer
---@return QueryResult
function Snap:query(dim, q)
	local bucket = math.floor(q / SNAP_THRESHOLD)
	local snap_values = self.bucket_maps[dim][bucket] or {}
	for sv in pairs(snap_values) do
		local delta = sv - q
		if math.abs(delta) <= SNAP_THRESHOLD then
			return {dim=dim, value=sv, delta=delta}
		end
	end
	return {dim=dim, value=nil, delta=nil}
end

---@param edge_name string
---@param query_result QueryResult
function Snap:draw_edge(edge_name, query_result)
	local canvas = self.edge_canvas[edge_name]

	if query_result.value == nil then
		if canvas then
			canvas:hide()
		end
		return
	end

	if not canvas then
		local rect = self.screen_frame:copy()
		if query_result.dim == "x" then
			rect.x = query_result.value - SNAP_EDGE_WIDTH / 2
			rect.w = SNAP_EDGE_WIDTH
		else
			rect.y = query_result.value - SNAP_EDGE_WIDTH / 2
			rect.h = SNAP_EDGE_WIDTH
		end

		canvas = hs.canvas.new(rect)
		canvas:appendElements({
			type="rectangle",
			action="fill",
			fillColor=SNAP_EDGE_COLOR,
		})
		self.edge_canvas[edge_name] = canvas
	end
	canvas:show()
end

function Snap:delete()
	fn.each(self.edge_canvas, function(c) c:delete() end)
	self.screen_frame = {}
	self.bucket_maps = {}
	self.edge_canvas = {}
end

--[[ MODULE ]]

return Snap
