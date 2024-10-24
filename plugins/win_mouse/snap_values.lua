local class = require("utils.class")


---@alias Bucket table<integer, boolean>

---@class SnapValues: Class
---@operator call: SnapValues
---@field min_value integer
---@field max_value integer
---@field snap_threshold integer
---@field buckets table<integer, Bucket>
local SnapValues = class.make_class("SnapValues")


---@param min_value integer
---@param max_value integer
---@param snap_threshold integer
function SnapValues:__init__(min_value, max_value, snap_threshold)
	self.min_value = min_value
	self.max_value = max_value
	self.snap_threshold = snap_threshold
	self.buckets = {}
end


---@param value number
function SnapValues:add(value)
	if value < self.min_value then return end
	if value > self.max_value then return end
	local buckets = self.buckets
	local mid_bucket = math.floor(value / self.snap_threshold)
	for b = mid_bucket - 1, mid_bucket + 1 do
		if not buckets[b] then buckets[b] = {} end
		buckets[b][value] = true
	end
end


---@param q integer
---@return integer?, integer?
function SnapValues:query(q)
	local bucket = math.floor(q / self.snap_threshold)
	for value in pairs(self.buckets[bucket] or {}) do
		local delta = value - q
		if math.abs(delta) <= self.snap_threshold then
			return value, delta
		end
	end
	return nil, nil
end


return SnapValues
