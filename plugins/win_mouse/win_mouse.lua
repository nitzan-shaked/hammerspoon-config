local Module = require("module")
local class = require("utils.class")

local SnapValues = require("snap_values")
local SnapEdgeRenderer = require("snap_edge_renderer")
local wu = require("utils.win_utils")



---@class WinMouse: Module
local WinMouse = class.make_class("WinMouse", Module)


local SNAP_THRESHOLD = 25
local SNAP_EDGE_THICKNESS = 2
---@type Color
local SNAP_EDGE_COLOR = {red=0, green=1, blue=1, alpha=0.5}


---@alias DragMode "DRAG_MODE_RESIZE" | "DRAG_MODE_MOVE"


function WinMouse:__init__()
	Module.__init__(
		self,
		"win_mouse",
		"Win-Mouse",
		"Control window positions and sizes with the mouse.",
		{{
			name="resize_only_bottom_right",
			title="Resize only bottom-right corner",
			descr="When enabled, resizing affects only the bottom-right corner.",
			control="checkbox",
			default=true,
		}, {
			name="move_mods",
			title="Move modifiers",
			descr="Modifiers to hold down for 'move' mode.",
			control="mods",
			default={"ctrl", "cmd"},
		}, {
			name="resize_mods",
			title="Resize modifiers",
			descr="Modifiers to hold down for 'resize' mode.",
			control="mods",
			default={"ctrl", "alt"},
		}},
		{}
	)

	---@type table<DragMode, string[]?>
	self._kbd_mods = {
		DRAG_MODE_MOVE=nil,
		DRAG_MODE_RESIZE=nil,
	}
	---@type string[]?
	self._kbd_mods_limit_axis = {}

	---@type EventTap
	self._kbd_mods_event_tap = nil
	---@type EventTap
	self._drag_event_tap = nil

	---@type DragMode?
	self._drag_mode = nil
	---@type Window?
	self._drag_win = nil
	---@type Screen?
	self._drag_screen = nil
	---@type Geometry?
	self._drag_screen_frame = nil
	---@type Geometry?
	self._drag_win_initial_frame = nil
	---@type MiniPreview?
	self._drag_win_mini_preview = nil
	---@type {x: number, y: number}?
	self._drag_initial_mouse_pos = nil
	---@type string?
	self._drag_edge_name_x = nil
	---@type string?
	self._drag_edge_name_y = nil
	---@type boolean?
	self._drag_do_snap = nil

	---@type boolean?
	self._drag_really_started = nil
	---@type SnapValues?
	self._snap_values_x = nil
	---@type SnapValues?
	self._snap_values_y = nil
	---@type SnapEdgeRenderer?
	self._snap_edge_renderer_x = nil
	---@type SnapEdgeRenderer?
	self._snap_edge_renderer_y = nil

end


function WinMouse:loadImpl(settings)
	self._resize_only_bottom_right = settings.resize_only_bottom_right
	self._kbd_mods.DRAG_MODE_MOVE = settings.move_mods
	self._kbd_mods.DRAG_MODE_RESIZE = settings.resize_mods

	self._kbd_mods_event_tap = hs.eventtap.new(
		{hs.eventtap.event.types.flagsChanged},
		function(e) self:_kbd_mods_event_handler(e) end
	)
	self._drag_event_tap = hs.eventtap.new(
		{hs.eventtap.event.types.mouseMoved},
		function(e) self:_drag_event_handler(e) end
	)
end


function WinMouse:startImpl()
	self._kbd_mods_event_tap:start()
end


function WinMouse:stopImpl()
	self:_stop_drag()
	self._kbd_mods_event_tap:stop()
end


function WinMouse:unloadImpl()
	self._kbd_mods_event_tap = nil
	self._drag_event_tap = nil
end


---@param e Event
---@return number, number
function WinMouse:_get_drag_dx_dy(e)
	assert(self._drag_mode)
	assert(self._drag_win_initial_frame)
	assert(self._drag_initial_mouse_pos)

	local mouse_pos = hs.mouse.absolutePosition()
	local dx = mouse_pos.x - self._drag_initial_mouse_pos.x
	local dy = mouse_pos.y - self._drag_initial_mouse_pos.y

	---@type "x" | "y" | nil
	local limit_to_axis = nil

	if self._kbd_mods_limit_axis and #self._kbd_mods_limit_axis > 0 then
		if not e:getFlags():contain(self._kbd_mods_limit_axis) then
			limit_to_axis = nil
		elseif math.abs(dx) >= 50 or math.abs(dy) >= 50 then
			limit_to_axis = math.abs(dx) >= math.abs(dy) and "x" or "y"
		end
	end

	if self._drag_mode == "DRAG_MODE_RESIZE" and self._drag_win_mini_preview then
		-- keep aspect ratio for mini-preview
		dy = dx * self._drag_win_initial_frame.h / self._drag_win_initial_frame.w

	elseif limit_to_axis == "x" then
		dy = 0

	elseif limit_to_axis == "y" then
		dx = 0

	end

	return dx, dy
end


