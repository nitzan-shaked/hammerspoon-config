local class = require("utils.class")


---@class Vector2: Class
---@operator call: Vector2
---@field coords number[]
local Vector2 = class.make_class("Vector2", class.Object, {"coords"})
Vector2.__vector_slots = {1, 2}


---@param arg_1 number | Vector2 | Geometry
---@param arg_2 number?
function Vector2:__init__(arg_1, arg_2)
	local slots = self.__vector_slots
	assert(slots)
	local slot_1 = slots[1]
	local slot_2 = slots[2]
	if type(arg_1) == "table" then
		assert(arg_2 == nil)
		local arg1_val1 = arg_1[slot_1]
		local arg1_val2 = arg_1[slot_2]
		if arg1_val1 and arg1_val2 then
	        arg_1, arg_2 = arg1_val1, arg1_val2
		else
			local coords = arg_1.coords
			assert(coords)
			arg_1, arg_2 = coords[1], coords[2]
		end
    end

	assert(type(arg_1) == "number")
	assert(type(arg_2) == "number")
	self[1] = arg_1
	self[2] = arg_2
	self[3] = nil
	self[4] = nil
end

---@return number[]
function Vector2:get_coords()
	return {self[1], self[2]}
end

---@param other Vector2
---@return boolean
function Vector2:__eq(other)
	local my_coords = self.coords
	local other_coords = other.coords
	return my_coords[1] == other_coords[1] and my_coords[2] == other_coords[2]
end

---@param other Vector2
---@return Vector2
function Vector2:__add(other)
	local my_coords = self.coords
	local other_coords = other.coords
	return self.__cls__(my_coords[1] + other_coords[1], my_coords[2] + other_coords[2])
end

---@param other Vector2
---@return Vector2
function Vector2:__sub(other)
	local my_coords = self.coords
	local other_coords = other.coords
	return self.__cls__(my_coords[1] - other_coords[1], my_coords[2] - other_coords[2])
end

---@param k number
---@return Vector2
function Vector2:__mul(k)
	if type(self) == "number" then
		self, k = k, self
	end
	local coords = self.coords
	return self.__cls__(coords[1] * k, coords[2] * k)
end

---@return Vector2
function Vector2:__unm()
	local coords = self.coords
	return self.__cls__(-coords[1], -coords[2])
end

---@param axis number
---@return any
function Vector2:axis_name(axis)
	assert(axis == 1 or axis == 2)
	return self.__vector_slots[axis]
end

---@param axis number
---@return Vector2
function Vector2:axis(axis)
	assert(axis == 1 or axis == 2)
	return axis == 1 and self(1, 0) or self(0, 1)
end


return Vector2
