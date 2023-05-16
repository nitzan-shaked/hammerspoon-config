local fn   = require("hs.fnutils")
local geom = require("hs.geometry")
local wu   = require("win_utils")
local snap = require("snap")
local mp   = require("mini_preview")

-- CONFIG

local kbd_mods_win_move		= nil
local kbd_mods_win_resize	= nil
local kbd_mods_limit_axis	= nil

local SNAP_THRESHOLD		= 25
local SNAP_EDGE_WIDTH		= 1
local SNAP_EDGE_COLOR		= {red=0, green=1, blue=1, alpha=0.5}

-- STATE

local drag_mode = nil
local drag_really_started = nil

local drag_win = nil
local drag_win_initial_frame = nil
local drag_win_mini_preview = nil

local drag_initial_mouse_pos = nil
local drag_limit_to_axis = nil
local drag_keep_aspect = nil

local last_snap_edge_values = nil

--[[ AUX ]]

local window_under_pointer = wu.window_under_pointer

--[[ DRAG EVENT HANDLER ]]

local function get_drag_dx_dy(e)
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

local function drag_event_handler(e)
	-- get by how much we moved from initial position
	local dx, dy = get_drag_dx_dy(e, mods)

	-- don't do anything (raise drag window, snap, move/resize, ...)
	-- until the mouse has started moving a bit
	if not drag_really_started then
		if not (math.abs(dx) >= 3 or math.abs(dy) >= 3) then
			return
		end
		drag_win:focus()
		snap.start(drag_win)
		drag_really_started = true
	end

	-- move or resize window from orig position by that amount
	local drag_dim1
	local drag_dim2

	if drag_mode == "DRAG_MODE_MOVE" then
		drag_dim1 = "x"
		drag_dim2 = "y"
	elseif drag_mode == "DRAG_MODE_RESIZE" then
		drag_dim1 = "w"
		drag_dim2 = "h"
	end

	local new_frame = drag_win_initial_frame:copy()
	new_frame[drag_dim1] = drag_win_initial_frame[drag_dim1] + dx
	new_frame[drag_dim2] = drag_win_initial_frame[drag_dim2] + dy

	-- snap
	local snap_edges = {}

	if drag_mode == "DRAG_MODE_RESIZE" then
		snap_edges["x2"] = snap.get_edge("x", new_frame.x2)
		snap_edges["y2"] = snap.get_edge("y", new_frame.y2)

	elseif drag_mode == "DRAG_MODE_MOVE" then
		snap_edges["x1"] = snap.get_edge("x", new_frame.x1)
		snap_edges["x2"] = snap.get_edge("x", new_frame.x2)
		--
		snap_edges["y1"] = snap.get_edge("y", new_frame.y1)
		snap_edges["y2"] = snap.get_edge("y", new_frame.y2)
	end

	local snap_delta = {x=nil, y=nil}

	for _, se in pairs(snap_edges) do
		if se.value ~= nil and snap_delta[se.dim] == nil then
			snap_delta[se.dim] = se.delta
		end
	end

	if snap_delta.x == nil then snap_delta.x = 0 end
	if snap_delta.y == nil then snap_delta.y = 0 end

	new_frame[drag_dim1] = new_frame[drag_dim1] + snap_delta.x
	new_frame[drag_dim2] = new_frame[drag_dim2] + snap_delta.y

	for se_name, se in pairs(snap_edges) do
		if last_snap_edge_values[se_name] ~= se.value then
			snap.draw_edge(se_name, se)
			last_snap_edge_values[se_name] = se.value
		end
	end

	-- keep aspect ratio
	if drag_mode == "DRAG_MODE_RESIZE" and (drag_keep_aspect or drag_win_mini_preview) then
		new_frame.h = drag_win_initial_frame.h * new_frame.w / drag_win_initial_frame.w
	end

	-- set new frame
	(drag_win_mini_preview or drag_win):setFrame(new_frame)

	return nil
end

local drag_event_tap = hs.eventtap.new(
	{hs.eventtap.event.types.mouseMoved},
	drag_event_handler
)

--[[ START / STOP ]]

local function start_drag(mode)
	drag_mode = nil
	drag_really_started = nil

	drag_win = window_under_pointer(true)
	if not drag_win then
		return
	end
	drag_win_initial_frame = drag_win:frame()
	drag_win_mini_preview = mp.MiniPreview.by_preview_window(drag_win)

	drag_initial_mouse_pos = hs.mouse.absolutePosition()
	drag_limit_to_axis = nil
	drag_keep_aspect = nil

	last_snap_edge_values = {}

	drag_mode = mode
	drag_event_tap:start()
end

local function stop_drag()
	drag_mode = nil
	drag_win = nil
	drag_win_mini_preview = nil
	snap.stop()
	drag_event_tap:stop()
end

local function maybe_stop_drag(mods)
	if drag_mode == "DRAG_MODE_MOVE" and not mods:contain(kbd_mods_win_move) then
		stop_drag()
	elseif drag_mode == "DRAG_MODE_RESIZE" and not mods:contain(kbd_mods_win_resize) then
		stop_drag()
	end
end

--[[ KBD MODS EVENTS ]]

local function mods_event_handler(e)
	local mods = e:getFlags()

	if not drag_mode then
		if kbd_mods_win_move and mods:contain(kbd_mods_win_move) then
			start_drag("DRAG_MODE_MOVE")
		elseif kbd_mods_win_resize and mods:contain(kbd_mods_win_resize) then
			start_drag("DRAG_MODE_RESIZE")
		end
	else
		maybe_stop_drag(mods)
	end

	return nil
end

-- NOTE: must return this as part of module, or else
-- this gets GC'ed and the even stops working, and we
-- are stuck in drag mode...
local mods_event_tap = hs.eventtap.new(
	{hs.eventtap.event.types.flagsChanged},
	mods_event_handler
)
mods_event_tap:start()

--[[ BIND HOTKEYS ]]

local function set_kbd_mods(win_move, win_resize, limit_axis)
	kbd_mods_win_move = win_move
	kbd_mods_win_resize = win_resize
	kbd_mods_limit_axis = limit_axis
end

--[[ MODULE ]]

return {
	set_kbd_mods=set_kbd_mods,
	mods_event_tap=mods_event_tap,
}
