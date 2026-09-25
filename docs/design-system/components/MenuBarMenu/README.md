English | [Tiếng Việt](README.vi.md)

# MenuBarMenu

The HandLive icon in the Mac menu bar and the **menu** that opens when you click it — per the HIG, a
menu bar extra opens a menu, not a popover. Its content is like the Wi-Fi and Bluetooth menus of macOS:
status at the top, commands in the middle, Settings and Quit at the bottom.

## Menu bar icon

A monochrome template image (the system tints it to match the menu bar background), sized to the 24 pt
menu bar.

| State | SF Symbol |
|-----------|-----------|
| Connected | `antenna.radiowaves.left.and.right` |
| Connecting | same as above, with the variable color effect (off with Reduce Motion) |
| Offline, disconnected | `antenna.radiowaves.left.and.right.slash` |
| Incoming call | `phone.fill` |
| Clipboard just sent | `checkmark` for ~1 second (Magic Replace) — see `Feedback` |
| Unread messages | The number of unread conversations right after the icon ("2"; above 99, "99+") |

## Menu content

1. **Phone:** the device's name as the group header; a status row that can't be clicked, with an icon
   in the status color; when disconnected, "Reconnect Now" is added.
2. **Ringing call** (if any, including after the panel was dismissed with "Ignore"): "Answer",
   "Decline".
3. **Commands:** "Send Clipboard to Phone", "Messages" (the unread count on the right), "Camera
   Preview".
4. **Camera** (while streaming): the status, checkmark items "Phone Microphone" and "Pause Video", the
   "Quality" submenu (Automatic, 480p, 720p, 1080p), "Switch Camera", "Stop Camera".
5. **Recent:** up to three items (missed calls, new messages); choosing an item opens the right place.
6. "Settings…" ⌘, · "Quit HandLive" ⌘Q.

Submenus go one level deep. Within a group, either every item has an icon or none does. Items that
can't be used yet are dimmed, not hidden.

## Show or hide

The user decides: the "Show HandLive in Menu Bar" setting (General), asked during setup, on by default.
When the icon is hidden — or when the system hides some icons because the menu bar is crowded — the app
has a Dock icon, a Dock menu, and its own menu bar, so every function stays reachable.

## API

`MenuBarExtra(_:systemImage:isInserted:content:)` (macOS 13) with `.menuBarExtraStyle(.menu)`;
`Section`, `Toggle` (shown as a checkmark), `Picker` (a submenu), `Divider`, `.keyboardShortcut`. For
two-line rows or colored icons → `NSStatusItem` + `NSMenu`.

## Dos and don'ts

- Do make every command in the menu also available in an app window or the app's menu bar.
- Don't cram the call panel, the camera preview, or a compose field into the menu.
