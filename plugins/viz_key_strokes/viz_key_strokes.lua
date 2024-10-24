local event_types = hs.eventtap.event.types

local settings = require("settings")


--[[ MODULE ]]

local cls = {}

cls.name = "viz_key_strokes"


--[[ CONFIG ]]

cls.cfg_schema = {
	name=cls.name,
	title="Visualize Key Strokes",
	descr="Visualize key presses with an on-screen banner.",
	items={{
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
}


--[[ CONSTS ]]

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


--[[ STATE ]]

cls.initialized = false
cls.started = false

---@type Canvas
cls.canvas = nil
---@type EventTap
cls.mods_event_tap = nil
---@type EventTap
cls.keys_event_tap = nil

---@type table<string, boolean>
cls.mods = {}
---@type string?
cls.curr_key_str = nil
cls.releasing_chord = false
---@type Timer?
cls.chord_release_timer = nil


--[[ LOGIC ]]

function cls.isInitialized()
	return cls.initialized
end


function cls.init()
	assert(not cls.initialized, "already initialized")

	local cfg = settings.loadPluginSection(cls.name)
	cls.text_size = cfg.text_size
	cls.canvas_height = cfg.canvas_height
	cls.v_margin = cfg.v_margin
	cls.h_padding = cfg.h_padding
	cls.fill_color = settings.colorFromHtml(cfg.fill_color)

	local screen = hs.screen.primaryScreen()
	local screen_frame = screen:frame()

	cls.canvas = hs.canvas.new({
		x=0,
		y=screen_frame.y2 - cls.v_margin - cls.canvas_height,
	})
	cls.canvas:appendElements({
		type="rectangle",
		action="fill",
		fillColor=cls.fill_color,
		roundedRectRadii={xRadius=4, yRadius=4},
	})
	cls.canvas:appendElements({
		type="text",
		textSize=cls.text_size,
		textAlignment="center",
	})

	cls.mods_event_tap = hs.eventtap.new({
		event_types.flagsChanged,
	}, cls._handle_mod_event)

	cls.keys_event_tap = hs.eventtap.new({
		event_types.keyDown,
		event_types.keyUp,
	}, cls._handle_key_event)

	cls.started = false
	cls.initialized = true
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	cls.mods_event_tap:start()
	cls.keys_event_tap:start()
	cls.started = true
end


function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	cls.canvas:hide()
	cls.mods_event_tap:stop()
	cls.keys_event_tap:stop()
	cls.mods = {}
	cls.curr_key_str = nil
	cls.releasing_chord = false
	if cls.chord_release_timer then
		cls.chord_release_timer:stop()
		cls.chord_release_timer = nil
	end
	cls.started = false
end


function cls.unload()
	if not cls.initialized then return end
	cls.stop()
	cls.canvas:delete()
	cls.canvas = nil
	cls.mods_event_tap = nil
	cls.keys_event_tap = nil
	cls.initialized = false
end


function cls._maybe_update_canvas()
	if cls.releasing_chord then
		assert(cls.chord_release_timer)
		return
	end

	local text = ""

	for mod_name, _ in pairs(cls.mods) do
		text = text .. MOD_TO_CHAR[mod_name]
	end

	if cls.curr_key_str ~= nil then
		text = text .. cls.curr_key_str
	end

	if text == "" then
		cls.canvas:hide()
		return
	end
	local text_elem_size = cls.canvas:minimumTextSize(2, text)
	cls.canvas:size({
		w=text_elem_size.w + 2 * cls.h_padding,
		h=cls.canvas_height,
	})
	cls.canvas[2].text = text
	cls.canvas:show()
end

function cls._on_down()
	cls.releasing_chord = false
	if cls.chord_release_timer then
		cls.chord_release_timer:stop()
		cls.chord_release_timer = nil
	end
end

function cls._on_up()
	if cls.releasing_chord then
		assert(cls.chord_release_timer)
		return
	end
	assert(cls.chord_release_timer == nil)
	if cls.curr_key_str == nil then
		-- it's not a proper "chord" we're releasing if not regular key
		-- was pressed; it's just some combo of modifiers
		return
	end
	cls.releasing_chord = true
	cls.chord_release_timer = hs.timer.doAfter(0.25, function ()
		cls.releasing_chord = false
		cls.chord_release_timer = nil
		cls._maybe_update_canvas()
	end)
end

---@param new_value boolean?
function cls._on_down_up(new_value)
	if new_value then
		cls._on_down()
	else
		cls._on_up()
	end
end

---@param mod_name string
---@param new_value boolean?
function cls._set_mod(mod_name, new_value)
	new_value = new_value or nil
	local old_value = cls.mods[mod_name]
	cls.mods[mod_name] = new_value
	if new_value ~= old_value then
		cls._on_down_up(new_value)
	end
end

---@param e Event
function cls._handle_mod_event(e)
	local e_flags = e:getFlags()
	for _, mod_name in pairs({"ctrl", "alt", "cmd", "shift"}) do
		cls._set_mod(mod_name, e_flags[mod_name])
	end
	cls._maybe_update_canvas()
end

---@param e Event
function cls._handle_key_event(e)
	local is_down = e:getType() == event_types.keyDown
	local e_key_code = e:getKeyCode()

	-- convert f18 to the Hyper mod
	if e_key_code == hs.keycodes.map.f18 then
		cls._set_mod("hyper", is_down)
		cls._maybe_update_canvas()
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

	cls._on_down_up(is_down)
	cls.curr_key_str = is_down and e_key_str or nil
	cls._maybe_update_canvas()
end


--[[ MODULE ]]

return cls