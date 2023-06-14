local class = require("class")
local TitleBarButton = require("titlebar.title_bar_button")

--[[ CONFIG ]]

local BUTTON_COLOR      = {red=0.93, green=0.41, blue=0.37}
local X_LINES_COLOR     = {red=0.41, green=0.07, blue=0.04}
local X_LINES_MARGIN    = 2
local X_LINES_THICKNESS = 2

--[[ LOGIC ]]

---@class TitleBarCloseButton: TitleBarButton
local TitleBarCloseButton = class("TitleBarCloseButton", TitleBarButton)

---@param callback fun(ev_type: string)
function TitleBarCloseButton:__init__(callback)
	TitleBarButton.__init__(self, "close", callback, BUTTON_COLOR)

	local line_1_x0 = self.circle_x0 + self.delta_45 + X_LINES_MARGIN
	local line_1_y0 = self.circle_y0 + self.delta_45 + X_LINES_MARGIN
	local line_1_x1 = self.circle_x1 - X_LINES_MARGIN - self.delta_45
	local line_1_y1 = self.circle_y1 - X_LINES_MARGIN - self.delta_45

	local line_2_x0 = line_1_x1
	local line_2_y0 = line_1_y0
	local line_2_x1 = line_1_x0
	local line_2_y1 = line_1_y1

	local canvas = self.canvas
	canvas:appendElements({
		id="line_1",
		type="segments",
		action="stroke",
		strokeColor=X_LINES_COLOR,
		strokeWidth=X_LINES_THICKNESS,
		strokeCapStyle="round",
		coordinates={
			{x=line_1_x0, y=line_1_y0},
			{x=line_1_x1, y=line_1_y1},
		},
	})
	canvas:appendElements({
		id="line_2",
		type="segments",
		action="stroke",
		strokeColor=X_LINES_COLOR,
		strokeWidth=X_LINES_THICKNESS,
		strokeCapStyle="round",
		coordinates={
			{x=line_2_x0, y=line_2_y0},
			{x=line_2_x1, y=line_2_y1},
		},
	})
	self.extra_element_ids = {"line_1", "line_2"}
	self:hideExtraElements()
end

--[[ MODULE ]]

return TitleBarCloseButton
