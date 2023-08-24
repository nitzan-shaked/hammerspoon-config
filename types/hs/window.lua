---@meta "hs.window"

---@class Window
local Window = {}

---@return integer
function Window:id() end

---@return Application
function Window:application() end

---@return Screen
function Window:screen() end

---@return string
function Window:title() end

---@return string
function Window:role() end

---@return string
function Window:subrole() end

---@return boolean
function Window:isStandard() end

---@return boolean
function Window:isVisible() end

---@return Geometry
function Window:frame() end

---@param frame Rect | Geometry
function Window:setFrame(frame) end

---@return Geometry
function Window:size() end

---@param size Size | Geometry
---@return nil
function Window:setSize(size) end

---@return Geometry
function Window:topLeft(p) end

---@param p Point | Geometry
function Window:setTopLeft(p) end

function Window:raise() end

function Window:focus() end

---@module "hs.window.filter"
local filter

---@class hs.window
---@operator call(integer):Window
---@field animationDuration number
local module = {
    filter=filter,
}

---@return integer[]
function module._orderedwinids() end

---@return Window
function module.desktop() end

---@return Window
function module.focusedWindow() end

---@param win_id integer | Window
---@param include_alpha boolean?
function module.snapshotForID(win_id, include_alpha) end

---@return Window[]
function module.allWindows() end

---@return Window[]
function module.visibleWindows() end

return module
