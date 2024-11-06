local SizeHint = require("tiling.size_hint")
local Container = require("tiling.container")
local Policy = require("tiling.policy")

local class = require("utils.class")

--[[ LOGIC ]]

---@class PolicyBsp: Policy
---@operator call: PolicyBsp
local PolicyBsp = class("PolicyBsp", {base_cls=Policy})

---@param w Window
---@return boolean
function PolicyBsp:add_window(w)
	local new_size_hint = SizeHint(0.5)
	local parent = self.top_container
	while true do
		local parent_n_children = #parent._children

		if parent_n_children == 0 and parent._window then
			parent:wrap_window()
			parent._children_size_hints[1] = new_size_hint
			local new_container = Container()
			parent:add_child(new_container, new_size_hint)
			new_container:set_window(w)
			return true
		end

		if parent_n_children == 0 then
			parent:set_window(w)
			return true
		end

		if parent_n_children == 1 then
			parent._children_size_hints[1] = new_size_hint
			local new_container = Container()
			parent:add_child(new_container, new_size_hint)
			new_container:set_window(w)
			return true
		end

		assert(parent_n_children == 2)
		parent = parent._children[2]
	end
end

---@param w Window
function PolicyBsp:remove_window(w)
	local c = Container.of(w)
	if c == nil then
		return
	end
	c:delete()
	local top_container = self.top_container
	if #top_container._children == 1 then
		top_container:unwrap()
	else
		for _, child in ipairs(top_container._children) do
			child:unwrap()
		end
	end
end

--[[ MODULE ]]

return PolicyBsp
