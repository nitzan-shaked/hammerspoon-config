print("testing Point")

local Point = require("point")

local origin = Point(0, 0)
assert(origin.x == 0)
assert(origin.y == 0)

local cls_keys = {}
local n_cls_keys = 0
for k, _ in pairs(origin) do
    cls_keys[k] = true
    n_cls_keys = n_cls_keys + 1
end
assert(n_cls_keys == 2)
assert(cls_keys["x"])
assert(cls_keys["y"])

local p1 = Point(1, 2)
assert(p1.x == 1)
assert(p1.y == 2)

local p2 = Point(3, 5)
assert(p2.x == 3)
assert(p2.y == 5)

local p_add = p1 + p2
assert(p_add.x == 4)
assert(p_add.y == 7)

assert(p_add == Point(4, 7))
assert(p_add ~= p1)
assert(p_add ~= p2)

local p_sub = p2 - p1
assert(p_sub.x == 2)
assert(p_sub.y == 3)

local p_mul = p1 * 5
assert(p_mul.x ==  5)
assert(p_mul.y == 10)

local p_mul_2 = 2 * p1
assert(p_mul_2.x == 2)
assert(p_mul_2.y == 4)

local p_unm = -p1
assert(p_unm.x == -1)
assert(p_unm.y == -2)
