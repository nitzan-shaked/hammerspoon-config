local geom = require("hs.geometry")
local u = require("utils")

--[[ LOGIC ]]

local function move_and_snap_1d_point(screen_len, grid_len, x, dg)
	if dg == nil then
		return x
	end
	local grid_cell_len = screen_len / grid_len
	local grid_x = u.round_to(x, grid_cell_len)

	if math.abs(x - grid_x) <= 1 then
		x = grid_x
	elseif dg < 0 then
		x = u.round_down_to(x, grid_cell_len)
		dg = dg + 1
	elseif dg > 0 then
		x = u.round_up_to(x, grid_cell_len)
		dg = dg - 1
	end

	x = x + dg * grid_cell_len
	if x < 0 then
		x = 0
	end
	if x > screen_len then
		x = screen_len
	end

	return x
end

local function move_and_snap_virtual_point(screen_size, grid_size, p, dgx, dgy)
	return geom.point(
		move_and_snap_1d_point(screen_size.w, grid_size.w, p.x, dgx),
		move_and_snap_1d_point(screen_size.h, grid_size.h, p.y, dgy)
	)
end

local function move_and_snap_screen_point(screen_frame, grid_size, p, dgx, dgy)
	local origin = screen_frame.topleft
	return origin + move_and_snap_virtual_point(
		screen_frame.wh,
		grid_size,
		p - origin,
		dgx,
		dgy
	)
end

--[[ MODULE ]]

return {
	move_and_snap=move_and_snap_screen_point,
}
