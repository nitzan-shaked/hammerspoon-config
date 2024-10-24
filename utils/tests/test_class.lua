print("testing class")

local class = require("utils.class")
local Object = class.Object

local function n_keys(t)
    local result = 0
    for _, _ in pairs(t) do result = result + 1 end
    return result
end

local function test_object()
    assert(Object.__name__ == "Object")
    assert(Object.__base__ == nil)
    assert(n_keys(Object.__prop__) == 0)
    assert(tostring(Object) == "<class 'Object'>")
    assert(class.is_subclass(Object, Object))

    local inst = Object()
    assert(inst.__cls__ == Object)
    assert(class.is_instance(inst, Object))
    assert(tostring(inst) == "Object instance")
end

local function test_basic_functionality()
    ---@class C1 : Class
    local C1 = class.make_class("C1")
    function C1:foo() return "C1:foo" end

    ---@class C2 : C1
    local C2 = class.make_class("C2", C1)
    function C2:__init__(x) self.x = x end

    ---@class C3 : C2
    local C3 = class.make_class("C3", C2)
    function C3:foo() return "C3:foo" end

    ---@class C4 : C2
    local C4 = class.make_class("C4", C3)
    function C4:__init__(x, y)
        C3.__init__(self, x * 2)
        self.y = y
    end

    assert(C1.__name__ == "C1")
    assert(C1.__base__ == Object)
    assert(n_keys(C1.__prop__) == 0)
    assert(tostring(C1) == "<class 'C1'>")
    assert(class.is_subclass(C1, Object))
    assert(class.is_subclass(C1, C1))
    assert(not class.is_subclass(Object, C1))

    assert(C2.__name__ == "C2")
    assert(C2.__base__ == C1)
    assert(n_keys(C2.__prop__) == 0)
    assert(tostring(C2) == "<class 'C2'>")
    assert(class.is_subclass(C2, Object))
    assert(class.is_subclass(C2, C1))
    assert(class.is_subclass(C2, C2))
    assert(not class.is_subclass(Object, C2))
    assert(not class.is_subclass(C1, C2))

    assert(C3.__name__ == "C3")
    assert(C3.__base__ == C2)
    assert(n_keys(C3.__prop__) == 0)
    assert(tostring(C3) == "<class 'C3'>")
    assert(class.is_subclass(C3, Object))
    assert(class.is_subclass(C3, C1))
    assert(class.is_subclass(C3, C2))
    assert(class.is_subclass(C3, C3))
    assert(not class.is_subclass(Object, C3))
    assert(not class.is_subclass(C1, C3))
    assert(not class.is_subclass(C2, C3))

    assert(C4.__name__ == "C4")
    assert(C4.__base__ == C3)
    assert(n_keys(C4.__prop__) == 0)
    assert(tostring(C4) == "<class 'C4'>")
    assert(class.is_subclass(C4, Object))
    assert(class.is_subclass(C4, C1))
    assert(class.is_subclass(C4, C2))
    assert(class.is_subclass(C4, C3))
    assert(class.is_subclass(C4, C4))
    assert(not class.is_subclass(Object, C4))
    assert(not class.is_subclass(C1, C4))
    assert(not class.is_subclass(C2, C4))
    assert(not class.is_subclass(C3, C4))

    local c1 = C1()
    local c2 = C2(5)
    local c3 = C3(5)
    local c4 = C4(5, 6)

    assert(c1.__cls__ == C1)
    assert(tostring(c1) == "C1 instance")
    assert(class.is_instance(c1, Object))
    assert(class.is_instance(c1, C1))

    assert(c2.__cls__ == C2)
    assert(tostring(c2) == "C2 instance")
    assert(class.is_instance(c2, Object))
    assert(class.is_instance(c2, C1))
    assert(class.is_instance(c2, C2))

    assert(c3.__cls__ == C3)
    assert(tostring(c3) == "C3 instance")
    assert(class.is_instance(c3, Object))
    assert(class.is_instance(c3, C1))
    assert(class.is_instance(c3, C2))
    assert(class.is_instance(c3, C3))

    assert(c4.__cls__ == C4)
    assert(tostring(c4) == "C4 instance")
    assert(class.is_instance(c4, Object))
    assert(class.is_instance(c4, C1))
    assert(class.is_instance(c4, C2))
    assert(class.is_instance(c4, C3))
    assert(class.is_instance(c4, C4))

    assert(c2.x == 5)
    assert(c3.x == 5)
    assert(c4.x == 10)
    assert(c4.y == 6)

    assert(c1:foo() == "C1:foo")
    assert(c2:foo() == "C1:foo")
    assert(c3:foo() == "C3:foo")
    assert(c4:foo() == "C3:foo")
end

local function test_properties()
    ---@class C1 : Class
    local C1 = class.make_class("C1")

    ---@class C2 : C1
    local C2 = class.make_class("C2", C1, {"x", "y"})
    function C2:get_x() return "C2.x" end
    function C2:get_y() return "C2.y" end

    ---@class C3 : C2
    local C3 = class.make_class("C3", C2)

    ---@class C4 : C3
    local C4 = class.make_class("C4", C3, {"z"})
    function C4:get_x() return "C4.x" end
    function C4:get_z() return "C4.z" end

    assert(n_keys(C1.__prop__) == 0)
    assert(n_keys(C2.__prop__) == 2)
    assert(n_keys(C3.__prop__) == 0)
    assert(n_keys(C4.__prop__) == 1)

    local c1 = C1()
    local c2 = C2()
    local c3 = C3()
    local c4 = C4()

    assert(c2.x == "C2.x")
    assert(c2.y == "C2.y")

    assert(c3.x == "C2.x")
    assert(c3.y == "C2.y")

    assert(c4.x == "C4.x")
    assert(c4.y == "C2.y")
    assert(c4.z == "C4.z")
end

local function test_meta_methods()
    ---@class A : Class
    local A = class.make_class("A")
    function A:__init__(x) self.x = x end
    function A:__eq(other) return self.x == other.x end
    function A:__add(other) return self.__cls__(self.x + other.x) end

    ---@class B : A
    local B = class.make_class("B", A)
    function B:__eq(other) return math.abs(self.x - other.x) <= 1 end

    local a1 = A(5)
    local a2 = A(6)
    assert(a1 + a2 == A(11))
    assert(a1 + a2 ~= A(12))

    local b1 = B(5)
    local b2 = B(6)
    assert(b1 + b2 == B(11))
    assert(b1 + b2 == B(12))
    assert(b1 + b2 ~= B(13))
end

test_object()
test_basic_functionality()
test_properties()
test_meta_methods()
