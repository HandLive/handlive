English | [Tiếng Việt](01-mau-sac.vi.md)

# Color

HandLive uses the system's semantic colors for text, backgrounds, and separators; system colors for
status; green as the accent color for actions; and brand colors only in the content layer. This
section says which token maps to which API and which color is used where.

HIG source: https://developer.apple.com/design/human-interface-guidelines/color

## Principles

- One color, one meaning. Green `accent` means an action; green `status-connected` is a status and
  always comes with text.
- Don't hard-code system colors on Apple platforms. Always call the API (`Color(.label)`,
  `NSColor.windowBackgroundColor` …): Apple changed the system color values on June 9, 2025 and may
  change them again. The hex values in the tokens are only a reference for Android and previews.
- Custom colors have all 4 variants: `light`, `dark`, `light-hc`, `dark-hc`. On Apple platforms,
  declare them as Color Sets in the asset catalog with the High Contrast variant turned on.
- Don't change the meaning of a semantic color: don't use `separator` as a text color, and don't use
  `secondary-label` as a background.

## Semantic colors and APIs

| Token | SwiftUI | UIKit | AppKit | Used for |
|---|---|---|---|---|
| `label` | `.primary` | `.label` | `.labelColor` | Primary text |
| `secondary-label` | `.secondary` | `.secondaryLabel` | `.secondaryLabelColor` | Secondary text |
| `tertiary-label` | `.tertiary` | `.tertiaryLabel` | `.tertiaryLabelColor` | Hints, unavailable items |
| `quaternary-label` | `.quaternary` | `.quaternaryLabel` | `.quaternaryLabelColor` | Decoration |
| `placeholder-text` | `Color(.placeholderText)` | `.placeholderText` | `.placeholderTextColor` | Placeholder text |
| `system-background`, `secondary-`, `tertiary-system-background` | `Color(.systemBackground)` … | `.systemBackground` … | — | iOS screen backgrounds, groups, nested groups |
| `system-grouped-background`, `secondary-`, `tertiary-system-grouped-background` | `Color(.systemGroupedBackground)` … | `.systemGroupedBackground` … | — | Backgrounds of grouped lists, cells, elements inside cells |
| `window-background` | `Color(nsColor: .windowBackgroundColor)` | — | `.windowBackgroundColor` | Mac window background |
| `control-background` | `Color(nsColor: .controlBackgroundColor)` | — | `.controlBackgroundColor` | Background of Mac lists and tables |
| `system-fill` … `quaternary-system-fill` | `Color(.systemFill)` … | `.systemFill` … | `.systemFill` … (macOS 14+) | Switch tracks, text fields |
| `separator` | `Color(.separator)` | `.separator` | `.separatorColor` | See-through separators |
| `opaque-separator` | `Color(.opaqueSeparator)` | `.opaqueSeparator` | — | Opaque separators |
| `link` | `Color.accentColor` | `tintColor` | `.controlAccentColor` | Links; equal to `accent` |

## System colors HandLive uses

| Token | API | Used for |
|---|---|---|
| `system-red` | `.red` · `systemRed` | Decline, End, delete, errors; `badge` |
| `system-orange` | `.orange` · `systemOrange` | Connecting, needs attention |
| `system-green` | `.green` · `systemGreen` | Connected; switch on (the iOS default) |
| `system-yellow` | `.yellow` · `systemYellow` | Rare ("Fire feeds Earth"), illustrations only |
| `system-pink`, `system-purple` | `.pink`, `.purple` | Letter avatars, illustrations (Fire) |
| `system-brown` | `.brown` | Letter avatars, used sparingly (Earth) |
| `system-gray` … `system-gray-6` | `.gray` · `systemGray` … `systemGray6` | Offline, borders, group backgrounds |

- AppKit has only `systemGray`; Gray 2–6 are iOS colors. On the Mac, use semantic colors
  (`separatorColor`, `controlBackgroundColor`) where iOS uses Gray 2–6.
- Not used ("Water overcomes Fire"): `systemBlue`, `systemCyan`, `systemTeal`, `systemMint`,
  `systemIndigo` — not for the brand, large color areas, status, or avatars. Parts the system draws
  from the user's own choices (accent color, text selection) are left as they are.

## Accent color

| Token | Used for |
|---|---|
| `accent` | Link text, selected icons, `unread`, `focus-ring`. As text it reaches 4.5:1 on every background; never a background behind white text |
| `accent-fill` | Primary button backgrounds, `bubble-outgoing`; it's the value of the `AccentColor` Color Set on Apple platforms (4 appearances), so the system's prominent buttons keep white text at ≥ 4.5:1 in the Dark appearance |
| `on-accent` | Text and icons on `accent-fill` |
| `accent-tint` | Light selection background. Don't put `accent` text smaller than 13 pt on it |

