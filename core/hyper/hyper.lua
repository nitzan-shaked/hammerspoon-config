local Module = require("module")
local class = require("utils.class")


---@class HyperOrEsc: Module
local Hyper = class.make_class("Hyper", Module)


function Hyper:__init__()
	Module.__init__(
		self,
		"hyper",
		"Hyper",
		"Magic.",
		{},
		{}
	)

	---@type EventTap
	self._event_tap = nil
	---@type Modal
	self._modal = nil
	self._modal_active = false
	self._anoter_key_pressed = false
	---@type table<string, integer>?
	self._bound_keys_idx = nil
end


function Hyper:loadImpl()
	self._event_tap = hs.eventtap.new(
		{
			hs.eventtap.event.types.keyDown,
			hs.eventtap.event.types.keyUp,
		},
		function(e) self:_kbd_event_handler(e) end
	)
	self._modal = hs.hotkey.modal.new()
	self._modal_active = false
	self._anoter_key_pressed = false
	self._bound_keys_idx = {}
end


function Hyper:startImpl()
	self._event_tap:start()
end


function Hyper:stopImpl()
	self._event_tap:stop()
	self._modal:exit()
end


function Hyper:unloadImpl()
	self._event_tap = nil
	self._modal:delete()
	self._modal = nil
end


---@param key string
---@param fn fun()
---@param with_repeat boolean?
function Hyper:bind(key, fn, with_repeat)
	self:_check_loaded_and_started()
	local function fn_wrapper()
		self._anoter_key_pressed = true
		fn()
	end
	self._modal:bind({}, key, fn_wrapper, nil, (with_repeat or nil) and fn_wrapper)
	self._bound_keys_idx[key] = #self._modal.keys
end


---@param key string
function Hyper:unbind(key)
	self:_check_loaded_and_started()
	local i = self._bound_keys_idx[key]
	if i == nil then return end
	local hk = self._modal.keys[i]
	hk:disable()
	hk:delete()
	table.remove(self._modal.keys, i)
	self._bound_keys_idx[key] = nil
	for k, v in pairs(self._bound_keys_idx) do
		if v > i then
			self._bound_keys_idx[k] = v - 1
		end
	end
end


function Hyper:_kbd_event_handler(e)
	local typ = e:getType()
	local key_code = e:getKeyCode()

	if key_code ~= hs.keycodes.map.f18 then
		if self._modal_active then
			self._anoter_key_pressed = true
		end
		return
	end

	if typ == hs.eventtap.event.types.keyDown and not self._modal_active then
		self:_enter()
	elseif typ == hs.eventtap.event.types.keyUp and self._modal_active then
		self:_exit()
	end

	e:setType(hs.eventtap.event.types.nullEvent)
	return true
end


function Hyper:_enter()
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.capslock, true):post()
	self._anoter_key_pressed = false
	self._modal_active = true
	self._modal:enter()
end


function Hyper:_exit()
	self._modal_active = false
	self._modal:exit()
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.capslock, false):post()
	if not self._anoter_key_pressed then
		hs.eventtap.keyStroke({}, "escape")
	end
end


return Hyper()
