local class = require("class")

--[[ CONFIG ]]

local BUTTON_AREA_PADDING_X = 4
local BUTTON_AREA_PADDING_Y = 2
local BUTTON_AREA_INTER_BUTTON_PADDING = 4

--[[ LOGIC ]]

---@class TitleBarButtonArea
---@field buttons TitleBarButton[]
---@field canvas Canvas
---@field w integer
---@field h integer
local TitleBarButtonArea = class("TitleBarButtonArea")

---@param buttons TitleBarButton[]
function TitleBarButtonArea:__init__(buttons)
	self.buttons = buttons

	local button_area_width = 0
	button_area_width = button_area_width + BUTTON_AREA_PADDING_X
	for _, button in pairs(self.buttons) do
		button_area_width = button_area_width + button.w
		button_area_width = button_area_width + BUTTON_AREA_INTER_BUTTON_PADDING
	end
	button_area_width = button_area_width - BUTTON_AREA_INTER_BUTTON_PADDING
	button_area_width = button_area_width + BUTTON_AREA_PADDING_X

	local button_area_height = 0
	for _, button in pairs(self.buttons) do
		button_area_height = math.max(button_area_height, button.h)
	end
	button_area_height = button_area_height + 2 * BUTTON_AREA_PADDING_Y

	self.w = button_area_width
	self.h = button_area_height

	self.canvas = hs.canvas.new({})
	self.canvas:appendElements({
		id="bg",
		type="rectangle",
		action="fill",
		fillColor={alpha=0},
		trackMouseEnterExit=true,
	})
	self.canvas:mouseCallback(function (...) self:mouseCallback(...) end)

	local curr_button_x0 = 0

	local function advance_curr_button_x(delta)
		curr_button_x0 = curr_button_x0 + delta
	end

	advance_curr_button_x(BUTTON_AREA_PADDING_X)
	for _, button in ipairs(self.buttons) do
		self.canvas:appendElements({
			id=button.name .. "_button",
			type="canvas",
			canvas=button.canvas,
			frame={
				x=curr_button_x0,
				y=BUTTON_AREA_PADDING_Y,
				w=button.w,
				h=button.h,
			},
		})
		advance_curr_button_x(button.w)
		advance_curr_button_x(BUTTON_AREA_INTER_BUTTON_PADDING)
	end
	advance_curr_button_x(-BUTTON_AREA_INTER_BUTTON_PADDING)
	advance_curr_button_x(BUTTON_AREA_PADDING_X)
end

function TitleBarButtonArea:mouseCallback(canvas, ev_type, elem_id, x, y)
	if elem_id == "bg" then
		if ev_type == "mouseEnter" then
			for _, button in ipairs(self.buttons) do
				button:onEnterButtonArea()
			end
		elseif ev_type == "mouseExit" then
			for _, button in ipairs(self.buttons) do
				button:onExitButtonArea()
			end
		end
	end
end

--[[ MODULE ]]

return TitleBarButtonArea
