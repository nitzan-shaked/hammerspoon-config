local event_types = hs.eventtap.event.types

local Module = require("module")
local class = require("utils.class")
local animate = require("utils.animate")
local nu = require("utils.number_utils")


---@class VizKeyStrokes: Module
local VizKeyStrokes = class.make_class("VizKeyStrokes", Module)


local _CFG_POS_X = {
	name="pos_x",
	title="Horizontal Position (%)",
	descr="Horizontal position (% of screen height).",
	control="number",
	default=0,
}
local _CFG_POS_Y = {
	name="pos_y",
	title="Vertical Position (%)",
	descr="Vertical position (% of screen height).",
	control="number",
	default=100,
}
local _CFG_OFFSET_X = {
	name="offset_x",
	title="Horizontal Offset (px)",
	descr="Horizontal offset in pixels.",
	control="number",
	default=0,
}
local _CFG_OFFSET_Y = {
	name="offset_y",
	title="Vertical Offset (px)",
	descr="Vertical offset in pixels.",
	control="number",
	default=0,
}
local _CFG_BG_COLOR = {
	name="bg_color",
	title="Background Color",
	descr="Background color.",
	control="color",
	default="#000000",
}
local _CFG_FG_COLOR = {
	name="fg_color",
	title="Foreground Color",
	descr="Text color.",
	control="color",
	default="#ffffff",
}
local _CFG_FONT_SIZE = {
	name="font_size",
	title="Font Size (pt.)",
	descr="Font size in points.",
	control="number",
	default=48,
}
local _CFG_PADDING_X = {
	name="padding_x",
	title="Horizontal Padding (px)",
	descr="Padding on the left and right of the text, in pixels.",
	control="number",
	default=6,
}
local _CFG_PADDING_Y = {
	name="padding_y",
	title="Vertical Padding (px)",
	descr="Padding on the top and bottom of the text, in pixels.",
	control="number",
	default=6,
}
local _CFG_FADE_DELAY = {
	name="fade_delay",
	title="Fade Delay (ms)",
	descr="Time in milliseconds for fading away.",
	control="number",
	default=500,
}


function VizKeyStrokes:__init__()
	Module.__init__(
		self,
		"viz_key_strokes",
		"Visualize Key Strokes",
		"Visualize key presses with an on-screen banner.",
		{
			_CFG_POS_X,
			_CFG_POS_Y,
			_CFG_OFFSET_X,
			_CFG_OFFSET_Y,
			_CFG_BG_COLOR,
			_CFG_FG_COLOR,
			_CFG_FONT_SIZE,
			_CFG_PADDING_X,
			_CFG_PADDING_Y,
			_CFG_FADE_DELAY,
		},
		{}
	)
end


local MODS_ORDER = {"hyper", "ctrl", "alt", "cmd", "shift"}


local MOD_NAME_XLAT = {
	f18="hyper",
	hyper="hyper",
	capslock="hyper",

	ctrl="ctrl",
	leftctrl="ctrl",
	rightctrl="ctrl",

	alt="alt",
	leftalt="alt",
	rightalt="alt",

	cmd="cmd",
	leftcmd="cmd",
	rightcmd="cmd",

	shift="shift",
	leftshift="shift",
	rightshift="shift",

	fn="fn",
}

local MOD_TO_CHAR = {
	hyper="✧",
	ctrl="⌃",
	alt="⌥",
	cmd="⌘",
	shift="⇧",
}

local CHAR_TO_CHAR = {
	["padclear"]="⌧",
	["padenter"]="↵",
	["return"]="↩",
	["tab"]="⇥",
	["space"]="␣",
	["delete"]="⌫",
	["escape"]="⎋",
	["help"]="?⃝",

	["home"]="↖",
	["pageup"]="⇞",
	["forwarddelete"]="⌦",
	["end"]="↘",
	["pagedown"]="⇟",
	["left"]="←",
	["right"]="→",
	["down"]="↓",
	["up"]="↑",
}


function VizKeyStrokes:loadImpl(settings)
	self._pos_x = nu.clip(settings.pos_x / 100, 0, 1)
	self._pos_y = nu.clip(settings.pos_y / 100, 0, 1)
	self._offset_x = settings.offset_x
	self._offset_y = settings.offset_y
	self._bg_color = settings.bg_color
	self._fg_color = settings.fg_color
	self._font_size = nu.cap_below(settings.font_size, 4)
	self._padding_x = settings.padding_x
	self._padding_y = settings.padding_y
	self._fade_delay = nu.cap_below(settings.fade_delay, 0)

	self._canvas = hs.canvas.new({x=0, y=0})
	self._canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor=self._bg_color,
		roundedRectRadii={xRadius=4, yRadius=4},
	})
	self._canvas:appendElements({
		type="text",
		textSize=self._font_size,
		textAlignment="center",
		textColor=self._fg_color,
	})

	self._mods_event_tap = hs.eventtap.new({
		event_types.flagsChanged,
	}, function(e) self:_handle_mod_event(e) end)

	self._keys_event_tap = hs.eventtap.new({
		event_types.keyDown,
		event_types.keyUp,
	}, function(e) self:_handle_key_event(e) end)
