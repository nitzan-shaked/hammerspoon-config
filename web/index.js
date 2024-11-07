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

const hotkey0 = mk_control("hotkey", []);
const hotkey1 = mk_control("hotkey", ["cmd", "shift", "a"]);
const mods1 = mk_control("mods", ["cmd", "shift", "a"]);
const key1 = mk_control("key", ["cmd", "shift", "a"]);

const item0 = new settings.SettingsItem("item0", "title0", "descr0", hotkey0);
const item1 = new settings.SettingsItem("item1", "title1", "descr1", hotkey1);
const item2 = new settings.SettingsItem("item2", "title2", "descr2", mods1);
const item3 = new settings.SettingsItem("item3", "title3", "descr3", key1);

const section1 = new settings.SettingsSection("section1", "title1", "descr1", [
    item0,
    item1,
    item2,
    item3,
]);
const dialog = new settings.SettingsDialog("dialog", $("#settings-dialog"), [section1]);
