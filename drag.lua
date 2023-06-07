local wu = require("win_utils")
local mp = require("mini_preview")

local snap_values_for_window = require("snap")
local snap_edge_renderers_for_window = require("snap_edge_renderer")

--[[ CONFIG ]]

local kbd_mods_win_move		= nil
local kbd_mods_win_resize	= nil
local kbd_mods_limit_axis	= nil

--[[ STATE ]]

---@class DragMode
---@field dim1 "x" | "w"
---@field dim2 "y" | "h"
---@field snap_edges_x string[]
---@field snap_edges_y string[]
local DragMode = {}

---@param dim1 "x" | "w"
---@param dim2 "y" | "h"
---@param snap_edges_x string[]
---@param snap_edges_y string[]
---@return DragMode
function DragMode.new(dim1, dim2, snap_edges_x, snap_edges_y)
	return {
		dim1=dim1,
		dim2=dim2,
		snap_edges_x=snap_edges_x,
		snap_edges_y=snap_edges_y,
	}
end

---@alias DragModeName "DRAG_MODE_RESIZE" | "DRAG_MODE_MOVE"

---@type table<DragModeName, DragMode>
local DRAG_MODES = {
	DRAG_MODE_MOVE=DragMode.new("x", "y", {"x1", "x2"}, {"y1", "y2"}),
	DRAG_MODE_RESIZE=DragMode.new("w", "h", {"x2"}, {"y2"}),
}

---@type string?
local drag_mode_name = nil
---@type DragMode?
local drag_mode = nil
---@type boolean?
local drag_really_started = nil

---@type Window?
local drag_win = nil
---@type Geometry?
local drag_win_initial_frame = nil
---@type MiniPreview?
local drag_win_mini_preview = nil

---@type {x: number, y: number}?
local drag_initial_mouse_pos = nil
---@type "x" | "y" | nil
local drag_limit_to_axis = nil
---@type boolean?
local drag_keep_aspect = nil

---@type SnapValues1D?
local snap_values_x = nil
---@type SnapValues1D?
local snap_values_y = nil
---@type SnapEdgeRenderer?
local snap_edge_renderer_x = nil
---@type SnapEdgeRenderer?
local snap_edge_renderer_y = nil

--[[ DRAG EVENT HANDLER ]]

---@param e Event
---@return number, number
local function get_drag_dx_dy(e)
	assert(drag_initial_mouse_pos)

	local mouse_pos = hs.mouse.absolutePosition()
	local dx = mouse_pos.x - drag_initial_mouse_pos.x
	local dy = mouse_pos.y - drag_initial_mouse_pos.y

	local mods = e:getFlags()
	if not mods:contain(kbd_mods_limit_axis) then
		-- if "limit axis" key is not pressed, no limiting
		drag_limit_to_axis = nil

	elseif math.abs(dx) >= 50 or math.abs(dy) >= 50 then
		-- "limit axis" key is pressed
		-- but we only set the limiting axis if mouse has moved "more than a little" in either axis,
		-- so there's no "noise" when just starting
		drag_limit_to_axis = math.abs(dx) >= math.abs(dy) and "x" or "y"

	else
		-- "limit axis" key is pressed, but mouse hasn't moved enough
		-- => do nothing, don't change existing value of drag_limit_to_axis
	end

	if drag_limit_to_axis == "x" then
		dy = 0
	elseif drag_limit_to_axis == "y" then
		dx = 0
	end

	return dx, dy
end

---@param e Event
local function drag_event_handler(e)
	-- get by how much we moved from initial position
	local dx, dy = get_drag_dx_dy(e)

	-- don't do anything (raise drag window, snap, move/resize, ...)
	-- until the mouse has started moving a bit
	if not drag_really_started then
		if not (math.abs(dx) >= 3 or math.abs(dy) >= 3) then
			return
		end
		assert(drag_win)
		drag_win:focus()

		snap_values_x, snap_values_y = snap_values_for_window(drag_win)
		snap_edge_renderer_x, snap_edge_renderer_y = snap_edge_renderers_for_window(drag_win)

		drag_really_started = true
	end

	assert(drag_mode)
	assert(drag_win_initial_frame)
	assert(snap_values_x)
	assert(snap_values_y)
	assert(snap_edge_renderer_x)
	assert(snap_edge_renderer_y)

	-- move or resize window from orig position by that amount
	local new_frame = drag_win_initial_frame:copy()
	new_frame[drag_mode.dim1] = drag_win_initial_frame[drag_mode.dim1] + dx
	new_frame[drag_mode.dim2] = drag_win_initial_frame[drag_mode.dim2] + dy

	-- snap: get relevant edges
	---@type integer?, integer?
	local snap_value_x, snap_delta_x = nil, nil
	---@type integer?, integer?
	local snap_value_y, snap_delta_y = nil, nil

	for _, edge_name in ipairs(drag_mode.snap_edges_x) do
		snap_value_x, snap_delta_x = snap_values_x:query(new_frame[edge_name])
		if snap_value_x ~= nil then break end
	end
	for _, edge_name in ipairs(drag_mode.snap_edges_y) do
		snap_value_y, snap_delta_y = snap_values_y:query(new_frame[edge_name])
		if snap_value_y ~= nil then break end
	end

	-- snap: draw snap edges
	snap_edge_renderer_x:update(snap_value_x)
	snap_edge_renderer_y:update(snap_value_y)

	-- snap: adjust new frame to snap edges
	new_frame[drag_mode.dim1] = new_frame[drag_mode.dim1] + (snap_delta_x or 0)
	new_frame[drag_mode.dim2] = new_frame[drag_mode.dim2] + (snap_delta_y or 0)

	-- keep aspect ratio
	if drag_mode_name == "DRAG_MODE_RESIZE" and (drag_keep_aspect or drag_win_mini_preview) then
		new_frame.h = drag_win_initial_frame.h * new_frame.w / drag_win_initial_frame.w
	end

	-- set new frame
	(drag_win_mini_preview or drag_win):setFrame(new_frame)
