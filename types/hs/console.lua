---@meta "hs.console"

---@alias Font string | {name: string, size: integer}

---@class hs.console
local module = {}

function module.clearConsole() end

---@return integer
function module.level() end

---@param level integer
---@return nil
function module.level(level) end

---@return number
function module.alpha() end

---@param alpha number
---@return nil
function module.alpha(alpha) end

---@return Window
function module.hswindow() end

---@return any
function module.toolbar() end

---@param toolbar any
---@return nil
function module.toolbar(toolbar) end

---@return Font
function module.consoleFont() end

---@param font Font
---@return nil
function module.consoleFont(font) end

return module
