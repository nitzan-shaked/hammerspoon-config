
---@class Class
---@field __name__ string
---@field __base__ Class?
---@field __cls__ Class

-------------------------------------------------------------------------------

local function __cls_call(cls, ...)
	local obj = {}
	setmetatable(obj, cls)
	obj:__init__(...)
	return obj
end

---@param cls_name string
---@param kwargs {base_cls: Class?, slots: string[]?}
---@return Class
local function _make_class(cls_name, kwargs)
	local base_cls = kwargs.base_cls

	local cls = {}
	for k, v in pairs(base_cls or {}) do
		cls[k] = v
	end
	cls.__name__ = cls_name
	cls.__base__ = base_cls
	setmetatable(cls, {
		__call=__cls_call,
		__tostring=function () return "class " .. cls_name end,
	})

	-- for instances
	if kwargs.slots then
		cls.__slots__ = {}
		cls.__islots__ = {}
		for i, slot_name in pairs(kwargs.slots) do
			cls.__slots__[i] = slot_name
			cls.__islots__[slot_name] = i
		end

		local function __pairs_stateless_iter(tbl, k)
			local prev_slot_idx = k == nil and 0 or cls.__islots__[k]
			if prev_slot_idx == nil then error("invalid state") end
			local curr_slot_idx = prev_slot_idx + 1
			local curr_slot_name = cls.__slots__[curr_slot_idx]
			if curr_slot_name == nil then
				return nil
			end
			return curr_slot_name, tbl[curr_slot_name]
		end

		local function __ipairs_stateless_iter(tbl, prev_slot_idx)
			if prev_slot_idx == nil then prev_slot_idx = 0 end
			local curr_slot_idx = prev_slot_idx + 1
			local curr_slot_name = cls.__slots__[curr_slot_idx]
			if curr_slot_name == nil then
				return nil
			end
			return curr_slot_idx, tbl[curr_slot_name]
		end

		function cls:__pairs()
			return __pairs_stateless_iter, self, nil
		end

		function cls:__ipairs()
			return __ipairs_stateless_iter, self, 0
		end
	end

	function cls:__index(k)
		if k == "__cls__" then
			return cls
		end
		local func = rawget(cls, "get_" .. k)
		return func and func(self) or rawget(cls, k)
	end

	function cls:__newindex(k, v)
		if k == "__cls__" then
			error("cannot set __cls__")
		end
		local func = rawget(cls, "set_" .. k)
		if func then
			func(self, v)
		else
			rawset(self, k, v)
		end
	end

	return cls
end

-------------------------------------------------------------------------------

local Object = _make_class("Object", {})

function Object:__init__()
end

function Object:__tostring()
	return self.__cls__.__name__ .. " instance"
end

function Object:get_table()
	local result = {}
	for k, v in pairs(self) do
		result[k] = v
	end
	return result
end

-------------------------------------------------------------------------------

---@param name string
---@param kwargs {base_cls: Class?, slots: string[]?}?
local function class(name, kwargs)
	kwargs = kwargs or {}
	kwargs.base_cls = kwargs.base_cls or Object
	return _make_class(name, kwargs)
end

---@param cls1 Class
---@param cls2 Class
---@return boolean
local function is_subclass(cls1, cls2)
	local c = cls1
	while c do
		if c == cls2 then
			return true
		end
		c = c.__base__
	end
	return false
end

---@param obj any
---@param cls Class
---@return boolean
local function is_instance(obj, cls)
	return is_subclass(obj.__cls__, cls)
end

local module = {
	Object=Object,
	is_instance=is_instance,
	is_subclass=is_subclass,
}
local function _module_call(t, ...)
	return class(...)
end
setmetatable(module, {__call=_module_call})

return module
