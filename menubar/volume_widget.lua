local Size = require("geom.size")
local u = require("utils.utils")

local MENUBAR_HEIGHT = 24
local ICON_WIDTH = 17
local VOLUME_LABEL_WIDTH = 23
local SLIDER_WIDTH_NET = 72
local SLIDER_THICKNESS = 4
local SLIDER_KNOB_RADIUS = 6
local SLIDER_SCALE_BG_COLOR       = {red=0.4, green=0.4, blue=0.4}
local SLIDER_SCALE_HILIGHT_COLOR  = {red=0.2, green=0.2, blue=1.0}
local SLIDER_SCALE_DISABLED_COLOR = {red=0.8, green=0.8, blue=0.8}
local SLIDER_KNOB_STROKE_COLOR    = {red=0.0, green=0.0, blue=0.0}
local SLIDER_KNOB_FILL_COLOR      = {red=0.8, green=0.8, blue=0.8}

local SLIDER_WIDTH_GROSS = SLIDER_WIDTH_NET + 2 * SLIDER_KNOB_RADIUS
local SLIDER_SCALE_Y_IN_CANVAS = (MENUBAR_HEIGHT - SLIDER_THICKNESS) / 2


---@type AudioDevice | nil
local curr_out_dev = nil
---@type string | nil
local curr_out_dev_uid = "not_a_real_uid"

---@type MenuBar
local menubar_widget

---@type Canvas
local slider_canvas
local slider_is_enabled = true
local slider_is_visible = false
local slider_knob_is_visible = false
local slider_knob_is_grabbed = false
local mouse_in_slider_canvas = false
local mouse_in_slider_knob = false


---@param volume number | nil
---@return number
local function volume_to_slider_x(volume)
    volume = u.clip(volume or 0, 0, 100)
    return SLIDER_KNOB_RADIUS + SLIDER_WIDTH_NET * volume / 100
end

---@param slider_x number
---@return number
local function slider_x_to_volume(slider_x)
    local slider_x_net = u.clip(slider_x - SLIDER_KNOB_RADIUS, 0, SLIDER_WIDTH_NET)
    return slider_x_net / SLIDER_WIDTH_NET * 100
end

---@param slider_x number
local function slider_set(slider_x)
    slider_canvas["hilight"].frame = {
        x=SLIDER_KNOB_RADIUS,
        y=SLIDER_SCALE_Y_IN_CANVAS,
        w=slider_x - SLIDER_KNOB_RADIUS,
        h=SLIDER_THICKNESS,
    }
    slider_canvas["knob"].center.x = slider_x
end

local function slider_knob_show()
    if slider_knob_is_visible then return end
    slider_canvas["knob"].action = "strokeAndFill"
    slider_knob_is_visible = true
end

local function slider_knob_hide()
    if not slider_knob_is_visible then return end
    slider_canvas["knob"].action = "skip"
    slider_knob_is_visible = false
end

local function slider_knob_update_visibility()
    if slider_knob_is_grabbed then
        slider_knob_show()
        return
    end
    if not slider_is_enabled then
        slider_knob_hide()
        return
    end
    if mouse_in_slider_canvas or mouse_in_slider_knob then
        slider_knob_show()
    else
        slider_knob_hide()
    end
end

local function slider_disable()
    if not slider_is_enabled then return end
    slider_is_enabled = false
    slider_knob_update_visibility()
    slider_canvas["hilight"].fillColor = SLIDER_SCALE_DISABLED_COLOR
end

local function slider_enable()
    if slider_is_enabled then return end
    slider_is_enabled = true
    slider_knob_update_visibility()
    slider_canvas["hilight"].fillColor = SLIDER_SCALE_HILIGHT_COLOR
end

local function slider_update_enabled()
    if curr_out_dev == nil then return end
    if curr_out_dev:muted() then
        slider_disable()
    else
        slider_enable()
    end
end

