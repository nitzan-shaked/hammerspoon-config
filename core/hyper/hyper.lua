local hid = require("hs.hid")
local plist = require("hs.plist")
local json = require("hs.json")

local Module = require("module")
local class = require("utils.class")
local hidutil = require("core.hyper.hidutil")


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
	self._orig_capslock_light = hid.capslock.get()
	hid.capslock.set(false)

	local key_mapping_str = hidutil.run_hidutil("property", "--get", "UserKeyMapping")
	self._orig_key_mapping = plist.readString(key_mapping_str)

	local KEYCODE_CAPSLOCK = 0x700000039
	local KEYCODE_F18      = 0x70000006D
	local SRC_NAME = "HIDKeyboardModifierMappingSrc"
	local DST_NAME = "HIDKeyboardModifierMappingDst"

	local new_key_mappings = {}
	local found_capslock = false
	for _, one_remap in ipairs(self._orig_key_mapping) do
		local src_key_code = tonumber(one_remap[SRC_NAME])
		local dst_key_code = tonumber(one_remap[DST_NAME])
		if src_key_code == KEYCODE_CAPSLOCK then
			dst_key_code = KEYCODE_F18
			found_capslock = true
		end
		table.insert(new_key_mappings, {
			SRC_NAME = src_key_code,
			DST_NAME = dst_key_code,
		})
	end
	if not found_capslock then
		table.insert(new_key_mappings, {
			SRC_NAME = KEYCODE_CAPSLOCK,
			DST_NAME = KEYCODE_F18,
		})
	end
	hidutil.run_hidutil(
		"property",
		"--set",
		json.encode({
			["UserKeyMapping"] = new_key_mappings,
		})
	)
	self._event_tap:start()
end


function Hyper:stopImpl()
	self._event_tap:stop()
	self._modal:exit()
	hidutil.run_hidutil(
		"property",
		"--set",
		json.encode({
			["UserKeyMapping"] = self._orig_key_mapping,
		})
	)
	hid.caps.set(self._orig_capslock_light)
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
	self._modal:bind({}, key, fn, nil, (with_repeat or nil) and fn)
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
	local is_down = e:getType() == hs.eventtap.event.types.keyDown
	local is_up   = e:getType() == hs.eventtap.event.types.keyUp
	local is_capslock = e:getKeyCode() == hs.keycodes.map.f18

	if (not self._modal_active) and is_capslock and is_down then
		self:_enter()

	elseif self._modal_active and (not is_capslock) and is_down then
		self._anoter_key_pressed = true

	elseif self._modal_active and is_capslock and is_up then
		self:_exit()
	end

	if is_capslock then
		e:setType(hs.eventtap.event.types.nullEvent)
		return true
	end

	return false
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
