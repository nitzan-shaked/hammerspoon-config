local wu = require("win_utils")
local mp = require("mini_preview")
local class = require("utils.class")

local snap_values_for_window = require("snap_values")
local snap_edge_renderers_for_window = require("snap_edge_renderer")

--[[ STATE ]]

---@alias DragMode "DRAG_MODE_RESIZE" | "DRAG_MODE_MOVE"

---@type table<DragMode, string[]?>
local kbd_mods = {
	DRAG_MODE_MOVE={},
	DRAG_MODE_RESIZE={},
}
---@type string[]?
local kbd_mods_limit_axis = {}

---@type DragMode?
local drag_mode = nil
---@type Window?
local drag_win = nil
---@type Screen?
local drag_screen = nil
---@type Geometry?
local drag_screen_frame = nil
---@type Geometry?
local drag_win_initial_frame = nil
---@type MiniPreview?
local drag_win_mini_preview = nil
---@type {x: number, y: number}?
local drag_initial_mouse_pos = nil
---@type string?
local drag_edge_name_x = nil
---@type string?
local drag_edge_name_y = nil
---@type boolean?
local drag_do_snap = nil

---@type boolean?
local drag_really_started = nil
---@type SnapValues?
local snap_values_x = nil
---@type SnapValues?
local snap_values_y = nil
---@type SnapEdgeRenderer?
local snap_edge_renderer_x = nil
---@type SnapEdgeRenderer?
local snap_edge_renderer_y = nil

--[[ DRAG EVENT HANDLER ]]

---@param e Event
---@return number, number
local function get_drag_dx_dy(e)
	assert(drag_mode)
	assert(drag_win_initial_frame)
	assert(drag_initial_mouse_pos)

	local mouse_pos = hs.mouse.absolutePosition()
	local dx = mouse_pos.x - drag_initial_mouse_pos.x
	local dy = mouse_pos.y - drag_initial_mouse_pos.y

	---@type "x" | "y" | nil
	local limit_to_axis = nil

	if kbd_mods_limit_axis and #kbd_mods_limit_axis > 0 then
		if not e:getFlags():contain(kbd_mods_limit_axis) then
			limit_to_axis = nil
		elseif math.abs(dx) >= 50 or math.abs(dy) >= 50 then
			limit_to_axis = math.abs(dx) >= math.abs(dy) and "x" or "y"
		end
	end

	if drag_mode == "DRAG_MODE_RESIZE" and drag_win_mini_preview then
		-- keep aspect ratio for mini-preview
		dy = dx * drag_win_initial_frame.h / drag_win_initial_frame.w

	elseif limit_to_axis == "x" then
		dy = 0

	elseif limit_to_axis == "y" then
		dx = 0

	end

	return dx, dy
end

