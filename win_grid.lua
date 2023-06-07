local Grid2D = require("grid2d")

--[[ LOGIC ]]

---@param win Window
---@param center_horiz boolean
---@param center_vert boolean
local function center_win(win, center_horiz, center_vert)
	if not win then return end
	local win_frame = win:frame()
	local screen_frame = win:screen():frame()

	win_frame.center = {
		center_horiz and screen_frame.center.x or win_frame.center.x,
		center_vert  and screen_frame.center.y or win_frame.center.y,
	}
	win:setFrame(win_frame)
end

---@param win Window
---@param grid_size Geometry
local function _grid(win, grid_size)
	local screen_frame = win:screen():frame()
	local cell_size = hs.geometry({
		w=math.floor(screen_frame.w / grid_size.w),
		h=math.floor(screen_frame.h / grid_size.h),
	})
	return Grid2D.new(screen_frame, cell_size)
end

---@param win Window
---@param grid_size Geometry
---@param gx integer
---@param gy integer
local function place_win(win, grid_size, gx, gy)
	if not win then return end
	local grid = _grid(win, grid_size)
	win:setFrame(grid:cell(gx, gy))
end

---@param win Window
---@param grid_size Geometry
---@param dgx integer
---@param dgy integer
local function move_win(win, grid_size, dgx, dgy)
	if not win then return end
	local win_frame = win:frame()
	local grid = _grid(win, grid_size)
	win_frame.topleft = grid:move_and_snap(win_frame, dgx, dgy)
	win:setFrame(win_frame)
end

---@param win Window
---@param grid_size Geometry
---@param dgx integer
---@param dgy integer
local function resize_win(win, grid_size, dgx, dgy)
	if not win then return end
	local win_frame = win:frame()
	local grid = _grid(win, grid_size)
	win_frame.bottomright = grid:resize_and_snap(win_frame, dgx, dgy)
	win:setFrame(win_frame)
end

--[[ MODULE ]]

return {
	center_win=center_win,
	place_win=place_win,
	move_win=move_win,
	resize_win=resize_win,
}
