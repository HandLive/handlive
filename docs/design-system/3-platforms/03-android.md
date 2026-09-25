English | [Tiếng Việt](03-android.vi.md)

# Android

The Android app rebuilds Apple's design language in Jetpack Compose — the way Apple built Apple Music
for Android — with the tokens, Inter type, and Material Symbols Rounded icons. The parts Android
manages keep the Android style. Where Apple conventions run into notifications, permission dialogs,
the back gesture, the system bars, hit targets, or TalkBack, Android's rules win.

HIG source (the Apple conventions carried over):
https://developer.apple.com/design/human-interface-guidelines/tab-bars ·
https://developer.apple.com/design/human-interface-guidelines/lists-and-tables ·
https://developer.apple.com/design/human-interface-guidelines/toggles ·
https://developer.apple.com/design/human-interface-guidelines/sheets ·
https://developer.apple.com/design/human-interface-guidelines/alerts

## Theme

- `HandLiveTheme` reads the tokens and provides them through `CompositionLocal` (colors, type,
  spacing, corner radii, shadows). `HL*` components read only from there.
- Don't use Material dynamic color (Android 12+), and don't take colors or type from `MaterialTheme`:
  status colors and the AccentColor must match the Mac and iPhone.
- On Android, the hex values in the tokens are the actual colors (on Apple platforms, the system APIs
  are called instead).
- The Dark appearance follows the system (`isSystemInDarkTheme()`), with no switch in the app.
  Increased contrast: when `UiModeManager.getContrast()` ≥ 0.5 (Android 14+), use the `-hc` set.

## Type and icons

- Inter bundled with the app (`res/font`, OFL license), with the same size scale as iOS, in sp
  (`android-*`): Body 17 sp, smallest 11 sp, tracking per the tokens. Be Vietnam Pro for
  `brand-large-title`, `brand-title`, `wordmark`; Roboto Mono for `code-pin`; `timer` turns on
  `fontFeatureSettings = "tnum"`.
- Text scales up to 200% (Android 14 scales nonlinearly): don't lock sizes, don't fix the height of
  text lines. The system's bold text: `Configuration.fontWeightAdjustment` (Android 12+).
- Material Symbols Rounded (Apache 2.0), weight 400, outlined; the selected tab uses the filled version
  (`FILL` 1). Names map to SF Symbols according to the table in Icons, for example `chevron.forward` ↔
  `chevron_right`, `checkmark.circle.fill` ↔ `check_circle`.

## Components built in the Apple style

| Component | Compose | Specification |
|---|---|---|
| Grouped list | `HLGroupedList` (`LazyColumn`) | `system-grouped-background` background, `secondary-system-grouped-background` groups with `radius-sheet` corners, rows ≥ 56 dp, sentence-case headers, captions under groups |
| Switch | `HLSwitch` 51×31 dp | On `system-green`, off `system-fill`, white thumb; the whole row is the hit target (`Role.Switch`) |
| Segmented control | `HLSegmented` | Track `tertiary-system-fill`, selected segment `tertiary-system-background`, the group is 48 dp tall |
| Button | `HLButton` capsule | Primary button `accent-fill` + `on-accent`, 50 dp tall; darkens by 8% when pressed, no ripple |
| Sheet | Sheet with a grabber | `radius-sheet` corners, two heights (medium, large), swipe down to close |
| Alert, action sheet | `HLAlert`, `HLActionSheet` | As on Apple platforms: "Cancel" on the left or at the bottom; don't use Material's `AlertDialog` |
| Tab bar | Floating glass at the bottom | Capsule `radius-capsule`, `glass-fill` + `RenderEffect` blur (API 31+), `glass-stroke` border, `shadow-glass` shadow; API 29–30 an opaque background, nearly opaque in increased contrast |
| Large title | A large title that shrinks on scroll | `android-large-title` 34 sp; on scroll it collapses into a centered `android-headline` title in the top bar |
| Feedback | `Feedback` HUD | Glass at the top of the screen for ~1.5 seconds with a haptic |

## Navigation

- A tab bar with two items: "Devices" (the paired Mac, iPhone, and iPad — `DeviceRow`, PAIR-02) and
  "Settings" (SET-02). No Clipboard tab: manual sending goes through the Quick Settings tile, the
  notification button, or the share sheet.
