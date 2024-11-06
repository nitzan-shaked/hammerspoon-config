print("testing tiling")

local Point = require("geom.point")
local Rect = require("geom.rect")
local Size = require("geom.size")

local size_hint = require("tiling.size_hint")
local SizeHint = size_hint.SizeHint
local SizeHintAbsolute = size_hint.SizeHintAbsolute
local SizeHintRatio = size_hint.SizeHintRatio

local Container = require("tiling.container")

---@param c Container
---@param prefix string?
local function print_container(c, prefix)
	prefix = prefix or ""
	print(prefix .. tostring(c.rect.size) .. " " .. c.split_mode)
	for _, sub_c in pairs(c.children) do
		print_container(sub_c.container, prefix .. "    ")
	end
end

local main = Container(nil, Container.SplitMode.LONG_SIDE)
main:set_rect(Rect(Point(0, 0), Size(1000, 1000)))

local left = main:add_child(SizeHintRatio(0.5))
left:add_child(SizeHintAbsolute(10))
left:add_child(SizeHintAbsolute(20))

local middle = main:add_child(SizeHint())
middle:add_child(SizeHintAbsolute(20))
middle:add_child(SizeHint())
middle:add_child(SizeHint())

local right = main:add_child(SizeHint())
right:add_child(SizeHint())
right:add_child(SizeHint())
right:add_child(SizeHint())

print_container(main)
