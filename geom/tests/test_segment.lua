print("testing Segment")

local Segment = require("geom.segment")

local s1 = Segment(100, 20)
assert(s1.x == 100)
assert(s1.w == 20)
assert(s1.x1 == 100)
assert(s1.x2 == 120)

local s2 = Segment(100, 20)
assert(s1 == s2)

local s3 = Segment(100, 40)
assert(s1 ~= s3)
