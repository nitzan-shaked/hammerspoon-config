local Point = require("geom.point")
local Size = require("geom.size")
local TitleBarButton = require("titlebar.title_bar_button")
local class = require("utils.class")

--[[ CONFIG ]]

local BUTTON_COLOR     = {red=0.39, green=0.78, blue=0.33}
local ARROWS_COLOR     = {red=0.16, green=0.37, blue=0.09}
local ARROWS_MARGIN    = Size(2, 2)
local ARROWS_THICKNESS = 2

--[[ LOGIC ]]

---@class TitleBarZoomButton: TitleBarButton
local TitleBarZoomButton = class("TitleBarZoomButton", {
	base_cls=TitleBarButton,
})

---@param callback fun(ev_type: string)
function TitleBarZoomButton:__init__(callback)
	TitleBarButton.__init__(self, "zoom", callback, BUTTON_COLOR)

	local t = self.d45xy + ARROWS_MARGIN
	local arrows_topLeft     = self.circle_xy00 + t
	local arrows_bottomRight = self.circle_xy11 - t

	local arrow_len = arrows_bottomRight.x - arrows_topLeft.x - 3
	local arrow_x = arrow_len * Point:x_axis()
	local arrow_y = arrow_len * Point:y_axis()

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
			arrows_topLeft,
			arrows_topLeft + arrow_x,
			arrows_topLeft + arrow_y,
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
			arrows_bottomRight,
			arrows_bottomRight - arrow_x,
			arrows_bottomRight - arrow_y,
		},
	})
	self.extra_element_ids = {"arrow_1", "arrow_2"}
	self:hideExtraElements()
end

--[[ MODULE ]]

return TitleBarZoomButton
