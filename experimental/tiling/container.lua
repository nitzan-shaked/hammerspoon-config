local SplitMode = require("tiling.split_mode")
local SizeHint = require("tiling.size_hint")

local Point = require("geom.point")
local Rect = require("geom.rect")
local Size = require("geom.size")

local class = require("utils.class")

--[[ CONFIG ]]

local GAP = 15

local RESIZER_THICKNESS = 7
local RESIZER_COLOR = {red=0, green=1, blue=1, alpha=1}
local RESIZER_HOVER_COLOR = {red=1, green=0, blue=0, alpha=1}

--[[ STATE ]]

local show_resizers = false

--[[ LOGIC ]]

---@class ContainerResizer: Class
---@operator call: ContainerResizer
---@field container Container
---@field i_resizer integer
---@field pos integer
local ContainerResizer = class("ContainerResizer")

function ContainerResizer:__init(container, i_resizer)
	self._container = container
	self._i_resizer = i_resizer

	self._canvas = hs.canvas.new({})
	self._canvas:appendElements({
		id="rectangle",
		type="rectangle",
		action="fill",
		fillColor=RESIZER_COLOR,
	})
	self._canvas:size(self._container._resizer_size)
	self._canvas:canvasMouseEvents(true, true, true, false)
	self._canvas:mouseCallback(function(...) self:canvas_mouse_callback(...) end)

	self._is_dragging = false
	self._drag_refresh_timer = hs.timer.new(0.025, function () self:refresh_drag() end)
	self._drag_refresh_last_dmouse = 0
	self._drag_initial_mouse_value = 0
	self._drag_initial_middle_of_resizer = 0
end

function ContainerResizer:delete()
	self:hide()
end

function ContainerResizer:show()
	self._canvas:show()
end

function ContainerResizer:hide()
	self._canvas:hide()
end

function ContainerResizer:highlight()
	self._canvas["rectangle"].fillColor = RESIZER_HOVER_COLOR
end

function ContainerResizer:unhighlight()
	self._canvas["rectangle"].fillColor = RESIZER_COLOR
end

---@param value integer
function ContainerResizer:set_middle_at(value)
	local p = self._container:_point_at(value - RESIZER_THICKNESS / 2)
	self._canvas:topLeft(p)
end

---@param s Size
function ContainerResizer:set_size(s)
	self._canvas:size(s)
end

---@param ev_canvas Canvas
---@param ev_type string
---@param elem_id integer | string
---@param x number
---@param y number
function ContainerResizer:canvas_mouse_callback(ev_canvas, ev_type, elem_id, x, y)
	if ev_type == "mouseEnter" then
		if self._is_dragging then return end
		self:highlight()
	elseif ev_type == "mouseExit" then
		if self._is_dragging then return end
		self:unhighlight()
	elseif ev_type == "mouseDown" then
		if self._is_dragging then return end
		self:start_drag()
	elseif ev_type == "mouseUp" then
		if not self._is_dragging then return end
		self:stop_drag()
	end
end

function ContainerResizer:start_drag()
	assert(not self._is_dragging)
	self._drag_initial_middle_of_resizer = self._container:_middle_of_resizer(self._i_resizer)
	self._drag_initial_mouse_value = hs.mouse.absolutePosition()[self._container._split_axis_name]
	self:highlight()
	self._is_dragging = true
	self._drag_refresh_timer:start()
end

function ContainerResizer:stop_drag()
	assert(self._is_dragging)
	self._drag_refresh_timer:stop()
	self._is_dragging = false
	self:unhighlight()
end

function ContainerResizer:refresh_drag()
	local curr_mouse_value = hs.mouse.absolutePosition()[self._container._split_axis_name]
	local d_mouse = curr_mouse_value - self._drag_initial_mouse_value
	if d_mouse == self._drag_refresh_last_dmouse then
		return
	end
	local new_middle_of_resizer = self._drag_initial_middle_of_resizer + d_mouse
	self._container:place_resizer_at(self._i_resizer, new_middle_of_resizer)
	self._drag_refresh_last_dmouse = d_mouse
end

---@class Container: Class
---@operator call: Container
---@field parent Container?
---@field rect Rect
---@field window Window?
---@field split_mode SplitMode
---@field children Container[]
local Container = class("Container", {
	props={"parent", "rect", "window", "split_mode", "children"},
})
---@type table<integer, Container>
Container._win_id_to_container = {}

function Container:__init()
	self._parent = nil
	self._rect = Rect(Point(0, 0), Size(0, 0))
	self._window = nil
	self._split_mode = SplitMode.LONG_SIDE
	---@type SizeHint[]
	self._children_size_hints = {}
	---@type Container[]
	self._children = {}
	---@type table<Container, integer>
	self._children_pos = {}
	---@type table<Container, integer>
	self._children_lengths = {}
	---@type ContainerResizer[]
	self._resizers = {}
	self:_resolve_split_mode()
end

