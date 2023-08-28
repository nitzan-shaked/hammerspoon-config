local Size = require("geom.size")

local ICON_WIDTH = 17
local VOLUME_LABEL_WIDTH = 23
local SLIDER_WIDTH = 72
local SLIDER_HEIGHT = 4
local SLIDER_BG_COLOR = {red=0.4, green=0.4, blue=0.4}
local SLIDER_HILIGHT_COLOR = {red=0.2, green=0.2, blue=1}


---@type MenuBar
local menu_item
---@type Canvas
local slider_canvas
local slider_is_shown = false

---@type AudioDevice | nil
local curr_out_dev = nil
---@type string | nil
local curr_out_dev_uid = "not_a_real_uid"


local function refresh_volume_icon()
    if curr_out_dev == nil then
        return
    end
    local volume = curr_out_dev:volume()
    local is_muted = curr_out_dev:muted()
    if volume ~= nil then
        volume = math.ceil(volume)
    end

    local show_icon = true
    local show_volume_label = volume ~= nil and not is_muted
    local show_slider = slider_is_shown

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

    local tab_stops = {}
    local x = 0
    if show_icon then
        x = x + ICON_WIDTH
        table.insert(tab_stops, {location=x})
    end
    if show_volume_label then
        x = x + VOLUME_LABEL_WIDTH
        table.insert(tab_stops, {location=x})
    end
    if show_slider then
        x = x + 6 + SLIDER_WIDTH
        table.insert(tab_stops, {location=x})
    end
    local paragraph_style = {
        tabStops=tab_stops,
    }

    local final_title = hs.styledtext.new("", {})

    if show_icon then
        final_title = final_title .. hs.styledtext.new(icon_str .. "\t", {
            font={name="RobotoMono Nerd Font", size=17},
            baselineOffset=-2.0,
            paragraphStyle=paragraph_style,
        })
    end

    if show_volume_label then
        final_title = final_title .. hs.styledtext.new(volume .. "\t", {
            paragraphStyle=paragraph_style,
        })
    end

    if show_slider then
        final_title = final_title .. hs.styledtext.new("\t", {
            paragraphStyle=paragraph_style,
        })

        slider_canvas["hilight"].frame = {
            x=0,
            y=0,
            w=SLIDER_WIDTH * (volume or 0) / 100,
            h=SLIDER_HEIGHT,
        }
    end

    menu_item:setTitle(final_title)
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

local function show_slider()
    local f = menu_item:frame()
    f.x1 = f.x2 - SLIDER_WIDTH - 12
    f.y1 = f.y1 + (f.h - SLIDER_HEIGHT) / 2
    f.w = SLIDER_WIDTH
    f.h = SLIDER_HEIGHT
    slider_canvas:frame(f)
    slider_is_shown = true
    refresh_volume_icon()
    slider_canvas:show()
end

local function hide_slider()
    slider_is_shown = false
    slider_canvas:hide()
    refresh_volume_icon()
end

local function toggle_slider()
    if slider_is_shown then hide_slider() else show_slider() end
end

local function init()
    menu_item = hs.menubar.new(true, "my_volume_icon")
    menu_item:setClickCallback(toggle_slider)

    slider_canvas = hs.canvas.new({})
    slider_canvas:size(Size(SLIDER_WIDTH, SLIDER_HEIGHT))
	slider_canvas:level(hs.canvas.windowLevels.popUpMenu)
	slider_canvas:appendElements({
		id="bg",
		type="rectangle",
        action="fill",
        fillColor=SLIDER_BG_COLOR,
	})
	slider_canvas:appendElements({
		id="hilight",
		type="rectangle",
        action="fill",
        fillColor=SLIDER_HILIGHT_COLOR,
	})

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
