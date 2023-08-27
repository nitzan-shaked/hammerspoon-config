
local menu_item = nil
local last_volume = nil
local last_is_muted = nil

local all_out_devs = {}

local function refresh_one_dev()
    local curr_device = hs.audiodevice.current()
    local volume = math.ceil(curr_device.volume)
    local is_muted = curr_device.muted
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
        font={
            name="RobotoMono Nerd Font",
            size=18,
        },
        baselineOffset=-2.0,
    })
    local label_text = is_muted and "" or hs.styledtext.new("  " .. volume)
    menu_item:setTitle(icon_text .. label_text)
end

local function refresh_all_out_devs()
    all_out_devs = {}
    for _, dev in ipairs(hs.audiodevice.allOutputDevices()) do
        table.insert(all_out_devs, dev)
        dev:watcherStop()
        dev:watcherCallback(function ()
            refresh_one_dev()
        end)
        dev:watcherStart()
    end
end

local function init()
    menu_item = hs.menubar.new(true, "my_volume_icon")

    hs.audiodevice.watcher.stop()
    hs.audiodevice.watcher.setCallback(function (e_type)
        if e_type == "dev#" then refresh_all_out_devs() end
    end)
    hs.audiodevice.watcher.start()
    refresh_all_out_devs()
    refresh_one_dev()
end


return {
    init=init,
}
