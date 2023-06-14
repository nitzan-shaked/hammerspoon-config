local class = require("class")
local TitleBarButtonArea = require("titlebar.title_bar_button_area")

--[[ CONFIG ]]

local TITLE_BAR_PADDING_X = 4
local TITLE_BAR_PADDING_Y = 2

--[[ LOGIC ]]

---@class TitleBar
---@field button_area TitleBarButtonArea
---@field canvas Canvas
---@field h integer
local TitleBar = class("TitleBar")

---@param buttons TitleBarButton[]
function TitleBar:__init__(buttons)
	self.button_area = TitleBarButtonArea(buttons)
	self.h = 2 * TITLE_BAR_PADDING_Y + self.button_area.h

	self.canvas = hs.canvas.new({})
	self.canvas:appendElements({
		id="bg",
		type="rectangle",
		action="fill",
		fillColor={red=0, green=0, blue=0},
	})
	self.canvas:appendElements({
		id="button_area",
		type="canvas",
		canvas=self.button_area.canvas,
		frame={
			x=TITLE_BAR_PADDING_X,
			y=TITLE_BAR_PADDING_Y,
			w=self.button_area.w,
			h=self.button_area.h,
		},
	})
end

--[[ MODULE ]]

return TitleBar
