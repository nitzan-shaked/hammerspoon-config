local u = require("utils")

--[[ STATE ]]

local lightbox = nil

--[[ LOGIC ]]

local modal_win_ops = hs.hotkey.modal.new()
local modal_win_ops_bind  = u.method(modal_win_ops, "bind" )
local modal_win_ops_enter = u.method(modal_win_ops, "enter")
local modal_win_ops_exit  = u.method(modal_win_ops, "exit" )

local function modal_win_ops:entered ()
	local win = hs.window.focusedWindow()
	if not win then
		modal_win_ops:exit()
		return
	end

	if lightbox then
		lightbox:delete()
		lightbox = nil
	end

	lightbox = hs.canvas.new(win:screen():frame())
	lightbox:appendElements({
		type = "rectangle",
		frame = {x = 0, y = 0, w = "100%", h = "100%"},
		action = "fill",
		fillColor = {red = 0, green = 1.0, blue = 1.0, alpha = 0.25},
	})
	lightbox:level(hs.canvas.windowLevels.normal)
	lightbox:show()

	win:raise()
end

local function modal_win_ops:exited ()
	if lightbox then
		lightbox:delete()
		lightbox = nil
	end
end

modal_win_ops:bind({}, "escape", modal_win_ops_exit)
modal_win_ops:bind({}, "return", modal_win_ops_exit)
modal_win_ops:bind({}, "f18",    modal_win_ops_exit)

hs.hotkey.bind({"shift"}, "f18", modal_win_ops_enter)

--[[ MODULE ]]

return {
}