function Container:delete()
	assert(#self._children == 0)
	if self._parent then
		self._parent:remove_child(self)
	end
	self:set_window(nil)
	for _, resizer in ipairs(self._resizers) do
		resizer:delete()
	end
	self._resizers = {}
end

---@return Container?
function Container:get_parent() return self._parent end

---@return Rect
function Container:get_rect() return self._rect end

---@return Window
function Container:get_window() return self._window end

---@return SplitMode
function Container:get_split_mode() return self._split_mode end

---@return Container[]
function Container:get_children() return self._children end

---@param rect Rect
function Container:set_rect(rect)
	self._rect = rect
	self:_resolve_split_mode()
	if self._window then
		self._window:setFrame(self._rect)
	else
		self:_recalc()
	end
end

---@param w Window?
function Container:set_window(w)
	assert(#self._children == 0)
	local curr_w = self._window
	if (
		(curr_w == nil and w == nil) or
		(curr_w ~= nil and w ~= nil and curr_w:id() == w:id())
	) then
		return
	end
	if curr_w then
		Container._win_id_to_container[curr_w:id()] = nil
		self._window = nil
	end
	if w then
		Container._win_id_to_container[w:id()] = self
		self._window = w
		self._window:setFrame(self._rect)
	end
end

function Container:reverse_children()
	local n_children = #self._children
	local new_size_hints = {}
	local new_children = {}
	for i = n_children, 1, -1 do
		table.insert(new_size_hints, self._children_size_hints[i])
		table.insert(new_children, self._children[i])
	end
	self._children_size_hints = new_size_hints
	self._children = new_children
	self:_recalc()
end

function Container:reverse_split_mode()
	self._split_mode = SplitMode.opposite[self._split_mode]
	self:_resolve_split_mode()
	self:_recalc()
end

---@param w Window
---@return boolean
function Container:has_window(w)
	local c = Container.of(w)
	while true do
		if c == nil then return false end
		if c == self then return true end
		c = c.parent
	end
end

---@param child_to_add Container
---@param size_hint SizeHint
function Container:add_child(child_to_add, size_hint)
	assert(not self._window)
	assert(child_to_add._parent == nil)
	table.insert(self._children_size_hints, size_hint)
	table.insert(self._children, child_to_add)
	table.insert(self._children_pos, 0)
	table.insert(self._children_lengths, 0)
	---@type ContainerResizer?
	local newly_added_resizer = nil
	if #self._children > 0 then
		local i_resizer = #self._resizers + 1
		newly_added_resizer = ContainerResizer(self, i_resizer)
		table.insert(self._resizers, newly_added_resizer)
	end
	child_to_add._parent = self
	self:_recalc()
	if newly_added_resizer and show_resizers then
		newly_added_resizer:show()
	end
end

---@param child_to_remove Container
function Container:remove_child(child_to_remove)
	for i, child in ipairs(self._children) do
		if child == child_to_remove then
			table.remove(self._children_size_hints, i)
			table.remove(self._children, i)
			table.remove(self._children_pos, i)
			table.remove(self._children_lengths, i)
			if #self._resizers > 0 then
				local resizer = table.remove(self._resizers)
				resizer:delete()
			end
			child_to_remove._parent = nil
			if #self._children == 0 then
				if self.parent then
					self:delete()
				end
			else
				self:_recalc()
			end
			return
		end
	end
	error("child not found")
end

---@param child_to_remove Container
---@param child_to_add Container
function Container:replace_child(child_to_remove, child_to_add)
	for i, child in ipairs(self._children) do
		if child == child_to_remove then
			self._children[i] = child_to_add
			child_to_remove._parent = nil
			child_to_add._parent = self
			child_to_add:set_rect(child_to_remove._rect)
			return
		end
	end
	error("child not found")
end

function Container:wrap_window()
	local w = self._window
	if w == nil then
		return
	end
	self._window = nil
	local new_child = Container()
	new_child._parent = self
	new_child._rect = self._rect
	new_child._window = w
	table.insert(self._children_size_hints, SizeHint(1))
	table.insert(self._children, new_child)
	table.insert(self._children_pos, 0)
	table.insert(self._children_lengths, self._rect[self._size_axis_name])
	Container._win_id_to_container[w:id()] = new_child
end

function Container:unwrap()
	while #self._children == 1 do
		local child = self._children[1]
		local child_w = child._window
		self._window = child_w
		if child_w then
			Container._win_id_to_container[child_w:id()] = self
		end
		self._split_mode = child._split_mode
		self._children_size_hints = child._children_size_hints
		self._children = child._children
		for _, adopted_child in ipairs(self._children) do
			adopted_child._parent = self
		end
		self._children_pos = child._children_pos
		self._children_lengths = child._children_lengths
		self._resizers = child._resizers
		for _, adopted_resizer in ipairs(self._resizers) do
			adopted_resizer._container = self
		end
		child._parent = nil
		child._window = nil
		child._children = {}
		child._resizers = {}
		child:delete()
		self:_resolve_split_mode()
	end
end

---@param win_id Window | integer
---@return Container?
function Container.of(win_id)
	if type(win_id) ~= "number" then
		---@cast win_id Window
		if not win_id.id then
			return nil
		end
		win_id = win_id:id()
	end
	return Container._win_id_to_container[win_id]
end

---@param show boolean
---@return Container?
function Container:show_resizers(show)
	show_resizers = show
	for _, resizer in ipairs(self._resizers) do
		if show then resizer:show() else resizer:hide() end
	end
	for _, child in ipairs(self._children) do
		child:show_resizers(show)
	end
end

---@param i_child integer
---@return number
function Container:_left_of_child(i_child)
	return self._children_pos[i_child]
end

---@param i_child integer
---@return number
function Container:_right_of_child(i_child)
	return self._children_pos[i_child] + self._children_lengths[i_child]
end

---@param i_resizer integer
---@return number
function Container:_middle_of_resizer(i_resizer)
	return self:_right_of_child(i_resizer) + GAP / 2
end

---@param i_resizer integer
---@param middle_of_resizer number
function Container:place_resizer_at(i_resizer, middle_of_resizer)
	local i_left_child  = i_resizer
	local i_right_child = i_resizer + 1

	local left_of_left_child   = self:_left_of_child(i_left_child)
	local right_of_right_child = self:_right_of_child(i_right_child)

	local left_child_min_len  = self._children_size_hints[i_left_child].min_len
	local right_child_min_len = self._children_size_hints[i_right_child].min_len

	local left_of_resizer  = middle_of_resizer - RESIZER_THICKNESS / 2
	local right_of_resizer = middle_of_resizer + RESIZER_THICKNESS / 2

	local new_left_child_len  = left_of_resizer - left_of_left_child
	local new_right_child_len = right_of_right_child - right_of_resizer

	if new_left_child_len  < left_child_min_len  then return end
	if new_right_child_len < right_child_min_len then return end

	local n_children = #self._children
	local total_supply = self._rect[self._size_axis_name] - GAP * (n_children - 1)
	self._children_size_hints[i_left_child]  = SizeHint(new_left_child_len  / total_supply, left_child_min_len)
	self._children_size_hints[i_right_child] = SizeHint(new_right_child_len / total_supply, right_child_min_len)
	self:_recalc()
end

---@param value integer
---@return Point
function Container:_point_at(value)
	local p = Point(self._rect.top_left)
	p[self._split_axis_name] = p[self._split_axis_name] + value
	return p
end

---@param value integer
---@return Size
function Container:_size_of(value)
	local s = Size(self._rect.size)
	s[self._size_axis_name] = value
	return s
end

function Container:_resolve_split_mode()
	local split_mode = self._split_mode
	local rect = self._rect
	if split_mode == SplitMode.LONG_SIDE then
		split_mode = rect.w >= rect.h and SplitMode.HORIZ or SplitMode.VERT
	elseif split_mode == SplitMode.SHORT_SIDE then
		split_mode = rect.w <= rect.h and SplitMode.HORIZ or SplitMode.VERT
	end
	self._split_axis_number = split_mode == SplitMode.HORIZ and 1 or 2
	self._split_axis_name = Point:axis_name(self._split_axis_number)
	self._size_axis_name = Size:axis_name(self._split_axis_number)
	self._resizer_size = Size(rect.size)
	self._resizer_size[self._size_axis_name] = RESIZER_THICKNESS
	for _, resizer in ipairs(self._resizers) do
		resizer:set_size(self._resizer_size)
	end
end

function Container:_recalc()
	local n_children = #self._children
	if n_children == 0 then
		return
	end

	self:_recalc_children_pos_and_length()

	for i, child in ipairs(self._children) do
		local curr_pos = self._children_pos[i]
		local curr_len = self._children_lengths[i]
		child:set_rect(Rect(self:_point_at(curr_pos), self:_size_of(curr_len)))
		if i < n_children then
			self._resizers[i]:set_middle_at(curr_pos + curr_len + GAP / 2)
		end
	end
end

function Container:_recalc_children_pos_and_length()
	local n_children = #self._children
	if n_children == 0 then
		return {}
	end

	local total_supply = self._rect[self._size_axis_name] - GAP * (n_children - 1)

	---@type number[]
	local min_lengths = {}
	---@type number[]
	local req_lengths = {}

	local total_min_demand = 0
	local total_demand = 0

	for i, size_hint in ipairs(self._children_size_hints) do
		local min_len = size_hint.min_len
		local req_len = math.max(size_hint.fraction * total_supply, min_len)

		min_lengths[i] = min_len
		req_lengths[i] = req_len

		total_min_demand = total_min_demand + min_len
		total_demand = total_demand + req_len
	end

	local not_enough_for_min = total_min_demand > total_supply
	local arr = not_enough_for_min and min_lengths or req_lengths
	local k = total_supply / (not_enough_for_min and total_min_demand or total_demand)

	local curr_pos = 0
	for i = 1, n_children do
		local curr_len = math.floor(arr[i] * k)
		self._children_pos[i] = curr_pos
		self._children_lengths[i] = curr_len
		curr_pos = curr_pos + curr_len + GAP
	end
end

---@param screen Screen
---@return Container
function Container:for_screen(screen)
	local container = Container()
	container:set_rect(Rect(screen:frame()))
	return container
end

--[[ MODULE ]]

return Container
