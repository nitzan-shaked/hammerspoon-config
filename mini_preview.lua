local anim = require("animate")

--[[ CONFIG ]]

local INITIAL_SCALE_FACTOR = 0.3
local PREVIEW_ALPHA = 0.6
local FOCUSED_ALPHA = 0.9
local BORDER_WIDTH = 5
local BORDER_PADDING = 2
local BORDER_COLOR = {red=0.2, green=0.5, blue=0.9}

--[[ LOGIC ]]

local hs_window_metatable = hs.getObjectMetatable("hs.window")

---@class MiniPreview
---@field id integer
---@field w Window
---@field win_id integer
local MiniPreview = {
	_next_id = 0,
	_id_to_mini_preview = {},
	_win_id_to_mini_preview = {},
}
MiniPreview.__index = MiniPreview

---@param win_id integer | Window
function MiniPreview.for_window(win_id)
	if getmetatable(win_id) == hs_window_metatable then
		---@cast win_id Window
		win_id = win_id:id()
	end
	---@cast win_id integer
	return MiniPreview._win_id_to_mini_preview[win_id]
end

---@param w Window
function MiniPreview.by_preview_window(w)
	local subrole = w:subrole()
	if subrole:sub(1, 13) ~= "mini_preview." then return nil end
	local mini_preview_id = subrole:sub(14, subrole:len()) + 0
	return MiniPreview._id_to_mini_preview[mini_preview_id]
end

---@param w Window
---@return MiniPreview
function MiniPreview.new(w)
	local win_id = w:id()
	local w_topLeft = w:topLeft()
	local w_size = w:size()

	-- local screen = w:screen()
	-- local screen_scale_factor = screen:currentMode().scale

	local mini_preview_id = MiniPreview._next_id
	MiniPreview._next_id = MiniPreview._next_id + 1

	local self = {}
	setmetatable(self, MiniPreview)
	self._deleted = false
	self.id = mini_preview_id
	self.w = w
	self.win_id = win_id
	self.canvas = hs.canvas.new({})
	self.timer = hs.timer.new(0.1, function () self:refreshImg() end)
	self.kbd_tap = hs.eventtap.new(
		{
			hs.eventtap.event.types.keyDown,
			hs.eventtap.event.types.keyUp,
		},
		function (...) self:onKey(...) end
	)
	self.showing_border = false

	MiniPreview._id_to_mini_preview[self.id] = self
	MiniPreview._win_id_to_mini_preview[self.win_id] = self

	local canvas = self.canvas
	canvas:_accessibilitySubrole("mini_preview." .. self.id)
	canvas:level(hs.canvas.windowLevels.normal - 1)
	canvas:topLeft(w_topLeft)
	canvas:size(w_size)

	---@type AnimSequenceData
	local anim_data = {
		alpha={1, PREVIEW_ALPHA},
		size_factor={1, INITIAL_SCALE_FACTOR},
	}
	---@param step_data AnimStepData
	local function anim_step_func(step_data)
		canvas:alpha(step_data.alpha)
		canvas:size(w_size * step_data.size_factor)
	end

	self:refreshImg()
	canvas:show()
	hs.timer.doAfter(0, function ()
		hs.timer.doAfter(0, function ()
			w:setTopLeft({x=100000, y=100000})
			self.canvas:level(hs.canvas.windowLevels.floating)
			anim.animate(anim_data, 0.15, anim_step_func, 60)
		end)
	end)

	self.timer:start()
	canvas:mouseCallback(function (...) self:mouseCallback(...) end)
	return self
end

function MiniPreview:delete()
	self._deleted = true

	local canvas_topLeft = self.canvas:topLeft()

	MiniPreview._id_to_mini_preview[self.id] = nil
	MiniPreview._win_id_to_mini_preview[self.win_id] = nil

	self.timer:stop()
	self.timer = nil

	self.kbd_tap:stop()
	self.kbd_tap = nil

	self.canvas:delete()
	self.canvas = nil

	self.showing_border = false
	if self.border_canvas then
		self.border_canvas:delete()
		self.border_canvas = nil
	end

	self.w:setTopLeft(canvas_topLeft)
end

function MiniPreview:refresh()
	self:refreshImg()
	self:refreshBorder()
end

function MiniPreview:refreshImg()
	if self._deleted then return end
	local img = hs.window.snapshotForID(self.win_id, true)
	if not img then return end
	self.canvas:assignElement({
		type="image",
		image=img,
		trackMouseEnterExit=true,
	}, 1)
end

function MiniPreview:refreshBorder()
	if self._deleted then return end

	if not self.showing_border then
		if self.border_canvas then
			self.border_canvas:delete()
			self.border_canvas = nil
		end
		return
	end

	if not self.border_canvas then
		self.border_canvas = hs.canvas.new({})
		self.border_canvas:show()
	end

	local img_canvas = self.canvas
	local img_canvas_topLeft = img_canvas:topLeft()
	local img_canvas_size = img_canvas:size()

	local border_canvas = self.border_canvas
	local border_canvas_topLeft = hs.geometry({
		x=img_canvas_topLeft.x - (BORDER_WIDTH + BORDER_PADDING),
		y=img_canvas_topLeft.y - (BORDER_WIDTH + BORDER_PADDING),
	})
	local border_canvas_size = hs.geometry({
		w=img_canvas_size.w + 2 * (BORDER_WIDTH + BORDER_PADDING),
		h=img_canvas_size.h + 2 * (BORDER_WIDTH + BORDER_PADDING),
	})

	border_canvas:topLeft(border_canvas_topLeft)
	border_canvas:size(border_canvas_size)
	border_canvas:assignElement({
		type="rectangle",
		action="stroke",
		frame={
			x=BORDER_WIDTH / 2,
			y=BORDER_WIDTH / 2,
			w=border_canvas_size.w - BORDER_WIDTH,
			h=border_canvas_size.h - BORDER_WIDTH,
		},
		roundedRectRadii={
			xRadius=BORDER_WIDTH,
			yRadius=BORDER_WIDTH,
		},
		strokeWidth=BORDER_WIDTH,
		strokeColor=BORDER_COLOR,
	}, 1)
end

---@param f Geometry
function MiniPreview:setFrame(f)
	self.canvas:frame(f)
	self:refresh()
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
	if ev_type == "mouseEnter" then
		self:onMouseEnter()
	elseif ev_type == "mouseExit" then
		self:onMouseExit()
	end
end

function MiniPreview:onMouseEnter()
	self.canvas:alpha(FOCUSED_ALPHA)
	self.showing_border = true
	self:refreshBorder()
	self.kbd_tap:start()
end

function MiniPreview:onMouseExit()
	self.kbd_tap:stop()
	self.showing_border = false
	self:refreshBorder()
	self.canvas:alpha(PREVIEW_ALPHA)
end

--[[ MODULE ]]

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

return {
	MiniPreview=MiniPreview,
	start_for_window=start_for_window,
	stop_for_window=stop_for_window,
	toggle_for_window=toggle_for_window,
}
