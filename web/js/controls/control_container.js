import { Control } from "./control.js";

Control.addCss(".control-container", "/css/controls/control_container.css");


export class ControlContainer extends Control {
    constructor(name, $el, children) {
        super($el);
        this._name = name;
        this._children = [];

        if (children) {
            if (Array.isArray(children)) {
                for (let child of children)
                    this.addChild(child);
            } else {
                this.addChild(children);
            }
        }
    }

    value() {
        let values = {};
        for (let child of this._children)
            values[child._name] = child.value();
        return values;
    }

    addChild(child) {
        if (!(child instanceof Control) && !(child instanceof ControlContainer))
            throw new Error("child must be an instance of Control or ControlContainer");
        this._children.push(child);
        this._$el.append(child._$el);
    }
}
