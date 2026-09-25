English | [Tiếng Việt](04-bo-cuc.vi.md)

# Layout

This section defines spacing, margins, layout by size class, corner radii, hit targets, and the rules
specific to Mac windows. On Apple platforms, margins and safe areas come from the system; the tokens
are values for custom views, previews, and Android.

HIG source: https://developer.apple.com/design/human-interface-guidelines/layout

## Spacing

4 pt grid (dp on Android).

| Token | Value | Used for |
|---|---|---|
| `space-4` | 4 | Gap between an icon and small text |
| `space-8` | 8 | Gap between elements in a row |
| `space-12` | 12 | Padding around bordered controls (HIG: ~12 pt) |
| `space-16` | 16 | Padding inside cards, gap between content rows |
| `space-20` | 20 | Content margins in Mac windows, gap between settings groups |
| `space-24` | 24 | Padding around borderless controls (HIG: ~24 pt), gap between the two round call buttons |
| `space-32` | 32 | Gap between large blocks on the welcome screen |
| `space-40` | 40 | Top margin of the welcome screen title |
| `margin-compact` | 16 | Screen margins on iPhone and Android phones |
| `margin-regular` | 20 | Screen margins on iPad and in wide windows |

## System margins

The HIG as of September 9, 2026 no longer has a margins table. On Apple platforms, read margins from
the system instead of adding fixed numbers:

- UIKit: `layoutMargins`, `directionalLayoutMargins`, `readableContentGuide` (limits paragraph width
  on iPad).
- SwiftUI: the default `.padding()`, `.scenePadding()`; `List` and `Form` set their own margins;
  `.safeAreaInset(edge:)` for custom bars.
- macOS: `Form` with `.formStyle(.grouped)` sets its own margins; custom views sit `space-20` from the
  window edge.
- Android: `margin-compact` when the width is under 600 dp, `margin-regular` from 600 dp, plus
  `WindowInsets.safeDrawing`.

## Size classes

Lay out by size class, not by device type or orientation. A change of size class only changes how much
content is shown, never which functions are available. Don't set fixed widths.

| Where it's shown | Horizontal | HandLive |
|---|---|---|
| iPhone | Compact (large phones in landscape: Regular) | Tab bar with 4 tabs; single-column lists; Messages pushes to the conversation screen |
| iPad full screen, wide windows | Regular | Messages uses `NavigationSplitView` (list + conversation) |
| iPad split screen, narrow windows | Compact | Like iPhone |
| iPhone Duo, outer display | Compact | Like iPhone; the system moves the tab bar and toolbar to the vertical edge |
| iPhone Duo, inner display | Regular | Like iPad: Messages in two columns |
| Android under 600 dp / from 600 dp | `WindowSizeClass` Compact / Medium, Expanded | Like iPhone / like iPad |

- iPhone Duo: system components avoid the camera area and the fold (reserved regions) on their own;
  only custom views need `ReservedRegion` (iOS 27.1). Every toolbar item has both text and a symbol.
  Preview with Device Hub in Xcode.
- At accessibility text sizes, horizontal layouts switch to vertical stacks and use fewer columns.

## Concentric corners

Inner corners are concentric with outer corners: inner radius = outer radius − padding. For example,
a card inside a sheet: `radius-sheet` 26 − `space-12` = 14 = `radius-card`.

- macOS 26, iOS 26 and later: controls, sheets, popovers, and windows take the system's concentric
  corners. Custom views use `ConcentricRectangle`, `.containerShape(_:)`, `rect(corners:isUniform:)`
  (SwiftUI) or `cornerConfiguration` (UIKit), instead of numeric radii.
- macOS 13–15, iOS 16–18, and Android use the tokens:

| Token | Value | Used for |
|---|---|---|
| `radius-control-mac` | 6 | Push buttons and text fields on macOS 13–15 |
| `radius-row` | 10 | Inset list groups (iOS 16–18), sidebar selection |
| `radius-card` | 14 | Cards in the content layer, alerts on iOS 16–18 |
| `radius-panel` | 18 | Menus, popovers, notifications, `CallPanel` |
| `radius-sheet` | 26 | Sheets; list groups and Mac windows from version 26 |
| `radius-capsule` | 999 | Capsule buttons, switches, badges, the floating tab bar |

## Hit targets

| Platform | Default | Minimum | Token |
|---|---|---|---|
| iOS, iPadOS | 44×44 pt | 28×28 pt | `size-hit-ios`, `size-hit-ios-min` |
| macOS | 28×28 pt | 20×20 pt | `size-hit-mac`, `size-hit-mac-min` |
| Android | 48×48 dp | 48×48 dp | `size-hit-android` |

- When an icon is smaller than its hit target, enlarge the hit target, not the icon: SwiftUI
  `.frame(minWidth:minHeight:)` with `.contentShape(Rectangle())`; Compose
  `Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)`.
- Padding around controls, measured from the visible edge: ~12 pt for bordered controls
  (`space-12`), ~24 pt for borderless controls (`space-24`).
- Round call buttons are `size-call-button` 48, spaced `space-24` apart.

## macOS windows

- Don't put controls or important information at the bottom of a window: people often drag windows
  partly off the bottom of the screen. A bottom bar holds only secondary information; the compose
  button goes in the toolbar, not at the bottom of the sidebar.
- Don't draw your own window frame, title bar, or window controls; don't put content under the camera
  housing (notch).
- Window titles are under 15 characters and never the app name. The Settings window changes its title
  and size with each pane.
- The menu bar is 24 pt tall (`size-menu-bar`). The HandLive icon can be hidden by the notch or a
  crowded menu bar, so there's always another way in: reopening the app shows the main window.
- Split views: a thin 1 pt divider.

## Widths HandLive uses

These aren't HIG numbers; they're values HandLive chose so that the platforms and previews match.

| Component | Width | Notes |
|---|---|---|
| `MenuBarMenu` | Computed by the system (preview 280 pt) | Short labels; long device names are truncated in the middle |
| `CallPanel`, `Notification` | 340 pt | Height fits the content; the width doesn't change when the call state changes |
| `Alert` on macOS | Computed by the system (preview 260 pt) | — |
| Popover | Fits the content | Short information only, never for warnings |
| `PairingCard` | QR code `size-qr` 220 pt | With a white quiet zone around the code |
| `MessageBubble` | At most 76% of the conversation pane | — |
| Avatar | `size-avatar` 40 (Mac 32) | — |

## Safe areas

- iOS and iPadOS: backgrounds extend under the glass tab bar and toolbar; content people read and tap
  stays inside the safe area. Use `ignoresSafeArea` only for backgrounds.
- Android: edge-to-edge (`enableEdgeToEdge()`), padded with `WindowInsets.safeDrawing`; don't put
  controls in the back-gesture zones along the two edges (`WindowInsets.systemGestures`). Android
  manages the status bar and the navigation bar.

## Dos and don'ts

| Do | Don't |
|---|---|
| Read margins and safe areas from the system | Add a fixed 16 pt margin on iOS |
| Lay out by size class | Branch on device names |
| Keep inner corners concentric with outer corners | Use the same radius for a card nested in a sheet |
| Put important buttons in the window body | Put important buttons at the bottom of a Mac window |
