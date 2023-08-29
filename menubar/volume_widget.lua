local Size = require("geom.size")
local u = require("utils.utils")

local MENUBAR_HEIGHT = 24
local ICON_WIDTH = 17
local VOLUME_LABEL_WIDTH = 23
local SLIDER_WIDTH_NET = 72
local SLIDER_THICKNESS = 4
local SLIDER_KNOB_RADIUS = 6

local ENABLED_COLOR               = {red=1.0, green=1.0, blue=1.0}
local DISABLED_COLOR              = {red=0.5, green=0.5, blue=0.5}
local SLIDER_SCALE_BG_COLOR       = {red=0.2, green=0.2, blue=0.2}
local SLIDER_SCALE_HILIGHT_COLOR  = {red=0.2, green=0.2, blue=1.0}
local SLIDER_KNOB_STROKE_COLOR    = {red=0.0, green=0.0, blue=0.0}
local SLIDER_KNOB_FILL_COLOR      = {red=0.8, green=0.8, blue=0.8}

local SLIDER_WIDTH_GROSS = SLIDER_WIDTH_NET + 2 * SLIDER_KNOB_RADIUS
local SLIDER_SCALE_Y_IN_CANVAS = (MENUBAR_HEIGHT - SLIDER_THICKNESS) / 2

---@type Canvas
local slider_canvas
---@type boolean | nil
local slider_is_visible = nil
---@type boolean | nil
local slider_knob_is_visible = nil
---@type boolean | nil
local slider_is_enabled = nil

local slider_knob_is_grabbed = false
local mouse_in_slider_canvas = false
local mouse_in_slider_knob = false

---@type MenuBar
local menubar_widget

---@type AudioDevice | nil
local curr_out_dev = nil
---@type string | nil
local curr_out_dev_uid = nil


--=============================================================================
--
-- SLIDER
--
--=============================================================================

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

---@param volume number
local function slider_set(volume)
    local slider_x = volume_to_slider_x(volume)
    slider_canvas["hilight"].frame.w = slider_x - SLIDER_KNOB_RADIUS
    slider_canvas["knob"].center.x = slider_x
end

local function slider_knob_show()
    if slider_knob_is_visible then return end
    slider_canvas["knob"].action = "strokeAndFill"
    slider_knob_is_visible = true
end

local function slider_knob_hide()
    if slider_knob_is_visible ~= nil and not slider_knob_is_visible then return end
    slider_canvas["knob"].action = "skip"
    slider_knob_is_visible = false
end

---@param is_visible boolean | nil
local function slider_knob_set_visibility(is_visible)
    if is_visible then
        slider_knob_show()
    else
        slider_knob_hide()
    end
end

local function slider_knob_refresh_visibility()
    slider_knob_set_visibility(
        slider_knob_is_grabbed or (
            slider_is_enabled and (mouse_in_slider_knob or mouse_in_slider_canvas)
        )
    )
end

local function slider_disable()
    if slider_is_enabled ~= nil and not slider_is_enabled then return end
    slider_is_enabled = false
    slider_knob_refresh_visibility()
    slider_canvas["hilight"].fillColor = DISABLED_COLOR
end

local function slider_enable()
    if slider_is_enabled then return end
    slider_is_enabled = true
    slider_knob_refresh_visibility()
    slider_canvas["hilight"].fillColor = SLIDER_SCALE_HILIGHT_COLOR
end

---@param is_enabled boolean | nil
local function slider_set_enabled(is_enabled)
    if is_enabled then
        slider_enable()
    else
        slider_disable()
    end
end

local function slider_refresh_enabled()
    slider_set_enabled(
        curr_out_dev ~= nil
        and not curr_out_dev:muted()
    )
end

local function slider_refresh()
    slider_knob_refresh_visibility()
    slider_refresh_enabled()
    if curr_out_dev == nil then return end
    local volume = curr_out_dev:volume()
    if volume ~= nil then
        slider_set(volume)
    end
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
    slider_knob_refresh_visibility()
end

local function slider_show()
    if slider_is_visible then return end
    slider_is_visible = true
    slider_canvas:show()
end

