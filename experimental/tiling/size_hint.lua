local class = require("utils.class")

--[[ LOGIC ]]

---@class SizeHint: Class
---@field min_len integer
---@field fraction number
local SizeHint = class("SizeHint")

---@param fraction number
---@param min_len integer?
function SizeHint:__init(fraction, min_len)
	assert(fraction > 0 and fraction <= 1)
	min_len = min_len or 64
	self.fraction = fraction
	self.min_len = min_len
end

--[[ MODULE ]]

return SizeHint
