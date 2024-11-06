local SizeHint = require("tiling.size_hint")
local Container = require("tiling.container")
local Policy = require("tiling.policy")
local PolicyMaxN = require("tiling.policy_max_n")

local class = require("utils.class")

--[[ LOGIC ]]

---@class PolicyCols: Policy
---@operator call: PolicyCols
local PolicyCols = class("PolicyCols", {base_cls=Policy})

---@param screen Screen
---@param space_id integer
---@param max_cols integer
function PolicyCols:__init(screen, space_id, max_cols)
	assert(max_cols >= 1)
	Policy.__init(self, screen, space_id)
	self._max_cols = max_cols
end

---@param w Window
---@return boolean
function PolicyCols:add_window(w)
	local top_container = self.top_container
	assert(self._max_cols)

	if self._last_col then
		return self._last_col:add_window(w)
	end

	local n_cols = #top_container._children
	local new_size_hint = SizeHint(1 / (n_cols + 1))

	for i = 1, #top_container._children do
		top_container._children_size_hints[i] = new_size_hint
	end

	if n_cols == self._max_cols - 1 then
		self._last_col = PolicyMaxN()
		top_container:add_child(self._last_col.top_container, new_size_hint)
		return self._last_col:add_window(w)
	else
		local new_col = Container()
		top_container:add_child(new_col, new_size_hint)
		new_col.window = w
		return true
	end
end

--[[ MODULE ]]

return PolicyCols
