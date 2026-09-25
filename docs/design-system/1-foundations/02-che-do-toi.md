English | [Tiếng Việt](02-che-do-toi.vi.md)

# Dark Mode and increased contrast

HandLive works correctly in four appearances and always follows the system setting. This section
defines backgrounds, colors, and images in the Dark appearance, and how to test them together with
Increase Contrast and Reduce Transparency.

HIG source: https://developer.apple.com/design/human-interface-guidelines/dark-mode ·
https://developer.apple.com/design/human-interface-guidelines/accessibility

## Four appearances

| Appearance | Token | Active when | Apple | Android |
|---|---|---|---|---|
| Light | `light` | Default | `colorScheme == .light` | `isSystemInDarkTheme()` = false |
| Dark | `dark` | Dark Mode or Auto | `colorScheme == .dark` | `isSystemInDarkTheme()` = true |
| Light · Increased Contrast | `light-hc` | Increase Contrast | `colorSchemeContrast == .increased` | `UiModeManager.getContrast()` ≥ 0.5 (Android 14+) |
| Dark · Increased Contrast | `dark-hc` | Dark and Increase Contrast | same as above | same as above |

- The app has no appearance switch of its own, and HandLive's Settings have no "Appearance" item. Per
  the HIG, an app-specific switch makes people adjust settings in several places and can make them
  think the app is broken.
- Auto mode changes the appearance while the app is open: don't store resolved colors; always use
  dynamic colors and the tokens of the current appearance.
- AppKit reads `NSApp.effectiveAppearance`; don't set `NSApp.appearance`.

## Base and elevated backgrounds

- iOS and iPadOS: Dark backgrounds come in two sets. Base is darker and recedes; elevated is lighter
  and comes forward. The system switches to elevated for sheets, popovers, and windows in multitasking
  when the view uses the `systemBackground` set. HandLive doesn't paint sheet backgrounds itself.
- Android and previews have no automatic elevation: sheets and dialogs in the Dark appearance use
  `secondary-system-background` as the raised background, and the elements inside them use
  `tertiary-system-background`.
- macOS: the `window-background` is gray, not black; lists and tables use `control-background`. The
  Graphite accent color tints window backgrounds with the wallpaper.
- The Dark appearance separates layers with background color, not shadows: `shadow-card` is `none` in
  Dark. Floating glass still has `shadow-glass`.

| Layer | Token | Dark | Dark · Increased Contrast |
|---|---|---|---|
| Screen background | `system-background` | #000000 | #000000 |
| Group; raised background on Android | `secondary-system-background` | #1c1c1e | #242426 |
| Nested in a group | `tertiary-system-background` | #2c2c2e | #363638 |
| Mac window | `window-background` | #282828 | #1c1c1c |
| Mac lists, tables | `control-background` | #1e1e1e | #141414 |

## Colors in the Dark appearance

Dark colors aren't Light colors inverted: backgrounds are softer, and text and colors are brighter.
Every custom token has its own Dark value; for example, `accent` #197934 in Light becomes #3ddc6c in
Dark.

HIG: minimum contrast is 4.5:1; custom colors should aim for 7:1, especially for small text. Results
measured on 7 backgrounds: `system-background`, `secondary-system-background`,
`tertiary-system-background`, `system-grouped-background`, `secondary-system-grouped-background`,
`window-background`, `control-background`.

| Token | Dark | Dark · Increased Contrast | Reaches 7:1 |
|---|---|---|---|
| `accent` | 7.7–11.7 | 7.5–13.0 | Yes |
| `text-green` | 7.6–11.4 | 7.7–13.3 | Yes |
| `text-orange` | 6.9–10.4 | 7.2–12.5 | Almost (6.9 on `tertiary-system-background`) |
| `text-red` | 4.7–7.2 | 5.4–9.4 | Only on black |
| `brand-fire` | 5.0–7.5 | 5.2–9.1 | No; large text only |

- `text-red` meets the minimum but not the recommended level: use it only for short labels that always
  come with an icon ("Not sent"), not for paragraphs.
- Secondary text on Apple platforms uses the system's `.secondary`; the `secondary-label` token
  (5.3–6.4:1 in Dark) is only for Android and previews.

## Images, QR codes, and video

- QR codes are always black on white (`qr-ink` on `qr-paper`) in all 4 appearances, with a white
  quiet zone around the code. Don't invert them in the Dark appearance: many scanners read inverted
  codes poorly. The white frame is only as wide as the code (`size-qr`) to reduce glare.
- The camera frame (`CameraPreview`) and the scan frame: black `video-background`, white `on-video`
  text and icons in every appearance.
- The user's images (images on the clipboard, profile pictures) are shown as they are. HandLive's
  illustrations have Light and Dark versions; per the HIG, soften white backgrounds in illustrations
  so they don't glare.
- SF Symbols adapt to the appearance on their own. Custom icons need Light and Dark versions, plus a
  thin outline if a dark shape disappears into a dark background.
- The `brand-glow` brand background changes from peach (#fde9e2) to a deep reddish brown (#3b1a12),
  not to black.

## Increase Contrast and Reduce Transparency

| Setting | The system does | HandLive also does |
|---|---|---|
| Increase Contrast | System colors switch to high-contrast variants; control borders become more visible | Tokens take `light-hc`, `dark-hc`; `glass-stroke` and `separator` get darker |
| Reduce Transparency | Glass and materials become nearly opaque backgrounds | Custom materials read `accessibilityReduceTransparency` (SwiftUI) or `NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency`, then use the opaque `secondary-system-background` or `window-background` |

`glass-fill` in the two Increased Contrast appearances is already nearly opaque (92%), so glass on
Android and in previews looks the way it does with Reduce Transparency on.

## Test matrix

The HIG asks you to test the Dark appearance with Increase Contrast and Reduce Transparency turned on,
each on its own and both together. Every main screen (`Onboarding`, `PairingCard`, `MenuBarMenu`,
`CallPanel`, Messages, Settings) goes through 4 appearances × Reduce Transparency off/on = 8
combinations.

| Combination | What to check |
|---|---|
| Light, Dark | Secondary text on group backgrounds; glass over light and dark wallpapers; `text-red` in Dark |
| The two Increased Contrast appearances | Glass borders, separators, and status dots still stand out from the background |
| Each appearance with Reduce Transparency | Glass becomes an opaque background; text and buttons stay readable |
| Auto mode | The appearance changes while the app is open: no color stays stuck in the old appearance |
| Inactive Mac window | Loses vibrancy, but the content stays readable |

Tools: Environment Overrides in Xcode (appearance, contrast, text size) and Accessibility Inspector;
on Android, change the system's Dark theme and contrast level, then take screenshots to compare.

## Dos and don'ts

| Do | Don't |
|---|---|
| Use dynamic colors and the tokens of the current appearance | Add a Light/Dark switch in the app |
| Let the system switch base backgrounds to elevated | Paint sheets black yourself |
| Keep QR codes black on white | Invert QR codes in the Dark appearance |
| Test all 8 combinations | Test only Light and Dark |
