--[[ MATH ]]

local function round_to(x, n)
	return n * math.floor((x + n / 2) / n)
end

local function round_up_to(x, n)
	return n * math.ceil(x / n)
end

local function round_down_to(x, n)
	return n * math.floor(x / n)
end

--[[ FUNCTIONAL PROGRAMMING ]]

local function array_concat (t1, t2)
	local retval = {table.unpack(t1)}
	for _, v in pairs(t2) do table.insert(retval, v) end
	return retval
end

local function curry (f, ...)
	local curried_args = {...}
	return function(...)
		final_args = array_concat(curried_args, {...})
		return f(table.unpack(final_args))
	end
end

local function method (obj, method_name)
	return curry(obj[method_name], obj)
end

--[[ MODULE ]]

return {
	round_up_to=round_down_to,
	round_down_to=round_down_to,
	round_to=round_to,
	array_concat=array_concat,
	curry=curry,
	method=method,
}
