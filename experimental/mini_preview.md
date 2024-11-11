# Mini-Preview

When focusing I have few windows open, and in particular I have all my messaging apps minimized and on "do not disturb".

I sometimes find myself, however, blocked or semi-blocked by others: I might need to ask them a question, or have them perform some action such as granting me permissions, for example. I then write them a message, and if they respond immediately then great: I re-minimize the messaging app and go back to being focused.

But if they don't immediately respond, however, I face a dillema:

* if I re-minimize the messaging app and go back to being focused I won't know when they do respond, and it might be an hour or more before I remember to check. This makes for inefficient communication, with async interactions that can span the whole day.

* if I keep the messaging app open then my regular flow is interrupted, mostly because it takes up screen real-estate that, in my workflow, "belongs to something else".

Ideal for me would be to make the messaging app really tiny and stick it in a corner of the screen, half transparent and hovering over whatever else is there, for a few minutes while I wait for a response.

But alas that is impossible: WhatsApp and Slack, for example, can't be made really small; even their smallest size is too large for me. What's more, their internal layout changes to something not so friendly in small sizes. Finally, they can't be made transparent and hovering.

Enter _**Mini-Preview**_, which does basically that. When _Mini-Preview_ is activated (HYPER-`m`) the window under the mouse cursor is replaced with a small snapshot of itself, called its "mini preview". This mini preview window is:

1. Smaller, with its size and position adjustable with _drag-to-move_ and _drag-to-resize_.
2. Semi-transparent.
3. Floating, or "always on top".
4. Read Only, and cannot be interacted with: mouse and keyboard events do not get forwarded to the original window, but are rather discarded.
5. Regularly updated, so you always see what's happening in the original window.

When hovering over the mini preview a faux title bar appears. Clicking the green "zoom" button will close the mini preview and restore the original window.

During that time, the original window gets sent to "almost off-screen": as far right and down as OSX will allow (which means you can barely see its top-left corner in the bottom-right part of the screen.)

https://github.com/nitzan-shaked/hammerspoon-config/assets/1918551/633255d6-bc79-4fe2-a5cf-2ffd438c3eb0
