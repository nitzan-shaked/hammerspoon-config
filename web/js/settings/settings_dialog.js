import { Control, ControlContainer } from "/js/controls/index.js";

Control.addCss(".settings-dialog", "/css/settings/settings_dialog.css");


export class SettingsDialog extends ControlContainer {

    constructor(name, $el, sections) {
        $el.addClass("settings-dialog");
        super(name, $el, sections);
    }
}
