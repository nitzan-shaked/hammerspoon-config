
--[[ LOGIC ]]

---@enum SplitMode
local SplitMode = {
	HORIZ="HORIZ",
	VERT="VERT",
	LONG_SIDE="LONG_SIDE",
	SHORT_SIDE="SHORT_SIDE",
}

SplitMode.opposite = {
	[SplitMode.HORIZ     ] = SplitMode.VERT,
	[SplitMode.VERT      ] = SplitMode.HORIZ,
	[SplitMode.LONG_SIDE ] = SplitMode.SHORT_SIDE,
	[SplitMode.SHORT_SIDE] = SplitMode.LONG_SIDE,
}

--[[ MODULE ]]

return SplitMode
