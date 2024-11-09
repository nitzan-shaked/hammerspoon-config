local class = require("utils.class")


---@class Module: Class
---@operator call: Module
local Module = class.make_class("Module", class.Object)


---@alias SettingsItem {name: string, title: string, descr: string, type: string, default: any}
---@alias Action {name: string, title: string, descr: string, fn: function}
---@alias HotkeySpec [string[], string]

---@param name string
---@param title string
---@param descr string
---@param settings_items SettingsItem[]
---@param actions Action[]
function Module:__init__(name, title, descr, settings_items, actions)
	self.name = name
	self.title = title
	self.descr = descr
	self.settings_schema = {
		name=name,
		title=title,
		descr=descr,
		items=settings_items,
	}
	self.actions = actions
	self.loaded = false
	self.started = false
	self.hotkeys = {}
	self.hyper_keys = {}
end


function Module:_check_loaded()
	assert(self.loaded, "not loaded")
end

function Module:_check_started()
	assert(self.started, "not started")
end

function Module:_check_loaded_and_started()
	self:_check_loaded()
	self:_check_started()
end


function Module:load()
	assert(not self.loaded, "already loaded")
	local core_modules = require("core_modules")
	self.core_modules = core_modules
	self:loadImpl()
	self.started = false
	self.loaded = true
	self:didLoad()
end


function Module:start()
	assert(self.loaded, "not loaded")
	assert(not self.started, "already started")
	self:startImpl()
	self:enableHotkeys()
	self.started = true
	self:didStart()
end


function Module:stop()
	assert(self.loaded, "not loaded")
	if not self.started then return end
	self:disableHotkeys()
	self:stopImpl()
	self.started = false
	self:didStop()
end


function Module:unload()
	if not self.loaded then return end
	self:stop()
	self:unloadImpl()
	self:unbindHotkeys()
	self.loaded = false
	self:didUnload()
end


function Module:loadImpl()   end
function Module:didLoad()    end

function Module:startImpl()  end
function Module:didStart()   end

function Module:stopImpl()   end
function Module:didStop()    end

function Module:unloadImpl() end
function Module:didUnload()  end


---@param spec table<string, HotkeySpec>
function Module:bindActionsHotkeys(spec)
	self:unbindHotkeys()
	for _, action in ipairs(self.actions) do
		local s = spec[action.name]
		if s == nil then goto continue end
		local mods = s[1]
		local key = s[2]
		local mods_contain_hyper = false
		for _, mod in ipairs(mods) do
			if mod == "hyper" then
				mods_contain_hyper = true
				break
			end
		end
		if mods_contain_hyper then
			if #mods ~= 1 then error("hyper key must be used alone") end
			self:_bind_hyper_key(key, action.fn)
		else
			self:_bind_hotkey(mods, key, action.fn, true)
		end
		::continue::
	end
end


---@param key string
---@param fn fun(...): nil
function Module:_bind_hyper_key(key, fn)
	self.hyper_keys[key] = fn
	if self.started then
		self.core_modules.hyper:bind(key, fn)
	end
end


---@param mods string[]
---@param key string
---@param fn fun(...): nil
---@param with_repeat boolean?
function Module:_bind_hotkey(mods, key, fn, with_repeat)
	local hk = hs.hotkey.bind(mods, key, fn, nil, with_repeat and fn or nil)
	if not self.started then
		hk:disable()
	end
	table.insert(self.hotkeys, hk)
end


function Module:disableHotkeys()
	for _, hk in ipairs(self.hotkeys) do
		hk:disable()
	end
	for key, _ in pairs(self.hyper_keys) do
		self.core_modules.hyper:unbind(key)
	end
end


function Module:enableHotkeys()
	for _, hk in ipairs(self.hotkeys) do
		hk:enable()
	end
	for key, fn in pairs(self.hyper_keys) do
		self.core_modules.hyper:bind(key, fn)
	end
end


function Module:unbindHotkeys()
	self:disableHotkeys()
	for _, hk in ipairs(self.hotkeys) do
		hk:delete()
	end
	self.hotkeys = {}
	self.hyper_keys = {}

end


return Module