--[[ STATE ]]

local modal = hs.hotkey.modal.new()
local triggered = false

--[[ LOGIC ]]

local function enter()
	triggered = false
	modal:enter()
end

local function exit()
	modal:exit()
	if not triggered then
		hs.eventtap.keyStroke({}, "escape")
	end
end

---@param key string
---@param fn fun()
---@param with_repeat boolean?
local function bind(key, fn, with_repeat)
	local function fn_wrapper()
		triggered = true
		fn()
	end
	local repeat_func = (with_repeat or nil) and fn_wrapper
	modal:bind({}, key, fn_wrapper, nil, repeat_func)
end


--[[ INIT ]]

hs.hotkey.bind({}, "f18", enter, exit)

--[[ MODULE ]]

return {
	bind=bind,
}
