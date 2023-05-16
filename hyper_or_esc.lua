--[[ STATE ]]

local cls = {
	modal=hs.hotkey.modal.new(),
	triggered=false,
}

--[[ LOGIC ]]

cls.enter = function ()
	cls.triggered = false
	cls.modal:enter()
end

cls.exit = function ()
	cls.modal:exit()
	if not cls.triggered then
		hs.eventtap.keyStroke({}, "escape")
	end
end

cls.bind = function (key, fn, with_repeat)
	local fn_wrapper = function ()
		cls.triggered = true
		fn()
	end
	repeat_func = with_repeat and fn_wrapper or nil
	cls.modal:bind({}, key, fn_wrapper, nil, repeat_func)
end

--[[ MODULE ]]

hs.hotkey.bind({}, "f18", cls.enter, cls.exit)

return cls
