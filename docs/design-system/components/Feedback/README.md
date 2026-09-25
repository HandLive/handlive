English | [Tiếng Việt](README.vi.md)

# Feedback

Lightweight feedback after an action — sent, waiting, blocked — shown right where the user is looking,
not as an alert or a notification. It uses several channels at once: icon, text, and haptics (iPhone,
Android).

## By platform

| Platform | Form | Example |
|---------|-----------|-------|
| macOS | The menu bar icon changes to `checkmark` for ~1 second (SF Symbols Magic Replace), then changes back; a status line in the menu the next time it opens | Sending the clipboard from the menu: no window, no notification |
| macOS | A small status line in the open window | "Clipboard waiting to send · 1:45 left" |
| iOS/iPadOS | A glass pill HUD at the top of the screen for ~1.5 seconds + a `success` haptic | "Sent to Lan's Pixel 8" |
| Android (app open) | Like iOS, a glass HUD + a `CONFIRM` haptic | "Sent to Lan's MacBook" |
| Android (app in the background: Quick Settings tile, notification button) | The system toast | "Sent to Lan's MacBook" |

The HUD has no buttons and holds no tasks. Tasks (for example "Send Anyway", "Send Again") go through
`Notification` or live in the screen that's open.

## Wording (CLIP-01)

| Result | Text | Icon |
|---------|-----|-----------|
| Success | "Sent to <device name>" | `checkmark.circle.fill` ↔ `check_circle` (`status-connected`) |
| Not connected | "Not connected — will send if reconnected within 2 minutes" | `clock` ↔ `schedule` (`status-connecting`) |
| Couldn't read | "The clipboard is empty or doesn't contain text" | `exclamationmark.circle` ↔ `error` (`status-offline`) |

Synced with the detailed design (September 25, 2026): CLIP-01 field 11 says "The clipboard is empty…".

## Dos and don'ts

- Do turn off the HUD's sliding motion when Reduce Motion is on (fade in and out only).
- Don't put the content that was just copied into the HUD or a notification.
- Don't confirm the obvious (automatic sync stays silent when everything is normal).
