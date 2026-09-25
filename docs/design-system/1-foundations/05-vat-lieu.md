English | [Tiếng Việt](05-vat-lieu.vi.md)

# Materials

HandLive uses Liquid Glass for the control layer that floats above content, and standard materials
for the content layer. This section says where glass is used, what the fallbacks are for older OS
versions and Android, and how it responds to Reduce Transparency.

HIG source: https://developer.apple.com/design/human-interface-guidelines/materials

## Two layers

| Layer | Material | HandLive components |
|---|---|---|
| Functional layer: controls, navigation | Liquid Glass | `MenuBarMenu`, `CallPanel`, the iOS tab bar, floating buttons, HUD-style `Feedback` |
| Content layer | Standard materials, system backgrounds | `GroupedList`, `ThreadRow`, `MessageBubble`, `PairingCard`, `PasteCard`, `Onboarding`, `CameraPreview` |

- Don't use Liquid Glass in the content layer. Exceptions made by the system: sliders and switches turn
  into glass while they're being dragged.
- Don't stack glass on glass. Don't put solid or translucent backgrounds under glass controls; let
  content scroll underneath and use the `automatic` scroll edge effect.
- Use it sparingly: system controls already come with glass; apply glass yourself only to the most
  important custom controls.

## Liquid Glass: regular and clear

| Variant | Characteristics | HandLive uses |
|---|---|---|
| `regular` | Blurs and adjusts the brightness of the content behind it so text always stays readable | Default: `MenuBarMenu`, `CallPanel`, tab bar, `Feedback` |
| `clear` | Highly transparent, favors showing the content behind it | Only the floating buttons on `CameraPreview` (switch camera, turn off the microphone). If the image behind is bright, add the 35% dark layer `glass-dim` |

- Tinting glass: tint only the background of one primary action (`.buttonStyle(.glassProminent)`,
  `Glass.tint(_:)`), never text or icons. The Answer and Decline buttons on `CallPanel` are solid,
  meaningful backgrounds (`call-accept-fill`, `call-decline-fill`), not tinted glass.
- Small glass elements (tab bars, floating buttons) switch between light and dark on their own based on
  the content underneath; text and symbols on glass are monochrome.
- Group nearby glass buttons in a `GlassEffectContainer` so the system renders them together and
  morphs between them.

## Where glass goes, by version

| Where | macOS 26+, iOS 26+ | macOS 13–15, iOS 16–18 | Android |
|---|---|---|---|
| `MenuBarMenu` | System menu, glass built in | System menu, `.menu` material drawn by the system | Not available |
| `CallPanel` | `NSGlassEffectView` | `NSVisualEffectView` `.popover`, blending `.behindWindow` | Not available |
| iOS tab bar | System `TabView` | System `TabView` | Custom floating tab bar |
| Floating buttons | `.buttonStyle(.glass)` or `glassEffect(_:in:)` | Circular `.regularMaterial` | `glass-fill` + blur |
| HUD-style `Feedback` | `glassEffect(.regular, in:)` | macOS `NSVisualEffectView` `.hudWindow`; iOS `.regularMaterial` | `glass-fill` + blur |
| Buttons on `CameraPreview` | `Glass.clear` + `glass-dim` | `.ultraThinMaterial` + `glass-dim` | `glass-dim` + `glass-stroke` |

When the app is built with SDK 27, system controls turn into glass on version 26 and later on their
own; `UIDesignRequiresCompatibility` is ignored, so don't use it to opt out of Liquid Glass.

## Standard materials

- Choose a material by purpose, not by the color you see. Thick materials for text and fine details;
  thin materials keep the context behind them.
- iOS, iPadOS: `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial` (default),
  `.thickMaterial`.
- macOS: `NSVisualEffectView.Material` by role: `.menu`, `.popover`, `.hudWindow`, `.sidebar`,
  `.sheet`, `.windowBackground`, `.contentBackground`. Blending `.behindWindow` for panels and HUDs
  floating on the screen; `.withinWindow` for layers inside a window.
- Text on materials uses vibrant colors: SwiftUI `.foregroundStyle(.secondary)` gets vibrancy on its
  own; UIKit `UIVibrancyEffectStyle` from `.label` to `.quaternaryLabel`. Don't use the quaternary
  level on `.thinMaterial`, `.ultraThinMaterial`.
- Inactive Mac windows lose vibrancy; text must stay readable.

## Glass tokens for Android and previews

Apple platforms don't use these tokens; the system draws glass, shadows, and highlights itself.

| Token | Light / Dark | Increased Contrast | Used for |
|---|---|---|---|
| `glass-fill` | White 72% / #262628 72% | Nearly opaque (92%) | Background of regular glass |
| `glass-stroke` | White 55% / white 14% | Stronger border | 1 px border that separates the shape |
| `glass-highlight` | White 85% / white 20% | White 85% / white 30% | Highlight along the top edge, 1 px inset |
| `glass-dim` | Black 35% | Same | Dark layer under clear glass when the image is bright |
| `shadow-glass` | 0 8 24 and 0 1 3 | Stronger | Shadow of floating glass |

- Android API 31+: blur the content layer behind with `RenderEffect.createBlurEffect`, cover it with
  `glass-fill`, add the `glass-stroke` border, the `glass-highlight` highlight, and the `shadow-glass`
  shadow.
- Android API 29–30 (no `RenderEffect` yet): an opaque background, that is `glass-fill` without alpha,
  keeping the border and shadow.

## Reduce Transparency and increased contrast

- Apple: system glass and materials become nearly opaque on their own when Reduce Transparency is on;
  Increase Contrast makes borders more visible. From version 26, people can also choose the glass
  style they prefer in Settings.
- Custom materials read `accessibilityReduceTransparency` (SwiftUI) or
  `NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency`, then use the opaque
  `secondary-system-background` (iOS) or `window-background` (macOS).
- Android: the `-hc` set makes `glass-fill` nearly opaque (92%) with a stronger border; API 29–30 is
  always opaque.

## API

| Platform | API |
|---|---|
| SwiftUI 26+ | `glassEffect(_:in:)`, `Glass` (`regular`, `clear`, `tint(_:)`, `interactive(_:)`), `GlassEffectContainer`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)` |
| AppKit 26+ | `NSGlassEffectView`, `NSButton.BezelStyle.glass` |
| UIKit 26+ | `UIGlassEffect`, `UIButton.Configuration.glass()`, `.prominentGlass()` |
| Older versions | SwiftUI `Material`; AppKit `NSVisualEffectView` |
| Android | `RenderEffect` (API 31+), the `glass-*` tokens, `shadow-glass` |

## Dos and don'ts

| Do | Don't |
|---|---|
| Glass for menus, panels, tab bars, floating buttons | Glass for lists, message bubbles, pairing cards |
| `clear` only over camera images | `clear` over backgrounds with text |
| Tint the background of one primary button on glass | Tint text or symbols on glass |
| Opaque backgrounds when Reduce Transparency is on | Keep the blur after someone has reduced transparency |
