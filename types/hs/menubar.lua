---@meta "hs.menubar"

---@class MenuBar
local MenuBar = {}

---@return MenuBar
---@param in_menu_bar boolean
---@param name string
function MenuBar.new(in_menu_bar, name) end

---@return MenuBar
---@param title string  | StyledText
function MenuBar:setTitle(title) end

---@class hs.menubar
local module = {
    new=MenuBar.new,
}

return module
