English | [Tiếng Việt](README.vi.md)

# CallPanel

A small floating window on the Mac for incoming calls and calls in progress (CALL-01…03, AUDIO-03). It
looks like Apple's Continuity call notification: a pane of glass in the top-right corner that doesn't
take focus from the app the user is working in.

**Intentional deviation from the HIG:** the HIG wants panels to hide when their app isn't active, but
an incoming call has to appear right when it happens. So the panel is a non-activating `NSPanel` that
floats on every Space. Each call also has a communication notification (`INStartCallIntent`): passive
while the panel is showing (it goes only to Notification Center, with no banner on top), time-sensitive
when a Focus is on and the panel isn't shown.

## States

| State | Content | Controls |
|-----------|---------|-----------|
| Ringing | Avatar, name or number ("No Caller ID", "Unknown Caller"), "Incoming call · SIM 1" (the SIM label when there are two SIMs) | Decline (`call-decline-fill`, left) · Answer (`call-accept-fill`, right); text buttons "Decline with Message…", "Ignore" |
| Ringing, with Take Calls on Mac turned on | Same as above | Answer splits into "Answer on Phone" and "Answer on Mac" |
| In a call | "In call · 02:15" (`timer`), "Audio: Phone" or "Audio: Mac" | "Switch to Mac" / "Switch to Phone"; End (red) |
| In a call, with the Mac connected to the phone over Bluetooth | Same as above | Adds Mute, Hold / Resume, Keypad (toggle buttons, not switches) |
| Call waiting | A lower line: the name or number of the waiting caller | Over Bluetooth: "Decline Waiting Call", "End & Answer", "Hold & Answer"; without it: "Handle it on the phone or connect Bluetooth" |

Mute, Hold, and Keypad are only available over Bluetooth HFP. When the Mac isn't connected, **hide**
these three buttons and replace them with the line "Connect to the phone over Bluetooth to hold, use
the keypad, or mute" (CALL-03 E2). Errors show right in the panel: "The phone couldn't perform this
action", "Disconnected from the phone".

## Behavior

- 340 pt wide, in the top-right corner of the active screen, 16 pt from the edges; draggable; glass
  material (`.hudWindow`/`.popover` before macOS 26); `radius-panel` corners.
- Keys: Return = Answer, ⌘⌫ = Decline, Esc = Ignore (closes the panel and silences the ringing on the
  Mac, without declining).
- A Focus is on → no panel, no ringing; the notification is time-sensitive so the system decides based
  on the caller; the call is still in `MenuBarMenu`. The Focus status can't be read (missing
  permission) → show the panel without ringing. This deviates from CALL-01 E4.
- The panel closes when the call ends; it never closes on a timer.
- Round icon-only buttons must have an accessibility label and a tooltip ("Mute the microphone on the
  Mac").

## Dos and don'ts

- Do keep Decline on the left and Answer on the right in every state; the two differ in color, icon
  (`phone.down.fill` / `phone.fill`), and position.
- Don't answer automatically; clicking an empty area does nothing.
- Don't change the colors of the two buttons to follow the system accent color.
