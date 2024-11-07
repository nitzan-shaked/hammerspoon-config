import * as controls from "./js/controls/index.js";
import * as settings from "./js/settings/index.js";


function mk_control(control_type, value) {
    switch (control_type) {
        case "checkbox":
            return new controls.CheckboxControl(value);
        case "number":
            return new controls.NumberControl(value);
        case "color":
            return new controls.ColorControl(value);
        case "hotkey":
            return new controls.KeysListControl(value, {
                allow_modifiers: true,
                allow_regular_keys: true,
            });
        case "mods":
            return new controls.KeysListControl(value, {
                allow_modifiers: true,
                allow_regular_keys: false,
            });
        case "key":
            return new controls.KeysListControl(value, {
                allow_modifiers: false,
                allow_regular_keys: true,
            });
        default:
            throw new Error(`Unknown control type: ${control_type}`);
    }
}

function mk_item(j_item, value) {
    return new settings.SettingsItem(
        j_item.name,
        j_item.title,
        j_item.descr,
        mk_control(j_item.control, value)
    );
}

function mk_section(j_section, values) {
    return new settings.SettingsSection(
        j_section.name,
        j_section.title,
        j_section.descr,
        j_section.items.map(
            j_item => { return mk_item(j_item, values[j_item.name]); }
        )
    );
}

function mk_settings_dialog($el, j_sections, values) {
    return new settings.SettingsDialog(
        "settings",
        $el,
        j_sections.map(
            (j_section, index) => { return mk_section(j_section, values[index]); }
        )
    );
}

