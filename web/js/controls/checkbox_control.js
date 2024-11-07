import { Control } from "./control.js";

Control.addCss(".checkbox-control", "/css/controls/checkbox_control.css");


export class CheckboxControl extends Control {

    constructor(value) {
        const $input = $(document.createElement("input"));
        $input.addClass("checkbox-control");
        $input.attr("type", "checkbox");
        super($input);
        if (value !== undefined)
            this.setChecked(value);
    }

    value() {
        return this.isChecked();
    }

    setValue(value) {
        this.setChecked(value);
    }

    isChecked() {
        return this._$el.prop("checked");
    }

    setChecked(is_checked) {
        if (typeof is_checked !== "boolean")
            throw new Error("is_checked must be a boolean");
        this._$el.prop("checked", is_checked);
    }
}
