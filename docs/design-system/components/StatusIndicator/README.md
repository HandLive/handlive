English | [Tiếng Việt](README.vi.md)

# StatusIndicator

Shows how the link between the two devices is doing: an icon tinted with the status color, alongside
text. It's an in-context indicator — the HIG recommends an indicator rather than an alert when the
connection is lost.

## States

| State | Text | SF Symbol ↔ Material | Icon color |
|-----------|-----|----------------------|----------------|
| Connected over the same Wi-Fi network | "Connected via Wi-Fi" (short label "LAN") | `wifi` ↔ `wifi` | `status-connected` |
| Connected over the internet | "Connected over the internet" | `globe` ↔ `public` | `status-connected` |
| Connected over USB (camera) | "Using USB" | `cable.connector` ↔ `usb` | `status-connected` |
| Connecting | "Connecting…" | A pulsing dot | `status-connecting` |
| Phone offline | "Phone offline · last seen 2:05 PM" | `antenna.radiowaves.left.and.right.slash` ↔ `mobile_off` | `status-offline` |
| This device has lost its network | "Connection lost" | `wifi.slash` ↔ `wifi_off` | `status-offline` |
| Needs re-pairing | "Needs re-pairing" | `exclamationmark.triangle.fill` ↔ `warning` | `status-error` |
| Camera live | "Camera live" | A pulsing dot | `status-connected` |

- Synced with the detailed design (September 25, 2026): CONN-01 and PAIR-02 use "Connected via Wi-Fi",
  "Connected over the internet"; "LAN" remains only in the short pill label.
- Text uses `secondary-label`, in the `mac-subheadline` / `ios-subheadline` / `android-subheadline`
  style for both the row and the pill forms; only the icon or dot carries color. Never a colored dot
  alone.
- The pill form (`pill`) is for short labels at the top of popovers and windows: a
  `tertiary-system-fill` background, an icon in the status color, `label` text.
- VoiceOver/TalkBack read the full sentence: "Connected via Wi-Fi to Lan's Pixel 8".
- Pulsing only for "Connecting" and "Camera live", and off when Reduce Motion is on
  (`duration-pulse`).

## Where

The Mac menu bar menu (the first row), the top of the Messages window when the connection is lost,
`DeviceRow` rows, the Devices screen on Android and iPhone, and the call panel when the session is lost
("Lost connection to the phone").

## Dos and don'ts

- Do update in place; don't push a notification on every reconnection.
- Don't use red for an ordinary offline state — offline is gray; red is only for when the user has to
  do something.
