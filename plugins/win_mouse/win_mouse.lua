local Module = require("module")
local class = require("utils.class")

local SnapValues = require("snap_values")
local SnapEdgeRenderer = require("snap_edge_renderer")
local wu = require("utils.win_utils")



---@class WinMouse: Module
local WinMouse = class.make_class("WinMouse", Module)


local SNAP_THRESHOLD = 25
local SNAP_EDGE_THICKNESS = 2
local SNAP_EDGE_COLOR = {red=0.12, green=0.61, blue=0.82, alpha=1}


---@alias DragMode "DRAG_MODE_RESIZE" | "DRAG_MODE_MOVE"


local _CFG_RESIZE_ONLY_BOTTOM_RIGHT = {
	name="resize_only_bottom_right",
	title="Resize only bottom-right corner?",
	descr="When enabled, resizing affects only the bottom-right corner.",
	control="checkbox",
	default=true,
}
local _CFG_MOVE_MODS = {
	name="move_mods",
	title="Move modifiers",
	descr="Modifiers to hold down for 'move' mode.",
	control="mods",
	default={"ctrl", "cmd"},
}
local _CFG_RESIZE_MODS = {
	name="resize_mods",
	title="Resize modifiers",
	descr="Modifiers to hold down for 'resize' mode.",
	control="mods",
	default={"ctrl", "alt"},
}


function WinMouse:__init__()
	Module.__init__(
		self,
		"win_mouse",
		"Win-Mouse",
		"Control window positions and sizes with the mouse.",
		{
			_CFG_RESIZE_ONLY_BOTTOM_RIGHT,
			_CFG_MOVE_MODS,
			_CFG_RESIZE_MODS,
		},
		{}
	)
end


function WinMouse:loadImpl(settings)
	self._resize_only_bottom_right = settings.resize_only_bottom_right
	self._kbd_mods = {
		DRAG_MODE_MOVE = settings.move_mods,
		DRAG_MODE_RESIZE = settings.resize_mods,
	}
	---@type string[]?
	self._kbd_mods_limit_axis = {}

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
	---@type DragMode?
	self._drag_mode = nil
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


---@param mode_name DragMode
function WinMouse:_start_drag(mode_name)
	assert(self._drag_mode == nil)

	self._drag_win = wu.window_under_pointer(true)
	if not self._drag_win then return end

	self._drag_mode = mode_name
	self._drag_screen = self._drag_win:screen()
	self._drag_screen_frame = self._drag_screen:frame()
	self._drag_win_initial_frame = self._drag_win:frame()
	---@type MiniPreview?
	-- self.drag_win_mini_preview = mp.MiniPreview.by_mini_preview_window(self.drag_win)
	self._drag_win_mini_preview = nil
	self._drag_initial_mouse_pos = hs.mouse.absolutePosition()

	if self._drag_mode == "DRAG_MODE_MOVE" then
		self._drag_edge_idx = {
			x = 1,
			y = 1,
		}
	elseif self._drag_mode == "DRAG_MODE_RESIZE" then
		local t = self._resize_only_bottom_right and 0.0 or 0.25
		local xt = self._drag_win_initial_frame.x1 + t * self._drag_win_initial_frame.w
		local yt = self._drag_win_initial_frame.y1 + t * self._drag_win_initial_frame.h
		self._drag_edge_idx = {
			x = self._drag_initial_mouse_pos.x < xt and 1 or 2,
			y = self._drag_initial_mouse_pos.y < yt and 1 or 2,
		}
	else
		assert(false)
	end

	self._other_edge_idx = {
		x = 3 - self._drag_edge_idx.x,
		y = 3 - self._drag_edge_idx.y,
	}

	self._drag_really_started = false

	self._drag_do_snap = (self._drag_mode == "DRAG_MODE_MOVE" or not self._drag_win_mini_preview)

	self._drag_event_tap:start()
end


function WinMouse:_stop_drag()
	self._drag_mode = nil
	self._drag_event_tap:stop()
	if (self._drag_do_snap) then
		self._snap_values = {}
		for _, dim_renderers in pairs(self._snap_edge_renderers or {}) do
			for _, renderer in pairs(dim_renderers) do
				renderer:delete()
			end
		end
		self._snap_edge_renderers = {}
	end
end


---@param e Event
function WinMouse:_drag_event_handler(e)
	assert(self._drag_mode)

	local mouse_dx, mouse_dy = self:_get_mouse_dx_dy(e)

	-- don't do anything (raise drag window, snap, move/resize, ...)
	-- until the mouse has moved a bit
	if not self._drag_really_started then
		if not (math.abs(mouse_dx) >= 3 or math.abs(mouse_dy) >= 3) then
			return
		end
		self:_really_start_drag()
	end

	local new_frame = self._drag_win_initial_frame:copy()

	-- move / resize window from initial position by mouse movement amount
	self:_update_frame_dim(new_frame, "x", "w", mouse_dx)
	self:_update_frame_dim(new_frame, "y", "h", mouse_dy)

	-- snap
	if self._drag_do_snap then
		self:_snap_frame(new_frame)
	end

	-- set new frame
	local w = (self._drag_win_mini_preview or self._drag_win)
	assert(w ~= nil)
	w:setFrame(new_frame)
