local SizeHint = require("tiling.size_hint")
local Container = require("tiling.container")
local Policy = require("tiling.policy")

local class = require("utils.class")

--[[ LOGIC ]]

---@class PolicyMaxN: Policy
---@operator call: PolicyMaxN
local PolicyMaxN = class("PolicyMaxN", {base_cls=Policy})

---@param screen Screen
---@param space_id integer
---@param max_children integer
function PolicyMaxN:__init(screen, space_id, max_children)
	assert(max_children >= 1)
	Policy.__init(self, screen, space_id)
	self._max_children = max_children
end

---@param w Window
---@return boolean
function PolicyMaxN:add_window(w)
	local top_container = self.top_container
	local n_children = #top_container._children

	if n_children == self._max_children then
		return false
	end

	if n_children == 0 and not top_container._window then
		top_container:set_window(w)
		return true
	end

	top_container:wrap_window()
	n_children = #top_container._children

	local new_size_hint = SizeHint(1 / (n_children + 1))
	for i = 1, #top_container._children do
		top_container._children_size_hints[i] = new_size_hint
	end

	local new_container = Container()
	top_container:add_child(new_container, new_size_hint)
	new_container:set_window(w)

	return true
end

--[[ MODULE ]]

return PolicyMaxN
