local class = require("utils.class")
local nu = require("utils.number_utils")


local _NS_PER_SEC = 1000000000

local function _get_timestamp()
	return hs.timer.absoluteTime() / _NS_PER_SEC
end


-- "s": in [0, 1] where 0 is the start of the animation and 1 is the end
---@alias FrameFunc fun(s: number)


---@class Animation: Class
---@operator call: Animation
local Animation = class.make_class("Animation")


---@param duration number
---@param frame_func FrameFunc
---@param end_func fun()?
---@param frame_rate number?
function Animation:__init__(duration, frame_func, end_func, frame_rate)
	self._duration = duration
	self._frame_func = frame_func
	self._end_func = end_func
	self._frame_rate = frame_rate or 60
	assert(self._frame_rate > 0, "frame_rate must be positive")
	self._frame_duration = 1 / self._frame_rate

	self._i_frame = 0
	self._paused = true
	self._finished = false
	self._timer = nil
end

function Animation:start()
	assert(not self._finished, "Animation already finished")
	assert(self._paused, "Animation already started")
	self._t0 = _get_timestamp()
	self._t1 = self._t0 + self._duration
	self._i_frame = 0
	self._paused = false
	self._timer = hs.timer.doAfter(0, function() self:_step() end)
end


function Animation:_step()
	if self._paused then return end

	local s = nu.cap_above((_get_timestamp() - self._t0) / self._duration, 1)
	self._frame_func(s)

	if s == 1.0 then
		if self._end_func then
			self._end_func()
		end
		self._finished = true
		self._paused = true
		return
	end

	self._i_frame = self._i_frame + 1
	local next_timestamp = self._t0 + self._i_frame * self._frame_duration
	local delay = nu.cap_below(next_timestamp - _get_timestamp(), 0)
	self._timer = hs.timer.doAfter(delay, function() self:_step() end)
end


function Animation:stop()
	self._paused = true
	if self._timer then
		self._timer:stop()
		self._timer = nil
	end
end


return {
	Animation=Animation,
}
