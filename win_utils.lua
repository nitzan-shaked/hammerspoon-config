local fn   = require("hs.fnutils")
local geom = require("hs.geometry")
local mp   = require("mini_preview")

--[[ STATE ]]

local hammerspoon_app = hs.application.get("org.hammerspoon.Hammerspoon")

--[[ LOGIC ]]

local function my_visibleWindows ()
	local result = {}
	for _, app in ipairs(hs.application.runningApplications()) do
		if (
			app:kind() > 0
			or app:bundleID() == hammerspoon_app:bundleID()
		) and not app:isHidden() then
			for _, w in ipairs(app:visibleWindows()) do
				result[#result + 1] = w
			end
		end
	end
	return result
end

local function my_orderedWindows ()
	local winset = {}
	for _, w in ipairs(my_visibleWindows()) do
		winset[w:id() or -1] = w
	end

	local result = {}
	for _, win_id in ipairs(hs.window._orderedwinids()) do
		result[#result + 1] = winset[win_id]
	end
	return result
end


local function mini_preview_under_pointer ()
	local mouse_pos = geom.point(hs.mouse.absolutePosition())
	local mouse_screen = hs.mouse.getCurrentScreen()
	return fn.find(hammerspoon_app:visibleWindows(), function (w)
		return (
			w:screen() == mouse_screen
			and mp.MiniPreview.by_preview_window(w)
			and mouse_pos:inside(w:frame())
		)
	end)
end

local function window_under_pointer (include_mini_previews)
	local mouse_pos = geom.point(hs.mouse.absolutePosition())
	local mouse_screen = hs.mouse.getCurrentScreen()
	if include_mini_previews then
		result = mini_preview_under_pointer()
		if result then
			return result
		end
	end
	return fn.find(my_orderedWindows(), function (w)
		return (
			w:screen() == mouse_screen
			and w:isStandard()
			and mouse_pos:inside(w:frame())
		)
	end)
end

--[[ MODULE ]]

return {
	my_visibleWindows=my_visibleWindows,
	my_orderedWindows=my_orderedWindows,
	window_under_pointer=window_under_pointer,
}