---@param e Event
function WinMouse:_drag_event_handler(e)
	-- get by how much we moved from initial position
	local dx, dy = self:_get_drag_dx_dy(e)

	assert(self._drag_mode)
	assert(self._drag_win)
	assert(self._drag_do_snap ~= nil)

	-- don't do anything (raise drag window, snap, move/resize, ...)
	-- until the mouse has started moving a bit
	if not self._drag_really_started then
		if not (math.abs(dx) >= 3 or math.abs(dy) >= 3) then
			return
		end
		self._drag_win:focus()

		if self._drag_do_snap then
			self._snap_values_x, self._snap_values_y = self:_snap_values_for_window(self._drag_win)
			self._snap_edge_renderer_x, self._snap_edge_renderer_y = self:_snap_edge_renderers_for_window(self._drag_win)
		end

		self._drag_really_started = true
	end

	assert(self._drag_screen)
	assert(self._drag_screen_frame)
	assert(self._drag_win_initial_frame)
	assert(self._drag_edge_name_x)
	assert(self._drag_edge_name_y)

	-- move or resize window from orig position by that amount
	local new_frame = self._drag_win_initial_frame:copy()

	---@param delta number
	local function update_x(delta)
		if self._drag_mode == "DRAG_MODE_MOVE" then
			assert(self._drag_edge_name_x == "x1")
			new_frame.x1 = new_frame.x1 + delta
			return
		end

		local orig_x1 = self._drag_win_initial_frame.x1
		local orig_x2 = self._drag_win_initial_frame.x2

		local new_x1 = new_frame.x1 + (self._drag_edge_name_x == "x1" and delta or 0)
		local new_x2 = new_frame.x2 + (self._drag_edge_name_x == "x2" and delta or 0)
		local new_width = new_x2 - new_x1

		local min_width = 75
		if new_width >= min_width then
			new_frame.x1 = new_x1
			new_frame.w = new_width
			return
		end

		new_frame.w = min_width

		if self._drag_edge_name_x == "x1" then
			new_frame.x1 = orig_x2 - new_frame.w
		elseif self._drag_edge_name_x == "x2" then
			new_frame.x1 = orig_x1
		end

	end

	---@param delta number
	local function update_y(delta)
		if self._drag_mode == "DRAG_MODE_MOVE" then
			assert(self._drag_edge_name_y == "y1")
			new_frame.y1 = new_frame.y1 + delta
			return
		end

		local orig_y1 = self._drag_win_initial_frame.y1
		local orig_y2 = self._drag_win_initial_frame.y2

		local new_y1 = new_frame.y1 + (self._drag_edge_name_y == "y1" and delta or 0)
		local new_y2 = new_frame.y2 + (self._drag_edge_name_y == "y2" and delta or 0)
		local new_height = new_y2 - new_y1

		local min_height = 75
		if new_height >= min_height then
			new_frame.y1 = new_y1
			new_frame.h = new_height

			if new_frame.y1 < self._drag_screen_frame.y1 then
				new_frame.y1 = self._drag_screen_frame.y1
				new_frame.y2 = orig_y2
			end

			return
		end

		new_frame.h = min_height

		if self._drag_edge_name_y == "y1" then
			new_frame.y1 = orig_y2 - new_frame.h
		elseif self._drag_edge_name_y == "y2" then
			new_frame.y1 = orig_y1
		end
	end

	update_x(dx)
	update_y(dy)

	if self._drag_do_snap then
		assert(self._snap_values_x)
		assert(self._snap_values_y)
		assert(self._snap_edge_renderer_x)
		assert(self._snap_edge_renderer_y)

		-- snap: get relevant edges
		---@type integer?, integer?
		local snap_value_x, snap_delta_x = nil, nil
		---@type integer?, integer?
		local snap_value_y, snap_delta_y = nil, nil

		if self._drag_mode == "DRAG_MODE_MOVE" then
			if snap_value_x == nil then
				snap_value_x, snap_delta_x = self._snap_values_x:query(new_frame.x1)
			end
			if snap_value_x == nil then
				snap_value_x, snap_delta_x = self._snap_values_x:query(new_frame.x2)
			end
			if snap_value_y == nil then
				snap_value_y, snap_delta_y = self._snap_values_y:query(new_frame.y1)
			end
			if snap_value_y == nil then
				snap_value_y, snap_delta_y = self._snap_values_y:query(new_frame.y2)
			end

		elseif self._drag_mode == "DRAG_MODE_RESIZE" then
			snap_value_x, snap_delta_x = self._snap_values_x:query(new_frame[self._drag_edge_name_x])
			snap_value_y, snap_delta_y = self._snap_values_y:query(new_frame[self._drag_edge_name_y])

		else
			assert(false)

		end

		-- snap: draw snap edges
		self._snap_edge_renderer_x:update(snap_value_x)
		self._snap_edge_renderer_y:update(snap_value_y)

		-- snap: adjust new frame to snap edges
		update_x(snap_delta_x or 0)
		update_y(snap_delta_y or 0)
	end

	-- set new frame
	local w = (self._drag_win_mini_preview or self._drag_win)
	assert(w ~= nil)
	w:setFrame(new_frame)
