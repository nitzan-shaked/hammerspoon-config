
local menu_item = nil
local hidden = false

---@param volume integer
---@param is_muted boolean
local function refresh(volume, is_muted)
    if hidden then return end
    local curr_device = hs.audiodevice.current()
    local volume = math.ceil(curr_device.volume)
    local is_muted = curr_device.muted
    local horiz_bar = "━"
    local part1_text = hs.styledtext.new(horiz_bar, {
        font={
            name="RobotoMono Nerd Font",
            size=10,
        },
        color={red=0.5, blue=1, green=0.5},
    })
    local part2_text = hs.styledtext.new(horiz_bar, {
        font={
            name="RobotoMono Nerd Font",
            size=10,
        },
        color={red=0.5, blue=0.5, green=0.5},
    })
    menu_item:setTitle(part1_text .. part2_text)
end

local function show()
    hidden = false
    refresh()
end

local function hide()
    hidden = true
    refresh()
end

local function init()
    menu_item = hs.menubar.new(true, "my_volume_slider")
    show()
end

return {
    init=init,
    refresh=refresh,
    show=show,
    show=hide,
}
