English | [Tiếng Việt](08-kha-nang-tiep-can.vi.md)

# Accessibility

HandLive must be usable with VoiceOver, TalkBack, the keyboard, large text sizes, and every system
display setting on all three platforms. This section covers control sizes, verified contrast, how to
label things, and a testing checklist.

HIG source: https://developer.apple.com/design/human-interface-guidelines/accessibility ·
https://developer.apple.com/design/human-interface-guidelines/voiceover

## Control sizes

| Platform | Default | Minimum | Token |
|---|---|---|---|
| iOS, iPadOS | 44×44 pt | 28×28 pt | `size-hit-ios`, `size-hit-ios-min` |
| macOS | 28×28 pt | 20×20 pt | `size-hit-mac`, `size-hit-mac-min` |
| Android | 48×48 dp | 48×48 dp | `size-hit-android` |

Space around controls: ~12 pt for bordered controls, ~24 pt for borderless controls (`space-12`,
`space-24`).

## Contrast

| Content | Minimum ratio |
|---|---|
| Text up to 17 pt, any weight | 4.5:1 |
| Text from 18 pt | 3:1 |
| Bold text, any size | 3:1 |
| Icons on solid backgrounds (HandLive rule) | 3:1 |

Accessibility Inspector measures against WCAG level AA. In the Dark appearance, custom colors aim for
7:1 (see Dark Mode and increased contrast).

## Verified token contrast

59 pairs × 4 appearances = 236 measurements, none below the threshold. Colors with alpha are drawn
over their background before measuring. Text is measured on 7 backgrounds: `system-background`,
`secondary-system-background`, `tertiary-system-background`, `system-grouped-background`,
`secondary-system-grouped-background`, `window-background`, `control-background`.

| Pair | Lowest | Threshold |
|---|---|---|
| `label` on every background | 12.06:1 | 4.5 |
| `secondary-label` on every background | 4.69:1 | 4.5 |
| `accent` on every background | 4.65:1 | 4.5 |
| `text-red`, `text-orange`, `text-green` | 4.60, 4.68, 4.65:1 | 4.5 |
| `on-accent` on `accent-fill` (also `bubble-outgoing`) | 4.63:1 | 4.5 |
| `on-call-fill` on `call-decline-fill` | 4.56:1 | 4.5 |
| `on-call-fill` on `call-accept-fill` | 3.52:1 | 3 (icon) |
| `label` on `bubble-incoming` | 13.14:1 | 4.5 |
| `accent` on `accent-tint` | 4.64:1 | 3 (text from 13 pt) |
| `brand-fire` on `system-background`, `brand-glow` | 4.86, 4.15:1 | 3 (large text) |

These don't reach 4.5:1 in the Light appearance, so they're never used for text that carries
information: `tertiary-label` (1.7:1), `system-green` (1.9–2.2:1), `system-orange` (2.0–2.3:1),
`system-gray` (2.8–3.3:1), `system-red` (3.0–3.6:1).

## VoiceOver and TalkBack

Every control has a label. Icon-only buttons must have a label, and on the Mac a tooltip too:

| Icon | Label |
|---|---|
| `phone.fill` | "Answer" |
| `phone.down.fill` | "Decline" while ringing, "End" during a call |
| `mic.slash.fill` | "Mute", with a selected state |
| `pause.fill` | "Hold", with a selected state |
| `circle.grid.3x3.fill` | "Keypad" |
| `arrow.triangle.2.circlepath.camera` | "Switch Camera" |
| `document.on.document` | "Send Clipboard" |
| `xmark` | "Close" |

- Status is read as text, not as color: status dots have no label of their own but are merged into
  the row. `DeviceRow` reads "Lan's Pixel 8, connected via the same Wi-Fi network". Merge with
  `.accessibilityElement(children: .combine)`; Compose
  `Modifier.semantics(mergeDescendants = true)`.
- Toggle buttons (Mute, Hold) report their state with the `.isSelected` trait; Compose
  `Modifier.toggleable`.
- The duration "02:15" is read as "2 minutes, 15 seconds" (`DateComponentsFormatter`, `.full`
  style). A PIN is read digit by digit (`.speechSpellsOutCharacters()`).
- The QR code is labeled "Pairing QR code" and always has an alternative: "Can't Scan? Use a PIN".
- Announce changes without moving focus ("Connected", "Sent", "Call ended"):
  `AccessibilityNotification.Announcement` (iOS 17, macOS 14),
  `UIAccessibility.post(notification: .announcement, argument:)`, AppKit `NSAccessibility.post` with
  `.announcementRequested`, Compose `liveRegion = LiveRegionMode.Polite`.
- Hide decorative images (`.accessibilityHidden(true)`; Compose `contentDescription = null`). Section
  titles carry the heading trait (`.isHeader`; Compose `heading()`).

## Keyboard on the Mac

- Full Keyboard Access: every control can be reached with Tab; custom controls have a `focus-ring`,
  system controls keep the system focus ring.
- Standard shortcuts: ⌘, opens Settings…, ⌘Q, ⌘W, ⌘M, ⌘F searches in Messages, Esc cancels a sheet
  or alert, Return chooses the default button. Don't override system shortcuts.
- Don't assign global shortcuts to Answer or Decline, so they can't be pressed by accident while
  typing.

## Large text

- iOS, iPadOS: Dynamic Type up to AX5, scaling to at least 200%; at accessibility sizes, horizontal
  rows become vertical stacks.
- Android: 200% font scale, text in sp; test Font size and Display size at their largest.
- macOS: no Dynamic Type; text is never smaller than 10 pt; the sidebar follows the size the user
  chooses.

## Display settings

| Setting | SwiftUI | Android | HandLive does |
|---|---|---|---|
| Differentiate Without Color | `accessibilityDifferentiateWithoutColor` | Not available; always applied | Status dots get shapes; call buttons differ in shape |
| Reduce Motion | `accessibilityReduceMotion` | `ANIMATOR_DURATION_SCALE` = 0 | See Motion and haptics |
| Reduce Transparency | `accessibilityReduceTransparency` | Not available | Glass becomes an opaque background |
| Increase Contrast | `colorSchemeContrast` | `UiModeManager.getContrast()` | The `-hc` color set |
| Bold Text | `legibilityWeight` | `Configuration.fontWeightAdjustment` | The brand font goes up one weight |
| Larger Text | `dynamicTypeSize` | `fontScale` | Vertical layouts |

AppKit reads the corresponding settings through `NSWorkspace.shared.accessibilityDisplayShould…`.

## Testing

1. Accessibility Inspector: run Audit on every Mac and iOS screen; fix every contrast problem, missing
   label, and small hit target.
2. VoiceOver, without looking at the screen: go through all of `Onboarding`, pair with a PIN, answer
   and end a call on `CallPanel`, send the clipboard, read and reply to messages.
3. Full Keyboard Access: complete Settings and Messages on the Mac without a mouse.
4. AX5 (iOS) and 200% (Android): no clipped diacritics, no overlapping text, no missing buttons.
5. The four appearances, each with Reduce Transparency on and off; with Reduce Motion on.
6. Android: TalkBack for the flows in step 2; Accessibility Scanner on every screen.
7. Declare the Accessibility Nutrition Labels on the App Store at exactly the level tested.

## Dos and don'ts

| Do | Don't |
|---|---|
| A label for every icon-only button | Let VoiceOver read the symbol name |
| Read status as text | Change only the dot's color |
| Read durations as minutes and seconds | Let "02:15" be read as a time of day |
| Test with real VoiceOver and TalkBack | Rely only on automated tools |