end


function VizKeyStrokes:startImpl()
	self._curr_mods = {}
	self._curr_key = nil
	self._releasing = false
	self._anim = nil
	self._mods_event_tap:start()
	self._keys_event_tap:start()
end


function VizKeyStrokes:stopImpl()
	self._canvas:hide()
	self._mods_event_tap:stop()
	self._keys_event_tap:stop()
	if self._anim then
		self._anim:stop()
		self._anim = nil
	end
end


function VizKeyStrokes:unloadImpl()
	self._canvas:delete()
	self._canvas = nil
	self._mods_event_tap = nil
	self._keys_event_tap = nil
end


---@param e Event
function VizKeyStrokes:_handle_mod_event(e)
	local e_flags = e:getFlags()
	for _, mod_name in ipairs(MODS_ORDER) do
		if mod_name ~= "hyper" then
			self:_set_mod_state(mod_name, e_flags[mod_name])
		end
	end
	self:_update_canvas()
end


---@param e Event
function VizKeyStrokes:_handle_key_event(e)
	local is_down = e:getType() == event_types.keyDown
	local key_code = e:getKeyCode()
	local key_name = hs.keycodes.map[key_code]
	local mod_name = MOD_NAME_XLAT[key_name]

	if mod_name then
		assert(key_code == hs.keycodes.map.f18)
		self:_set_mod_state(mod_name, is_down)
		self:_update_canvas()
		return
	end

	key_name = CHAR_TO_CHAR[key_name] or key_name

	if is_down then
		self._curr_key = key_name
		self:_cancel_release()
	else
		self._curr_key = nil
		self:_start_release()
	end
	self:_update_canvas()
end


---@param mod_name string
---@param new_value boolean?
function VizKeyStrokes:_set_mod_state(mod_name, new_value)
	assert(MOD_NAME_XLAT[mod_name], "Unknown mod name: " .. mod_name)
	new_value = new_value or nil
	local old_value = self._curr_mods[mod_name]
	if new_value == old_value then return end
	self._curr_mods[mod_name] = new_value
	if new_value then
		self:_cancel_release()
	end
end


function VizKeyStrokes:_start_release()
	if self._releasing then return end
	self._releasing = true
	assert(self._anim == nil)
	self._anim = animate.Animation(
		self._fade_delay / 1000,
		function(s) self._canvas:alpha(1 - s) end,
		function() self:_finish_release() end
	)
	self._anim:start()
end


function VizKeyStrokes:_cancel_release()
	if not self._releasing then return end
	self._releasing = false
	assert(self._anim)
	self._anim:stop()
	self._anim = nil
	self._canvas:alpha(1)
end


function VizKeyStrokes:_finish_release()
	if not self._releasing then return end
	self:_cancel_release()
	self._curr_key = nil
	self:_update_canvas()
end


--============================================================


function VizKeyStrokes:_update_canvas()
	if self._releasing then return end

	local text = ""

	for _, mod_name in ipairs(MODS_ORDER) do
		if self._curr_mods[mod_name] then
			text = text .. MOD_TO_CHAR[mod_name]
		end
	end

	if self._curr_key ~= nil then
		text = text .. self._curr_key
	end

	if text == "" then
		self._canvas:hide()
		self:_cancel_release()
		return
	end

	local screen = hs.screen.primaryScreen()
	local screen_frame = screen:frame()

	local text_elem_size = self._canvas:minimumTextSize(2, text)
	local canvas_w = text_elem_size.w + 2 * self._padding_x
	local canvas_h = self._font_size  + 2 * self._padding_y

	local canvas_achor_point_x = canvas_w * self._pos_x
	local canvas_achor_point_y = canvas_h * self._pos_y
	local screen_anchor_point_x = screen_frame.w * self._pos_x
	local screen_anchor_point_y = screen_frame.h * self._pos_y
	local canvas_top_left_x = screen_frame.x + screen_anchor_point_x - canvas_achor_point_x + self._offset_x
	local canvas_top_left_y = screen_frame.y + screen_anchor_point_y - canvas_achor_point_y + self._offset_y

	self._canvas:size({
		w = canvas_w,
		h = canvas_h,
	})
	self._canvas:topLeft({
		x = canvas_top_left_x,
		y = canvas_top_left_y,
	})
	self._canvas[2].text = text
	self._canvas:show()
end


return VizKeyStrokes()