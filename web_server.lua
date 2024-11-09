local httpserver = require("hs.httpserver")
local lfs = require("hs.fs")

local class = require("utils.class")


---@class WebServer: Class
---@operator call: WebServer
local WebServer = class.make_class("WebServer")


local function _read_file(p)
	local file = io.open(p, "r")
	if file == nil then return nil end
	local content = file:read("*a")
	file:close()
	return content
end


local function _read_files_recursively(dir, result_table)
	result_table = result_table or {}

	for entry in lfs.dir(dir) do
		if entry == "." or entry == ".." then goto continue end
		local full_path = dir .. "/" .. entry
		local attr = lfs.attributes(full_path)
		if attr == nil then goto continue end
		if attr.mode == "directory" then
			_read_files_recursively(full_path, result_table)
		elseif attr.mode == "file" then
			result_table[full_path] = _read_file(full_path)
		end
		::continue::
	end

	return result_table
end


function WebServer:__init__(web_root_path)
	self._started = false

	self._web_root_path_abs = lfs.pathToAbsolute(web_root_path)
	self._web_files = _read_files_recursively(self._web_root_path_abs)

	self._http_server = httpserver.new(false)
	self._http_server:setInterface("localhost")
	self._http_server:setCallback(function(method, path, headers, body)
		if method ~= "GET" then
			return "405 Method Not Allowed", 405, { ["Content-Type"]="text/plain" }
		end
		local file_path_rel = self._web_root_path_abs .. path
		local attrs = lfs.attributes(file_path_rel)
		if attrs == nil then
			return "404 Not Found", 404, { ["Content-Type"]="text/plain" }
		end
		if attrs.mode ~= "file" then  -- this catches also symlinks
			return "404 Not Found", 404, { ["Content-Type"]="text/plain" }
		end
		local file_path_abs = lfs.pathToAbsolute(self._web_root_path_abs .. path)
		if file_path_abs:sub(1, #self._web_root_path_abs) ~= self._web_root_path_abs then
			return "404 Not Found", 404, { ["Content-Type"]="text/plain" }
		end

		-- local file_content = read_file(file_path_abs)
		local file_content = self._web_files[file_path_abs]
		if file_content == nil then
			return "404 Not Found", 404, { ["Content-Type"]="text/plain" }
		end

		local content_type = "text/plain"
		if path:match("[.]js$") then
			content_type = "application/javascript"
		elseif path:match("[.]css$") then
			content_type = "text/css"
		elseif path:match("[.]html$") then
			content_type = "text/html"
		end
		return file_content, 200, { ["Content-Type"]=content_type }
	end)
end


function WebServer:start()
	if self._started then error("WebServer is already started") end
	self._http_server:start()
	self._started = true
end


function WebServer:started()
	return self._started
end


function WebServer:stop()
	if not self._started then error("WebServer is not started") end
	self._http_server:stop()
	self._started = false
end


---@return string
function WebServer:getBaseUrl()
	if not self._started then error("WebServer is not started") end
	return "http://localhost:" .. self._http_server:getPort()
end


return WebServer
