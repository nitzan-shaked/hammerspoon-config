local SnapValues = require("snap_values")
local SnapEdgeRenderer = require("snap_edge_renderer")

local wu = require("utils.win_utils")
-- local mp = require("experimental.mini_preview")

local settings = require("settings")


--[[ MODULE ]]

local cls = {}

cls.name = "win_mouse"


--[[ CONFIG ]]

cls.cfg_schema = {
	name=cls.name,
	title="Win-Mouse",
	descr="Control window positions and sizes with the mouse.",
	items={{
		name="resize_only_bottom_right",
		title="Resize only bottom-right corner",
		descr="When enabled, resizing affects only the bottom-right corner.",
		control="checkbox",
		default=true,
	}},
}

---@alias DragMode "DRAG_MODE_RESIZE" | "DRAG_MODE_MOVE"

---@type table<DragMode, string[]?>
cls.kbd_mods = {
	DRAG_MODE_MOVE=nil,
	DRAG_MODE_RESIZE=nil,
}
---@type string[]?
cls.kbd_mods_limit_axis = {}
cls.snap_threshold = 25
cls.snap_edge_thickness = 2
---@type Color
cls.snap_edge_color = {red=0, green=1, blue=1, alpha=0.5}


--[[ STATE ]]

cls.initialized = false
cls.started = false

---@type EventTap
cls.kbd_mods_event_tap = nil
---@type EventTap
cls.drag_event_tap = nil

---@type DragMode?
cls.drag_mode = nil
---@type Window?
cls.drag_win = nil
---@type Screen?
cls.drag_screen = nil
---@type Geometry?
cls.drag_screen_frame = nil
---@type Geometry?
cls.drag_win_initial_frame = nil
---@type MiniPreview?
cls.drag_win_mini_preview = nil
---@type {x: number, y: number}?
cls.drag_initial_mouse_pos = nil
---@type string?
cls.drag_edge_name_x = nil
---@type string?
cls.drag_edge_name_y = nil
---@type boolean?
cls.drag_do_snap = nil

---@type boolean?
cls.drag_really_started = nil
---@type SnapValues?
cls.snap_values_x = nil
---@type SnapValues?
cls.snap_values_y = nil
---@type SnapEdgeRenderer?
cls.snap_edge_renderer_x = nil
---@type SnapEdgeRenderer?
cls.snap_edge_renderer_y = nil


--[[ LOGIC ]]

function cls.isInitialized()
	return cls.initialized
end


function cls.init()
	assert(not cls.initialized, "already initialized")

	local cfg = settings.loadPluginSection(cls.name)
	cls.resize_only_bottom_right = cfg.resize_only_bottom_right

	cls.kbd_mods_event_tap = hs.eventtap.new(
		{hs.eventtap.event.types.flagsChanged},
		cls._kbd_mods_event_handler
	)
	cls.drag_event_tap = hs.eventtap.new(
		{hs.eventtap.event.types.mouseMoved},
		cls._drag_event_handler
	)

	cls.started = false
	cls.initialized = true
	cls.start()
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	cls.kbd_mods_event_tap:start()
	cls.started = true
end


function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	cls._stop_drag()
	cls.kbd_mods_event_tap:stop()
	cls.started = false
end


function cls.unload()
	if not cls.initialized then return end
	cls.stop()
	cls.kbd_mods_event_tap = nil
	cls.kbd_drag_event_tap = nil
	cls.initialized = false
end


---@param mods_move string[]?
---@param mods_resize string[]?
---@param mods_limit_axis string[]?
function cls.setKbdMods(mods_move, mods_resize, mods_limit_axis)
	assert(cls.initialized, "not initialized")
	cls.kbd_mods.DRAG_MODE_MOVE = mods_move
	cls.kbd_mods.DRAG_MODE_RESIZE = mods_resize
	cls.kbd_mods_limit_axis = mods_limit_axis
end


