local cls = {}


local function escape_for_sh(s)
	-- convert every char in s that is not alphanumeric to an escaped version
	return s:gsub("[^%w]", function(c)
		return string.format("\\" .. c)
	end)
end


function cls.run_hidutil(...)
	local escaped_args = {}
	for i = 1, select("#", ...) do
		escaped_args[i] = escape_for_sh(select(i, ...))
	end
	local cmd_str = "/usr/bin/hidutil " .. table.concat(escaped_args, " ")
	local handle = io.popen(cmd_str)
	if not handle then
		print("failed to open hidutil")
		return nil
	end
	local result = handle:read("*a")
	handle:close()
	return result
end


return cls
