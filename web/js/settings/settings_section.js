import { Control, ControlContainer } from "/js/controls/index.js";

Control.addCss(".settings-section", "/css/settings/settings_section.css");


export class SettingsSection extends ControlContainer {

    constructor(name, title, descr, items) {
        const $div = $(document.createElement("div"));
        $div.addClass("settings-section");

        const $h1 = $(document.createElement("h1"));
        $h1.addClass("title");
        $h1.text(title);
        $div.append($h1);

        if (descr) {
            const $p = $(document.createElement("p"));
            $p.addClass("description");
            $p.text(descr);
            $div.append($p);
        }
        super(name, $div, items);
    }
}
