import { Control, CheckboxControl, ColorControl } from "/js/controls/index.js";

Control.addCss(".settings-item", "/css/settings/settings_item.css");


export class SettingsItem extends Control {

    constructor(name, title, descr, control) {
        if (!(control instanceof Control))
            throw new Error("control must be an instance of Control");

        const div = $(document.createElement("div"));
        div.addClass("settings-item");

        if (title) {
            const $title_p = $(document.createElement("p"));
            $title_p.addClass("title");
            $title_p.text(title);
            div.append($title_p);
        }

        const $descr_p = $(document.createElement("p"));
        $descr_p.addClass("description");
        $descr_p.text(descr);

        if ((control instanceof ColorControl) || (control instanceof CheckboxControl)) {
            const $container = $(document.createElement("label"));
            $container.addClass("control-container");
            $container.append(control._$el);
            $container.append(" ");
            $descr_p.addClass("side-by-side");
            $container.append($descr_p);
            div.append($container);
        } else {
            div.append($descr_p, control._$el);
        }

        super(div);
        this._name = name;
        this._control = control;
    }

    value() {
        return this._control.value();
    }
}
