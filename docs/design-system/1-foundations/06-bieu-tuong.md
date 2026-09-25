English | [Tiếng Việt](06-bieu-tuong.vi.md)

# Icons

HandLive uses SF Symbols on Mac, iPhone, and iPad, and Material Symbols Rounded on Android. This
section covers how to use SF Symbols, the mapping between the two icon sets, the Mac menu bar icon, and
the app icon specification.

HIG source: https://developer.apple.com/design/human-interface-guidelines/icons ·
https://developer.apple.com/design/human-interface-guidelines/sf-symbols ·
https://developer.apple.com/design/human-interface-guidelines/app-icons

## SF Symbols

| Aspect | HandLive |
|---|---|
| Rendering mode | Monochrome by default. Hierarchical for large icons in empty states. Palette and Multicolor only when the color carries meaning. Tint with semantic colors (`label`, `secondary-label`, `accent`) so icons follow the appearance |
| Weight, scale | Weight matches the adjacent text (the symbol takes its weight from `.font`); scale `small`, `medium` (default), `large` through `imageScale(_:)` or `NSImage.SymbolConfiguration` |
| Outline or fill | Toolbars, lists, menus: outline. iOS tab bar: fill (the system chooses). Round call buttons, floating buttons: fill. Unavailable: the slash variant |
| Size | Set with the same text style so the symbol scales with Dynamic Type; don't set a fixed point size |
| Animation | Rare and purposeful (see Motion and haptics). Symbol effects need macOS 14, iOS 17; Magic Replace needs macOS 15, iOS 18 |

- Familiar actions use the HIG's standard icons: copy `document.on.document`, paste
  `document.on.clipboard`, delete `trash`, close `xmark`, done `checkmark`, compose
  `square.and.pencil`, search `magnifyingglass`, more `ellipsis`, account `person.crop.circle`, share
  `square.and.arrow.up`. The `document.*` names exist only in newer SF Symbols releases; older OS
  versions use `doc.on.doc`, `doc.on.clipboard` (check the availability column in the SF Symbols app).
- Menus: use the standard commands (Copy, Paste…) so the system adds their icons itself. Within a
  group, either every item has an icon or none does.
- Don't redraw Apple hardware; use the product symbols (`laptopcomputer`, `iphone`, `ipad`) and don't
  modify them.
- Custom icons: vector (SVG, PDF), optically centered, with an accessibility label.

## Mapping table

Material Symbols Rounded: weight 400, grade 0, optical size 24, FILL 0 unless the Android section
says otherwise.

| Concept | SF Symbol | Material Symbols Rounded |
|---|---|---|
| Android phone | `candybarphone` | `smartphone` |
| Mac | `laptopcomputer` | `laptop_mac` |
| iPhone | `iphone` | `phone_iphone` |
| iPad | `ipad` | `tablet_mac` |
| Same Wi-Fi network | `wifi` | `wifi` |
| Internet connection | `globe` | `public` |
| USB | `cable.connector` | `usb` |
| Copy, send the clipboard | `document.on.document` | `content_copy` |
| Paste | `document.on.clipboard` | `content_paste` |
| Messages | `message` | `chat_bubble` |
| Call, Answer | `phone.fill` | `call` |
| Decline, End | `phone.down.fill` | `call_end` |
| Missed call | `phone.arrow.down.left` | `phone_missed` |
| Mute | `mic.slash.fill` | `mic_off` |
| Hold | `pause.fill` | `pause` |
| Keypad | `circle.grid.3x3.fill` | `dialpad` |
| Camera | `video.fill` | `videocam` |
| Switch camera | `arrow.triangle.2.circlepath.camera` | `cameraswitch` |
| Phone overheating | `thermometer.medium` | `thermostat` |
| QR code | `qrcode` | `qr_code_2` |
| Scan a code | `qrcode.viewfinder` | `qr_code_scanner` |
| Encryption, lock | `lock.fill` | `lock` |
| Warning | `exclamationmark.triangle.fill` | `warning` |
| Information | `info.circle` | `info` |
| Settings | `gearshape` | `settings` |
| Done, selected | `checkmark` | `check` |
| Close, cancel | `xmark` | `close` |
| Delete | `trash` | `delete` |
| Compose a message | `square.and.pencil` | `edit_square` |
| Search | `magnifyingglass` | `search` |
| More commands | `ellipsis` | `more_horiz` |
| Person, contact | `person.crop.circle` | `account_circle` |
| Connection status | `antenna.radiowaves.left.and.right`, `antenna.radiowaves.left.and.right.slash` | `sensors`, `sensors_off` |

Bluetooth: SF Symbols has no Bluetooth icon, so HandLive writes the word "Bluetooth" on every
platform. Android doesn't use `bluetooth` either, so both sides look the same.

## Menu bar icon (macOS)

| State | Icon |
|---|---|
| Connected | `antenna.radiowaves.left.and.right` |
| Connecting | `antenna.radiowaves.left.and.right` with a repeating variable color effect (macOS 14+); with Reduce Motion on, or on macOS 13, the icon stays static and the status is written in the first line of the menu ("Connecting…") |
| Offline, disconnected, not paired | `antenna.radiowaves.left.and.right.slash` |
| Incoming call | `phone.fill` |
| Unread conversations | The status icon, followed right away by the number of conversations as text ("3") |
| Clipboard just sent | `checkmark` for about 1 second, then back to the status icon |

- Always a template image (black and transparent); the system tints it for light and dark menu bars
  and when it's selected. Don't color it, and don't change its color with the status.
- The HIG doesn't give a glyph size; use an SF Symbol so the system fits it into the 24 pt menu bar.
  API: `MenuBarExtra(_:systemImage:isInserted:content:)` (macOS 13); custom images use
  `init(_:image:isInserted:content:)` (macOS 14).

## App icon

| Item | Specification |
|---|---|
| Tool | Icon Composer, exported to Xcode |
| Size, structure | 1024×1024 px for iOS, iPadOS, macOS; one background layer and at least one foreground layer; square, unmasked layers, as SVG or PDF vectors |
| Appearance | Default, dark, clear light, clear dark, tinted light, tinted dark; all six keep the same identifying features |
| Layer colors | Background `brand-ember` (ember red, in place of black); foreground `brand-fire`, `brand-flame` (the signal fire) |
| Don't use | SF Symbols or shapes easily mistaken for symbols, the SF font, Apple hardware, text; don't add shadows, highlights, raised borders, or glow yourself, because the system adds them |
| Current state | No icon yet. Previews use a fire gradient block `brand-flame` → `brand-fire` → `brand-ember` (145°) as a placeholder |

Android: the adaptive icon uses the same background and foreground layers (108 dp layers, 66 dp safe
zone), with a monochrome layer for themed icons (Android 13+); Android crops the shape.

## Android

- Material Symbols Rounded (Apache 2.0) bundled with the app; weight 400, grade 0, 24 dp; 48 dp hit
  target.
- FILL 0 by default; FILL 1 for the selected tab (like fill on iOS), round call buttons, and floating
  buttons.
- Colors come from the tokens (`label`, `secondary-label`, `accent`). The small notification icon is a
  monochrome shape that Android tints.

## Dos and don'ts

| Do | Don't |
|---|---|
| Standard icons for copy, paste, delete | Custom icons for actions that already have a standard one |
| Template symbols in the menu bar | Colored icons in the menu bar |
| Write the word "Bluetooth" | A hand-drawn Bluetooth logo |
| The signal fire in the app icon | SF Symbols in the app icon or logo |
