local geom     = require("hs.geometry")
local win_grid = require("win_grid")

--[[ CONFIG ]]

hs.window.animationDuration = 0

local WIN_GRID = geom.size(16, 8)

--[[ LOGIC ]]

local function win_op (f)
	return function (...)
		return f(hs.window.focusedWindow(), ...)
	end
end

local function grid_op (f)
	local wo = win_op (f)
	return function (grid_size)
		return function (x, y)
			return function ()
				return wo(grid_size, x, y)
			end
		end
	end
end

local grid_place_op  = grid_op(win_grid.place_win )
local grid_move_op   = grid_op(win_grid.move_win  )(WIN_GRID)
local grid_resize_op = grid_op(win_grid.resize_win)(WIN_GRID)

function bind_hotkeys(bind_func, kbd_place, kbd_move, kbd_resize)

	local function bind_with_repeat(mods, key, f)
		bind_func(mods, key, f, nil, f)
	end

	local GRID_3x1 = geom.size(3, 1)
	local GRID_2x2 = geom.size(2, 2)
	local GRID_2x1 = geom.size(2, 1)
	local GRID_1x1 = geom.size(1, 1)

	if kbd_place then
		-- 3x1 grid
		bind_func(kbd_place, "1", grid_place_op(GRID_3x1)(0, 0))
		bind_func(kbd_place, "2", grid_place_op(GRID_3x1)(1, 0))
		bind_func(kbd_place, "3", grid_place_op(GRID_3x1)(2, 0))
		-- 2x2 grid
		bind_func(kbd_place, "o", grid_place_op(GRID_2x2)(0, 0))
		bind_func(kbd_place, "p", grid_place_op(GRID_2x2)(1, 0))
		bind_func(kbd_place, "l", grid_place_op(GRID_2x2)(0, 1))
		bind_func(kbd_place, ";", grid_place_op(GRID_2x2)(1, 1))
		-- 2x1 grid
		bind_func(kbd_place, "[", grid_place_op(GRID_2x1)(0, 0))
		bind_func(kbd_place, "]", grid_place_op(GRID_2x1)(1, 0))
		-- 1x1 grid
		bind_func(kbd_place, "/", grid_place_op(GRID_1x1)(0, 0))
	end

	if kbd_move then
		bind_with_repeat(kbd_move, "LEFT",  grid_move_op( -1, nil))
		bind_with_repeat(kbd_move, "RIGHT", grid_move_op(  1, nil))
		bind_with_repeat(kbd_move, "UP",    grid_move_op(nil,  -1))
		bind_with_repeat(kbd_move, "DOWN",  grid_move_op(nil,   1))
		bind_func(kbd_move, ",", function ()
			win_op(win_grid.center_win)(true, true)
		end)
	end

	if kbd_resize then
		bind_with_repeat(kbd_resize, "LEFT",  grid_resize_op( -1, nil))
		bind_with_repeat(kbd_resize, "RIGHT", grid_resize_op(  1, nil))
		bind_with_repeat(kbd_resize, "UP",    grid_resize_op(nil,  -1))
		bind_with_repeat(kbd_resize, "DOWN",  grid_resize_op(nil,   1))
	end

end

--[[ MODULE ]]

return {
	bind_hotkeys=bind_hotkeys,
}
