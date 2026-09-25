English | [Tiếng Việt](README.vi.md)

# Button

A button defined by the HIG's three attributes — style, content (text, an icon, or both), and role —
for Mac, iPhone/iPad, and Android.

## Styles and roles

| Style | When to use | macOS / iOS (SwiftUI) | Android (Compose) | Token |
|------|----------|----------------------|-------------------|-------|
| Prominent | The screen's primary action, at most one (rarely two) | `.borderedProminent`; from 26: `.glassProminent` | `HLButton(style = Prominent)` | `accent-fill`, `on-accent` |
| Glass / bordered | Secondary actions next to the primary button | `.bordered`; from 26: `.glass` | `HLButton(style = Glass)` | `glass-fill`, `glass-stroke`, `label` text |
| Tinted | Actions that should be seen but aren't the primary one ("Open Settings") | `.bordered` + `.tint(.accentColor)` | `style = Tinted` | `accent-tint`, `accent` |
| Plain | Links, secondary commands within a sentence | `.borderless` / `.plain` | `style = Plain` | `accent` |
| Destructive | Unpair, delete history | `role: .destructive` | `style = Destructive` | `destructive-text` on a glass background (`glass-fill`, `glass-stroke`); the solid red `call-decline-fill` background is only for the round Decline and End buttons in `CallPanel` |

- Roles: normal, primary (responds to Return), cancel (responds to Esc), destructive. **Never** give a
  destructive button the primary role.
- Distinguish priority by style, not by size. One prominent button per screen.
- Labels start with a verb, with title-style capitalization in English (sentence case in Vietnamese):
  "Pair", "Send Clipboard", "Unpair". Buttons that open a window or another step end with "…":
  "Settings…", "Decline with Message…".
- Icon-only buttons must have an accessibility label and (on the Mac) a tooltip that starts with a
  verb.

## Sizes

| Platform | Size used in HandLive | Hit area |
|----------|------------------------|----------|
| macOS | `.controlSize(.regular)`, ~24 pt tall, in forms and sheets; `.large` for the final button of the welcome window | ≥ `size-hit-mac` (28 pt), 20 pt minimum |
| iOS/iPadOS | `.controlSize(.large)` + `.buttonBorderShape(.capsule)`, 50 pt tall, full width between the margins for the screen's primary action | ≥ `size-hit-ios` (44 pt) |
| Android | Capsule 50 dp tall (primary) or 48 dp (secondary), Inter 17 sp Semibold text | ≥ `size-hit-android` (48 dp) |

## States

Pressed: darkens by 8%, with no ripple on Android. Disabled: 40% opacity, always with a line nearby
explaining why. Working: the label changes to show progress ("Pairing…") with a small `ProgressView`,
without changing the button's size.

## Dos and don'ts

- Do put the primary button at the right edge (Mac) or at the bottom within easy reach (iPhone,
  Android).
- Don't put two prominent buttons side by side; don't use vermilion `brand-fire` for buttons.
- Don't use "OK", "Yes", or "No" as labels; "Cancel" is only for cancel buttons.
