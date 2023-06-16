local class = require("class")

--[[ LOGIC ]]

---@class Vector2: Class
---@field x number
---@field y number
local Vector2 = class("Vector2")

---@param param1 number
---@param param2 number
---@overload fun(param1: Vector2)
function Vector2:__init__(param1, param2)
	if param2 == nil then
		self.x = param1.x
		self.y = param1.y
	else
		self.x = param1
		self.y = param2
	end
end

---@param other Vector2
---@return boolean
function Vector2:__eq(other)
	return self.x == other.x and self.y == other.y
end

---@param other Vector2
---@return Vector2
function Vector2:__add(other)
	return self.__cls__(self.x + other.x, self.y + other.y)
end

---@param other Vector2
---@return Vector2
function Vector2:__sub(other)
	return self.__cls__(self.x - other.x, self.y - other.y)
end

---@param k number
---@return Vector2
function Vector2:__mul(k)
	if type(self) == "number" then
		self, k = k, self
	end
	return self.__cls__(self.x * k, self.y * k)
end

---@return Vector2
function Vector2:__unm()
	return self.__cls__(-self.x, -self.y)
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
