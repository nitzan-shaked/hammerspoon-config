local Point = require("point")
local Size = require("size")
local TitleBarButton = require("titlebar.title_bar_button")
local class = require("class")

--[[ CONFIG ]]

local BUTTON_COLOR      = {red=0.93, green=0.41, blue=0.37}
local X_LINES_COLOR     = {red=0.41, green=0.07, blue=0.04}
local X_LINES_MARGIN    = Size(2, 2)
local X_LINES_THICKNESS = 2

--[[ LOGIC ]]

---@class TitleBarCloseButton: TitleBarButton
local TitleBarCloseButton = class("TitleBarCloseButton", {
	base_cls=TitleBarButton,
})

---@param callback fun(ev_type: string)
function TitleBarCloseButton:__init__(callback)
	TitleBarButton.__init__(self, "close", callback, BUTTON_COLOR)

	local t = self.d45xy + X_LINES_MARGIN
	local topLeft     = self.circle_xy00 + t
	local bottomRight = self.circle_xy11 - t
	local topRight    = Point(bottomRight.x, topLeft.y)
	local bottomLeft  = Point(topLeft.x, bottomRight.y)

	local canvas = self.canvas
	canvas:appendElements({
		id="line_1",
		type="segments",
		action="stroke",
		strokeColor=X_LINES_COLOR,
		strokeWidth=X_LINES_THICKNESS,
		strokeCapStyle="round",
		coordinates={topLeft, bottomRight},
	})
	canvas:appendElements({
		id="line_2",
		type="segments",
		action="stroke",
		strokeColor=X_LINES_COLOR,
		strokeWidth=X_LINES_THICKNESS,
		strokeCapStyle="round",
		coordinates={topRight, bottomLeft},
	})
	self.extra_element_ids = {"line_1", "line_2"}
	self:hideExtraElements()
end

--[[ MODULE ]]

return TitleBarCloseButton
