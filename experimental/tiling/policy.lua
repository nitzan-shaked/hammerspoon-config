local Container = require("tiling.container")
local class = require("utils.class")

--[[ LOGIC ]]

---@class Policy: Class
---@field screen Screen
---@field space_id integer
---@field top_container Container
local Policy = class("Policy")

---@param screen Screen
---@param space_id integer
function Policy:__init(screen, space_id)
	self.screen = screen
	self.space_id = space_id
	self.top_container = Container:for_screen(screen)
end

---@param w Window
function Policy:has_window(w)
	return self.top_container:has_window(w)
end

---@param w Window
---@return boolean
function Policy:add_window(w) error("must implement in subclass") end

---@param w Window
function Policy:remove_window(w) error("must implement in subclass") end

---@param w Window
function Policy:on_window_allowed(w)
	if not self:has_window(w) then
		self:add_window(w)
	end
end

---@param w Window
function Policy:on_window_rejected(w)
	if self:has_window(w) then
		self:remove_window(w)
	end
end

---@param w Window
function Policy:on_window_moved(w)
	local c = Container.of(w)
	if c == nil then return end
	w:setFrame(c._rect)
end

--[[ MODULE ]]

return Policy