- Apple: the `AccentColor` Color Set takes the `accent-fill` value (4 variants; the app target sets
  `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`); system controls pick it up on their
  own; custom controls use `Color.accentColor` or `NSColor.controlAccentColor` for backgrounds and
  `accent` for text, links, and icons.
- Restraint: one tinted button per screen, two at most. Distinguish priority with the button style,
  not the size.
- macOS: the app's accent color shows only when the user leaves Accent color set to Multicolor (System
  Settings › Appearance). If the user chooses another color, controls follow it; HandLive doesn't
  force green. Colors with a fixed meaning (status, call buttons) don't change with it. When Graphite
  is chosen, window backgrounds take on a tint from the wallpaper, so custom controls in their neutral
  state should be slightly translucent.
- Liquid Glass: tint only the background of one primary action on glass
  (`.buttonStyle(.glassProminent)`, `Glass.tint(_:)`); don't tint text or icons on glass; don't tint
  several controls at once. Status dots on glass are allowed.
- Intentional deviation: links use `accent` instead of the system's blue `link` color ("Water
  overcomes Fire"); links always sit in a clear context and never rely on color alone.

## Status

| Status | Dot, icon | Small colored text | Accompanying text |
|---|---|---|---|
| Connected | `status-connected` (systemGreen) | `text-green` | "Connected" |
| Connecting, needs attention | `status-connecting` (systemOrange) | `text-orange` | "Connecting…" |
| Offline | `status-offline` (systemGray) | `secondary-label` | "Offline" |
| Error | `status-error` (systemRed) | `text-red` | "Needs to be paired again" |

- In the Light appearance, systemGreen and systemOrange reach only 1.9–2.3:1 on white or gray
  backgrounds: use them only for dots and icons. Small colored text uses `text-red`, `text-orange`,
  `text-green` (≥ 4.5:1 on every background, in all 4 appearances).
- Status text is `label` or `secondary-label` by default; color it only when the color adds meaning,
  for example the reason a feature isn't available yet, written in `text-orange`.
- `destructive-text` (= `text-red`) for text-style destructive buttons. `badge` (= `system-red`) for
  numeric badges: use the system badge API, don't draw your own.

## Call buttons

| Token | Button | Notes |
|---|---|---|
| `call-accept-fill` | Answer | Darker than systemGreen so the white icon reaches ≥ 3:1 (systemGreen only reaches 2.2:1) |
| `call-decline-fill` | Decline, End, solid destructive buttons | White text ≥ 4.5:1 |
| `on-call-fill` | Icons and text on the two backgrounds above | White |

Always pair them with differently shaped icons (`phone.fill`, `phone.down.fill`), fixed positions
(Decline on the left, Answer on the right), and a text label under each button.

## Red, green, and color blindness

- People with color blindness have trouble telling red from green. Every red–green pair in HandLive
  must differ on all three levels: icon, position, text.
- When Differentiate Without Color is on, status dots become shaped icons: `checkmark.circle.fill`
  (connected), `ellipsis.circle.fill` (connecting), `exclamationmark.triangle.fill` (error),
  `record.circle` (camera live). Android has no such setting, so it always shows the status text.

## Increased contrast

System colors switch to their high-contrast variants on their own; custom colors take `light-hc`,
`dark-hc`. How to read the setting and test it: see Dark Mode and increased contrast.

## Tokens on Android

- The tokens are the only source of color: generate four Compose color schemes (`light`, `dark`,
  `light-hc`, `dark-hc`), chosen by `isSystemInDarkTheme()` and `UiModeManager.getContrast()`
  (Android 14+; at ≥ 0.5 use the `-hc` set).
- Don't use dynamic color (Material You) or Material color schemes.
- Colors with alpha (`separator`, `system-fill`, `glass-fill` …) are drawn over the background of
  the right layer, not converted into solid colors.
- The token version of `secondary-label` is darker than Apple's original value (75% instead of 60% in
  Light) to reach 4.5:1; on Apple platforms, keep using the system's `.secondary`.

## Dos and don'ts

| Do | Don't |
|---|---|
| Call the semantic color APIs on Apple platforms | Copy the hex `#FF383C` into Swift code |
| Tint one primary button per screen | Tint every button with `accent-fill` |
| Use `text-*` for small colored text | Small text in `system-green`, `system-orange` |
| Keep vermilion in the content layer | Buttons or status in `brand-fire` |