local function slider_hide()
    if slider_is_visible ~= nil and not slider_is_visible then return end
    slider_is_visible = false
    slider_canvas:hide()
end

local function slider_toggle_visibility()
    if slider_is_visible then
        slider_hide()
    else
        slider_show()
    end
end

local function slider_init()
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

--=============================================================================
--
-- WIDGET
--
--=============================================================================

local function widget_refresh()
    slider_refresh()
    if curr_out_dev == nil then
        return
    end
    local volume = curr_out_dev:volume()
    local is_muted = curr_out_dev:muted()
    if volume ~= nil then
        volume = math.ceil(volume)
    end

    local show_icon = true
    local show_volume_label = volume ~= nil
    local show_slider = slider_is_visible

    local icon_str = ""
    if is_muted then
        icon_str = "󰖁"
    elseif volume == nil then
        icon_str = "?"
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
        local icon_color = (volume ~= nil) and ENABLED_COLOR or DISABLED_COLOR
        final_title = final_title .. hs.styledtext.new(icon_str .. "\t", {
            font={name="RobotoMono Nerd Font", size=17},
            color=icon_color,
            baselineOffset=-2.0,
            paragraphStyle=paragraph_style,
        })
    end

    if show_volume_label then
        assert(volume ~= nil)
        local volume_label_color = (not is_muted) and ENABLED_COLOR or DISABLED_COLOR
        local volume_str = volume .. ""
        final_title = final_title .. hs.styledtext.new(volume_str .. "\t", {
            paragraphStyle=paragraph_style,
            color=volume_label_color,
        })
    end

    if show_slider then
        final_title = final_title .. hs.styledtext.new("\t", {
            paragraphStyle=paragraph_style,
        })
    end

    menubar_widget:setTitle(final_title)
end

local function widget_show_slider()
    local f = menubar_widget:frame()
    slider_show()
    widget_refresh()
    f.x1 = f.x2 - SLIDER_WIDTH_GROSS - 12
    f.w = SLIDER_WIDTH_GROSS
    slider_canvas:frame(f)
end

local function widget_hide_slider()
    slider_hide()
    widget_refresh()
end

local function widget_toggle_slider()
    if slider_is_visible then
        widget_hide_slider()
    else
        widget_show_slider()
    end
end

local function widget_toggle_mute()
    if not curr_out_dev then return end
    local is_muted = curr_out_dev:muted()
    if is_muted == nil then return end
    curr_out_dev:setMuted(not is_muted)
end

---@param mods table<string, boolean>
local function widget_click_callback(mods)
    if mods.alt then
        widget_toggle_slider()
    else
        widget_toggle_mute()
    end
end

local function widget_init()
    menubar_widget = hs.menubar.new(true, "my_volume_widget")
    menubar_widget:setClickCallback(widget_click_callback)
    slider_init()
end

--=============================================================================
--
-- AUDIO-DEVICE WATCHER
--
--=============================================================================

local function adev_watcher_refresh_curr_out_dev()
    local new_out_dev = hs.audiodevice.defaultOutputDevice()
    if new_out_dev == nil then
        curr_out_dev = nil
        curr_out_dev_uid = nil
        return
    end
    local new_out_dev_uid = new_out_dev:uid()
    if new_out_dev_uid == nil then
        curr_out_dev_uid = nil
        return
    end
    if new_out_dev_uid == curr_out_dev_uid then
        return
    end
    curr_out_dev = new_out_dev
    curr_out_dev_uid = new_out_dev_uid
    widget_refresh()
    curr_out_dev:watcherStop()
    curr_out_dev:watcherCallback(widget_refresh)
    curr_out_dev:watcherStart()
end

---@param e_type string
local function adev_watcher_callback(e_type)
    if e_type == "dev#" then
        adev_watcher_refresh_curr_out_dev()
    end
end

local function adev_watcher_init()
    hs.audiodevice.watcher.stop()
    hs.audiodevice.watcher.setCallback(adev_watcher_callback)
    hs.audiodevice.watcher.start()
    adev_watcher_refresh_curr_out_dev()
end

--=============================================================================
--
-- MODULE
--
--=============================================================================

local function init()
    widget_init()
    adev_watcher_init()
end

return {
    init=init,
}
