local anim = require("animate")
local hsu = require("hammerspoon_utils")

--[[ CONFIG ]]

local INITIAL_SCALE_FACTOR = 0.3
local PREVIEW_ALPHA = 0.6
local FOCUSED_ALPHA = 0.9

--[[ LOGIC ]]

local hs_window_metatable = hs.getObjectMetatable("hs.window")

---@class MiniPreview
---@field mp_id integer
---@field orig_win Window
---@field orig_win_id integer
---@field ax_subrole string
local MiniPreview = {
	__next_mp_id = 0,
	__mp_id_to_mini_preview = {},
	__orig_win_id_to_mini_preview = {},
}
MiniPreview.__index = MiniPreview

---@param orig_win_id integer | Window
function MiniPreview.for_window(orig_win_id)
	if getmetatable(orig_win_id) == hs_window_metatable then
		---@cast orig_win_id Window
		orig_win_id = orig_win_id:id()
	end
	---@cast orig_win_id integer
	return MiniPreview.__orig_win_id_to_mini_preview[orig_win_id]
end

---@param mp_win Window
function MiniPreview.by_preview_window(mp_win)
	local subrole = mp_win:subrole()
	if subrole:sub(1, 13) ~= "mini_preview." then
		return nil
	end
	local mini_preview_id = subrole:sub(14, subrole:len()) + 0
	return MiniPreview.__mp_id_to_mini_preview[mini_preview_id]
end

---@param orig_win Window
---@return MiniPreview
function MiniPreview.new(orig_win)
	local orig_win_size = orig_win:size()

	local mini_preview_id = MiniPreview.__next_mp_id
	MiniPreview.__next_mp_id = MiniPreview.__next_mp_id + 1

	local self = {}
	setmetatable(self, MiniPreview)
	self._deleted = false
	self.mp_id = mini_preview_id
	self.orig_win_id = orig_win:id()
	self.orig_win = orig_win

	self.ax_subrole = "mini_preview." .. self.mp_id
	local canvas = hs.canvas.new({})
	canvas:_accessibilitySubrole(self.ax_subrole)
	canvas:level(hs.canvas.windowLevels.normal)
	canvas:topLeft(orig_win:topLeft())
	canvas:size(orig_win_size)

	canvas:appendElements({
		id="img",
		type="image",
		trackMouseEnterExit=true,
	})

	local zoom_button_size = 12
	local zoom_button_circle_radius = zoom_button_size / 2
	local zoom_button_arrow_margin = 2
	local zoom_button_arrow_size = zoom_button_size - 2 * zoom_button_arrow_margin - 2

	local zoom_button_x0 = 8
	local zoom_button_y0 = 4
	local zoom_button_x1 = zoom_button_x0 + zoom_button_size
	local zoom_button_y1 = zoom_button_y0 + zoom_button_size

	local zoom_button_arrow_x0 = zoom_button_x0 + zoom_button_arrow_margin
	local zoom_button_arrow_y0 = zoom_button_y0 + zoom_button_arrow_margin
	local zoom_button_arrow_x1 = zoom_button_x1 - zoom_button_arrow_margin
	local zoom_button_arrow_y1 = zoom_button_y1 - zoom_button_arrow_margin

	canvas:appendElements({
		id="zoom_button",
		type="circle",
		action="fill",
		fillColor={red=0.2, green=0.8, blue=0.25, alpha=0},
		center={
			x=zoom_button_x0 + zoom_button_circle_radius,
			y=zoom_button_y0 + zoom_button_circle_radius
		},
		radius=zoom_button_circle_radius,
		trackMouseEnterExit=true,
		trackMouseDown=true,
	})
	canvas:appendElements({
		id="zoom_button_arrow_1",
		type="segments",
		closed=true,
		action="fill",
		fillColor={red=0, green=0.4, blue=0, alpha=0},
		coordinates={
			{
				x=zoom_button_arrow_x0,
				y=zoom_button_arrow_y0,
			},
			{
				x=zoom_button_arrow_x0 + zoom_button_arrow_size,
				y=zoom_button_arrow_y0,
			},
			{
				x=zoom_button_arrow_x0,
				y=zoom_button_arrow_y0 + zoom_button_arrow_size,
			},
		},
	})
	canvas:appendElements({
		id="zoom_button_arrow_2",
		type="segments",
		closed=true,
		action="fill",
		fillColor={red=0, green=0.4, blue=0, alpha=0},
		coordinates={
			{
				x=zoom_button_arrow_x1,
				y=zoom_button_arrow_y1,
			},
			{
				x=zoom_button_arrow_x1 - zoom_button_arrow_size,
				y=zoom_button_arrow_y1,
			},
			{
				x=zoom_button_arrow_x1,
				y=zoom_button_arrow_y1 - zoom_button_arrow_size,
			},
		},
	})

	canvas:mouseCallback(function (...) self:mouseCallback(...) end)
	self.canvas = canvas

	self.timer = hs.timer.new(0.1, function () self:refreshImg() end)
	self.kbd_tap = hs.eventtap.new(
		{
			hs.eventtap.event.types.keyDown,
			hs.eventtap.event.types.keyUp,
		},
		function (...) self:onKey(...) end
	)

	MiniPreview.__mp_id_to_mini_preview[self.mp_id] = self
	MiniPreview.__orig_win_id_to_mini_preview[self.orig_win_id] = self

	self:refreshImg()
	self.canvas:show()
	self.timer:start()

	---@type AnimData
	local anim_data = {
		alpha={1, PREVIEW_ALPHA},
		size_factor={1, INITIAL_SCALE_FACTOR},
	}
	---@param step_data AnimStepData
	local function anim_step_func(step_data)
		canvas:alpha(step_data.alpha)
		canvas:size(orig_win_size * step_data.size_factor)
	end

	local function anim_done_func()
		hs.window.desktop():focus()
	end

	hs.timer.doAfter(0, function ()
		hs.timer.doAfter(0, function ()
			orig_win:setTopLeft({x=100000, y=100000})
			self.canvas:level(hs.canvas.windowLevels.floating)
			anim.animate(anim_data, 0.15, anim_step_func, anim_done_func)
		end)
	end)

	return self