if (!window.SECTIONS_SCHEMAS || !window.SECTIONS_VALUES) {
    window.SECTIONS_SCHEMAS = JSON.parse("[{\"name\":\"dark_bg.hotkeys\",\"items\":[{\"title\":\"Darker\",\"control\":\"hotkey\",\"name\":\"darker\",\"descr\":\"Make the desktop background darker.\"},{\"title\":\"Lighter\",\"control\":\"hotkey\",\"name\":\"lighter\",\"descr\":\"Make the desktop background lighter.\"}],\"title\":\"Dark Background: Hotkeys\"},{\"title\":\"Find Mouse Cursor\",\"items\":[{\"title\":\"Highlight Duration\",\"control\":\"number\",\"name\":\"highlight_duration\",\"default\":3000,\"descr\":\"Duration of the highlight in milliseconds.\"},{\"title\":\"Circle Radius\",\"control\":\"number\",\"name\":\"circle_radius\",\"default\":30,\"descr\":\"Radius of the highlight circle in pixels.\"},{\"title\":\"Stroke Width\",\"control\":\"number\",\"name\":\"stroke_width\",\"default\":5,\"descr\":\"Width of the circle's circumference in pixels.\"},{\"title\":\"Stroke Color\",\"control\":\"color\",\"name\":\"stroke_color\",\"default\":\"#ff0000\",\"descr\":\"Color of the circle's circumference.\"},{\"title\":\"Fill Color\",\"control\":\"color\",\"name\":\"fill_color\",\"default\":\"#ff00004c\",\"descr\":\"Color of the circle's interior.\"}],\"name\":\"find_mouse_cursor\",\"descr\":\"Highlight the mouse cursor for a short duration.\"},{\"name\":\"find_mouse_cursor.hotkeys\",\"items\":[{\"title\":\"Highlight Mouse Cursor\",\"control\":\"hotkey\",\"name\":\"highlight\",\"descr\":\"Highlight the mouse cursor for a short duration.\"}],\"title\":\"Find Mouse Cursor: Hotkeys\"},{\"name\":\"launch.hotkeys\",\"items\":[{\"control\":\"hotkey\",\"name\":\"newFinderWindow\",\"descr\":\"Open a new Finder window.\"},{\"control\":\"hotkey\",\"name\":\"newChromeWindow\",\"descr\":\"Open a new Chrome window.\"},{\"control\":\"hotkey\",\"name\":\"newIterm2Window\",\"descr\":\"Open a new iTerm2 window.\"},{\"control\":\"hotkey\",\"name\":\"newWeztermWindow\",\"descr\":\"Open a new Wezterm window.\"},{\"control\":\"hotkey\",\"name\":\"launchMacPass\",\"descr\":\"Launch or focus MacPass.\"},{\"control\":\"hotkey\",\"name\":\"launchNotes\",\"descr\":\"Launch or focus Notes.\"},{\"control\":\"hotkey\",\"name\":\"startScreenSaver\",\"descr\":\"Start the screen saver.\"}],\"title\":\"Launch: Hotkeys\"},{\"title\":\"Visualize Key Strokes\",\"items\":[{\"title\":\"Text Size\",\"control\":\"number\",\"name\":\"text_size\",\"default\":48,\"descr\":\"Size of the text in the banner.\"},{\"title\":\"Canvas Height\",\"control\":\"number\",\"name\":\"canvas_height\",\"default\":56,\"descr\":\"Height of the banner.\"},{\"title\":\"Vertical Margin\",\"control\":\"number\",\"name\":\"v_margin\",\"default\":32,\"descr\":\"Margin between the banner and the bottom of the screen.\"},{\"title\":\"Horizontal Padding\",\"control\":\"number\",\"name\":\"h_padding\",\"default\":6,\"descr\":\"Padding on the left and right of the text in the banner.\"},{\"title\":\"Fill Color\",\"control\":\"color\",\"name\":\"fill_color\",\"default\":\"#ffffff4c\",\"descr\":\"Color of the banner.\"}],\"name\":\"viz_key_strokes\",\"descr\":\"Visualize key presses with an on-screen banner.\"},{\"title\":\"Visualize Mouse Clicks\",\"items\":[{\"title\":\"Circle Radius\",\"control\":\"number\",\"name\":\"circle_radius\",\"default\":35,\"descr\":\"The radius of the circle drawn around the mouse cursor.\"},{\"title\":\"Stroke Width\",\"control\":\"number\",\"name\":\"stroke_width\",\"default\":2,\"descr\":\"The width of the circle's stroke.\"},{\"title\":\"Left Click Stroke Color\",\"control\":\"color\",\"name\":\"left_click_stroke_color\",\"default\":\"#ffff00\",\"descr\":\"The color of the circle's stroke when left-clicking.\"},{\"title\":\"Right Click Stroke Color\",\"control\":\"color\",\"name\":\"right_click_stroke_color\",\"default\":\"#ff00ff\",\"descr\":\"The color of the circle's stroke when right-clicking.\"},{\"title\":\"Animation Duration\",\"control\":\"number\",\"name\":\"anim_duration\",\"default\":225,\"descr\":\"The duration of the circle's animation when clicking, in milliseconds.\"}],\"name\":\"viz_mouse_clicks\",\"descr\":\"Visualize mouse clicks with a short animation around the mouse cursor.\"},{\"title\":\"Win-Mouse\",\"items\":[{\"title\":\"Resize only bottom-right corner\",\"control\":\"checkbox\",\"name\":\"resize_only_bottom_right\",\"default\":true,\"descr\":\"When enabled, resizing affects only the bottom-right corner.\"}],\"name\":\"win_mouse\",\"descr\":\"Control window positions and sizes with the mouse.\"}]");
    window.SECTIONS_VALUES  = JSON.parse("[[],{\"highlight_duration\":3000,\"stroke_width\":5,\"fill_color\":\"#FF00004C\",\"circle_radius\":30,\"stroke_color\":\"#FF0000\"},[],[],{\"h_padding\":6,\"v_margin\":32,\"canvas_height\":56,\"text_size\":48,\"fill_color\":\"#FFFFFF4C\"},{\"left_click_stroke_color\":\"#FFFF00\",\"stroke_width\":2,\"circle_radius\":35,\"right_click_stroke_color\":\"#FF00FF\",\"anim_duration\":225},{\"resize_only_bottom_right\":true}]");
}
const dialog = mk_settings_dialog(
    $("#settings-dialog"),
    window.SECTIONS_SCHEMAS,
    window.SECTIONS_VALUES
);


$("#save").click(function () {
    let msg = dialog.value();
    if (window.RUNNING_IN_HAMMERSPOON) {
        webkit.messageHandlers.settings_dialog.postMessage(msg);
    } else {
        console.log(msg);
    }
});
