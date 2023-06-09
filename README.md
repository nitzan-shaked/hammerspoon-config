# My Personal Hammerspoon Config

This is my personal Hammerspoon setup, placed here with the hopes that you find it (or parts of it -- everybody's flow is different) useful.

Some of the features, I believe, are unique, while others (as I've come to realize recently, while cleaning up the code) are also available elsewhere.

## What's here

### Moving and resizing windows

I dislike clicking and try to minimize clicks involved in common actions. To that end, I:

* use a trackpad (tap is better than click, but wait there's more)
* turn on [three-finger drag](https://support.apple.com/en-il/HT204609)
* use [AutoRaise](https://github.com/sbmpost/AutoRaise)

To complement the above I wrote _**Drag-to-Move**_ and _**Drag-to-Resize**_, which I suppose should really be called _move to move_ and _move to resize_.

_**Drag-to-Move**_ lets you move the window under the mouse cursor as you move the mouse. There are no clicks / right-clicks involved, no need to keep a mouse button (or the trackpad) pressed, and no need to grab any specific part of the window (e.g. title bar) in order to move it. Just hover anywhere in the window, and while pressing CTRL-CMD simply move the mouse.

_**Drag-to-Resize**_ does the same for resizing a window, by pressing CTRL-OPTION instead of CTRL-CMD.

I find the keys used convenient as the only thing required to switch between moving and resizing windows is a tiny movement of the left thumb, but naturally the keys used can be configured.

While in either mode, window edges _**snap**_ to screen edges, the screen's vertical and horizontal centers, and the edges of other windows. Which edges snap to what is configurable.

These featues are one reason why my iTerm2 windows have no title bar whatsoever, and the thinnest possible border. I think this looks more pleasant and clean, and saves desktop real-estate on my 13" laptop.

	**TODO** add screen recording here

The keyboard-only counterparts of the above are _**Kbd-to-Move**_ and _**Kbd-to-Resize**_, operating on the focused window rather than the window under the mouse cursor.

Pressing CTRL-CMD (same as _drag-to-move_) and using the arrow keys moves the focused window's top-left corner along a 16x8 grid while maintaining its size.

Doing the same with CTRL-OPTION (same as _drag-to-resize_) moves the focused window's bottom-right corner along the same grid, keeping its top-left corner fixed.

Finally, _**Kbd-to-Place**_ both moves and resizes the focused window so as to fill a particular part of the screen. Press CTRL-CMD with:

* `1` / `2` / `3` -- to place the focused window in the left / middle / right third of the screen.
* `o` / `p` / `l` / `;` -- to place the focused window in the {left / right} x {top / bottom} quadrant of the screen.
* `[` / `]` -- to place the focused window in the left / right half of the screen.
* `/` -- to make the focused window full size (but not enter "Full Screen").
* `,` -- to center the focused window, keeping its size.

-
    **TODO** add screen recording here

### Hyper-or-Esc

With a little Karabiner-Elements magic (see "Installing") my CAPS key is now a new modifier key called HYPER.

Some variations define HYPER as "the same as pressing the 4 modifiers SHIFT, CTRL, OPTION and CMD together", as if a musical chord. In my version, HYPER is a unique new key in its own right. You could imagine, for example, a HYPER-SHIFT-K hotkey.

As a matter of fact, my CAPS key is one of two things:

* pressed by itself, CAPS acts as ESC. This is great because it's on the home row and large, which ESC is neither.
* pressed together with another key, CAPS acts as HYPER + that-key.

I mostly use HYPER for launching some favorite applications:

* HYPER-`b` -- launch a new Chrome window ("Browser")
* HYPER-`f` -- launch a new Finder window ("Finder")
* HYPER-`t` -- launch a new iTerm2 window ("Terminal")
* HYPER-`n` -- launch Notes ("Notes")
* HYPER-`k` -- launch KeePass ("Keepass")

I also use HYPER for specific functionality:

* HYPER-`m` -- activate Mini-Preview (see "Mini-Preview")
* HYPER-`=` -- decrease background brightness (see "Dark-Bg")
* HYPER-`=` -- increase background brightness (see "Dark-Bg")
* HYPER-`l` -- activate screensaver ("Lock")

### Mini-Preview

When focusing I have few windows open, and in particular I have all my messaging apps minimized and on "do not disturb".

I sometimes find myself, however, blocked or semi-blocked by others: I might need to ask them a question, or have them perform some action such as granting me permissions, for example. I then write them a message, and if they respond immediately then great: I re-minimize the messaging app and go back to being focused.

But if they don't immediately respond, however, I face a dillema:

* if I re-minimize the messaging app and go back to being focused I won't know when they do respond, and it might be an hour or more before I remember to check. This makes for inefficient communication, with async interactions that can span the whole day.

* if I keep the messaging app open then my regular flow is interrupted, mostly because it takes up screen real-estate that, in my workflow, "belongs to something else".

Ideal for me would be to make the messaging app really tiny and stick it in a corner of the screen, half transparent and hovering over whatever else is there, for a few minutes while I wait for a response.

But alas that is impossible: WhatsApp and Slack, for example, can't be made really small; even their smallest size is too large for me. What's more, their internal layout changes to something not so friendly in small sizes. Finally, they can't be made transparent and hovering.

Enter _**Mini-Preview**_, which does basically that. When _Mini-Preview_ is activated (HYPER-`m`) the window under the mouse cursor is replaced with a smaller version of itself called its "mini preview". This mini preview window is:

1. Smaller, but its size and position are adjustable with _drag-to-move_ and _drag-to-resize_.
2. Semi-transparent.
3. Floating, or "always on top".
4. Read Only, and cannot be interacted with: mouse and keyboard events do not get forwarded to the original window, but are rather discarded.
5. Regularly updated, such that you always see what's happening in the original window.

Pressing `x` or `q` while hovering over the mini preview closes it and restores the original window.

During that time, the original window gets sent to "almost off-screen": as far right and down as OSX will allow (which means you can barely see its top-left corner in the bottom-right part of the screen.)

    **TODO** add screen recording here

### Dark-Bg

### Highlight-Mouse

### Reload-Config

## Installing

* Karabiner Elements
* in Karabiner Elements, add a mapping from CAPSLOCK to F18
* in OSX Keyboard Modifier Preferences panel, disable CAPSLOCK

* git clone into ~/.hammerspoon

* not in Spoons/ format now, because ...

## Contributing

* By all means send PRs / Bug Reports

## Hacking

* How to change visual styles
* How to change hotkeys
* Lua-LS and the dir `types/`

## Caveats

* My Lua is informal (but by all means help with PRs)
* Was not tested on different setups
* in particular, was not tested on multi-monitor / multi-spaces setup
* No release process per-se
* TODO is possibly not up-to-date

## Resources

A good place to start looking would be [Evan Travers' blog](https://evantravers.com/), which has nice writeups and links to other resources as well. It is 

## APPENDIX

[ HIGHLIGHT MOUSE ]

* draws a red circle around the mouse cursor for a few seconds, making it easy
  to visually locate the mouse cursor
* activate with `CMD`-`CTRL`-`m`

[ DARK-BG ]

* press `Hyper`-`-` to decrease the brightness of the desktop background
* press `Hyper`-`=` to increase the brightness of the desktop background
* brightness is preserved across restarts
