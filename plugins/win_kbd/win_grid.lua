local class = require("utils.class")
local Size = require("geom.size")
local Grid2D = require("grid2d")


---@class WinGrid: Class
---@operator call: WinGrid
---@field grid_size Size
local WinGrid = class.make_class("WinGrid")


---@param grid_size Size
function WinGrid:__init__(grid_size)
	self.grid_size = grid_size
end


---@param win Window?
---@param g Point
function WinGrid:placeWin(win, g)
	if not win then return end
	win:setFrame(self:_gridForWin(win):cell(g))
end


---@param win Window?
---@param dg Point
function WinGrid:moveWin(win, dg)
	if not win then return end
	local win_frame = win:frame()
	win_frame.topleft = self:_gridForWin(win):moveAndSnap(win_frame, dg)
	win:setFrame(win_frame)
end


---@param win Window?
---@param dg Point
function WinGrid:resizeWin(win, dg)
	if not win then return end
	local win_frame = win:frame()
	win_frame.bottomright = self:_gridForWin(win):resizeAndSnap(win_frame, dg)
	win:setFrame(win_frame)
end


---@param win Window
function WinGrid:_gridForWin(win)
	local screen_frame = win:screen():frame()
	local cell_size = Size(
		math.floor(screen_frame.w / self.grid_size.w),
		math.floor(screen_frame.h / self.grid_size.h)
	)
	return Grid2D(screen_frame, cell_size)
end


return WinGrid
