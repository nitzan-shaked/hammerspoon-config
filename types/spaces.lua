---@meta "hs.spaces"

---@module "hs.spaces.watcher"
local watcher

---@class hs.spaces
local module = {
    watcher=watcher,
}

---@param screen Screen
---@return integer
function module.activeSpaceOnScreen(screen) end

return module
