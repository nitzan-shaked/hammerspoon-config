//==============================================================================

class Control {
  constructor($el) {
    this._$el = $el;
    this._$el.addClass("control");
  }

  value() { throw new Error("Not implemented"); }

  setValue(value) { throw new Error("Not implemented"); }
}

//==============================================================================

class CheckboxControl extends Control {
  constructor(value) {
    const $input = $(document.createElement("input"));
    $input.attr("type", "checkbox");
    super($input);
    if (value !== undefined)
      this.setChecked(value);
  }

  value() { return this.isChecked(); }

  setValue(value) { this.setChecked(value); }

  isChecked() { return this._$el.prop("checked"); }

  setChecked(is_checked) {
    if (typeof is_checked !== "boolean")
      throw new Error("is_checked must be a boolean");
    this._$el.prop("checked", is_checked);
  }
}

//==============================================================================

class NumberControl extends Control {
  constructor(value) {
    const $input = $(document.createElement("input"));
    $input.attr("type", "number");
    super($input);
    if (value !== undefined)
      this.setValue(value);
  }

  value() { return Number(this._$el.val()); }

  setValue(value) {
    if (!Number.isInteger(value))
      throw new Error("value must be an integer");
    this._$el.val(value);
  }
}

//==============================================================================

class ColorControl extends Control {
  constructor(value) {
    const outer_div = document.createElement("div");
    const $outer_div = $(outer_div);
    $outer_div.addClass("color-picker");

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

  value() { return this._pickr.getSelectedColor().toHEXA().toString(); }

  setValue(value) { this._pickr.setColor(value); }
}

//==============================================================================

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
    $div.css({top: "50%", left: "50%", transform: "translate(-50%, -50%)"});
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
      console.error("Invalid valign: " + valign);
    }
    if (halign == "left") {
      $div.css({left: h_margin});
    } else if (halign == "center") {
      $div.css({left: "50%", transform: "translateX(-50%)"});
    } else if (halign == "right") {
      $div.css({right: h_margin});
    } else {
      console.error("Invalid halign: " + halign);
    }
  }

  if (font_size) {
    $div.css({fontSize: font_size});
  }

  return $div;
}

class KeyControl extends Control {
  constructor(name, options, labels) {
    const base_size = 48;
    const w = options.w || 1.0;

    const $key_div = $(document.createElement("div"));
    $key_div.addClass("key");

    const $key_top_div = $(document.createElement("div"));
    $key_top_div.addClass("key-top");

    const $key_labels_div = $(document.createElement("div"));
    $key_labels_div.addClass("key-labels");
    $key_labels_div.css({
      position: "relative",
      height:   `${base_size}px`,
      width:    `${base_size * w}px`,
    });

    for (let label of labels) {
      $key_labels_div.append(_mk_key_label(label));
    }

    $key_top_div.append($key_labels_div);
    $key_div.append($key_top_div);

    super($key_div);
    this._name = name;
  }

  value() { return this._name; }
}

//==============================================================================

