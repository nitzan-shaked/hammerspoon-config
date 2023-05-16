anim = require("animate")

--[[ CONFIG ]]

local INITIAL_SCALE_FACTOR = 0.3
local PREVIEW_ALPHA = 0.6
local FOCUSED_ALPHA = 0.9
local BORDER_WIDTH = 15
local BORDER_PADDING = 2
local BORDER_COLOR = {red=0.2, green=0.5, blue=0.9}

--[[ LOGIC ]]

local MiniPreview = {
	_next_id = 0,
	_id_to_mini_preview = {},
	_win_id_to_mini_preview = {},
}

function MiniPreview.for_window (win_id)
	if getmetatable(win_id) == hs.getObjectMetatable("hs.window") then
		win_id = win_id:id()
	end
	return MiniPreview._win_id_to_mini_preview[win_id]
end

function MiniPreview.by_preview_window (w)
	if type(w) == "number" then
		w = hs.window(w)
	end
	subrole = w:subrole()
	if subrole:sub(1, 13) ~= "mini_preview." then return nil end
	mini_preview_id = subrole:sub(14, subrole:len()) + 0
	return MiniPreview._id_to_mini_preview[mini_preview_id]
end

function MiniPreview:new (win_id)
	if getmetatable(win_id) == hs.getObjectMetatable("hs.window") then
		win_id = win_id:id()
	end
	local w = hs.window(win_id)
	local w_topLeft = w:topLeft()
	local w_size = w:size()

	local orig_space_ids = hs.spaces.windowSpaces(w)
	if #orig_space_ids > 1 then
		print("window spans more than one space, cannot do mini-preview")
		return nil
	end
	orig_space_id = orig_space_ids[1]

	local screen = w:screen()
	local screen_scale_factor = screen:currentMode().scale

	local other_space_ids = {}
	for _, space_id in ipairs(hs.spaces.spacesForScreen(screen)) do
		if (
			space_id ~= orig_space_id
			and hs.spaces.spaceType(space_id) == "user"
	 	) then
			other_space_ids[#other_space_ids + 1] = space_id
		end
	end
	if #other_space_ids ~= 1 then
		print("need exactly one other user-type space")
		return nil
	end

	local preview_id = MiniPreview._next_id
	MiniPreview._next_id = MiniPreview._next_id + 1
	o = {}
	setmetatable(o, self)
	self.__index = self
	self._deleted = false
	self.id = preview_id
	self.win_id = win_id
	self.win_orig_space_id = orig_space_id
	self.win_orig_size = w_size
	self.canvas = hs.canvas.new({})
	self.timer = hs.timer.new(0.5, function () self:refreshImg() end)
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

	local anim_data = {
		alpha={1, PREVIEW_ALPHA},
		size_factor={1, INITIAL_SCALE_FACTOR},
	}
	local function anim_step (data)
		canvas:alpha(data.alpha)
		canvas:size(w_size * data.size_factor)
	end
	local function anim_end ()
		self.timer:start()
		canvas:mouseCallback(function (...) self:mouseCallback(...) end)
	end

	self:refreshImg()
	canvas:show()
	hs.timer.doAfter(0, function ()
		hs.timer.doAfter(0, function ()
			hs.spaces.moveWindowToSpace(self.win_id, other_space_ids[1])
			self.canvas:level(hs.canvas.windowLevels.floating)
			anim.animate(anim_data, 0.15, anim_step, anim_end, 60)
		end)
	end)

	return o
end

function MiniPreview:delete ()
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

	-- to move the window when it's in another space we need to get it by a filter
	local w_in_other_space = nil
	local wf = hs.window.filter.new(function (w) return w:id() == self.win_id end)
	for _, v in pairs(wf:getWindows()) do
		w_in_other_space = v
	end
	if w_in_other_space then
		w_in_other_space:setTopLeft(canvas_topLeft)
	end

	hs.spaces.moveWindowToSpace(self.win_id, self.win_orig_space_id)

	if not w_in_other_space then
		hs.window(self.win_id):setTopLeft(my_topLeft)
	end
end

function MiniPreview:refresh ()
	self:refreshImg()
	self:refreshBorder()
end

function MiniPreview:refreshImg ()
	if self._deleted then return end
	local img = hs.window.snapshotForID(self.win_id, true)
	if not img then return end
	self.canvas:assignElement({
		type="image",
		image=img,
		trackMouseEnterExit=true,
	}, 1)
end

function MiniPreview:refreshBorder ()
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
			xRadius=BORDER_WIDTH / 2,
			yRadius=BORDER_WIDTH / 2,
		},
		strokeWidth=BORDER_WIDTH,
		strokeColor=BORDER_COLOR,
	}, 1)
end

function MiniPreview:setFrame (f)
	self.canvas:frame(f)
	self:refresh()
end

function MiniPreview:onKey (ev)
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

function MiniPreview:mouseCallback (canvas, ev_type, elem_id, x, y)
	if self._deleted then return end
	if ev_type == "mouseEnter" then
		self:onMouseEnter()
	elseif ev_type == "mouseExit" then
		self:onMouseExit()
	end
end

function MiniPreview:onMouseEnter ()
	self.canvas:alpha(FOCUSED_ALPHA)
	self.showing_border = true
	self:refreshBorder()
	self.kbd_tap:start()
end

function MiniPreview:onMouseExit ()
	self.kbd_tap:stop()
	self.showing_border = false
	self:refreshBorder()
	self.canvas:alpha(PREVIEW_ALPHA)
end

--[[ MODULE ]]

local function start_for_window (w)
	if not w then return end
	if not MiniPreview.for_window(w) then
		MiniPreview:new(w)
	end
end

local function stop_for_window (w)
	if not w then return end
	local mini_preview = MiniPreview.for_window(w)
	if mini_preview then
		mini_preview:delete()
	end
end

local function toggle_for_window (w)
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
	toggle_for_window=toggle_for_window,
}