---@param e Event
---@return number, number
function cls._get_drag_dx_dy(e)
	assert(cls.drag_mode)
	assert(cls.drag_win_initial_frame)
	assert(cls.drag_initial_mouse_pos)

	local mouse_pos = hs.mouse.absolutePosition()
	local dx = mouse_pos.x - cls.drag_initial_mouse_pos.x
	local dy = mouse_pos.y - cls.drag_initial_mouse_pos.y

	---@type "x" | "y" | nil
	local limit_to_axis = nil

	if cls.kbd_mods_limit_axis and #cls.kbd_mods_limit_axis > 0 then
		if not e:getFlags():contain(cls.kbd_mods_limit_axis) then
			limit_to_axis = nil
		elseif math.abs(dx) >= 50 or math.abs(dy) >= 50 then
			limit_to_axis = math.abs(dx) >= math.abs(dy) and "x" or "y"
		end
	end

	if cls.drag_mode == "DRAG_MODE_RESIZE" and cls.drag_win_mini_preview then
		-- keep aspect ratio for mini-preview
		dy = dx * cls.drag_win_initial_frame.h / cls.drag_win_initial_frame.w

	elseif limit_to_axis == "x" then
		dy = 0

	elseif limit_to_axis == "y" then
		dx = 0

	end

	return dx, dy
end


---@param e Event
function cls._drag_event_handler(e)
	-- get by how much we moved from initial position
	local dx, dy = cls._get_drag_dx_dy(e)

	assert(cls.drag_mode)
	assert(cls.drag_win)
	assert(cls.drag_do_snap ~= nil)

	-- don't do anything (raise drag window, snap, move/resize, ...)
	-- until the mouse has started moving a bit
	if not cls.drag_really_started then
		if not (math.abs(dx) >= 3 or math.abs(dy) >= 3) then
			return
		end
		cls.drag_win:focus()

		if cls.drag_do_snap then
			cls.snap_values_x, cls.snap_values_y = cls._snap_values_for_window(cls.drag_win)
			cls.snap_edge_renderer_x, cls.snap_edge_renderer_y = cls._snap_edge_renderers_for_window(cls.drag_win)
		end

		cls.drag_really_started = true
	end

	assert(cls.drag_screen)
	assert(cls.drag_screen_frame)
	assert(cls.drag_win_initial_frame)
	assert(cls.drag_edge_name_x)
	assert(cls.drag_edge_name_y)

	-- move or resize window from orig position by that amount
	local new_frame = cls.drag_win_initial_frame:copy()

	---@param delta number
	local function update_x(delta)
		if cls.drag_mode == "DRAG_MODE_MOVE" then
			assert(cls.drag_edge_name_x == "x1")
			new_frame.x1 = new_frame.x1 + delta
			return
		end

		local orig_x1 = cls.drag_win_initial_frame.x1
		local orig_x2 = cls.drag_win_initial_frame.x2

		local new_x1 = new_frame.x1 + (cls.drag_edge_name_x == "x1" and delta or 0)
		local new_x2 = new_frame.x2 + (cls.drag_edge_name_x == "x2" and delta or 0)
		local new_width = new_x2 - new_x1

		local min_width = 75
		if new_width >= min_width then
			new_frame.x1 = new_x1
			new_frame.w = new_width
			return
		end

		new_frame.w = min_width

		if cls.drag_edge_name_x == "x1" then
			new_frame.x1 = orig_x2 - new_frame.w
		elseif cls.drag_edge_name_x == "x2" then
			new_frame.x1 = orig_x1
		end

	end

	---@param delta number
	local function update_y(delta)
		if cls.drag_mode == "DRAG_MODE_MOVE" then
			assert(cls.drag_edge_name_y == "y1")
			new_frame.y1 = new_frame.y1 + delta
			return
		end

		local orig_y1 = cls.drag_win_initial_frame.y1
		local orig_y2 = cls.drag_win_initial_frame.y2

		local new_y1 = new_frame.y1 + (cls.drag_edge_name_y == "y1" and delta or 0)
		local new_y2 = new_frame.y2 + (cls.drag_edge_name_y == "y2" and delta or 0)
		local new_height = new_y2 - new_y1

		local min_height = 75
		if new_height >= min_height then
			new_frame.y1 = new_y1
			new_frame.h = new_height

			if new_frame.y1 < cls.drag_screen_frame.y1 then
				new_frame.y1 = cls.drag_screen_frame.y1
				new_frame.y2 = orig_y2
			end

			return
		end

		new_frame.h = min_height

		if cls.drag_edge_name_y == "y1" then
			new_frame.y1 = orig_y2 - new_frame.h
		elseif cls.drag_edge_name_y == "y2" then
			new_frame.y1 = orig_y1
		end
	end

	update_x(dx)
	update_y(dy)

	if cls.drag_do_snap then
		assert(cls.snap_values_x)
		assert(cls.snap_values_y)
		assert(cls.snap_edge_renderer_x)
		assert(cls.snap_edge_renderer_y)

		-- snap: get relevant edges
		---@type integer?, integer?
		local snap_value_x, snap_delta_x = nil, nil
		---@type integer?, integer?
		local snap_value_y, snap_delta_y = nil, nil

		if cls.drag_mode == "DRAG_MODE_MOVE" then
			if snap_value_x == nil then
				snap_value_x, snap_delta_x = cls.snap_values_x:query(new_frame.x1)
			end
			if snap_value_x == nil then
				snap_value_x, snap_delta_x = cls.snap_values_x:query(new_frame.x2)
			end
			if snap_value_y == nil then
				snap_value_y, snap_delta_y = cls.snap_values_y:query(new_frame.y1)
			end
			if snap_value_y == nil then
				snap_value_y, snap_delta_y = cls.snap_values_y:query(new_frame.y2)
			end

		elseif cls.drag_mode == "DRAG_MODE_RESIZE" then
			snap_value_x, snap_delta_x = cls.snap_values_x:query(new_frame[cls.drag_edge_name_x])
			snap_value_y, snap_delta_y = cls.snap_values_y:query(new_frame[cls.drag_edge_name_y])

		else
			assert(false)

		end

		-- snap: draw snap edges
		cls.snap_edge_renderer_x:update(snap_value_x)
		cls.snap_edge_renderer_y:update(snap_value_y)

		-- snap: adjust new frame to snap edges
		update_x(snap_delta_x or 0)
		update_y(snap_delta_y or 0)
	end

	-- set new frame
	local w = (cls.drag_win_mini_preview or cls.drag_win)
	assert(w ~= nil)
	w:setFrame(new_frame)
