local Point = require("geom.point")
local Size = require("geom.size")
local WinGrid = require("win_grid")


--[[ MODULE ]]

local cls = {}

cls.name = "win_kbd"


--[[ CONFIG ]]

cls.cfg_schema = {
	name=cls.name,
	title="Window Keyboard",
	descr="Control window positions and sizes with the keyboard.",
	items={},
}

cls.grid_size = Size(16, 8)


--[[ STATE ]]

cls.initialized = false
cls.started = false

---@type WinGrid
cls.grid = nil
---@type Hotkey[]
cls.hotkeys = nil


--[[ LOGIC ]]

function cls.isInitialized()
	return cls.initialized
end


function cls.init()
	assert(not cls.initialized, "already initialized")
	cls.grid = WinGrid(cls.grid_size)
	cls.hotkeys = {}
	cls.started = false
	cls.initialized = true
	cls.start()
end


function cls.start()
	assert(cls.initialized, "not initialized")
	assert(not cls.started, "already started")
	for _, hk in ipairs(cls.hotkeys) do
		hk:enable()
	end
	cls.started = true
end

function cls.stop()
	assert(cls.initialized, "not initialized")
	if not cls.started then return end
	for _, hk in ipairs(cls.hotkeys) do
		hk:disable()
	end
	cls.started = false
end


function cls.unload()
	if not cls.initialized then return end
	cls.stop()
	cls.grid = nil
	cls.hotkeys = nil
	cls.initialized = false
end


---@param kbd_place string[]?
---@param kbd_move string[]?
---@param kbd_resize string[]?
function cls.bindHotkeys(kbd_place, kbd_move, kbd_resize)
	assert(cls.initialized, "not initialized")

	---@param mods string[]
	---@param key string
	---@param f fun(...): nil
	local function bind(mods, key, f)
		local hk = hs.hotkey.bind(mods, key, f, nil, f)
		table.insert(cls.hotkeys, hk)
	end

	---@param mods string[]
	---@param key string
	---@param f fun(...): nil
	local function bind_with_repeat(mods, key, f)
		local hk = hs.hotkey.bind(mods, key, f, nil, f)
		table.insert(cls.hotkeys, hk)
	end

	if kbd_place then
		bind(kbd_place, "/", function ()
			cls._maximizeWin(hs.window.focusedWindow(), true, true)
		end)
	end

	if kbd_move then
		bind(kbd_move, ",", function ()
			cls._centerWin(hs.window.focusedWindow(), true, true)
		end)
	end

	local function op(grid, fn, ...)
		local args = {...}
		return function ()
			return fn(grid, hs.window.focusedWindow(), table.unpack(args))
		end
	end

	-- if kbd_place then
	-- 	local grid_2x2 = WinGrid(Size(2, 2))
	-- 	bind(kbd_place, "1", op(grid_2x2, WinGrid.placeWin, Point(0, 0)))
	-- 	bind(kbd_place, "2", op(grid_2x2, WinGrid.placeWin, Point(1, 0)))
	-- 	bind(kbd_place, "3", op(grid_2x2, WinGrid.placeWin, Point(0, 1)))
	-- 	bind(kbd_place, "4", op(grid_2x2, WinGrid.placeWin, Point(1, 1)))

	-- 	local grid_2x1 = WinGrid(Size(2, 1))
	-- 	bind(kbd_place, "[", op(grid_2x1, WinGrid.placeWin, Point(0, 0)))
	-- 	bind(kbd_place, "]", op(grid_2x1, WinGrid.placeWin, Point(1, 0)))
	-- end

	if kbd_move then
		bind_with_repeat(kbd_move, "LEFT",  op(cls.grid, WinGrid.moveWin, Point(-1,  0)))
		bind_with_repeat(kbd_move, "RIGHT", op(cls.grid, WinGrid.moveWin, Point( 1,  0)))
		bind_with_repeat(kbd_move, "UP",    op(cls.grid, WinGrid.moveWin, Point( 0, -1)))
		bind_with_repeat(kbd_move, "DOWN",  op(cls.grid, WinGrid.moveWin, Point( 0,  1)))
	end

	if kbd_resize then
		bind_with_repeat(kbd_resize, "LEFT",  op(cls.grid, WinGrid.resizeWin, Point(-1,  0)))
		bind_with_repeat(kbd_resize, "RIGHT", op(cls.grid, WinGrid.resizeWin, Point( 1,  0)))
		bind_with_repeat(kbd_resize, "UP",    op(cls.grid, WinGrid.resizeWin, Point( 0, -1)))
		bind_with_repeat(kbd_resize, "DOWN",  op(cls.grid, WinGrid.resizeWin, Point( 0,  1)))
	end

end


---@param win Window
---@param center_horiz boolean
---@param center_vert boolean
function cls._centerWin(win, center_horiz, center_vert)
	if not win then return end
	local screen_frame = win:screen():frame()
	local win_frame = win:frame()
	win_frame.center = {
		x=(center_horiz and screen_frame or win_frame).center.x,
		y=(center_vert  and screen_frame or win_frame).center.y,
	}
	win:setFrame(win_frame)
end


---@param win Window
---@param maximize_horiz boolean
---@param maximize_vert boolean
function cls._maximizeWin(win, maximize_horiz, maximize_vert)
	if not win then return end
	local screen_frame = win:screen():frame()
	local win_frame = win:frame()
	if maximize_horiz then
		win_frame.x = screen_frame.x
		win_frame.w = screen_frame.w
	end
	if maximize_vert then
		win_frame.y = screen_frame.y
		win_frame.h = screen_frame.h
	end
	win:setFrame(win_frame)
end


--[[ MODULE ]]

return cls