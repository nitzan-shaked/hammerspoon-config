print("testing Rect")

local Point = require("point")
local Size = require("size")
local Segment = require("segment")
local Rect = require("rect")

local r = Rect(Point(10, 20), Size(30, 40))
assert(r.x == 10)
assert(r.y == 20)
assert(r.w == 30)
assert(r.h == 40)
assert(r.x1 == 10)
assert(r.y1 == 20)
assert(r.x2 == 40)
assert(r.y2 == 60)
assert(r.topLeft == Point(10, 20))
assert(r.size == Size(30, 40))
assert(r.bottomRight == Point(40, 60))

assert(r == Rect(Point(10, 20), Size(30, 40)))
assert(r ~= Rect(Point(10, 22), Size(30, 40)))
assert(r ~= Rect(Point(10, 20), Size(30, 42)))

assert(r.h_segment == Segment(10, 30))
assert(r.v_segment == Segment(20, 40))

assert(r:contains(Point(15, 25)))
assert(r:contains(Rect(Point(15, 25), Size(2, 2))))

assert(not r:contains(Rect(Point(55, 55), Size(2, 2))))
assert(not r:contains(Rect(Point(15, 25), Size(50, 2))))
assert(not r:contains(Rect(Point(15, 25), Size(2, 50))))

assert(r + Point(10, 20) == Rect(Point(20, 40), Size(30, 40)))
