---@meta "hs.styledtext"

---@class StyledText
local StyledText = {}

---@return StyledText
---@param s string
---@param attrs table<string, any>
function StyledText.new(s, attrs) end

---@class hs.styledtext
local module = {
    new=StyledText.new,
}

return module
