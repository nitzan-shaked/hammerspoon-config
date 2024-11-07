import { Control } from "./control.js";
import { KeyControl } from "./key_control.js";

Control.addCss(".keys-list-control", "/css/controls/keys_list_control.css");


class KeyInfo {
    constructor(key_name) {
        this.key_name = key_name;
        this.modifier = MODIFIER_NAME_XLAT[key_name];
        this.is_modifier = (this.modifier !== undefined);
        this.is_regular_key = !this.is_modifier && key_name.length == 1;
    }
}


export class KeysListControl extends Control {

    constructor(value, options) {
        const allow_modifiers = coallesce(options.allow_modifiers, false);
        const allow_regular_keys = coallesce(options.allow_regular_keys, false);
        if (!allow_modifiers && !allow_regular_keys)
            throw new Error("at least one of allow_modifiers or allow_regular_keys must be true");

        const $outer_div = $(document.createElement("div"));
        $outer_div.addClass("keys-list-control");

        const $content_div = $(document.createElement("div"));
        $content_div.addClass("content");

        const $clear_div = $(document.createElement("div"));
        $clear_div.addClass("clear");

        const $clear_content_div = $(document.createElement("div"));
        $clear_content_div.addClass("content");
        $clear_content_div.text("⨯");

        $clear_div.append($clear_content_div);
        $clear_div.on("click", e => {
            this.setValue([]);
            e.stopPropagation();
        });

        $outer_div.append($content_div);
        $outer_div.append($clear_div);

        super($outer_div);
        this.allow_modifiers = allow_modifiers;
        this.allow_regular_keys = allow_regular_keys;
        this._keys = [];
        this._$content_div = $content_div;
        this._$clear_div = $clear_div;
        this._is_recording = false;

        if (value === undefined)
            value = [];
        this.setValue(value);

        $outer_div.on("click", e => {
            e.preventDefault();
            e.stopPropagation();
            if (this._is_recording) {
                cancel_recording();
            } else {
                start_recording(this);
            }
        });
    }

    value() {
        return this._keys.map(key => key.value());
    }

    setValue(value) {
        if (!Array.isArray(value))
            throw new Error("value must be an array");
        this.clear();
        for (let key_name of value)
            if (this.keyAllowed(key_name))
                this._append_key_control(KeyControl.mk_key(key_name));
    }

    clear() {
        this._keys = [];
        this._$content_div.empty();
        this._$el.addClass("empty");
    }

    startRecording() {
        this._is_recording = true;
        this._$el.addClass("recording");
        this.clear();
    }

    stopRecording(value) {
        this._is_recording = false;
        this._$el.removeClass("recording");
        this.setValue(value);
    }

    keyAllowed(key_name) {
        const key_info = new KeyInfo(key_name);
        return (
            (this.allow_modifiers && key_info.is_modifier) ||
            (this.allow_regular_keys && key_info.is_regular_key)
        );
    }

    _append_key_control(key) {
        this._keys.push(key);
        this._$content_div.append(key._$el);
        this._$el.removeClass("empty");
    }
}


const MODIFIER_NAME_XLAT = {
    "shift": "shift",
    "lshift": "shift",
    "rshift": "shift",

    "ctrl": "ctrl",
    "control": "ctrl",
    "lctrl": "ctrl",
    "lcontrol": "ctrl",
    "rctrl": "ctrl",
    "rcontrol": "ctrl",

    "option": "option",
    "loption": "option",
    "roption": "option",

    "alt": "option",
    "lalt": "option",
    "ralt": "option",

    "command": "cmd",
    "lcommand": "cmd",
    "rcommand": "cmd",

    "cmd": "cmd",
    "lcmd": "cmd",
    "rcmd": "cmd",

    "meta": "cmd",
    "lmeta": "cmd",
    "rmeta": "cmd",
}


let _recording_key_list_control = null;
let _orig_handle_key = Mousetrap.prototype.handleKey;
let _recorded_modifiers = {};
let _recorded_regular_key = null;


function start_recording(keys_list_control) {
    if (!(keys_list_control instanceof KeysListControl))
        throw new Error("key_list_control must be an instance of KeysListControl");

    if (_recording_key_list_control)
        stop_recording();

    _recording_key_list_control = keys_list_control;
    _recorded_modifiers = {};
    _recorded_regular_key = null;
    _recording_key_list_control.startRecording();
    Mousetrap.prototype.handleKey = handle_key;
}

function cancel_recording() {
    _recorded_modifiers = {};
    _recorded_regular_key = null;
    stop_recording();
}

function stop_recording() {
    if (!_recording_key_list_control)
        return;
    let new_value = [];
    for (let modifier of ["ctrl", "option", "cmd", "shift"])
        if (_recorded_modifiers[modifier])
            new_value.push(modifier);
    if (_recorded_regular_key)
        new_value.push(_recorded_regular_key);
    _recording_key_list_control.stopRecording(new_value);
    _recording_key_list_control = null;
    Mousetrap.prototype.handleKey = _orig_handle_key;
}

function handle_key(character, modifiers, e) {
    e.preventDefault();
    e.stopPropagation();

    const allow_modifiers = _recording_key_list_control.allow_modifiers;
    const allow_regular_keys = _recording_key_list_control.allow_regular_keys;

    if (e.type == "keyup") {
        if (allow_regular_keys) {
            if (_recorded_regular_key)
                stop_recording();
            return;
        }
        if (allow_modifiers && Object.keys(_recorded_modifiers).length)
            stop_recording();

    } else if (e.type == "keydown") {
        const key_info = new KeyInfo(character);
        if (key_info.is_modifier && allow_modifiers) {
            _recorded_modifiers[key_info.modifier] = true;
        } else if (key_info.is_regular_key && allow_regular_keys) {
            _recorded_regular_key = character;
        }
    }
}

function coallesce(...args) {
    for (let arg of args)
        if (arg !== undefined)
            return arg;
    return undefined;
}
