---@meta "hs.window.filter"

---@class Filter
local Filter = {}

---@param callback fun()
---@return Filter
function Filter.new(callback) end

---@param value boolean
function Filter:setCurrentSpace(value) end

---@param w Window
---@return boolean
function Filter:isWindowAllowed(w) end

---@alias SubscribeCallback fun(w: Window, app_name: string, ev_name: string)
---@param events string | string[]
---@param callbacks SubscribeCallback | SubscribeCallback[]
---@param immediate boolean?
function Filter:subscribe(events, callbacks, immediate) end

---@class hs.window.filter
local module = {
    new=Filter.new,
	windowAllowed="windowAllowed",
	windowRejected="windowRejected",
	windowCreated="windowCreated",
	windowDestroyed="windowDestroyed",
	windowFullscreened="windowFullscreened",
	windowHidden="windowHidden",
	windowInCurrentSpace="windowInCurrentSpace",
	windowMinimized="windowMinimized",
	windowMoved="windowMoved",
	windowNotInCurrentSpace="windowNotInCurrentSpace",
	windowNotOnScreen="windowNotOnScreen",
	windowNotVisible="windowNotVisible",
	windowOnScreen="windowOnScreen",
	windowUnfullscreened="windowUnfullscreened",
	windowUnhidden="windowUnhidden",
	windowUnminimized="windowUnminimized",
	windowVisible="windowVisible",
}

return module