end


---@param mode_name DragMode
function cls._start_drag(mode_name)
	assert(cls.drag_mode == nil)

	assert(cls.drag_win == nil)
	assert(cls.drag_screen == nil)
	assert(cls.drag_screen_frame == nil)
	assert(cls.drag_win_initial_frame == nil)
	assert(cls.drag_win_mini_preview == nil)
	assert(cls.drag_initial_mouse_pos == nil)
	assert(cls.drag_edge_name_x == nil)
	assert(cls.drag_edge_name_y == nil)
	assert(cls.drag_do_snap == nil)

	assert(cls.drag_really_started == nil)
	assert(cls.snap_values_x == nil)
	assert(cls.snap_values_y == nil)
	assert(cls.snap_edge_renderer_x == nil)
	assert(cls.snap_edge_renderer_y == nil)

	cls.drag_win = wu.window_under_pointer(true)
	if not cls.drag_win then return end

	cls.drag_mode = mode_name
	cls.drag_screen = cls.drag_win:screen()
	cls.drag_screen_frame = cls.drag_screen:frame()
	cls.drag_win_initial_frame = cls.drag_win:frame()
	-- cls.drag_win_mini_preview = mp.MiniPreview.by_mini_preview_window(cls.drag_win)
	cls.drag_win_mini_preview = nil
	cls.drag_initial_mouse_pos = hs.mouse.absolutePosition()

	if cls.drag_mode == "DRAG_MODE_MOVE" then
		cls.drag_edge_name_x = "x1"
		cls.drag_edge_name_y = "y1"
	elseif cls.drag_mode == "DRAG_MODE_RESIZE" then
		local t = cls.resize_only_bottom_right and 0.0 or 0.25
		local xt = cls.drag_win_initial_frame.x1 + t * cls.drag_win_initial_frame.w
		local yt = cls.drag_win_initial_frame.y1 + t * cls.drag_win_initial_frame.h
		cls.drag_edge_name_x = cls.drag_initial_mouse_pos.x < xt and "x1" or "x2"
		cls.drag_edge_name_y = cls.drag_initial_mouse_pos.y < yt and "y1" or "y2"
	else
		assert(false)
	end

	cls.drag_do_snap = (cls.drag_mode == "DRAG_MODE_MOVE" or not cls.drag_win_mini_preview)

	cls.drag_really_started = false
	cls.drag_event_tap:start()
