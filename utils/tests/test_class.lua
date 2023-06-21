print("testing class")

local class = require("utils.class")

local Object = class.Object
assert(Object.__name__ == "Object")
assert(getmetatable(Object).__tostring() == "class Object")
assert(class.is_subclass(Object, Object))

local MyClass = class("MyClass")
function MyClass:__init(x)
    self.x = x
end
assert(MyClass.__name__ == "MyClass")
assert(getmetatable(MyClass).__tostring() == "class MyClass")
assert(not class.is_subclass(Object, MyClass))
assert(class.is_subclass(MyClass, Object))
assert(class.is_subclass(MyClass, MyClass))

local object = Object()
assert(not class.is_instance(object, MyClass))

local my_instance = MyClass(5)
assert(my_instance.__cls__ == MyClass)
assert(my_instance.x == 5)
assert(class.is_instance(my_instance, MyClass))
assert(class.is_instance(my_instance, Object))

local MyClass_Derived = class("MyClass_Derived", {base_cls=MyClass})
function MyClass_Derived:__init(x, y)
    MyClass.__init(self, x)
    self.y = y
end

local d = MyClass_Derived(6, 7)
assert(d.x == 6)
assert(d.y == 7)

local Point = class("Point")

function Point:__init(x, y)
    self.x = x
    self.y = y
end

function Point:__add(other)
    return self.__cls__(self.x + other.x, self.y + other.y)
end

function Point:foo()
    return "Point:foo"
end

local p1 = Point(1, 2)
local p2 = Point(3, 4)
local p3 = p1 + p2
assert(p3.x == 4)
assert(p3.y == 6)
assert(p3:foo() == "Point:foo")

local Size = class("Size", {base_cls=Point})
local s1 = Size(10, 20)
local s2 = Size(30, 40)
local s3 = s1 + s2
assert(s3.x == 40)
assert(s3.y == 60)
assert(s3:foo() == "Point:foo")

local SpecialSize = class("SpecialSize", {base_cls=Size})
function SpecialSize:__add(other)
    return self.__cls__(31415, 271)
end
function SpecialSize:foo()
    return "SpecialSize:foo"
end

local ss_1 = SpecialSize(1, 2)
local ss_2 = SpecialSize(3, 4)
local ss_3 = ss_1 + ss_2
assert(ss_3.x == 31415)
assert(ss_3.y == 271)
assert(ss_3:foo() == "SpecialSize:foo")

assert(class.is_subclass(SpecialSize, Object))
assert(class.is_subclass(SpecialSize, Point))
assert(class.is_subclass(SpecialSize, Size))
assert(class.is_subclass(SpecialSize, SpecialSize))
assert(not class.is_subclass(SpecialSize, MyClass))
assert(not class.is_subclass(MyClass, SpecialSize))

assert(class.is_instance(ss_3, Object))
assert(class.is_instance(ss_3, Point))
assert(class.is_instance(ss_3, Size))
assert(class.is_instance(ss_3, SpecialSize))
assert(not class.is_instance(ss_3, MyClass))
