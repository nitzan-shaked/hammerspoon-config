# Fenstr

My personal "Window Manager", based on Hammerspoon.

## Features

### Win-Mouse, Win-Kbd

I dislike clicking and try to minimize clicks in common actions. To that end, I:

* use a trackpad (tap is better than click, but wait there's more)
* turn on [three-finger drag](https://support.apple.com/en-il/HT204609)
* use the awesome [AutoRaise](https://github.com/sbmpost/AutoRaise)

To complement the above I wrote _**Win-Mouse**_ and _**Win-Kbd**_.

_**Win-Mouse**_ allows you to move windows by simply moving the mouse while holding down certain modifiers. No clicks or right-clicks are involved, no mouse buttons need to be held down, and there's no need to grab window corners or title-bars. Just hover anywhere over a window, and while holding down `Ctrl`+`Cmd` simply move the mouse.

The same can is done for resizing windows, with `Ctrl`+`Option` instead of `Ctrl`+`Cmd`.

(The keys are configurable, but the defaults are such because I find it convenient to switch between moving and resizing windows with just a tiny movement of my left thumb.)

While moving or resizing, window edges _**snap**_ to screen edges, the screen's vertical and horizontal centers, and the edges of other windows.

(_**Win-Mouse**_ is one reason why my iTerm2 windows have no title bar and the thinnest possible border. Not only does this look cleaner, it also saves desktop real-estate.)

https://github.com/nitzan-shaked/fenstr/assets/1918551/cd2a3862-73e2-4233-bc8d-c36bb604be5c

_**Win-Kbd**_ is the keyboard-only counterpart to _**Win-Mouse**_, operating on the focused window instead of the window under the mouse pointer.

Holding down `Ctrl`+`Cmd` and using the arrow keys moves the focused window along a 16x8 grid, while doing the same with `Ctrl`+`Option` instead resizes.

https://github.com/nitzan-shaked/fenstr/assets/1918551/948b974f-a158-44f0-a3b2-da613bd61886

### Hyper (-or-Esc)

With a little from `hidutils`, my CapsLock key is now a new modifier key which I call `Hyper`.

Some variations define Hyper as pressing all four modifiers (`Shift`, `Ctrl`, `Option` and `Cmd`) together, but in my version Hyper is a unique new key in its own right (well, almost). One could a `Hyper`-`Shift`-`k` hotkey (but read the note below).

Actually, my CapsLock key acts in two distinct ways:

* pressed by itself, without any other key, CapsLock acts as Esc. This is great because it's on the home row and large, of which Esc is neither.
* pressed together with other keys (but read the note below), CapsLock acts as `Hyper`+those-keys.

I use `Hyper` for launching applications and performing systems tasks. E.g.:

* `Hyper`+`b` launches a new Chrome window ("Browser")
* `Hyper`+`l` activate the screensaver ("Lock")

_Note_: as a modifier, `Hyper` currently only supports a single non-modifier key together with it. This restriction will be lifted in the future.

### Dark Background

_**Dark Background**_ lets you decrease and increase the desktop wallpaper brightness. When the room is not well lit this can reduce glare and eye strain. (When in focus mode, I dim the wallpaper to the point where it is completely black, removing any visual distractions.)

The default keys are `Ctrl`+`Cmd`+`-` / `Ctrl`+`Cmd`+`=` to decrease / increase the brightness.

Brightness is preserved across restarts.

### Find Mouse Pointer

Press `Ctrl`+`Cmd`+`m` (for "Mouse") to draw a red circle around the mouse pointer for 3 seconds.

It's the same idea as "wiggling your mouse to make the mouse pointer large" in OxX, but much less annoying.

### Visualize Mouse Clicks

When activated, mouse clicks provide visual feedback in the form a circle around the mouse pointer; the circle remains visible as long as the mouse button remains pressed, and collapses into the mouse pointer when the mouse button is released. The circle is yellow for a left click and purple for a right click.

### Visualize Keyboard Presses

a-la the excellent [Key-Castr](https://github.com/keycastr/keycastr), but with:

1. Support for (my) Hyper key
2. Support for modifiers-only chords (e.g. `Cmd`-`Ctrl`)
3. Easier (?) to tweak visualization
4. Support for "linger time" for chords

_**_Note**:_ the functionality and visuals are basic, as this was written for recording the screencasts in this README. It can look nicer, and _maybe_ one day it will.

### Reload Config

The bread-and-butter dev-mode assistant: when files in `~/.hammerspoon` change, this will tell Hammerspoon to reload its `init.lua`.

### Menubar Widget

Click the Fenstr menubar widget for a list of plugins and the ability to enable/disable each. You can also launch the Settings and Hotkeys dialogs (see below).

The menubar widget itself is a plugin, and as such can be disabled.

### Settings Dialog

Pressing `Hyper`-`,` shows the Settings dialog, where you can enable/disable individual plugins and set plugin configurations.

### Hotkeys Dialog

Pressing `Hyper`-`.` shows the Hotkeys dialog, where you can record the hotkey combination for actions provided by the different plugins. A hotkey is a combination of zero or more modifiers and a single non-modifier key. (but see the note under "Hyper" regarding using it with other modifiers.)

An action with no bound hotkey shows as an empty slot with a dashed border.

Clicking a slot turns it red and start the recording. Clicking again cancels the recording.

## Installing

Simply:

```bash
git clone git@github.com:nitzan-shaked/fenstr.git ~/.hammerspoon
```

## Contributing

Feel free to open issues and submit PRs of any kind. Nothing too formal here.

## Hacking

The codebase uses the [Lua Language Server](https://github.com/LuaLS/lua-language-server), which I have installed as a VSCode extension; as such, rudimentary static type hints for the parts of Hammerspoon I use, the way I use them, live under `types/`.

Under `experimental/` you can find stuff I'm working on, which may one day graduate and become first-class features. Currently there are _Live Preview_ (see `experimental/live_preview.md`), some Tiling Window-Manager code, and a menubar widget for controlling the output volume.

Feel free to ignore both `types/` and `experimental/`.

## Caveats

My setup uses one monitor so the codebase is not well-tested on multi-monitor setups. Let me know.
