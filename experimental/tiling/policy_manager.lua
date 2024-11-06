local Container = require("tiling.container")
local PolicyBsp = require("tiling.policy_bsp")
local class = require("utils.class")

--[[ STATE ]]

---@alias PolicyFactory fun(screen: Screen, space_id: integer): Policy

---@param screen Screen
---@param space_id integer
---@return Policy
local function default_policy_factory(screen, space_id)
	return PolicyBsp(screen, space_id)
end

---@type PolicyFactory
local policy_factory = default_policy_factory

---@type table<integer, table<integer, Policy>>
local screen_id_space_id_to_policy = {}

--[[ LOGIC ]]

local PolicyManager = class("PolicyManager")

---@param f PolicyFactory
function PolicyManager.set_policy_factory(f)
	policy_factory = f
end

---@return Policy
function PolicyManager.current_policy()
	return PolicyManager.policy_for_screen(hs.screen.mainScreen())
end

---@param w Window
---@return Policy
function PolicyManager.policy_for_window(w)
	return PolicyManager.policy_for_screen(w:screen())
end

---@param screen Screen
---@return Policy
function PolicyManager.policy_for_screen(screen)
	return PolicyManager.policy_for_screen_and_space(
		screen,
		hs.spaces.activeSpaceOnScreen(screen)
	)
end

---@param screen Screen
---@param space_id integer
---@return Policy
function PolicyManager.policy_for_screen_and_space(screen, space_id)
	local screen_id = screen:id()
	local s = screen_id_space_id_to_policy[screen_id]
	if s == nil then
		s = {}
		screen_id_space_id_to_policy[screen_id] = s
	end
	local policy = s[space_id]
	if policy == nil then
		policy = policy_factory(screen, space_id)
		s[space_id] = policy
	end
	return policy
end

---@param w Window
function PolicyManager.on_window_allowed(w)
	PolicyManager.policy_for_window(w):on_window_allowed(w)
end

---@param w Window
function PolicyManager.on_window_rejected(w)
	PolicyManager.policy_for_window(w):on_window_rejected(w)
end

---@param w Window
function PolicyManager.on_window_moved(w)
	PolicyManager.policy_for_window(w):on_window_moved(w)
end

--[[ MODULE ]]

return PolicyManager
