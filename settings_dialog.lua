local screen = require("hs.screen")
local webview = require("hs.webview")
local spoons = require("hs.spoons")

--[[ CONFIG ]]

--[[ STATE ]]

local obj = {}
obj.__index = obj

--[[ LOGIC ]]

local function mk_browser()
	local frame = screen:primaryScreen():frame():copy()
	frame.w = frame.w / 4
	frame.h = frame.h / 4
	local options = {}

	local browser = webview.new(frame, options)
		:windowStyle({"titled", "closable", "utility", "HUD"})
		:closeOnEscape(true)
		:deleteOnClose(true)
		:bringToFront(true)
		:allowTextEntry(true)
		:transparent(false)

	return browser
end

function obj:start()
	local browser = mk_browser()
	browser:url("file://" .. spoons.scriptPath() .. "html/settings_dialog.html")
	browser:show()
end

--[[ MODULE ]]

return obj
