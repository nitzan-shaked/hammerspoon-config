local class = require("class")

--[[ LOGIC ]]

---@class Vector2: Class
---@field coords number[]
local Vector2 = class("Vector2", {
	slots={1, 2},
})

---@param param1 number
---@param param2 number
---@overload fun(param1: Vector2)
function Vector2:__init__(param1, param2)
	local slots = self.__cls__.__slots__
	assert(slots)
	local slot_1 = slots[1]
	local slot_2 = slots[2]
    if param2 == nil then
        local coords = param1.coords
        self[slot_1] = coords[1]
        self[slot_2] = coords[2]
    else
        self[slot_1] = param1
        self[slot_2] = param2
    end
end

---@return number[]
function Vector2:get_coords()
	local slots = self.__cls__.__slots__
	assert(slots)
	local slot_1 = slots[1]
	local slot_2 = slots[2]
	return {self[slot_1], self[slot_2]}
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

---@return Vector2
function Vector2:x_axis()
	return self(1, 0)
end

---@return Vector2
function Vector2:y_axis()
	return self(0, 1)
end

--[[ MODULE ]]

return Vector2
