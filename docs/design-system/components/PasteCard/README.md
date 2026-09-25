English | [Tiếng Việt](README.vi.md)

# PasteCard

The Clipboard tab on iPhone and iPad (CLIP-04): send what was just copied to the phone, and view and
copy again what was just received. iOS doesn't let apps read the clipboard in the background, so
people send with one tap on the system **Paste** button.

## Anatomy

| Part | Specification |
|------|---------|
| Send | A "Send to Lan's Pixel 8" card with `PasteButton` (SwiftUI) / `UIPasteControl` (UIKit) — the system paste button, which does **not** trigger the "Allow Paste" dialog; tinted `accent`, capsule-shaped; a one-line explanation under the button |
| Result | The `Feedback` HUD "Sent to Lan's Pixel 8" + a `success` haptic; when not connected: "Not connected — will send if reconnected within 2 minutes" |
| Last received | A content card (text trimmed to 3 lines, or a thumbnail), the line "From Lan's Pixel 8 · 2:05 PM", a "Copy" button (`document.on.document`) |
| Sensitive content | The content isn't shown, only "Sensitive content hidden" |
| Empty | "Nothing Received Yet" and a sentence explaining how to copy on the phone |

The tab bar (floating glass on iOS 26 and later): "Clipboard", "Messages" (with an unread count badge
in `badge`), "Calls", "Settings"; filled icons, the selected tab in `accent`.

## Android

Android is the hub, so it has no such tab: manual sending goes through the "Send Clipboard" Quick
Settings tile, the button in the ongoing notification, or the share sheet — all of them Android
interfaces. Auto-Send on Copy is turned on in Settings (it needs Accessibility; see
`ConsentSheet`).

## Dos and don'ts

- Do make the Paste button the first action, within easy reach; don't add a second paste button.
- Don't read the clipboard in code when the app opens (that would trigger iOS's permission prompt).
- Don't keep a long history; only the most recently received item.
