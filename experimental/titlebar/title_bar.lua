local class = require("utils.class")
local Size = require("geom.size")
local TitleBarButtonArea = require("experimental.titlebar.title_bar_button_area")

--[[ CONFIG ]]

local CORNER_RADIUS = 8
local TITLE_BAR_PADDING = Size(2, 4)
local TITLE_BAR_BG_COLOR = {red=0.15, green=0.15, blue=0.15}

--[[ LOGIC ]]

---@class TitleBar: Class
---@operator call: TitleBar
---@field button_area TitleBarButtonArea
---@field canvas Canvas
---@field h integer
local TitleBar = class("TitleBar")

---@param buttons TitleBarButton[]
function TitleBar:__init__(buttons)
	self.button_area = TitleBarButtonArea(buttons)
	self.h = 2 * (CORNER_RADIUS + TITLE_BAR_PADDING.h) + self.button_area.size.h
	self.canvas = hs.canvas.new({})
	self.canvas:appendElements({
		id="bg",
		type="rectangle",
		action="fill",
		fillColor=TITLE_BAR_BG_COLOR,
	})
	self.canvas:appendElements({
		id="bg2",
		type="rectangle",
		action="fill",
		fillColor=TITLE_BAR_BG_COLOR,
	})
	self.canvas:appendElements({
		id="line",
		type="rectangle",
		action="fill",
		fillColor={black=1},
	})
	self.canvas:appendElements({
		id="button_area",
		type="canvas",
		canvas=self.button_area.canvas,
	})
	self:on_resized(1, 1)
end

---@param x_ratio number
---@param y_ratio number
function TitleBar:on_resized(x_ratio, y_ratio)
	local actual_corner_radius_x = math.ceil(CORNER_RADIUS * x_ratio)
	local actual_corner_radius_y = math.ceil(CORNER_RADIUS * y_ratio)
	self.h = 2 * (actual_corner_radius_y + TITLE_BAR_PADDING.h) + self.button_area.size.h
	self.canvas["bg"].roundedRectRadii = {
		xRadius=actual_corner_radius_x,
		yRadius=actual_corner_radius_y,
	}
	self.canvas["bg2"].frame = {
		x=0,
		y=self.h - actual_corner_radius_y,
		w="100%",
		h=actual_corner_radius_y,
	}
	self.canvas["line"].frame = {
		x=0,
		y=self.h - 1,
		w="100%",
		h=1,
	}
	self.canvas["button_area"].frame = {
		x=actual_corner_radius_x + TITLE_BAR_PADDING.w,
		y=actual_corner_radius_y + TITLE_BAR_PADDING.h,
		w=self.button_area.size.w,
		h=self.button_area.size.h,
	}
end

--[[ MODULE ]]

return TitleBar
