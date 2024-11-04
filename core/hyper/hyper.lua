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

	---@type Modal
	self._modal = nil
	---@type Hotkey?
	self._hotkey = nil
	---@type table<string, integer>?
	self._bound_keys_idx = nil
	---@type boolean
	self._triggered = nil
end


function Hyper:loadImpl()
	self._modal = hs.hotkey.modal.new()
	self._hotkey = nil
	self._triggered = false
	self._bound_keys_idx = {}
end


function Hyper:startImpl()
	self._triggered = false
	self._hotkey = hs.hotkey.bind(
		{},
		"f18",
		function() self:_enter() end,
		function() self:_exit() end
	)
end


function Hyper:stopImpl()
	self._hotkey:disable()
	self._hotkey:delete()
	self._hotkey = nil
	self._modal:exit()
end


function Hyper:unloadImpl()
	self._modal:delete()
	self._modal = nil
	self._bound_keys_idx = nil
end


---@param key string
---@param fn fun()
---@param with_repeat boolean?
function Hyper:bind(key, fn, with_repeat)
	self:_check_loaded_and_started()
	local function fn_wrapper()
		self._triggered = true
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


function Hyper:_enter()
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.capslock, true):post()
	self._triggered = false
	self._modal:enter()
end


function Hyper:_exit()
	self._modal:exit()
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.capslock, false):post()
	if not self._triggered then
		hs.eventtap.keyStroke({}, "escape")
	end
end


return Hyper()
