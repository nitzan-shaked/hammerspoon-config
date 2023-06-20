print("testing Vector2")

local Vector2 = require("vector2")

local x_axis = Vector2:x_axis()
assert(x_axis[1] == 1)
assert(x_axis[2] == 0)

local y_axis = Vector2:y_axis()
assert(y_axis[1] == 0)
assert(y_axis[2] == 1)
