print("testing Size")

local Size = require("geom.size")

local function test_init()
    local s = Size(1, 2)
    assert(s.w == 1)
    assert(s.h == 2)
end

local function test_eq_neq()
    assert(Size(1, 2) == Size(1, 2))
    assert(Size(1, 2) ~= Size(1, 3))
    assert(Size(1, 2) ~= Size(3, 2))
end

local function test_add_sub_unm()
    assert(Size(1, 2) + Size(3, 5) == Size(4, 7))
    assert(Size(1, 2) - Size(3, 5) == Size(-2, -3))
end

local function test_mul()
    assert(Size(1, 2) * 2 == Size(2, 4))
    assert(2 * Size(1, 2) == Size(2, 4))
end

test_init()
test_eq_neq()
test_add_sub_unm()
test_mul()