end


function cls._stop_drag()
	cls.drag_event_tap:stop()

	cls.drag_mode = nil
	cls.drag_win = nil
	cls.drag_screen = nil
	cls.drag_screen_frame = nil
	cls.drag_win_initial_frame = nil
	cls.drag_win_mini_preview = nil
	cls.drag_initial_mouse_pos = nil
	cls.drag_edge_name_x = nil
	cls.drag_edge_name_y = nil
	cls.drag_do_snap = nil

	cls.drag_really_started = nil
	cls.snap_values_x = nil
	cls.snap_values_y = nil
	if cls.snap_edge_renderer_x then cls.snap_edge_renderer_x:delete() end
	if cls.snap_edge_renderer_y then cls.snap_edge_renderer_y:delete() end
	cls.snap_edge_renderer_x = nil
	cls.snap_edge_renderer_y = nil
end


---@param mods EventMods
function cls._maybe_start_drag(mods)
	for mode_name, mode_kbd_mods in pairs(cls.kbd_mods) do
		if mode_kbd_mods and #mode_kbd_mods > 0 and mods:contain(mode_kbd_mods) then
			cls._start_drag(mode_name)
			return
		end
	end
end


---@param mods EventMods
function cls._maybe_stop_drag(mods)
	assert(cls.drag_mode)
	local mode_kbd_mods = cls.kbd_mods[cls.drag_mode]
	assert(mode_kbd_mods)
	assert(#mode_kbd_mods > 0)
	if not mods:contain(mode_kbd_mods) then
		cls._stop_drag()
	end
end


---@param e Event
function cls._kbd_mods_event_handler(e)
	local mods = e:getFlags()
	if cls.drag_mode then
		cls._maybe_stop_drag(mods)
	else
		cls._maybe_start_drag(mods)
	end
end


---@param win Window
---@return SnapValues, SnapValues
function cls._snap_values_for_window(win)
	local screen = win:screen()
	local screen_frame = screen:frame()

	local snap_values_x = SnapValues(screen_frame.x1, screen_frame.x2, cls.snap_threshold)
	local snap_values_y = SnapValues(screen_frame.y1, screen_frame.y2, cls.snap_threshold)

	snap_values_x:add(screen_frame.x1)
	snap_values_x:add(screen_frame.x2)
	snap_values_x:add(screen_frame.center.x)

	snap_values_y:add(screen_frame.y1)
	snap_values_y:add(screen_frame.y2)
	snap_values_y:add(screen_frame.center.y)

	-- edges of other on-screen windows
	hs.fnutils.each(wu.my_visibleWindows(), function (w)
		if w:screen() ~= screen then return end
		if not w:isStandard() then return end
		if w == win then return end
		-- if mp.MiniPreview.for_window(w) then return end
		local win_frame = w:frame()
		snap_values_x:add(win_frame.x1)
		snap_values_x:add(win_frame.x2)
		snap_values_y:add(win_frame.y1)
		snap_values_y:add(win_frame.y2)
	end)

	return snap_values_x, snap_values_y
end


---@param win Window
---@return SnapEdgeRenderer, SnapEdgeRenderer
function cls._snap_edge_renderers_for_window(win)
	local screen_frame = win:screen():frame()
	local renderer_x = SnapEdgeRenderer(screen_frame, "x", cls.snap_edge_thickness, cls.snap_edge_color)
	local renderer_y = SnapEdgeRenderer(screen_frame, "y", cls.snap_edge_thickness, cls.snap_edge_color)
	return renderer_x, renderer_y
end


--[[ MODULE ]]

return cls
