local class = require("utils.class")
local TitleBarButton = require("titlebar.title_bar_button")

--[[ CONFIG ]]

local BUTTON_COLOR   = {red=0.96, green=0.75, blue=0.31}
local DASH_COLOR     = {red=0.56, green=0.35, blue=0.11}
local DASH_MARGIN    = 3
local DASH_THICKNESS = 2

--[[ LOGIC ]]

---@class TitleBarMinimizeButton: TitleBarButton
local TitleBarMinimizeButton = class("TitleBarMinimizeButton", {
	base_cls=TitleBarButton,
})

---@param callback fun(ev_type: string)
function TitleBarMinimizeButton:__init__(callback)
	TitleBarButton.__init__(self, "minimize", callback, BUTTON_COLOR)

	local canvas = self.canvas
	canvas:appendElements({
		id="dash",
		type="segments",
		action="stroke",
		strokeColor=DASH_COLOR,
		strokeWidth=DASH_THICKNESS,
		strokeCapStyle="round",
		coordinates={
			{x=self.circle_xy00.x + DASH_MARGIN, y=self.circle_center.y},
			{x=self.circle_xy11.x - DASH_MARGIN, y=self.circle_center.y},
		},
	})
	self.extra_element_ids = {"dash"}
	self:hideExtraElements()
end

--[[ MODULE ]]

return TitleBarMinimizeButton
