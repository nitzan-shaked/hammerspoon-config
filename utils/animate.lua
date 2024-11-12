local class = require("utils.class")


local _NS_PER_SEC = 1000000000

--[[ LOGIC ]]

-- "s": in [0, 1] where 0 is the start of the animation and 1 is the end
---@alias AnimStepFunc fun(s: number)


---@class Animation: Class
---@operator call: Animation
local Animation = class.make_class("Animation")


---@param duration number
---@param frame_func AnimStepFunc
---@param end_func fun()?
---@param frame_rate number?
function Animation:__init__(duration, frame_func, end_func, frame_rate)
	self._duration = duration
	self._frame_func = frame_func
	self._end_func = end_func
	self._frame_rate = frame_rate or 60
	self._frame_duration = 1 / self._frame_rate

	self._i_frame = 0
	self._paused = true
	self._finished = false
	self._timer = nil
end

function Animation:start()
	assert(not self._finished, "Animation already finished")
	assert(self._paused, "Animation already started")
	self._t0 = hs.timer.absoluteTime() / _NS_PER_SEC
	self._t1 = self._t0 + self._duration
	self._i_frame = 0
	self._paused = false
	self._timer = hs.timer.doAfter(0, function() self:_step() end)
end


function Animation:_step()
	if self._paused then return end

	local curr_timestamp = hs.timer.absoluteTime() / _NS_PER_SEC
	local s = (curr_timestamp - self._t0) / self._duration
	s = s <= 1 and s or 1

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
	local delay = next_timestamp - curr_timestamp
	delay = delay >= 0 and delay or 0
	self._timer = hs.timer.doAfter(delay, function() self:_step() end)
end


function Animation:stop()
	self._paused = true
	if self._timer then
		self._timer:stop()
		self._timer = nil
	end
end


--=============================================================================

---@alias AnimData table<string, any[]>
---@alias AnimStepData table<string, any>
---@alias OldAnimStepFunc fun(step_data: AnimStepData, i_step: number)

---@param anim_data AnimData
---@param duration number
---@param step_func OldAnimStepFunc
---@param done_func fun()?
---@param frame_rate number?
local function animate(anim_data, duration, step_func, done_func, frame_rate)
	frame_rate = frame_rate or 60
	local frame_duration = 1 / frame_rate
	local i_frame = 0
	local t0 = hs.timer.absoluteTime() / _NS_PER_SEC
	local t1 = t0 + duration

	local function anim_step()
		local curr_timestamp = hs.timer.absoluteTime() / _NS_PER_SEC
		local t = (curr_timestamp - t0) / duration
		t = t <= 1 and t or 1

		local fn_anim_data = {}
		for k, v in pairs(anim_data) do
			local v0, v1 = table.unpack(v)
			fn_anim_data[k] = v0 + t * (v1 - v0)
		end
		step_func(fn_anim_data, t)

		if curr_timestamp >= t1 then
			if done_func then
				done_func()
			end
			return
		end

		i_frame = i_frame + 1
		local next_timestamp = t0 + i_frame * frame_duration
		local delay = next_timestamp - curr_timestamp
		delay = delay >= 0 and delay or 0
		hs.timer.doAfter(delay, anim_step)
	end
	hs.timer.doAfter(0, anim_step)
end


--=============================================================================


return {
	animate=animate,
	Animation=Animation,
}
