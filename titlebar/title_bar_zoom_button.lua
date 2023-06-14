local class = require("class")
local TitleBarButton = require("titlebar.title_bar_button")

--[[ CONFIG ]]

local BUTTON_COLOR     = {red=0.39, green=0.78, blue=0.33}
local ARROWS_COLOR     = {red=0.16, green=0.37, blue=0.09}
local ARROWS_MARGIN    = 2
local ARROWS_THICKNESS = 2

--[[ LOGIC ]]

---@class TitleBarZoomButton: TitleBarButton
local TitleBarZoomButton = class("TitleBarZoomButton", TitleBarButton)

---@param callback fun(ev_type: string)
function TitleBarZoomButton:__init__(callback)
	TitleBarButton.__init__(self, "zoom", callback, BUTTON_COLOR)

	local t = math.ceil(self.delta_45 + ARROWS_MARGIN)
	local arrow_1_x0 = self.circle_x0 + t
	local arrow_1_y0 = self.circle_y0 + t
	local arrow_2_x1 = self.circle_x1 - t
	local arrow_2_y1 = self.circle_y1 - t
	local arrow_size = arrow_2_x1 - arrow_1_x0 - 3

	local canvas = self.canvas
	canvas:appendElements({
		id="arrow_1",
		type="segments",
		closed=true,
		action="stroke",
		strokeColor=ARROWS_COLOR,
		strokeWidth=ARROWS_THICKNESS,
		strokeCapStyle="round",
		fillColor=ARROWS_COLOR,
		coordinates={
			{
				x=arrow_1_x0,
				y=arrow_1_y0,
			},
			{
				x=arrow_1_x0 + arrow_size,
				y=arrow_1_y0,
			},
			{
				x=arrow_1_x0,
				y=arrow_1_y0 + arrow_size,
			},
		},
	})
	canvas:appendElements({
		id="arrow_2",
		type="segments",
		closed=true,
		action="stroke",
		strokeColor=ARROWS_COLOR,
		strokeWidth=ARROWS_THICKNESS,
		strokeCapStyle="round",
		fillColor=ARROWS_COLOR,
		coordinates={
			{
				x=arrow_2_x1,
				y=arrow_2_y1,
			},
			{
				x=arrow_2_x1 - arrow_size,
				y=arrow_2_y1,
			},
			{
				x=arrow_2_x1,
				y=arrow_2_y1 - arrow_size,
			},
		},
	})
	self.extra_element_ids = {"arrow_1", "arrow_2"}
	self:hideExtraElements()
end

--[[ MODULE ]]

return TitleBarZoomButton
