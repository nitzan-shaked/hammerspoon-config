import { Control } from "./control.js";

Control.addCss(".number-control", "/css/controls/number_control.css");


export class NumberControl extends Control {

    constructor(value) {
        const $input = $(document.createElement("input"));
        $input.addClass("number-control");
        $input.attr("type", "number");
        super($input);
        if (value !== undefined)
            this.setValue(value);
    }

    value() {
        return Number(this._$el.val());
    }

    setValue(value) {
        if (!Number.isInteger(value))
            throw new Error("value must be an integer");
        this._$el.val(value);
    }
}
