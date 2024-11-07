import { Control } from "./control.js";

Control.addCss(".key-control", "/css/controls/key_control.css");


export class KeyControl extends Control {
    constructor(name, options, labels) {
        const BASE_SIZE = 48;
        const w = options.w || 1.0;

        const $key_div = $(document.createElement("div"));
        $key_div.addClass("key-control");

        const $key_top_div = $(document.createElement("div"));
        $key_top_div.addClass("key-top");

        const $key_labels_div = $(document.createElement("div"));
        $key_labels_div.addClass("key-labels");
        $key_labels_div.css({
            position: "relative",
            height:   `${BASE_SIZE}px`,
            width:    `${BASE_SIZE * w}px`,
        });

        for (let label of labels)
            $key_labels_div.append(_mk_key_label(label));

        $key_top_div.append($key_labels_div);
        $key_div.append($key_top_div);

        super($key_div);
        this._name = name;
    }

    value() {
        return this._name;
    }

    static mk_key(key_name) {
        if (key_name == "shift") {
            return new KeyControl("shift", {w: 1.2}, [{
                label: "⇧",
                valign: "bottom",
                halign: "left",
            }]);

        } else if (key_name == "hyper") {
            return new KeyControl("hyper", {w: 1.8}, [{
                label: "⏺",
                valign: "top",
                halign: "left",
                font_size: "12px",
            }, {
                label: "caps lock",
                valign: "bottom",
                halign: "left",
                font_size: "10px",
            }]);

        } else if (key_name == "ctrl" || key_name == "control") {
            return new KeyControl("ctrl", {w: 1.2}, [{
                label: "⌃",
                valign: "top",
                halign: "left",
                font_size: "18px",
            }, {
                label: "control",
                valign: "bottom",
                halign: "right",
                font_size: "10px",
            }]);

        } else if (key_name == "option" || key_name == "alt") {
            return new KeyControl("option", {w: 1.2}, [{
                label: "⌥",
                valign: "top",
                halign: "right",
            }, {
                label: "option",
                valign: "bottom",
                halign: "right",
                font_size: "10px",
            }]);

        } else if (key_name == "cmd" || key_name == "command") {
            return new KeyControl("cmd", {w: 1.2}, [{
                label: "⌘",
                valign: "top",
                halign: "right",
            }, {
                label: "command",
                valign: "bottom",
                halign: "right",
                font_size: "10px",
            }]);

        } else {
            if (key_name.length > 1)
                throw new Error(`Invalid key name: ${key_name}`);
            return new KeyControl(key_name, {}, [{
                label: key_name.toUpperCase(),
            }]);
        }
    }
}


function _mk_key_label(options) {
    const label = options.label || "";
    const valign = options.valign || "middle";
    const halign = options.halign || "center";
    const font_size = options.font_size;

    const $div = $(document.createElement("div"));
    $div.addClass("key-label");
    $div.text(label);
    $div.css({position: "absolute"});

    if (valign == "middle" && halign == "center") {
        $div.css({
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
        });

    } else {
        const v_margin = "4px";
        const h_margin = "4px";

        if (valign == "top") {
            $div.css({top: v_margin});
        } else if (valign == "middle") {
            $div.css({top: "50%", transform: "translateY(-50%)"});
        } else if (valign == "bottom") {
            $div.css({bottom: v_margin});
        } else {
            throw new Error("Invalid valign: " + valign);
        }

        if (halign == "left") {
            $div.css({left: h_margin});
        } else if (halign == "center") {
            $div.css({left: "50%", transform: "translateX(-50%)"});
        } else if (halign == "right") {
            $div.css({right: h_margin});
        } else {
            throw new Error("Invalid halign: " + halign);
        }
    }

    if (font_size)
        $div.css({fontSize: font_size});

    return $div;
}
