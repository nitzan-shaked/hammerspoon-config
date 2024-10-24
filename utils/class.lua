
---@class Class
---@field __name__ string
---@field __base__ Class?
---@field __prop__ table<string, boolean>
---@field __keys__ table<string, boolean>
---@field __cls__ Class

---@class Instance
---@field __cls__ Class
---@field __keys__ table<string, boolean>
---@field __dict__ table<string, any>

--==============================================================================

---@param cls Class
---@return string
local function __cls_tostring(cls)
	return "<class '" .. cls.__name__ .. "'>"
end

---@param cls Class
---@param k string
---@return boolean
local function __cls_lookup_prop(cls, k)
	local base_cls = cls
	while base_cls do
		if base_cls.__prop__[k] then
			return true
		end
		base_cls = base_cls.__base__
	end
	return false
end

---@param cls Class
---@param k string
---@return boolean, any
local function __cls_lookup(cls, k)
	local base_cls = cls
	while base_cls do
		if base_cls.__keys__[k] then
			return true, rawget(base_cls, k)
		end
		base_cls = base_cls.__base__
	end
	return false, nil
end

---@param cls Class
---@param k string
---@return any
local function __cls_index(cls, k)
	if k == "__name__" then return rawget(cls, k) end
	if k == "__base__" then return rawget(cls, k) end
	if k == "__prop__" then return rawget(cls, k) end
	if k == "__keys__" then return rawget(cls, k) end

	local have, v = __cls_lookup(cls, k)
	if have then return v end
	error("class " .. cls.__name__ .. " does not have attribute " .. k)
end

---@param cls Class
---@param k string
---@param v any
local function __cls_newindex(cls, k, v)
	if k == "__name__" then error("cannot change " .. k .. " on class " .. cls.__name__) end
	if k == "__base__" then error("cannot change " .. k .. " on class " .. cls.__name__) end
	if k == "__prop__" then error("cannot change " .. k .. " on class " .. cls.__name__) end
	if k == "__keys__" then error("cannot change " .. k .. " on class " .. cls.__name__) end

	cls.__keys__[k] = true
	rawset(cls, k, v)
end

---@param cls Class
---@return Instance
local function __cls_call(cls, ...)
	local obj = {
		__keys__={},
		__dict__={},
	}
	setmetatable(obj, cls)
	local init_method = cls.__init__
	if init_method then
		init_method(obj, ...)
	end
	return obj
end

--==============================================================================

---@param self Instance
---@return string
local function __obj_tostring(self)
	return self.__cls__.__name__ .. " instance"
end

---@param self Instance
---@param k string
local function __obj_index(self, k)
	if k == "__cls__"  then return getmetatable(self) end
	if k == "__keys__" then return rawget(self, k) end
	if k == "__dict__" then return rawget(self, k) end

	if self.__keys__[k] then
		return self.__dict__[k]
	end

	local cls = self.__cls__

	if __cls_lookup_prop(cls, k) then
		local _, get_func = __cls_lookup(cls, "get_" .. k)
		if not get_func then
			error("cannot find get() method for property " .. k .. " on class " .. cls.__name__)
		end
		return get_func(self)
	end

	local have, v = __cls_lookup(cls, k)
	if have then return v end
	error("instance of class " .. self.__cls__.__name__ .. " does not have attribute " .. k)
end

---@param self Instance
---@param k string
---@param v any
local function __obj_newindex(self, k, v)
	local cls_name = self.__cls__.__name__
	if k == "__cls__"  then return error("cannot change " .. k .. " on instance of class " .. cls_name) end
	if k == "__keys__" then return error("cannot change " .. k .. " on instance of class " .. cls_name) end
	if k == "__dict__" then return error("cannot change " .. k .. " on instance of class " .. cls_name) end

	local cls = self.__cls__

	if __cls_lookup_prop(cls, k) then
		local _, set_func = __cls_lookup(cls, "set_" .. k)
		if not set_func then
			error("cannot find set() method for property " .. k .. " on class " .. cls.__name__)
		end
		set_func(self, v)
		return
	end

	self.__keys__[k] = true
	self.__dict__[k] = v
end

--==============================================================================

---@param cls_name string
---@param base_cls Class?
---@param prop string[]?
---@return Class
local function _make_class(cls_name, base_cls, prop)
	local cls = {
		__name__=cls_name,
		__base__=base_cls,
		__prop__={},
		__keys__={},
	}

	for k, v in pairs(base_cls or {}) do
		if (
			k ~= "__name__"
			and k ~= "__base__"
			and k ~= "__prop__"
			and k ~= "__keys__"
		) then
			cls.__keys__[k] = true
			cls[k] = v
		end
	end

	for _, prop_name in ipairs(prop or {}) do
		cls.__prop__[prop_name] = true
	end

	setmetatable(cls, {
		__call=__cls_call,
		__tostring=__cls_tostring,
		__index=__cls_index,
		__newindex=__cls_newindex,
	})

	function cls:__tostring()
		return __obj_tostring(self)
	end

	function cls:__index(k)
		return __obj_index(self, k)
	end

	function cls:__newindex(k, v)
		return __obj_newindex(self, k, v)
	end

	return cls
end

--==============================================================================

---@class Class
local Object = _make_class("Object")

function Object:__init__(...)
end

--==============================================================================

---@param cls_name string
---@param base_cls Class?
---@param prop string[]?
---@return Class
local function make_class(cls_name, base_cls, prop)
	return _make_class(cls_name, base_cls or Object, prop)
end

---@param cls1 Class
---@param cls2 Class
---@return boolean
local function is_subclass(cls1, cls2)
	local c = cls1
	while c do
		if c == cls2 then return true end
		c = c.__base__
	end
	return false
end

---@param obj Instance
---@param cls Class
---@return boolean
local function is_instance(obj, cls)
	return is_subclass(obj.__cls__, cls)
end

--==============================================================================

return {
	make_class=make_class,
	is_subclass=is_subclass,
	is_instance=is_instance,
	Object=Object
}
