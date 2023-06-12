--[[ CONFIG ]]

local TEXT_SIZE = 48
local PADDING = 4
local MARGIN = 32

--[[ CONSTS ]]

local EXTRA_MOD_TO_CHAR = {
	hyper="✧",
}

local MOD_TO_CHAR = {
	ctrl="^",
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

	f18="hyper ",
}

--[[ STATE ]]

---@type Canvas
local canvas

---@type EventTap
local event_tap

---@type string[]
local extra_mods = {}

--[[ LOGIC ]]

local event_types = hs.eventtap.event.types

---@param e Event
local function handle_event(e)
	local e_type = e:getType()
	local is_down = e_type == event_types.keyDown
	local is_up = e_type == event_types.keyUp

	local e_flags = e:getFlags()
	local e_key_code = e:getKeyCode()
	---@type string?
	local e_chr = hs.keycodes.map[e_key_code]

	-- convert f18 to the Hyper mods
	if e_chr == "f18" then
		if is_down then
			extra_mods.hyper = true
		elseif is_up then
			extra_mods.hyper = nil
		end
		e_chr = nil
	end

	local text = ""

	-- first add updated state of all modifiers,
	-- no matter whether this is key up/down

	for extra_mod, extra_mod_char in pairs(EXTRA_MOD_TO_CHAR) do
		if extra_mods[extra_mod] then
			text = text .. extra_mod_char
		end
	end

	for mod, mod_char in pairs(MOD_TO_CHAR) do
		if e_flags[mod] then
			text = text .. mod_char
		end
	end

	-- on key down, add the char
	if e_type == event_types.keyDown then
		if e_chr ~= nil then
			e_chr = CHAR_TO_CHAR[e_chr] or CHAR_TO_CHAR["_" .. e_chr] or e_chr
			text = text .. e_chr
		end
	end
	canvas[1].text = text
	canvas:show()
end

local function start()
	event_tap:start()
end

local function stop()
	event_tap:stop()
	canvas:hide()
end

--[[ INIT ]]

local screen = hs.screen.primaryScreen()
local screen_frame = screen:frame()

local canvas_height = TEXT_SIZE + 2 * PADDING
canvas = hs.canvas.new({
	x=0,
	y=screen_frame.y2 - MARGIN - canvas_height,
	w=screen_frame.w,
	h=canvas_height,
})
canvas:appendElements({
	type="text",
	textSize=TEXT_SIZE,
	text="",
})

event_tap = hs.eventtap.new({
	event_types.keyDown,
	event_types.keyUp,
	event_types.flagsChanged,
}, handle_event)

--[[ MODULE ]]

return {
	start=start,
	stop=stop,
}
