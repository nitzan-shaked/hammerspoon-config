---@meta "hs.audiodevice"

---@class AudioDevice
local AudioDevice = {}

---@module "hs.audiodevice.watcher"
local watcher

---@return AudioDevice | nil
function AudioDevice.defaultOutputDevice() end

---@return string | nil
function AudioDevice:uid() end

---@return boolean | nil
function AudioDevice:muted() end

---@param is_muted boolean
function AudioDevice:setMuted(is_muted) end

---@return integer | nil
function AudioDevice:volume() end

---@param volume number
---@return AudioDevice | nil
function AudioDevice:setVolume(volume) end

---@return AudioDevice
---@param fn fun(...): nil
function AudioDevice:watcherCallback(fn) end

---@return AudioDevice | nil
function AudioDevice:watcherStart() end

---@return AudioDevice
function AudioDevice:watcherStop() end

---@class hs.audiodevice
local module = {
    watcher=watcher,
    defaultOutputDevice=AudioDevice.defaultOutputDevice,
}

return module
