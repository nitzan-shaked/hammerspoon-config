local fn = require("hs.fnutils")
local wu = require("win_utils")

--[[ CONFIG ]]

local SNAP_THRESHOLD  = 25
local SNAP_EDGE_WIDTH = 1
local SNAP_EDGE_COLOR = {red=0, green=1, blue=1, alpha=0.5}

--[[ STATE ]]

local screen_frame = nil
local snap_values = nil
local edge_canvas = nil

--[[ LOGIC ]]

local function prepare_screen_edges(win)

	snap_values = {x={}, y={}}
	edge_canvas = {}

	local screen = win:screen()
	screen_frame = screen:frame()

	local function add_snap_value(dim, value, min_value, max_value)
		if value < min_value then return end
		if value > max_value then return end
		local sv = snap_values[dim]
		local mid_bucket = math.floor(value / SNAP_THRESHOLD)
		for bucket = mid_bucket-1, mid_bucket+1 do
			if not sv[bucket] then sv[bucket] = {} end
			sv[bucket][value] = true
		end
	end

	local function add_x_snap_value(value)
		add_snap_value("x", value, screen_frame.x1, screen_frame.x2)
	end

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
end

local function get_edge(dim, query_value)
	local bucket = math.floor(query_value / SNAP_THRESHOLD)
	local relevant_values = snap_values[dim][bucket]
	if relevant_values then
		for snap_value in pairs(relevant_values) do
			local delta = snap_value - query_value
			if math.abs(delta) <= SNAP_THRESHOLD then
				return {dim=dim, value=snap_value, delta=delta}
			end
		end
	end
	return {dim=dim, value=nil, delta=0}
end

local function draw_edge(edge_name, snap_edge)
	local canvas = edge_canvas[edge_name]

	if snap_edge.value == nil then
		if canvas then canvas:hide() end
		return
	end

	local rect = screen_frame:copy()
	if snap_edge.dim == "x" then
		rect.x = snap_edge.value
		rect.w = SNAP_EDGE_WIDTH
	else
		rect.y = snap_edge.value
		rect.h = SNAP_EDGE_WIDTH
	end
	rect:fit(screen_frame)

	if not canvas then
		canvas = hs.canvas.new({x=0, y=0, w=rect.w, h=rect.h})
		canvas:appendElements({
			type = "rectangle",
			frame = {x=0, y=0, w="100%", h="100%"},
			action = "fill",
			fillColor = SNAP_EDGE_COLOR,
		})
		edge_canvas[edge_name] = canvas
	end
	canvas:topLeft(rect.topleft)
	canvas:show()
end

local function delete_all_edges()
	if edge_canvas then
		fn.each(edge_canvas, function(canvas) canvas:delete() end)
		edge_canvas = nil
	end
end

local function start(win)
	prepare_screen_edges(win)
end

local function stop()
	delete_all_edges()
end

--[[ MODULE ]]

return {
	start=start,
	stop=stop,
	get_edge=get_edge,
	draw_edge=draw_edge,
}
