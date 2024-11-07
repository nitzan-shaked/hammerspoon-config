import { Control } from "./control.js";

Control.addCss(".color-control", "/css/controls/color_control.css");


export class ColorControl extends Control {

    constructor(value) {
        const outer_div = document.createElement("div");
        const $outer_div = $(outer_div);
        $outer_div.addClass("color-control");

        const inner_div = document.createElement("div");
        const $inner_div = $(inner_div);
        $outer_div.append($inner_div);

        const pickr = Pickr.create({
            el: inner_div,
            padding: 0,
            default: value,
            theme: "nano",
            comparison: true,
            adjustableNumbers: false,

            components: {
                preview: true,
                opacity: true,
                hue: true,
                closeWithKey: null,
                interaction: {
                    input: true,
                    cancel: true,
                    save: true,
                }
            }
        });

        super($outer_div);
        this._pickr = pickr;

        let curr_color = value;
        pickr.on("save", (color, instance) => {
            curr_color = color.toHEXA().toString();
            pickr.hide();
        });
        pickr.on("cancel", (instance) => {
            pickr.hide();
            pickr.setColor(curr_color, true);
        });

        $outer_div.on("keydown", e => {
            if (e.key === "Enter") {
                pickr.applyColor();  // triggers "save" event
                e.preventDefault();
            } else if (e.key === "Escape") {
                pickr.hide();
                pickr.setColor(curr_color, true);
                e.preventDefault();
            }
        });
    }

    value() {
        return this._pickr.getSelectedColor().toHEXA().toString();
    }

    setValue(value) {
        this._pickr.setColor(value);
    }
}