---@param e Event
local function drag_event_handler(e)
	-- get by how much we moved from initial position
	local dx, dy = get_drag_dx_dy(e)

	assert(drag_mode)
	assert(drag_win)
	assert(drag_do_snap ~= nil)

	-- don't do anything (raise drag window, snap, move/resize, ...)
	-- until the mouse has started moving a bit
	if not drag_really_started then
		if not (math.abs(dx) >= 3 or math.abs(dy) >= 3) then
			return
		end
		drag_win:focus()

		if drag_do_snap then
			snap_values_x, snap_values_y = snap_values_for_window(drag_win)
			snap_edge_renderer_x, snap_edge_renderer_y = snap_edge_renderers_for_window(drag_win)
		end

		drag_really_started = true
	end

	assert(drag_screen)
	assert(drag_screen_frame)
	assert(drag_win_initial_frame)
	assert(drag_edge_name_x)
	assert(drag_edge_name_y)

	-- move or resize window from orig position by that amount
	local new_frame = drag_win_initial_frame:copy()

	---@param edge_name string
	---@param delta number
	local function update_x(edge_name, delta)
		if drag_mode == "DRAG_MODE_MOVE" then
			assert(edge_name == "x1")
			new_frame.x1 = new_frame.x1 + delta
			return
		end

		local orig_x1 = drag_win_initial_frame.x1
		local orig_x2 = drag_win_initial_frame.x2

		local new_x1 = new_frame.x1 + (edge_name == "x1" and delta or 0)
		local new_x2 = new_frame.x2 + (edge_name == "x2" and delta or 0)
		local new_width = new_x2 - new_x1

		local min_width = 75
		if new_width >= min_width then
			new_frame.x1 = new_x1
			new_frame.w = new_width
			return
		end

		new_frame.w = min_width

		if edge_name == "x1" then
			new_frame.x1 = orig_x2 - new_frame.w
		elseif edge_name == "x2" then
			new_frame.x1 = orig_x1
		end

	end

	---@param edge_name string
	---@param delta number
	local function update_y(edge_name, delta)
		if drag_mode == "DRAG_MODE_MOVE" then
			assert(edge_name == "y1")
			new_frame.y1 = new_frame.y1 + delta
			return
		end

		local orig_y1 = drag_win_initial_frame.y1
		local orig_y2 = drag_win_initial_frame.y2

		local new_y1 = new_frame.y1 + (edge_name == "y1" and delta or 0)
		local new_y2 = new_frame.y2 + (edge_name == "y2" and delta or 0)
		local new_height = new_y2 - new_y1

		local min_height = 75
		if new_height >= min_height then
			new_frame.y1 = new_y1
			new_frame.h = new_height

			if new_frame.y1 < drag_screen_frame.y1 then
				new_frame.y1 = drag_screen_frame.y1
				new_frame.y2 = orig_y2
			end

			return
		end

		new_frame.h = min_height

		if edge_name == "y1" then
			new_frame.y1 = orig_y2 - new_frame.h
		elseif edge_name == "y2" then
			new_frame.y1 = orig_y1
		end
	end

	update_x(drag_edge_name_x, dx)
	update_y(drag_edge_name_y, dy)

	if drag_do_snap then
		assert(snap_values_x)
		assert(snap_values_y)
		assert(snap_edge_renderer_x)
		assert(snap_edge_renderer_y)

		-- snap: get relevant edges
		---@type integer?, integer?
		local snap_value_x, snap_delta_x = nil, nil
		---@type integer?, integer?
		local snap_value_y, snap_delta_y = nil, nil

		if drag_mode == "DRAG_MODE_MOVE" then
			if snap_value_x == nil then
				snap_value_x, snap_delta_x = snap_values_x:query(new_frame.x1)
			end
			if snap_value_x == nil then
				snap_value_x, snap_delta_x = snap_values_x:query(new_frame.x2)
			end
			if snap_value_y == nil then
				snap_value_y, snap_delta_y = snap_values_y:query(new_frame.y1)
			end
			if snap_value_y == nil then
				snap_value_y, snap_delta_y = snap_values_y:query(new_frame.y2)
			end

		elseif drag_mode == "DRAG_MODE_RESIZE" then
			snap_value_x, snap_delta_x = snap_values_x:query(new_frame[drag_edge_name_x])
			snap_value_y, snap_delta_y = snap_values_y:query(new_frame[drag_edge_name_y])

		else
			assert(false)

		end

		-- snap: draw snap edges
		snap_edge_renderer_x:update(snap_value_x)
		snap_edge_renderer_y:update(snap_value_y)

		-- snap: adjust new frame to snap edges
		update_x(drag_edge_name_x, snap_delta_x or 0)
		update_y(drag_edge_name_y, snap_delta_y or 0)
	end

	-- set new frame
	local w = (drag_win_mini_preview or drag_win)
	w:setFrame(new_frame)
end

local drag_event_tap = hs.eventtap.new(
	{hs.eventtap.event.types.mouseMoved},
	drag_event_handler
)

--[[ START / STOP ]]

