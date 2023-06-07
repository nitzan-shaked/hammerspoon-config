---@meta "hs.canvas"

---@alias CanvasElement table<string, any>

---@class Canvas
local Canvas = {}

---@param obj table<string, any>
---@return Canvas
function Canvas.new(obj) end

---@param level integer
---@return nil
---@overload fun(): integer
function Canvas:level(level) end

---@param frame Geometry
---@return nil
---@overload fun(): Geometry
function Canvas:frame(frame) end

---@param p Geometry
---@return nil
---@overload fun(): Geometry
function Canvas:topLeft(p) end

---@param size Geometry
---@return nil
---@overload fun(): Geometry
function Canvas:size(size) end

---@param subrole string
---@return nil
---@overload fun(): string?
function Canvas:_accessibilitySubrole(subrole) end

---@param elements CanvasElement[]
function Canvas:appendElements(elements) end

---@param element CanvasElement
---@param index number?
function Canvas:assignElement(element, index) end

---@param alpha number
---@return nil
---@overload fun(): number
function Canvas:alpha(alpha) end

function Canvas:hide() end

function Canvas:show() end

function Canvas:delete() end

---@param callback function()
function Canvas:mouseCallback(callback) end

---@class hs.canvas
---@field windowLevels table<string, integer>
local module = {
    new=Canvas.new,
}

return module
