print("testing Vector2")

local Vector2 = require("vector2")

local x_axis = Vector2:x_axis()
assert(x_axis.x == 1)
assert(x_axis.y == 0)

local y_axis = Vector2:y_axis()
assert(y_axis.x == 0)
assert(y_axis.y == 1)