local function refresh_widget()
    if curr_out_dev == nil then
        return
    end
    slider_update_enabled()
    local volume = curr_out_dev:volume()
    local is_muted = curr_out_dev:muted()
    if volume ~= nil then
        volume = math.ceil(volume)
    end

    local show_icon = true
    local show_volume_label = volume ~= nil and not is_muted
    local show_slider = slider_is_visible

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
        x = x + 6 + SLIDER_WIDTH_GROSS
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

    menubar_widget:setTitle(final_title)
end

local function slider_show()
    local f = menubar_widget:frame()
    f.x1 = f.x2 - SLIDER_WIDTH_GROSS - 12
    f.y1 = 0
    f.w = SLIDER_WIDTH_GROSS
    f.h = MENUBAR_HEIGHT
    slider_canvas:frame(f)
    slider_is_visible = true
    refresh_widget()
    slider_canvas:show()
end

local function slider_hide()
    slider_is_visible = false
    slider_canvas:hide()
    refresh_widget()
end

local function toggle_slider()
    if slider_is_visible then slider_hide() else slider_show() end
end

local function toggle_mute()
    if not curr_out_dev then return end
    local is_muted = curr_out_dev:muted()
    if is_muted == nil then return end
    curr_out_dev:setMuted(not is_muted)
end

---@type EventTap | nil
local slider_tap = nil

---@param ev Event
local function slider_tap_event_handler(ev)
    local ev_type = ev:getType()
    if ev_type == hs.eventtap.event.types.leftMouseDragged then
        assert(slider_knob_is_grabbed)
        if not curr_out_dev then return end
        local mouse_pos = hs.mouse.absolutePosition()
        local slider_x = mouse_pos.x - slider_canvas:frame().x
        local volume = slider_x_to_volume(slider_x)
        curr_out_dev:setVolume(volume)
    end
end

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
        if elem_id == "knob" and not slider_knob_is_grabbed then
            slider_knob_is_grabbed = true
            assert(slider_tap == nil)
            slider_tap = hs.eventtap.new({
                hs.eventtap.event.types.leftMouseDragged,
            }, slider_tap_event_handler)
            slider_tap:start()
        end
    elseif ev_type == "mouseUp" then
        if slider_knob_is_grabbed then
            assert(slider_tap):stop()
            slider_tap = nil
        end
        slider_knob_is_grabbed = false
    end
    slider_knob_update_visibility()
end

local function init_slider_canvas()
    slider_canvas = hs.canvas.new({})
    slider_canvas:size(Size(SLIDER_WIDTH_GROSS, MENUBAR_HEIGHT))
	slider_canvas:level(hs.canvas.windowLevels.popUpMenu)
	slider_canvas:appendElements({
		id="bg",
		type="rectangle",
        action="fill",
        frame={
            x=SLIDER_KNOB_RADIUS,
            y=SLIDER_SCALE_Y_IN_CANVAS,
            w=SLIDER_WIDTH_NET,
            h=SLIDER_THICKNESS,
        },
        fillColor=SLIDER_SCALE_BG_COLOR,
	})
	slider_canvas:appendElements({
		id="hilight",
		type="rectangle",
        action="fill",
        frame={
            x=SLIDER_KNOB_RADIUS,
            y=SLIDER_SCALE_Y_IN_CANVAS,
            w=0,
            h=SLIDER_THICKNESS,
        },
        fillColor=SLIDER_SCALE_HILIGHT_COLOR,
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

---@param mods table<string, boolean>
local function widget_click_callback(mods)
    if mods.alt then
        toggle_slider()
    else
        toggle_mute()
    end
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
    refresh_widget()
    curr_out_dev:watcherStop()
    curr_out_dev:watcherCallback(refresh_widget)
    curr_out_dev:watcherStart()
end

local function init()
    menubar_widget = hs.menubar.new(true, "my_volume_widget")
    menubar_widget:setClickCallback(widget_click_callback)
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
