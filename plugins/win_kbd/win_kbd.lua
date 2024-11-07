local Module = require("module")
local class = require("utils.class")
local settings = require("settings")
local settings_utils = require("settings_utils")

local Point = require("geom.point")
local Size = require("geom.size")
local WinGrid = require("win_grid")


---@class WinKbd: Module
local WinKbd = class.make_class("WinKbd", Module)


function WinKbd:__init__()
	Module.__init__(
		self,
		"win_kbd",
		"Win-Kbd",
		"Control window positions and sizes with the keyboard.",
		{{
			name="move_mods",
			title="Move modifiers",
			descr="Modifiers to hold down for 'move' mode.",
			control="mods",
			default={"ctrl", "cmd"},
		}, {
			name="resize_mods",
			title="Resize modifiers",
			descr="Modifiers to hold down for 'resize' mode.",
			control="mods",
			default={"ctrl", "alt"},
		}},
		{}
	)

	self._grid_size = Size(16, 8)
	---@type WinGrid
	self._grid = nil
end


function WinKbd:loadImpl()
	self._grid = WinGrid(self._grid_size)
	local cfg = settings.loadPluginSettings(self.name)
	local move_mods = settings_utils.modsFromHtml(cfg.move_mods)
	local resize_mods = settings_utils.modsFromHtml(cfg.resize_mods)

	if move_mods and #move_mods > 0 then
		self:_bind_hotkey(move_mods, ",", function ()
			self:_center_win(hs.window.focusedWindow(), true, true)
		end)
		self:_bind_hotkey(move_mods, "/", function ()
			self:_maximize_win(hs.window.focusedWindow(), true, true)
		end)
	end

	local function op(grid, fn, ...)
		local args = {...}
		return function ()
			return fn(grid, hs.window.focusedWindow(), table.unpack(args))
		end
	end

	if move_mods and #move_mods > 0 then
		self:_bind_hotkey(move_mods, "LEFT",  op(self._grid, WinGrid.moveWin, Point(-1,  0)), true)
		self:_bind_hotkey(move_mods, "RIGHT", op(self._grid, WinGrid.moveWin, Point( 1,  0)), true)
		self:_bind_hotkey(move_mods, "UP",    op(self._grid, WinGrid.moveWin, Point( 0, -1)), true)
		self:_bind_hotkey(move_mods, "DOWN",  op(self._grid, WinGrid.moveWin, Point( 0,  1)), true)
	end

	if resize_mods and #resize_mods > 0 then
		self:_bind_hotkey(resize_mods, "LEFT",  op(self._grid, WinGrid.resizeWin, Point(-1,  0)), true)
		self:_bind_hotkey(resize_mods, "RIGHT", op(self._grid, WinGrid.resizeWin, Point( 1,  0)), true)
		self:_bind_hotkey(resize_mods, "UP",    op(self._grid, WinGrid.resizeWin, Point( 0, -1)), true)
		self:_bind_hotkey(resize_mods, "DOWN",  op(self._grid, WinGrid.resizeWin, Point( 0,  1)), true)
	end
end


function WinKbd:unloadImpl()
	self._grid = nil
end


---@param win Window
---@param center_horiz boolean
---@param center_vert boolean
function WinKbd:_center_win(win, center_horiz, center_vert)
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
function WinKbd:_maximize_win(win, maximize_horiz, maximize_vert)
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


return WinKbd()