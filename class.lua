
-------------------------------------------------------------------------------

local META_METHODS = {
	"__index",
	-- "__newindex",
	-- "__mode",
	"__call",
	-- "__metatable",
	"__tostring",
	-- "__len",
	-- "__pairs",
	-- "__ipairs",
	-- "__gc",
	-- "__name",
	-- "__close",
	"__unm",
	"__add",
	"__sub",
	"__mul",
	"__div",
	"__idiv",
	"__pow",
	"__concat",
	"__band",
	"__bor",
	"__bxor",
	"__bnot",
	"__shl",
	"__shr",
	"__eq",
	"__lt",
	"__le",
}

local function __cls_call(cls, ...)
	local obj = {
		__cls__=cls,
	}
	setmetatable(obj, cls)
	cls.__init__(obj, ...)
	return obj
end

local function __cls_tostring(cls)
	return "class " .. cls.__name__
end

local function __cls_index(cls, name)
	return cls.__base__[name]
end

local __cls_mt = {
	__call=__cls_call,
	__tostring=__cls_tostring,
	__index=__cls_index,
}

-------------------------------------------------------------------------------

local function _make_class(name, base_cls)
	local new_cls = {
		__name__=name,
		__base__=base_cls,
	}
	for _, meta_method_name in ipairs(META_METHODS) do
		new_cls[meta_method_name] = base_cls[meta_method_name]
	end
	new_cls.__index = new_cls
	setmetatable(new_cls, __cls_mt)
	return new_cls
end

local Object = _make_class("Object", {})

function Object:__init__()
end

function Object:__tostring()
	return self.__cls__.__name__ .. " instance"
end

-------------------------------------------------------------------------------

local function class(name, base_cls)
	if name == nil then
		return Object
	end
	return _make_class(name, base_cls or Object)
end

-------------------------------------------------------------------------------

return class