- Subscreens: a `chevron_left` chevron at the top left with the previous screen's name, as on iOS. The
  system back button and gesture always work; predictive back (Android 14+) with
  `PredictiveBackHandler`, declaring `android:enableOnBackInvokedCallback="true"`.
- Don't put controls in the back-gesture zones along the two edges (`WindowInsets.systemGestures`).

## Keeping the Android style

| Part | Approach |
|---|---|
| Notifications | `NotificationCompat` with the channels `hl_service`, `camera_request`, `camera_live`, `camera_alert` (Notifications section) |
| Runtime permission dialog | The system's own, not redrawn; `PermissionPrimer` comes before it (Requesting permission section) |
| Quick Settings tile | `TileService`, label "Send Clipboard", subtitle "To Lan's MacBook", "To 2 devices", or "Not connected"; on API 34+ call `startActivityAndCollapse(PendingIntent)` |
| Share sheet | The target "Send to Device (HandLive)", accepting only `text/plain` |
| Toast | Send results while the app isn't visible ("Sent to Lan's MacBook"); the toast "HandLive pasted from your clipboard" (Android 12+) is shown by the system and can't be turned off |
| Accessibility | The system's Settings › Accessibility page; HandLive only links there after `ConsentSheet` |
| Status bar, navigation bar | Edge-to-edge: `enableEdgeToEdge()`, padded with `WindowInsets.safeDrawing` |
| Splash | The system `SplashScreen` (Android 12+) on `system-background`, with no added text |
| Camera and microphone in-use indicators | The system's own |

## Accessibility and feel

- Hit targets ≥ 48 dp (`size-hit-android`) instead of iOS's 44 pt; the space between two hit targets
  ≥ 8 dp.
- TalkBack: every custom control has a label, a `role`, and a `stateDescription` ("On", "Off"); merge
  rows with `semantics(mergeDescendants = true)`; the connection status is a live region; screen
  titles are marked with `heading()`.
- Animations off: when `ValueAnimator.areAnimatorsEnabled()` is `false`, drop the motion and only
  change the state (the `duration-*` tokens).
- Haptics through `View.performHapticFeedback`: `CONFIRM`, `REJECT` (API 30+); `TOGGLE_ON`,
  `TOGGLE_OFF` (API 34+); API 29 uses `CONTEXT_CLICK`. Respect the system vibration settings.

## Licenses

- Don't use Apple's SF Pro, SF Mono, SF Symbols, or UI Kits in the Android app, not even to build
  Android mock-ups; don't use Apple icons or images of Apple hardware.
- Inter, Be Vietnam Pro (OFL), Roboto Mono, and Material Symbols Rounded (Apache 2.0) are bundled with
  the app and listed on the open source licenses screen.

## Versions (minSdk 29, targetSdk 35)

| Since | Effect on the interface |
|---|---|
| API 29 (Android 10) | No reading the clipboard in the background; glass is an opaque background; no Opus/WS audio path |
| API 30 (11) | `CONFIRM`, `REJECT` haptics; Opus/WS through Shizuku may work on some devices |
| API 31 (12) | `RenderEffect` blur; the `BLUETOOTH_CONNECT` permission; the system splash screen; a toast when the clipboard is read; opening activities indirectly from notifications is blocked |
| API 33 (13) | The `POST_NOTIFICATIONS` permission; restricted settings for installs from outside Google Play; a preview overlay when the clipboard is written |
| API 34 (14) | Predictive back; nonlinear text scaling up to 200%; `getContrast()`; the `TOGGLE_ON` haptic; users can swipe away the service notification |
| API 35 (15) | Edge-to-edge is required with targetSdk 35 |

## Deviations

- Synced with the detailed design (September 25, 2026): CLIP-01 fields 4–5 "Send Clipboard".
- Synced with the detailed design (September 25, 2026): SET-01 field 6 uses "Continue".
- The Vietnamese detailed design writes "Huỷ"; the Vietnamese version of this page uses the Apple style
  "Hủy".

## Dos and don'ts

| Do | Don't |
|---|---|
| Build controls to Apple's specifications with the tokens | Use Material 3 or dynamic color for HandLive's interface |
| Leave notifications, permission dialogs, and the back gesture to Android | Redraw notifications or permission dialogs in the iOS style |
| Keep 48 dp hit targets even when the graphic is smaller | Shrink hit targets to 44 dp to look like the iPhone |