end


---@param e Event
---@return number, number
function WinMouse:_get_mouse_dx_dy(e)
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


function WinMouse:_really_start_drag()
	self._drag_win:focus()

	if self._drag_do_snap then
		self._snap_values = self:_snap_values_for_window(self._drag_win)
		self._snap_edge_renderers = self:_snap_edge_renderers_for_window(self._drag_win)
	end

	self._drag_really_started = true
end


---@param new_frame Geometry
---@param dim_name string
---@param size_name string
---@param delta number
function WinMouse:_update_frame_dim(new_frame, dim_name, size_name, delta)
	local drag_edge_idx = self._drag_edge_idx[dim_name]
	local drag_edge_name  = dim_name .. drag_edge_idx

	if self._drag_mode == "DRAG_MODE_MOVE" then
		new_frame[drag_edge_name] = new_frame[drag_edge_name] + delta
		return
	end

	local edge_1_name = dim_name .. 1
	local edge_2_name = dim_name .. 2

	local initial_edge_1_value = self._drag_win_initial_frame[edge_1_name]
	local initial_edge_2_value = self._drag_win_initial_frame[edge_2_name]

	local new_edge_1_value = new_frame[edge_1_name] + (drag_edge_idx == 1 and delta or 0)
	local new_edge_2_value = new_frame[edge_2_name] + (drag_edge_idx == 2 and delta or 0)
	local new_size = new_edge_2_value - new_edge_1_value

	local min_size = 75
	if new_size >= min_size then
		new_frame[edge_1_name] = new_edge_1_value
		new_frame[size_name] = new_size

		if new_frame[edge_1_name] < self._drag_screen_frame[edge_1_name] then
			new_frame[edge_1_name] = self._drag_screen_frame[edge_1_name]
			new_frame[edge_2_name] = initial_edge_2_value
		end

		return
	end

	new_frame[size_name] = min_size

	if drag_edge_idx == 1 then
		new_frame[edge_1_name] = initial_edge_2_value - new_frame[size_name]
	elseif drag_edge_idx == 2 then
		new_frame[edge_1_name] = initial_edge_1_value
	end
end


---@param new_frame Geometry
function WinMouse:_snap_frame(new_frame)
	local snap_value_x, snap_delta_x = self._snap_values.x:query(new_frame["x" .. self._drag_edge_idx.x])
	local snap_value_y, snap_delta_y = self._snap_values.y:query(new_frame["y" .. self._drag_edge_idx.y])

	if self._drag_mode == "DRAG_MODE_MOVE" then
		if snap_value_x == nil then
			snap_value_x, snap_delta_x = self._snap_values.x:query(new_frame["x" .. self._other_edge_idx.x])
		end
		if snap_value_y == nil then
			snap_value_y, snap_delta_y = self._snap_values.y:query(new_frame["y" .. self._other_edge_idx.y])
		end
	end

	-- draw snap edges
	self._snap_edge_renderers.x[self._drag_edge_idx.x]:setValue(snap_value_x)
	self._snap_edge_renderers.y[self._drag_edge_idx.y]:setValue(snap_value_y)

	-- adjust new frame to snap edges
	self:_update_frame_dim(new_frame, "x", "w", snap_delta_x or 0)
	self:_update_frame_dim(new_frame, "y", "h", snap_delta_y or 0)

	-- show other snap edge if it happens to perfectly align
	local function maybe_draw_other_snap_edge(dim_name)
		local other_edge_idx = self._other_edge_idx[dim_name]
		local other_edge_name = dim_name .. other_edge_idx
		local other_renderer = self._snap_edge_renderers[dim_name][other_edge_idx]

		local other_snap_value, other_snap_delta = self._snap_values[dim_name]:query(new_frame[other_edge_name])
		if not (other_snap_delta ~= nil and math.abs(other_snap_delta) <= 0.5) then
			other_snap_value = nil
		end
		other_renderer:setValue(other_snap_value)
	end

	maybe_draw_other_snap_edge("x")
	maybe_draw_other_snap_edge("y")
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


---@param win Window
---@return table<string, SnapValues>
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

	return {
		x=snap_values_x,
		y=snap_values_y,
	}
end


---@param win Window
---@return table<string, table<integer, SnapEdgeRenderer>>
function WinMouse:_snap_edge_renderers_for_window(win)
	local screen_frame = win:screen():fullFrame()
	return {
		x = {
			[1] = SnapEdgeRenderer(screen_frame, "x", SNAP_EDGE_THICKNESS, SNAP_EDGE_COLOR),
			[2] = SnapEdgeRenderer(screen_frame, "x", SNAP_EDGE_THICKNESS, SNAP_EDGE_COLOR),
		},
		y = {
			[1] = SnapEdgeRenderer(screen_frame, "y", SNAP_EDGE_THICKNESS, SNAP_EDGE_COLOR),
			[2] = SnapEdgeRenderer(screen_frame, "y", SNAP_EDGE_THICKNESS, SNAP_EDGE_COLOR),
		},
	}
end


return WinMouse()
