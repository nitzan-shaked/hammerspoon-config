--[[ STATE ]]

local cls = {
	light_level=1,
	canvas=nil,
}

--[[ LOGIC ]]

cls.show = function ()
	if cls.canvas then return end
	canvas = hs.canvas.new({})
	canvas:appendElements({
		type="rectangle",
		frame={x=0, y=0, w="100%", h="100%"},
		action="fill",
		fillColor={red=0, green=0, blue=0, alpha=1 - cls.light_level},
	})
	canvas:level(hs.canvas.windowLevels.desktop)
	canvas:_accessibilitySubrole("dark_bg")
	cls.canvas = canvas
	cls.refresh_screen_layout()
	cls.canvas:show()
end

cls.hide = function ()
	if not cls.canvas then return end
	cls.canvas:delete()
	cls.canvas = nil
end

cls.refresh_screen_layout = function ()
	if not cls.canvas then return end
	cls.canvas:frame(hs.screen.mainScreen():frame())
end

cls.set_light_level = function (light_level)
	cls.light_level = light_level < 0 and 0 or light_level > 1 and 1 or light_level

	if cls.light_level == 1 then
		cls.hide()
	elseif not cls.canvas then
		cls.show()
	else
		cls.canvas[1].fillColor.alpha = 1 - cls.light_level
	end
end

cls.darker = function ()
	cls.set_light_level(cls.light_level - 0.1)
end

cls.lighter = function ()
	cls.set_light_level(cls.light_level + 0.1)
end

cls.watcher = hs.screen.watcher.new(cls.refresh_screen_layout)

--[[ MODULE ]]

return cls
