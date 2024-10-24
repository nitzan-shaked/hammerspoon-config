--[[ TODO ]]
--   * add config: whether to also serve as esc or not


--[[ MODULE ]]

local cls = {}

cls.name = "hyper_or_esc"


--[[ CONFIG ]]

cls.cfg_schema = nil


--[[ STATE ]]

cls.initialized = false
cls.started = false

---@type Modal
cls.modal = nil
---@type Hotkey?
cls.hotkey = nil
---@type table<string, integer>?
cls.bound_keys_idx = nil
---@type boolean
cls.triggered = nil


--[[ LOGIC ]]

function cls.init()
	assert(not cls.initialized, "already initialized")
	cls.modal = hs.hotkey.modal.new()
	cls.hotkey = nil
	cls.triggered = false
	cls.started = false
	cls.bound_keys_idx = {}
	cls.initialized = true
	cls.start()
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	cls.triggered = false
	cls.hotkey = hs.hotkey.bind({}, "f18", cls._enter, cls._exit)
	cls.started = true
end


function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	cls.hotkey:disable()
	cls.hotkey:delete()
	cls.hotkey = nil
	cls.modal:exit()
	cls.started = false
end


function cls.unload()
	assert(cls.initialized, "not initialized")
	cls.stop()
	cls.modal:delete()
	cls.modal = nil
	cls.bound_keys_idx = nil
	cls.initialized = false
end


---@param key string
---@param fn fun()
---@param with_repeat boolean?
function cls.bind(key, fn, with_repeat)
	assert(cls.initialized, "not initialized")
	local function fn_wrapper()
		cls.triggered = true
		fn()
	end
	local repeat_func = (with_repeat or nil) and fn_wrapper
	cls.modal:bind({}, key, fn_wrapper, nil, repeat_func)
	cls.bound_keys_idx[key] = #cls.modal.keys
end


---@param key string
function cls.unbind(key)
	local i = cls.bound_keys_idx[key]
	if i == nil then return end
	local hk = cls.modal.keys[i]
	hk:disable()
	hk:delete()
	table.remove(cls.modal.keys, i)
	cls.bound_keys_idx[key] = nil
	for k, v in pairs(cls.bound_keys_idx) do
		if v > i then
			cls.bound_keys_idx[k] = v - 1
		end
	end
end


function cls._enter()
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.capslock, true):post()
	cls.triggered = false
	cls.modal:enter()
end


function cls._exit()
	cls.modal:exit()
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.capslock, false):post()
	if not cls.triggered then
		hs.eventtap.keyStroke({}, "escape")
	end
end


--[[ MODULE ]]

return cls
