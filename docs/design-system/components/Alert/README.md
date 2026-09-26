English | [Tiếng Việt](README.vi.md)

# Alert

Asks for confirmation before an action that can't be undone, or reports an error the app can't recover
from on its own. HandLive uses alerts very rarely: a lost connection, a failed send, or a missing
permission all show in place (`StatusIndicator`, `GroupedList`), not as an alert.

## When to use

| Situation | macOS | iOS/iPadOS and Android |
|-----------|-------|-----------------------|
| Unpair (PAIR-03) — the user chose it deliberately | A sheet-style alert attached to the Settings window: "Cancel" + "Unpair" (default, on the right) | An action sheet rising from the row just tapped: "Unpair" in red at the top, "Cancel" at the bottom |
| Delete all HandLive data, remove the device from the server (SET-02 field 28) | Same as above, with "Delete All" or "Remove from Server" | Same as above, with "Delete All" or "Remove from Server" |
| An error that can't recover on its own (for example, installing the virtual camera failed) | An alert with a button that leads to the fix | Alert |
| Connection lost, failed send, missing permission | No alert | No alert |

## Content

- The title states the exact situation, in two lines at most; a complete question with a question mark:
  "Unpair Lan's Pixel 8?". Don't use "Error" or error codes.
- A message only when it helps: state the consequence and the way back ("To use it again, you'll need
  to scan a new QR code.").
- At most three buttons, 1–2 words each, verbs. The cancel button is always "Cancel", placed on the left
  (horizontal row) or at the bottom (column), and it's never the default. "OK" only for purely
  informational alerts.
- On the Mac, the destructive (red) style is only for actions the user did **not** choose
  deliberately; an action they just chose is a regular default button. In action sheets on
  iPhone/Android, the destructive action is always red and at the top.

## API

SwiftUI `alert(_:isPresented:actions:message:)`,
`confirmationDialog(_:isPresented:titleVisibility:actions:)` (iOS 16, macOS 13) with
`ButtonRole.destructive` /`.cancel`; AppKit `NSAlert.beginSheetModal(for:)`. Android: `HLAlert`,
`HLActionSheet` built to the same specification (glass, capsule), not Material's `AlertDialog`.

## Dos and don'ts

- Do make Esc (Mac) and tapping outside (action sheet) equivalent to "Cancel".
- Don't show an alert right as the app opens; don't stack two alerts on top of each other.
