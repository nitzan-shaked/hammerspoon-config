---@meta "hs.audiodevice.watcher"

---@class Watcher
local Watcher = {}

---@param fn fun(...): any
---@return nil
function Watcher.setCallback(fn) end
---@return nil
function Watcher.start() end
---@return Watcher
function Watcher.stop() end

---@class hs.caffeinate.watcher
local module = {
    setCallback=Watcher.setCallback,
    start=Watcher.start,
    stop=Watcher.stop,
}

return module