end

function MiniPreview:delete()
	self._deleted = true

	local canvas_topLeft = self.canvas:topLeft()

	MiniPreview.__mp_id_to_mini_preview[self.mp_id] = nil
	MiniPreview.__orig_win_id_to_mini_preview[self.orig_win_id] = nil

	self.timer:stop()
	self.timer = nil

	self.kbd_tap:stop()
	self.kbd_tap = nil

	self.canvas:delete()
	self.canvas = nil

	self.orig_win:setTopLeft(canvas_topLeft)
end

---@return Window?
function MiniPreview:previeWindow()
	local expected_subrole = self.ax_subrole
	return hs.fnutils.find(
		hsu.hammerspoon_app:visibleWindows(),
		function (w) return w:subrole() == expected_subrole end
	)
end

function MiniPreview:refreshImg()
	if self._deleted then return end
	local img = hs.window.snapshotForID(self.orig_win_id, true)
	if not img then
		return
	end
	self.canvas["img"].image = img
end

---@param f Geometry
function MiniPreview:setFrame(f)
	self.canvas:frame(f)
	self:refreshImg()
end

---@param ev Event
function MiniPreview:onKey(ev)
	local ev_type = ev:getType()
	local key_str = ev:getCharacters()

	-- "swallow" event
	ev:setType(hs.eventtap.event.types.nullEvent)

	-- handle keyDown
	if ev_type == hs.eventtap.event.types.keyDown then
		if key_str == "x" or key_str == "q" then
			self:delete()
		end
	end
end

function MiniPreview:mouseCallback(canvas, ev_type, elem_id, x, y)
	if self._deleted then return end

	local function on_enter_canvas()
		self.canvas:alpha(FOCUSED_ALPHA)
		self.canvas["zoom_button"].fillColor.alpha = 1
		self.kbd_tap:start()
	end

	local function on_exit_canvas()
		self.canvas:alpha(PREVIEW_ALPHA)
		self.canvas["zoom_button"].fillColor.alpha = 0
		self.kbd_tap:stop()
	end

	local function on_enter_zoom_button()
		on_enter_canvas()
		self.canvas["zoom_button_arrow_1"].fillColor.alpha = 1
		self.canvas["zoom_button_arrow_2"].fillColor.alpha = 1
	end

	local function on_exit_zoom_button()
		on_exit_canvas()
		self.canvas["zoom_button_arrow_1"].fillColor.alpha = 0
		self.canvas["zoom_button_arrow_2"].fillColor.alpha = 0
	end

	if elem_id == "img" then
		if ev_type == "mouseEnter" then
			on_enter_canvas()
		elseif ev_type == "mouseExit" then
			on_exit_canvas()
		end

	elseif elem_id == "zoom_button" then
		if ev_type == "mouseEnter" then
			on_enter_zoom_button()
		elseif ev_type == "mouseExit" then
			on_exit_zoom_button()
		elseif ev_type == "mouseDown" then
			self:delete()
		end

	end
end

--- @param w Window?
local function start_for_window(w)
	if not w then return end
	if not MiniPreview.for_window(w) then
		MiniPreview.new(w)
	end
end

--- @param w Window?
local function stop_for_window(w)
	if not w then return end
	local mini_preview = MiniPreview.for_window(w)
	if mini_preview then
		mini_preview:delete()
	end
end

--- @param w Window?
local function toggle_for_window(w)
	if not w then return end
	local mini_preview = MiniPreview.for_window(w)
	if mini_preview then
		mini_preview:delete()
	else
		start_for_window(w)
	end
end

--[[ MODULE ]]

return {
	MiniPreview=MiniPreview,
	start_for_window=start_for_window,
	stop_for_window=stop_for_window,
	toggle_for_window=toggle_for_window,
}