function _mk_key(key_name) {
  if (key_name == "shift") {
    return new KeyControl("shift", {w: 1.2}, [{
      label: "⇧",
      valign: "bottom",
      halign: "left",
    }]);
  } else if (key_name == "hyper") {
      return new KeyControl("ctrl", {w: 1.8}, [{
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
  } else if (key_name.match(/^__(.*)__$/)) {
    let match = key_name.match(/^__(.*)__$/);
    let special_key_name = match[1];
    let label = {
      "blank": "(blank)",
      "recording": "(rec)",
    }[special_key_name];
    let k = new KeyControl(key_name, {w: 1.5}, [{
      label: label,
    }]);
    k._$el.addClass("special-key");
    k._$el.addClass("special-key-" + special_key_name);
    return k;
  } else {
    if (key_name.length > 1) {
      console.error("Invalid key name: " + key_name);
      return;
    }
    return new KeyControl(key_name, {}, [{
      label: key_name.toUpperCase(),
    }]);
  }
}

class KeysListControl extends Control {
  constructor(value) {
    const $outer_div = $(document.createElement("div"));
    $outer_div.addClass("keys-list");

    const $content_div = $(document.createElement("div"));
    $content_div.addClass("content");

    const $clear_div = $(document.createElement("div"));
    $clear_div.addClass("clear");

    const $clear_content_div = $(document.createElement("div"));
    $clear_content_div.addClass("clear-content");
    $clear_content_div.text("⨯");

    $clear_div.append($clear_content_div);
    $clear_div.on("click", e => {
      this.setValue([]);
      e.stopPropagation();
    });

    $outer_div.append($content_div);
    $outer_div.append($clear_div);

    super($outer_div);
    this._keys = [];
    this._$content_div = $content_div;
    this._$clear_div = $clear_div;
    if (value === undefined) {
      value = [];
    }
    this.setValue(value);
    $outer_div.on("click", e => {
      record_hotkey(this);
      e.stopPropagation();
    });
  }

  value() { return this._keys.map(key => key.value()); }

  setValue(value) {
    if (!Array.isArray(value))
      throw new Error("value must be an array");
    this._clear();
    for (let key_name of value)
      this._addKey(_mk_key(key_name));
    if (!this._keys.length) {
      this._$content_div.append(_mk_key("__blank__")._$el);
    }
  }

  startRecording() {
    this._$el.addClass("recording");
    this._clear();
    this._$content_div.append(_mk_key("__recording__")._$el);
  }

  stopRecording(value) {
    this._$el.removeClass("recording");
    this.setValue(value);
  }

  _clear() {
    this._keys = [];
    this._$content_div.empty();
    this._$el.addClass("empty");
  }

  _addKey(key) {
    if (!(key instanceof KeyControl))
      throw new Error("key must be an instance of KeyControl");
    this._keys.push(key);
    this._$content_div.append(key._$el);
    this._$el.removeClass("empty");
  }
}

//==============================================================================

function record_hotkey(key_list_control) {

  const modifier_name_xlat = {
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

    "capslock": "hyper",
    "f18": "hyper",
  }

  let recorded_modifiers = {};
  let recorded_key = null;
  const _origHandleKey = Mousetrap.prototype.handleKey;

  function start_recording() {
    key_list_control.startRecording();
    Mousetrap.prototype.handleKey = _handleKey;
  }

  function stop_recording() {
    let new_value = [];
    for (let modifier of ["hyper", "ctrl", "option", "cmd", "shift"])
      if (recorded_modifiers[modifier])
        new_value.push(modifier);
    if (recorded_key)
      new_value.push(recorded_key);
    key_list_control.stopRecording(new_value);
    Mousetrap.prototype.handleKey = _origHandleKey;
  }

  function _handleKey(character, modifiers, e) {
    e.preventDefault();
    e.stopPropagation();

    if (e.type == "keyup") {
      if (Object.keys(recorded_modifiers).length || recorded_key) {
        stop_recording();
      }

    } else if (e.type == "keydown") {
      const modifier = modifier_name_xlat[character];
      if (modifier) {
        recorded_modifiers[modifier] = true;
      } else if (character.length == 1) {
        recorded_key = character;
        stop_recording();
      }
    }

  }

  start_recording();
}

//==============================================================================

class SettingsItem extends Control {
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

  value() { return this._control.value(); }
}

//==============================================================================

class SettingsItemContainer extends Control {
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
    if (!(child instanceof SettingsItem) && !(child instanceof SettingsItemContainer))
      throw new Error("child must be an instance of SettingsItem or SettingsItemContainer");
    this._children.push(child);
    this._$el.append(child._$el);
  }
}

class Section extends SettingsItemContainer {
  constructor(name, title, descr, items) {
    const $div = $(document.createElement("div"));
    $div.addClass("section");
    const $h1 = $(document.createElement("h1"));
    $h1.text(title);
    $div.append($h1);
    if (descr) {
      const $p = $(document.createElement("p"));
      $p.addClass("description");
      $p.addClass("section-description");
      $p.text(descr);
      $div.append($p);
    }
    super(name, $div, items);
  }
}

class SettingsDialog extends SettingsItemContainer {
  constructor(name, $el, sections) {
    $el.addClass("settings-dialog");
    super(name, $el, sections);
  }
}

//==============================================================================
