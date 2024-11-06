---@meta "hs.menubar"

---@class MenuBar
local MenuBar = {}

---@return MenuBar
---@param in_menu_bar boolean
---@param name string
function MenuBar.new(in_menu_bar, name) end

function MenuBar:delete() end

---@return MenuBar
---@param title string | StyledText
function MenuBar:setTitle(title) end

---@param tooltip string
function MenuBar:setTooltip(tooltip) end

---@param icon string
function MenuBar:setIcon(icon) end

---@param menu table | function
function MenuBar:setMenu(menu) end

---@return nil
function MenuBar:removeFromMenuBar() end

---@return nil
function MenuBar:returnToMenuBar() end

---@return Geometry
function MenuBar:frame() end

---@param fn fun(...): any
---@return nil
function MenuBar:setClickCallback(fn) end

---@class hs.menubar
local module = {
    new=MenuBar.new,
}

return module
