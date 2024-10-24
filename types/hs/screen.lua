---@meta "hs.screen"

---@class Screen
local Screen = {}

---@return integer
function Screen:id() end

---@return Geometry
function Screen:frame() end

---@return Geometry
function Screen:fullFrame() end

---@module "hs.screen.watcher"
local watcher

---@class hs.screen
local module = {
    watcher=watcher,
}

---@return Screen
function module.primaryScreen() end

---@return Screen
function module.mainScreen() end

return module
