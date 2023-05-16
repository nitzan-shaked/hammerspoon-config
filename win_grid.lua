local geom = require("hs.geometry")
local grid = require("grid")

--[[ CONFIG ]]

local WIN_MIN_WIDTH  = 16
local WIN_MIN_HEIGHT = 16

--[[ LOGIC ]]

local function geom_params (win)
	local win_frame = win:frame()
	local screen_frame = win:screen():frame()
	return win_frame, screen_frame
end

local function center_win (win, center_horiz, center_vert)
	if not win then return end
	local win_frame, screen_frame = geom_params(win)
	if not win_frame or not screen_frame then return end

	win_frame.center = {
		center_horiz and screen_frame.center.x or win_frame.center.x,
		center_vert  and screen_frame.center.y or win_frame.center.y,
	}
	win:setFrame(win_frame)
end

local function place_win (win, grid_size, gx, gy)
	if not win then return end
	local win_frame, screen_frame = geom_params(win)
	if not win_frame or not screen_frame then return end

	local cell_size = geom.size(
		screen_frame.w / grid_size.w,
		screen_frame.h / grid_size.h
	)
	local relative_topleft = geom.point(gx, gy) * cell_size
	local relative_frame = geom(relative_topleft, cell_size)
	local new_frame = screen_frame.topleft + relative_frame
	new_frame:fit(screen_frame)
	win:setFrame(new_frame)
end

local function move_win (win, grid_size, dgx, dgy)
	if not win then return end
	local win_frame, screen_frame = geom_params(win)
	if not win_frame or not screen_frame then return end

	win_frame.topleft = grid.move_and_snap(
		screen_frame,
		grid_size,
		win_frame.topleft,
		dgx,
		dgy
	)
	win_frame:fit(screen_frame)
	win:setFrame(win_frame)
end

local function resize_win (win, grid_size, dgx, dgy)
	if not win then return end
	local win_frame, screen_frame = geom_params(win)
	if not win_frame or not screen_frame then return end

	win_frame.bottomright = grid.move_and_snap(
		screen_frame,
		grid_size,
		win_frame.bottomright,
		dgx,
		dgy
	)
	win_frame:fit(screen_frame)
	win:setFrame(win_frame)
end

--[[ MODULE ]]

return {
	place_win=place_win,
	move_win=move_win,
	resize_win=resize_win,
	center_win=center_win,
}
