local event_types = hs.eventtap.event.types

local Module = require("module")
local class = require("utils.class")
local settings = require("settings")


---@class VizKeyStrokes: Module
local VizKeyStrokes = class.make_class("VizKeyStrokes", Module)


function VizKeyStrokes:__init__()
	Module.__init__(
		self,
		"viz_key_strokes",
		"Visualize Key Strokes",
		"Visualize key presses with an on-screen banner.",
		{{
			name="text_size",
			title="Text Size",
			descr="Size of the text in the banner.",
			control="number",
			default=48,
		}, {
			name="canvas_height",
			title="Canvas Height",
			descr="Height of the banner.",
			control="number",
			default=56,
		}, {
			name="v_margin",
			title="Vertical Margin",
			descr="Margin between the banner and the bottom of the screen.",
			control="number",
			default=32,
		}, {
			name="h_padding",
			title="Horizontal Padding",
			descr="Padding on the left and right of the text in the banner.",
			control="number",
			default=6,
		}, {
			name="fill_color",
			title="Fill Color",
			descr="Color of the banner.",
			control="color",
			default="#ffffff4c",
		}},
		{}
	)

	---@type Canvas
	self._canvas = nil
	---@type EventTap
	self._mods_event_tap = nil
	---@type EventTap
	self._keys_event_tap = nil

	---@type table<string, boolean>
	self._mods = {}
	---@type string?
	self._curr_key_str = nil
	self._releasing_chord = false
	---@type Timer?
	self._chord_release_timer = nil
end


local MOD_TO_CHAR = {
	hyper="✧",
	ctrl="⌃",
	alt="⌥",
	cmd="⌘",
	shift="⇧",
}

local CHAR_TO_CHAR = {
	padclear="⌧",
	padenter="↵",
	_return="↩",
	tab="⇥",
	space="␣",
	delete="⌫",
	escape="⎋",
	help="?⃝",

	home="↖",
	pageup="⇞",
	forwarddelete="⌦",
	_end="↘",
	pagedown="⇟",
	left="←",
	right="→",
	down="↓",
	up="↑",

	shift="",
	rightshift="",
	cmd="",
	rightcmd="",
	alt="",
	rightalt="",
	ctlr="",
	rightctrl="",
	capslock="⇪",
	fn="",
	f18="",
}


function VizKeyStrokes:loadImpl()
	local cfg = settings.loadPluginSettings(self.name)
	self._text_size = cfg.text_size
	self._canvas_height = cfg.canvas_height
	self._v_margin = cfg.v_margin
	self._h_padding = cfg.h_padding
	self._fill_color = settings.colorFromHtml(cfg.fill_color)

	local screen = hs.screen.primaryScreen()
	local screen_frame = screen:frame()

	self._canvas = hs.canvas.new({
		x=0,
		y=screen_frame.y2 - self._v_margin - self._canvas_height,
	})
	self._canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor=self._fill_color,
		roundedRectRadii={xRadius=4, yRadius=4},
	})
	self._canvas:appendElements({
		type="text",
		textSize=self._text_size,
		textAlignment="center",
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
	self._mods_event_tap:start()
	self._keys_event_tap:start()
end


function VizKeyStrokes:stopImpl()
	self._canvas:hide()
	self._mods_event_tap:stop()
	self._keys_event_tap:stop()
	self._mods = {}
	self._curr_key_str = nil
	self._releasing_chord = false
	if self._chord_release_timer then
		self._chord_release_timer:stop()
		self._chord_release_timer = nil
	end
end


function VizKeyStrokes:unloadImpl()
	self._canvas:delete()
	self._canvas = nil
	self._mods_event_tap = nil
	self._keys_event_tap = nil
end


function VizKeyStrokes:_maybe_update_canvas()
	if self._releasing_chord then
		assert(self._chord_release_timer)
		return
	end

	local text = ""

	for mod_name, _ in pairs(self._mods) do
		text = text .. MOD_TO_CHAR[mod_name]
	end

	if self._curr_key_str ~= nil then
		text = text .. self._curr_key_str
	end

	if text == "" then
		self._canvas:hide()
		return
	end
	local text_elem_size = self._canvas:minimumTextSize(2, text)
	self._canvas:size({
		w=text_elem_size.w + 2 * self._h_padding,
		h=self._canvas_height,
	})
	self._canvas[2].text = text
	self._canvas:show()
end


function VizKeyStrokes:_on_down()
	self._releasing_chord = false
	if self._chord_release_timer then
		self._chord_release_timer:stop()
		self._chord_release_timer = nil
	end
end


function VizKeyStrokes:_on_up()
	if self._releasing_chord then
		assert(self._chord_release_timer)
		return
	end
	assert(self._chord_release_timer == nil)
	if self._curr_key_str == nil then
		-- it's not a proper "chord" we're releasing if not regular key
		-- was pressed; it's just some combo of modifiers
		return
	end
	self._releasing_chord = true
	self._chord_release_timer = hs.timer.doAfter(0.25, function ()
		self._releasing_chord = false
		self._chord_release_timer = nil
		self:_maybe_update_canvas()
	end)
end


---@param new_value boolean?
function VizKeyStrokes:_on_down_up(new_value)
	if new_value then
		self:_on_down()
	else
		self:_on_up()
	end
end


---@param mod_name string
---@param new_value boolean?
function VizKeyStrokes:_set_mod(mod_name, new_value)
	new_value = new_value or nil
	local old_value = self._mods[mod_name]
	self._mods[mod_name] = new_value
	if new_value ~= old_value then
		self:_on_down_up(new_value)
	end
end


---@param e Event
function VizKeyStrokes:_handle_mod_event(e)
	local e_flags = e:getFlags()
	for _, mod_name in ipairs({"ctrl", "alt", "cmd", "shift"}) do
		self:_set_mod(mod_name, e_flags[mod_name])
	end
	self:_maybe_update_canvas()
end


---@param e Event
function VizKeyStrokes:_handle_key_event(e)
	local is_down = e:getType() == event_types.keyDown
	local e_key_code = e:getKeyCode()

	-- convert f18 to the Hyper mod
	if e_key_code == hs.keycodes.map.f18 then
		self:_set_mod("hyper", is_down)
		self:_maybe_update_canvas()
	end

	local e_key_str = hs.keycodes.map[e_key_code]
	e_key_str = (
		CHAR_TO_CHAR[e_key_str]
		or CHAR_TO_CHAR["_" .. e_key_str]
		or e_key_str
	)
	-- modifiers are translated to empty strings, so don't
	-- use those to update curr_key_str
	if e_key_str == "" then
		return
	end

	self:_on_down_up(is_down)
	self._curr_key_str = is_down and e_key_str or nil
	self:_maybe_update_canvas()
end


return VizKeyStrokes()