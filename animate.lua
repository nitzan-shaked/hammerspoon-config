local _NS_PER_SEC = 1000000000

--[[ LOGIC ]]

---@alias AnimData table<string, number[]>
---@alias AnimStepData table<string, number>
---@alias AnimStepFunc fun(step_data: AnimStepData, i_step: number)

---@param anim_data AnimData
---@param duration number
---@param fn AnimStepFunc
---@param frame_rate number?
local function animate(anim_data, duration, fn, frame_rate)
	frame_rate = frame_rate or 30
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
		fn(fn_anim_data, t)

		if curr_timestamp >= t1 then
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

--[[ MODULE ]]

return {
	animate=animate,
}