---@param mode_name DragMode
local function start_drag(mode_name)
	assert(drag_mode == nil)

	assert(drag_win == nil)
	assert(drag_screen == nil)
	assert(drag_screen_frame == nil)
	assert(drag_win_initial_frame == nil)
	assert(drag_win_mini_preview == nil)
	assert(drag_initial_mouse_pos == nil)
	assert(drag_edge_name_x == nil)
	assert(drag_edge_name_y == nil)
	assert(drag_do_snap == nil)

	assert(drag_really_started == nil)
	assert(snap_values_x == nil)
	assert(snap_values_y == nil)
	assert(snap_edge_renderer_x == nil)
	assert(snap_edge_renderer_y == nil)

	drag_win = wu.window_under_pointer(true)
	if not drag_win then return end

	drag_mode = mode_name
	drag_screen = drag_win:screen()
	drag_screen_frame = drag_screen:frame()
	drag_win_initial_frame = drag_win:frame()
	drag_win_mini_preview = mp.MiniPreview.by_mini_preview_window(drag_win)
	drag_initial_mouse_pos = hs.mouse.absolutePosition()

	if drag_mode == "DRAG_MODE_MOVE" then
		drag_edge_name_x = "x1"
		drag_edge_name_y = "y1"
	elseif drag_mode == "DRAG_MODE_RESIZE" then
		local t = 0.25
		local xt = drag_win_initial_frame.x1 + t * drag_win_initial_frame.w
		local yt = drag_win_initial_frame.y1 + t * drag_win_initial_frame.h
		drag_edge_name_x = drag_initial_mouse_pos.x < xt and "x1" or "x2"
		drag_edge_name_y = drag_initial_mouse_pos.y < yt and "y1" or "y2"
	else
		assert(false)
	end

	drag_do_snap = (drag_mode == "DRAG_MODE_MOVE" or not drag_win_mini_preview)

	drag_really_started = false
	drag_event_tap:start()
end

local function stop_drag()
	drag_event_tap:stop()

	drag_mode = nil
	drag_win = nil
	drag_screen = nil
	drag_screen_frame = nil
	drag_win_initial_frame = nil
	drag_win_mini_preview = nil
	drag_initial_mouse_pos = nil
	drag_edge_name_x = nil
	drag_edge_name_y = nil
	drag_do_snap = nil

	drag_really_started = nil
	snap_values_x = nil
	snap_values_y = nil
	if snap_edge_renderer_x then snap_edge_renderer_x:delete() end
	if snap_edge_renderer_y then snap_edge_renderer_y:delete() end
	snap_edge_renderer_x = nil
	snap_edge_renderer_y = nil
end

---@param mods EventMods
local function maybe_start_drag(mods)
	for mode_name, mode_kbd_mods in pairs(kbd_mods) do
		if mode_kbd_mods and #mode_kbd_mods > 0 and mods:contain(mode_kbd_mods) then
			start_drag(mode_name)
			return
		end
	end
end

---@param mods EventMods
local function maybe_stop_drag(mods)
	assert(drag_mode)
	local mode_kbd_mods = kbd_mods[drag_mode]
	assert(mode_kbd_mods)
	assert(#mode_kbd_mods > 0)
	if not mods:contain(mode_kbd_mods) then
		stop_drag()
	end
end

--[[ KBD MODS EVENTS ]]

---@param e Event
local function kbd_mods_event_handler(e)
	local mods = e:getFlags()
	if drag_mode then
		maybe_stop_drag(mods)
	else
		maybe_start_drag(mods)
	end
end

--[[ BIND HOTKEYS ]]

---@param mods_move string[]?
---@param mods_resize string[]?
---@param mods_limit_axis string[]?
local function set_kbd_mods(mods_move, mods_resize, mods_limit_axis)
	kbd_mods.DRAG_MODE_MOVE = mods_move
	kbd_mods.DRAG_MODE_RESIZE = mods_resize
	kbd_mods_limit_axis = mods_limit_axis
end

--[[ INIT ]]

-- NOTE: must return this as part of module, or else
-- this gets GC'ed and the even stops working, and we
-- are stuck in drag mode...

local kbd_mods_event_tap = hs.eventtap.new(
	{hs.eventtap.event.types.flagsChanged},
	kbd_mods_event_handler
)
kbd_mods_event_tap:start()

--[[ MODULE ]]

return {
	set_kbd_mods=set_kbd_mods,
	kbd_mods_event_tap=kbd_mods_event_tap,
}
