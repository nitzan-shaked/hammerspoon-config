--[[ CONFIG ]]

local INITIAL_SCALE_FACTOR = 0.3
local PREVIEW_ALPHA = 0.6
local FOCUSED_ALPHA = 0.9
local FRAME_STROKE_WIDTH = 4
local FRAME_STROKE_COLOR = {green=1}

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
	if type(w) == "number" then w = hs.window(w) end
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

	o = {}
	setmetatable(o, self)
	self.__index = self
	self.id = MiniPreview._next_id
	self.win_id = win_id
	self.win_orig_space_id = orig_space_id
	self.win_orig_frame = w:frame()
	self.kbd_tap = hs.eventtap.new(
		{
			hs.eventtap.event.types.keyDown,
			hs.eventtap.event.types.keyUp,
		},
		function (...) self:on_key(...) end
	)

	local canvas = hs.canvas.new({})
	canvas:_accessibilitySubrole("mini_preview." .. self.id)
	canvas:mouseCallback(function (...) self:mouse_callback(...) end)
	canvas:topLeft(self.win_orig_frame.topleft)
	canvas:size(w:size())
	self.canvas = canvas

	MiniPreview._id_to_mini_preview[self.id] = self
	MiniPreview._win_id_to_mini_preview[self.win_id] = self
	MiniPreview._next_id = MiniPreview._next_id + 1

	self:update()
	self.canvas:show()

	self.animate_data = {
		alpha={1, PREVIEW_ALPHA},
		size_factor={
			1,  -- 1 / screen_scale_factor,
			INITIAL_SCALE_FACTOR, -- / screen_scale_factor
		},
	}
	self.animate_step = 0
	self.animate_num_steps = 20

	animate_duration = 0.4
	self.animate_timer = hs.timer.new(
		animate_duration / self.animate_num_steps,
		function () self:animate() end
	)
	self.animate_timer:start()

	hs.spaces.moveWindowToSpace(self.win_id, other_space_ids[1])

	self.timer = hs.timer.new(0.5, function () self:update() end)
	self.timer:start()

	return o
end

function MiniPreview:animate ()
	self.animate_step = self.animate_step + 1
	if self.animate_step == self.animate_num_steps then
		self.animate_timer:stop()
	end

	local alpha_0 = self.animate_data.alpha[1]
	local alpha_1 = self.animate_data.alpha[2]
	local d_alpha = alpha_1 - alpha_0

	local size_factor_0 = self.animate_data.size_factor[1]
	local size_factor_1 = self.animate_data.size_factor[2]
	local d_size_factor = size_factor_1 - size_factor_0

	local t = self.animate_step / self.animate_num_steps
	local alpha = alpha_0 + t * d_alpha
	local size_factor = size_factor_0 + t * d_size_factor

	local canvas_size = self.win_orig_frame.wh:copy():scale(size_factor)
	self.canvas:size(canvas_size)
	self.canvas:alpha(alpha)
end

function MiniPreview:delete ()
	MiniPreview._id_to_mini_preview[self.id] = nil
	MiniPreview._win_id_to_mini_preview[self.win_id] = nil

	self.timer:stop()
	self.kbd_tap:stop()
	self.canvas:hide()

	self.canvas:delete()

	self.timer = nil
	self.kbd_tap = nil
	self.canvas = nil

	if self.win_orig_space_id then
		hs.spaces.moveWindowToSpace(self.win_id, self.win_orig_space_id)
		self.win_orig_space_id = nil
	end
	local w = hs.window(self.win_id)
	if self.win_orig_frame then
		w:setFrame(self.win_orig_frame)
		self.win_orig_frame = nil
	end
	w:raise()
end

function MiniPreview:update ()
	local canvas = self.canvas
	if not canvas then
		return
	end
	local img = hs.window.snapshotForID(self.win_id, true)
	if not img then
		self:delete()
		return
	end
	canvas:assignElement({
		type="image",
		image=img,
		size=canvas:frame().wh,
		trackMouseEnterExit=true,
	}, 1)
end

function MiniPreview:mouse_callback (canvas, ev_type, elem_id, x, y)
	if ev_type == "mouseEnter" then
		self:on_entered()
	elseif ev_type == "mouseExit" then
		self:on_exited()
	end
end

function MiniPreview:on_entered ()
	if not self.canvas then return end
	self.canvas:alpha(FOCUSED_ALPHA)
	self.canvas:insertElement({
		type="rectangle",
		action="stroke",
		strokeColor=FRAME_STROKE_COLOR,
		strokeWidth=FRAME_STROKE_WIDTH,
	})
	self.kbd_tap:start()
end

function MiniPreview:on_exited ()
	if not self.canvas then return end
	self.canvas:alpha(PREVIEW_ALPHA)
	self.canvas:removeElement()
	self.kbd_tap:stop()
end

function MiniPreview:on_key (ev)
	local ev_type = ev:getType()
	local key_str = ev:getCharacters()

	-- "swallow" event
	ev:setType(hs.eventtap.event.types.nullEvent)

	-- handle keyDown
	if ev_type == hs.eventtap.event.types.keyDown then
		if key_str == "x" then
			self:delete()
		end
	end
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