end


---@param mode_name DragMode
function WinMouse:_start_drag(mode_name)
	assert(self._drag_mode == nil)

	assert(self._drag_win == nil)
	assert(self._drag_screen == nil)
	assert(self._drag_screen_frame == nil)
	assert(self._drag_win_initial_frame == nil)
	assert(self._drag_win_mini_preview == nil)
	assert(self._drag_initial_mouse_pos == nil)
	assert(self._drag_edge_name_x == nil)
	assert(self._drag_edge_name_y == nil)
	assert(self._drag_do_snap == nil)

	assert(self._drag_really_started == nil)
	assert(self._snap_values_x == nil)
	assert(self._snap_values_y == nil)
	assert(self._snap_edge_renderer_x == nil)
	assert(self._snap_edge_renderer_y == nil)

	self._drag_win = wu.window_under_pointer(true)
	if not self._drag_win then return end

	self._drag_mode = mode_name
	self._drag_screen = self._drag_win:screen()
	self._drag_screen_frame = self._drag_screen:frame()
	self._drag_win_initial_frame = self._drag_win:frame()
	-- self.drag_win_mini_preview = mp.MiniPreview.by_mini_preview_window(self.drag_win)
	self._drag_win_mini_preview = nil
	self._drag_initial_mouse_pos = hs.mouse.absolutePosition()

	if self._drag_mode == "DRAG_MODE_MOVE" then
		self._drag_edge_name_x = "x1"
		self._drag_edge_name_y = "y1"
	elseif self._drag_mode == "DRAG_MODE_RESIZE" then
		local t = self._resize_only_bottom_right and 0.0 or 0.25
		local xt = self._drag_win_initial_frame.x1 + t * self._drag_win_initial_frame.w
		local yt = self._drag_win_initial_frame.y1 + t * self._drag_win_initial_frame.h
		self._drag_edge_name_x = self._drag_initial_mouse_pos.x < xt and "x1" or "x2"
		self._drag_edge_name_y = self._drag_initial_mouse_pos.y < yt and "y1" or "y2"
	else
		assert(false)
	end

	self._drag_do_snap = (self._drag_mode == "DRAG_MODE_MOVE" or not self._drag_win_mini_preview)

	self._drag_really_started = false
	self._drag_event_tap:start()
end


function WinMouse:_stop_drag()
	self._drag_event_tap:stop()

	self._drag_mode = nil
	self._drag_win = nil
	self._drag_screen = nil
	self._drag_screen_frame = nil
	self._drag_win_initial_frame = nil
	self._drag_win_mini_preview = nil
	self._drag_initial_mouse_pos = nil
	self._drag_edge_name_x = nil
	self._drag_edge_name_y = nil
	self._drag_do_snap = nil

	self._drag_really_started = nil
	self._snap_values_x = nil
	self._snap_values_y = nil
	if self._snap_edge_renderer_x then self._snap_edge_renderer_x:delete() end
	if self._snap_edge_renderer_y then self._snap_edge_renderer_y:delete() end
	self._snap_edge_renderer_x = nil
	self._snap_edge_renderer_y = nil
end


---@param mods EventMods
function WinMouse:_maybe_start_drag(mods)
	for mode_name, mode_kbd_mods in pairs(self._kbd_mods) do
		if mode_kbd_mods and #mode_kbd_mods > 0 and mods:contain(mode_kbd_mods) then
			self:_start_drag(mode_name)
			return
		end
	end
end


---@param mods EventMods
function WinMouse:_maybe_stop_drag(mods)
	assert(self._drag_mode)
	local mode_kbd_mods = self._kbd_mods[self._drag_mode]
	assert(mode_kbd_mods)
	assert(#mode_kbd_mods > 0)
	if not mods:contain(mode_kbd_mods) then
		self:_stop_drag()
	end
end


---@param e Event
function WinMouse:_kbd_mods_event_handler(e)
	local mods = e:getFlags()
	if self._drag_mode then
		self:_maybe_stop_drag(mods)
	else
		self:_maybe_start_drag(mods)
	end
end


---@param win Window
---@return SnapValues, SnapValues
function WinMouse:_snap_values_for_window(win)
	local screen = win:screen()
	local screen_frame = screen:frame()

	local snap_values_x = SnapValues(screen_frame.x1, screen_frame.x2, SNAP_THRESHOLD)
	local snap_values_y = SnapValues(screen_frame.y1, screen_frame.y2, SNAP_THRESHOLD)

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
function WinMouse:_snap_edge_renderers_for_window(win)
	local screen_frame = win:screen():frame()
	local renderer_x = SnapEdgeRenderer(screen_frame, "x", SNAP_EDGE_THICKNESS, SNAP_EDGE_COLOR)
	local renderer_y = SnapEdgeRenderer(screen_frame, "y", SNAP_EDGE_THICKNESS, SNAP_EDGE_COLOR)
	return renderer_x, renderer_y
end


return WinMouse()