end

local drag_event_tap = hs.eventtap.new(
	{hs.eventtap.event.types.mouseMoved},
	drag_event_handler
)

--[[ START / STOP ]]

---@param mode_name DragModeName
local function start_drag(mode_name)
	assert(drag_mode_name == nil)
	assert(drag_mode == nil)
	assert(drag_really_started == nil)

	assert(drag_win == nil)
	assert(drag_win_initial_frame == nil)
	assert(drag_win_mini_preview == nil)

	assert(drag_initial_mouse_pos == nil)
	assert(drag_limit_to_axis == nil)
	assert(drag_keep_aspect == nil)

	assert(snap_values_x == nil)
	assert(snap_values_y == nil)
	assert(snap_edge_renderer_x == nil)
	assert(snap_edge_renderer_y == nil)

	drag_win = wu.window_under_pointer(true)
	if not drag_win then return end
	drag_win_initial_frame = drag_win:frame()
	drag_win_mini_preview = mp.MiniPreview.by_preview_window(drag_win)

	drag_initial_mouse_pos = hs.mouse.absolutePosition()

	drag_mode_name = mode_name
	drag_mode = assert(DRAG_MODES[mode_name])
	drag_really_started = false
	drag_event_tap:start()
end

local function stop_drag()
	drag_mode_name = nil
	drag_mode = nil
	drag_really_started = nil

	drag_win = nil
	drag_win_initial_frame = nil
	drag_win_mini_preview = nil

	drag_initial_mouse_pos = nil
	drag_limit_to_axis = nil
	drag_keep_aspect = nil

	snap_values_x = nil
	snap_values_y = nil
	if snap_edge_renderer_x then
		snap_edge_renderer_x:delete()
		snap_edge_renderer_x = nil
	end
	if snap_edge_renderer_y then
		snap_edge_renderer_y:delete()
		snap_edge_renderer_y = nil
	end

	drag_event_tap:stop()
end

---@param mods EventMods
local function maybe_start_drag(mods)
	if kbd_mods_win_move and mods:contain(kbd_mods_win_move) then
		start_drag("DRAG_MODE_MOVE")
	elseif kbd_mods_win_resize and mods:contain(kbd_mods_win_resize) then
		start_drag("DRAG_MODE_RESIZE")
	end
end

---@param mods EventMods
local function maybe_stop_drag(mods)
	if drag_mode_name == "DRAG_MODE_MOVE" and not mods:contain(kbd_mods_win_move) then
		stop_drag()
	elseif drag_mode_name == "DRAG_MODE_RESIZE" and not mods:contain(kbd_mods_win_resize) then
		stop_drag()
	end
end

--[[ KBD MODS EVENTS ]]

---@param e Event
local function mods_event_handler(e)
	local mods = e:getFlags()
	if drag_mode then
		maybe_stop_drag(mods)
	else
		maybe_start_drag(mods)
	end
end

--[[ BIND HOTKEYS ]]

local function set_kbd_mods(win_move, win_resize, limit_axis)
	kbd_mods_win_move = win_move
	kbd_mods_win_resize = win_resize
	kbd_mods_limit_axis = limit_axis
end

--[[ INIT ]]

-- NOTE: must return this as part of module, or else
-- this gets GC'ed and the even stops working, and we
-- are stuck in drag mode...
local mods_event_tap = hs.eventtap.new(
	{hs.eventtap.event.types.flagsChanged},
	mods_event_handler
)
mods_event_tap:start()

--[[ MODULE ]]

return {
	set_kbd_mods=set_kbd_mods,
	mods_event_tap=mods_event_tap,
}
