
---@type MenuBar
local menu_item = nil

---@type AudioDevice | nil
local curr_out_dev = nil
---@type string | nil
local curr_out_dev_uid = "not_a_real_uid"

---@type integer | nil
local last_volume = nil
---@type boolean | nil
local last_is_muted = nil


local function refresh_volume_icon()
    if curr_out_dev == nil then
        return
    end
    local volume = curr_out_dev:volume()
    local is_muted = curr_out_dev:muted()
    if volume ~= nil then
        volume = math.ceil(volume)
    end
    if volume == last_volume and is_muted == last_is_muted then
        return
    end
    last_volume = volume
    last_is_muted = is_muted

    local icon_str = ""
    if is_muted then
        icon_str = "󰖁"
    elseif volume >= 75 then
        icon_str = "󰕾"
    elseif volume >= 35 then
        icon_str = "󰖀"
    else
        icon_str = "󰕿"
    end

    local icon_text = hs.styledtext.new(icon_str, {
        font={name="RobotoMono Nerd Font", size=17},
        baselineOffset=-2.0,
    })
    local volume_text = (
        (is_muted or volume == nil) and ""
        or hs.styledtext.new("  " .. volume, {
            font={name="SF Pro", size=18},
        })
    )
    menu_item:setTitle(icon_text .. volume_text)
end

local function refresh_curr_out_dev()
    local new_out_dev = hs.audiodevice.defaultOutputDevice()
    if new_out_dev == nil then
        curr_out_dev = nil
        curr_out_dev_uid = "not_a_real_uid"
        return
    end
    local new_out_dev_uid = new_out_dev:uid()
    if new_out_dev_uid == nil then
        curr_out_dev_uid = "not_a_real_uid"
        return        
    end
    if new_out_dev_uid == curr_out_dev_uid then
        return
    end
    curr_out_dev = new_out_dev
    curr_out_dev_uid = new_out_dev_uid
    refresh_volume_icon()
    curr_out_dev:watcherStop()
    curr_out_dev:watcherCallback(refresh_volume_icon)
    curr_out_dev:watcherStart()
end

local function init()
    menu_item = hs.menubar.new(true, "my_volume_icon")

    hs.audiodevice.watcher.stop()
    hs.audiodevice.watcher.setCallback(function (e_type)
        if e_type == "dev#" then refresh_curr_out_dev() end
    end)
    hs.audiodevice.watcher.start()
    refresh_curr_out_dev()
end


return {
    init=init,
}
