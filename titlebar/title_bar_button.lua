local class = require("class")

--[[ CONFIG ]]

local BUTTON_RADIUS = 6
local BUTTON_PADDING_X = 2
local BUTTON_PADDING_Y = 2

--[[ LOGIC ]]

---@class TitleBarButton
---@field name string
---@field canvas Canvas
local TitleBarButton = class("TitleBarButton")

---@param name string
---@param callback fun(button: TitleBarButton)
---@param color any
function TitleBarButton:__init__(name, callback, color)
	self.name = name
	self.callback = callback

	self.radius = BUTTON_RADIUS
	self.padding_x = BUTTON_PADDING_X
	self.padding_y = BUTTON_PADDING_Y

	self.circle_diameter = 2 * self.radius

	self.circle_x0 = self.padding_x
	self.circle_y0 = self.padding_y
	self.circle_x1 = self.circle_x0 + self.circle_diameter
	self.circle_y1 = self.circle_y0 + self.circle_diameter
	self.circle_center_x = self.padding_x + self.radius
	self.circle_center_y = self.padding_y + self.radius

	local sqrt_2 = math.sqrt(2)
	self.delta_45 = self.radius * (sqrt_2 - 1) / sqrt_2

	self.w = 2 * self.padding_x + self.circle_diameter
	self.h = 2 * self.padding_y + self.circle_diameter

	self.canvas = hs.canvas.new({})
	self.canvas:appendElements({
		id="button",
		type="circle",
		action="fill",
		fillColor=color,
		center={x=self.circle_center_x, y=self.circle_center_y},
		radius=self.radius,
		trackMouseDown=true,
	})
	self.canvas:mouseCallback(function (...) self:mouseCallback() end)

	---@type string[]
	self.extra_element_ids = {}
end

function TitleBarButton:mouseCallback()
	self.callback(self)
end

function TitleBarButton:showExtraElements()
	for _, elem_id in ipairs(self.extra_element_ids) do
		local elem = self.canvas[elem_id]
		elem.fillColor.alpha = 1
		elem.strokeColor.alpha = 1
	end
end

function TitleBarButton:hideExtraElements()
	for _, elem_id in ipairs(self.extra_element_ids) do
		local elem = self.canvas[elem_id]
		elem.fillColor.alpha = 0
		elem.strokeColor.alpha = 0
	end
end

function TitleBarButton:onEnterButtonArea()
	self:showExtraElements()
end

function TitleBarButton:onExitButtonArea()
	self:hideExtraElements()
end

--[[ MODULE ]]

return TitleBarButton
