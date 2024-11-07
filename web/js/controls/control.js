export class Control {

    constructor($el) {
        this._$el = $el;
        this._$el.addClass("control");
    }

    value() {
        throw new Error("Not implemented");
    }

    setValue(value) {
        throw new Error("Not implemented");
    }

    static addCss(css_selector, css_url) {
        if (document.querySelector(css_selector))
            return;
        const link = document.createElement("link");
        link.rel = "stylesheet";
        link.href = css_url;
        document.head.appendChild(link);
        return link;
    }
}


Control.addCss(".control", "/css/controls/control.css");
