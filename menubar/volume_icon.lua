local Size = require("geom.size")
local u = require("utils.utils")

local MENUBAR_HEIGHT = 24
local ICON_WIDTH = 17
local VOLUME_LABEL_WIDTH = 23
local SLIDER_WIDTH = 72
local SLIDER_THICKNESS = 4
local SLIDER_KNOB_RADIUS = 6
local SLIDER_BG_COLOR = {red=0.4, green=0.4, blue=0.4}
local SLIDER_HILIGHT_COLOR = {red=0.2, green=0.2, blue=1}
local SLIDER_KNOB_STROKE_COLOR = {white=0}
local SLIDER_KNOB_FILL_COLOR = {white=0.8}

local avail_slider_width = SLIDER_WIDTH - 2 * SLIDER_KNOB_RADIUS
local slider_y_in_canvas = (MENUBAR_HEIGHT - SLIDER_THICKNESS) / 2


---@type MenuBar
local menu_item
---@type Canvas
local slider_canvas
local slider_is_shown = false

---@type AudioDevice | nil
local curr_out_dev = nil
---@type string | nil
local curr_out_dev_uid = "not_a_real_uid"


---@param volume number | nil
---@return number
local function _volume_to_slider_x(volume)
    volume = u.clip(volume or 0, 0, 100)
    return SLIDER_KNOB_RADIUS + avail_slider_width * volume / 100
end

---@param slider_x number
---@return number
local function _slider_x_to_volume(slider_x)
    slider_x = u.clip(slider_x, 0, avail_slider_width)
    return (slider_x - SLIDER_KNOB_RADIUS) / avail_slider_width * 100
end

---@param slider_x number
local function _set_slider(slider_x)
    slider_canvas["hilight"].frame = {
        x=0,
        y=slider_y_in_canvas,
        w=slider_x,
        h=SLIDER_THICKNESS,
    }
    slider_canvas["knob"].center.x = slider_x
end

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
        _set_slider(_volume_to_slider_x(volume))
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
    f.y1 = 0
    f.w = SLIDER_WIDTH
    f.h = MENUBAR_HEIGHT
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
    slider_canvas:size(Size(SLIDER_WIDTH, MENUBAR_HEIGHT))
	slider_canvas:level(hs.canvas.windowLevels.popUpMenu)
	slider_canvas:appendElements({
		id="bg",
		type="rectangle",
        action="fill",
        frame={
            x=0,
            y=slider_y_in_canvas,
            w="100%",
            h=SLIDER_THICKNESS,
        },
        fillColor=SLIDER_BG_COLOR,
	})
	slider_canvas:appendElements({
		id="hilight",
		type="rectangle",
        action="fill",
        frame={
            x=0,
            y=slider_y_in_canvas,
            w=0,
            h=SLIDER_THICKNESS,
        },
        fillColor=SLIDER_HILIGHT_COLOR,
	})
	slider_canvas:appendElements({
		id="knob",
		type="circle",
        action="strokeAndFill",
        strokeColor=SLIDER_KNOB_STROKE_COLOR,
        fillColor=SLIDER_KNOB_FILL_COLOR,
        radius=SLIDER_KNOB_RADIUS,
        trackMouseEnterExit=true,
        trackMouseDown=true,
        trackMouseUp=true,
        trackMouseMove=true,
	})
    slider_canvas:canvasMouseEvents(true, true, true, true)

    ---@param slider_x number
    local function _move_knob_and_set_volume(slider_x)
        _set_slider(slider_x)
        local volume = _slider_x_to_volume(slider_x)
        assert(curr_out_dev):setVolume(volume)
    end

    local mouse_in_canvas = false
    local mouse_in_knob = false
    local knob_grabbed = false
    local knob_visible = false

    local function _show_knob()
        if knob_visible then return end
        slider_canvas["knob"].action = "strokeAndFill"
        knob_visible = true
    end

    local function _hide_knob()
        if not knob_visible then return end
        slider_canvas["knob"].action = "skip"
        knob_visible = false
    end

    local function _update_knob_visibility()
        if mouse_in_canvas or mouse_in_knob or knob_grabbed then
            _show_knob()
        else
            _hide_knob()
        end
    end

    slider_canvas:mouseCallback(function (_, ev_type, elem_id, ev_x, ev_y)
        if elem_id == "_canvas_" then
            if ev_type == "mouseEnter" then
                mouse_in_canvas = true
                _update_knob_visibility()
            elseif ev_type == "mouseExit" then
                mouse_in_canvas = false
                _update_knob_visibility()
            elseif ev_type == "mouseDown" then
                knob_grabbed = true
                _update_knob_visibility()
                _move_knob_and_set_volume(ev_x)
            elseif ev_type == "mouseUp" then
                if knob_grabbed then
                    _move_knob_and_set_volume(ev_x)
                end
                knob_grabbed = false
                _update_knob_visibility()
            elseif ev_type == "mouseMove" then
                if knob_grabbed then
                    _move_knob_and_set_volume(ev_x)
                end
                _update_knob_visibility()
            end
        elseif elem_id == "knob" then
            if ev_type == "mouseEnter" then
                mouse_in_knob = true
                _update_knob_visibility()
            elseif ev_type == "mouseExit" then
                mouse_in_knob = false
                _update_knob_visibility()
            elseif ev_type == "mouseDown" then
                knob_grabbed = true
                _update_knob_visibility()
                _move_knob_and_set_volume(ev_x)
            elseif ev_type == "mouseUp" then
                if knob_grabbed then
                    _move_knob_and_set_volume(ev_x)
                end
                knob_grabbed = false
                _update_knob_visibility()
            elseif ev_type == "mouseMove" then
                if knob_grabbed then
                    _move_knob_and_set_volume(ev_x)
                end
                _update_knob_visibility()
            end
        end
    end)

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
