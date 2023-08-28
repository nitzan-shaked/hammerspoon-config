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
local function volume_to_slider_x(volume)
    volume = u.clip(volume or 0, 0, 100)
    return SLIDER_KNOB_RADIUS + avail_slider_width * volume / 100
end

---@param slider_x number
---@return number
local function slider_x_to_volume(slider_x)
    slider_x = u.clip(slider_x, SLIDER_KNOB_RADIUS, SLIDER_WIDTH - SLIDER_KNOB_RADIUS)
    return (slider_x - SLIDER_KNOB_RADIUS) / avail_slider_width * 100
end

---@param slider_x number
local function slider_set(slider_x)
    slider_canvas["hilight"].frame = {
        x=SLIDER_KNOB_RADIUS,
        y=slider_y_in_canvas,
        w=slider_x - SLIDER_KNOB_RADIUS,
        h=SLIDER_THICKNESS,
    }
    slider_canvas["knob"].center.x = slider_x
end

local function volume_icon_refresh()
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
        slider_set(volume_to_slider_x(volume))
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
    volume_icon_refresh()
    curr_out_dev:watcherStop()
    curr_out_dev:watcherCallback(volume_icon_refresh)
    curr_out_dev:watcherStart()
end

local function slider_show()
    local f = menu_item:frame()
    f.x1 = f.x2 - SLIDER_WIDTH - 12
    f.y1 = 0
    f.w = SLIDER_WIDTH
    f.h = MENUBAR_HEIGHT
    slider_canvas:frame(f)
    slider_is_shown = true
    volume_icon_refresh()
    slider_canvas:show()
end

local function slider_hide()
    slider_is_shown = false
    slider_canvas:hide()
    volume_icon_refresh()
end

local function slider_toggle()
    if slider_is_shown then slider_hide() else slider_show() end
end

local mouse_in_slider_canvas = false
local mouse_in_slider_knob = false
local slider_knob_grabbed = false
local slider_knob_visible = false

local function _show_knob()
    if slider_knob_visible then return end
    slider_canvas["knob"].action = "strokeAndFill"
    slider_knob_visible = true
end

local function _hide_knob()
    if not slider_knob_visible then return end
    slider_canvas["knob"].action = "skip"
    slider_knob_visible = false
end

local function _update_knob_visibility()
    if mouse_in_slider_canvas or mouse_in_slider_knob or slider_knob_grabbed then
        _show_knob()
    else
        _hide_knob()
    end
end

---@param slider_x number
local function _move_knob_and_set_volume(slider_x)
    slider_set(slider_x)
    local volume = slider_x_to_volume(slider_x)
    assert(curr_out_dev):setVolume(volume)
end

---@param ev Event
local function slider_tap_event_handler(ev)
    local ev_type = ev:getType()
    if ev_type == hs.eventtap.event.types.leftMouseDragged then
        assert(slider_knob_grabbed)
        local mouse_pos = hs.mouse.absolutePosition()
        local slider_x = mouse_pos.x - slider_canvas:frame().x
        slider_x = u.clip(
            slider_x,
            SLIDER_KNOB_RADIUS,
            SLIDER_WIDTH - SLIDER_KNOB_RADIUS
        )
        _move_knob_and_set_volume(slider_x)
    end
end

---@type EventTap | nil
local slider_tap = nil

local function slider_canvas_event_handler(_, ev_type, elem_id, ev_x, ev_y)
    if ev_type == "mouseEnter" then
        if elem_id == "_canvas_" then
            mouse_in_slider_canvas = true
        elseif elem_id == "knob" then
            mouse_in_slider_knob = true
        end
    elseif ev_type == "mouseExit" then
        if elem_id == "_canvas_" then
            mouse_in_slider_canvas = false
        elseif elem_id == "knob" then
            mouse_in_slider_knob = false
        end
    elseif ev_type == "mouseDown" then
        if elem_id == "knob" and not slider_knob_grabbed then
            slider_knob_grabbed = true
            assert(slider_tap == nil)
            slider_tap = hs.eventtap.new({
                hs.eventtap.event.types.leftMouseDragged,
            }, slider_tap_event_handler)
            slider_tap:start()
        end
    elseif ev_type == "mouseUp" then
        if slider_knob_grabbed then
            assert(slider_tap):stop()
            slider_tap = nil
        end
        slider_knob_grabbed = false
    end
    _update_knob_visibility()
end

local function init_slider_canvas()
    slider_canvas = hs.canvas.new({})
    slider_canvas:size(Size(SLIDER_WIDTH, MENUBAR_HEIGHT))
	slider_canvas:level(hs.canvas.windowLevels.popUpMenu)
	slider_canvas:appendElements({
		id="bg",
		type="rectangle",
        action="fill",
        frame={
            x=SLIDER_KNOB_RADIUS,
            y=slider_y_in_canvas,
            w=avail_slider_width,
            h=SLIDER_THICKNESS,
        },
        fillColor=SLIDER_BG_COLOR,
	})
	slider_canvas:appendElements({
		id="hilight",
		type="rectangle",
        action="fill",
        frame={
            x=SLIDER_KNOB_RADIUS,
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
	})
    slider_canvas:canvasMouseEvents(true, true, true, false)
    slider_canvas:mouseCallback(slider_canvas_event_handler)
end

local function init_menu_item()
    menu_item = hs.menubar.new(true, "my_volume_icon")
    menu_item:setClickCallback(slider_toggle)
end

local function init()
    init_menu_item()
    init_slider_canvas()

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
