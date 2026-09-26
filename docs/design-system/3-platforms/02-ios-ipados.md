English | [Tiếng Việt](02-ios-ipados.vi.md)

# iOS and iPadOS

On iPhone and iPad, HandLive receives the clipboard, messages, and call details from the Android phone;
it doesn't carry call audio. This section defines the tab bar, lists, sheets, how the clipboard is
sent, notifications, iPad, iPhone Duo, the background limits, and the fallbacks for iOS 16.

HIG source: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios ·
https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados ·
https://developer.apple.com/design/human-interface-guidelines/tab-bars ·
https://developer.apple.com/design/human-interface-guidelines/sheets ·
https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo

## Tab bar

| Tab | SF Symbol | Content | Badge |
|---|---|---|---|
| Clipboard | `doc.on.clipboard.fill` | `PasteCard` | — |
| Messages | `message.fill` | `ThreadRow`, the "All / Unread" filter | Number of unread conversations |
| Calls | `phone.fill` | The CALL-04 log | Unseen missed calls |
| Settings | `gearshape.fill` | `GroupedList` (Settings section) | — |

- iOS 26+: the floating glass tab bar at the bottom belongs to the system; don't draw a background
  under it. iOS 16–17: `TabView` with `.tabItem`; iOS 18+: `Tab`.
- Filled icons, the selected tab in `accent`, badges in `badge`.
- The tab bar is only for navigation; actions such as "New Message" (`square.and.pencil`) go in the
  toolbar.
- Don't hide or disable tabs when a feature is off or the phone isn't paired; the tab explains the
  reason and the next step right in its content.

## Screens and lists

- Each tab's root screen has a large title ("Clipboard", "Messages", "Calls", "Settings") that shrinks
  when scrolling (`NavigationStack`). Navigation titles use the system font; Be Vietnam Pro is only for
  brand titles (welcome, pairing, empty states).
- Settings: `List` `.insetGrouped`; on iOS 16–18 set `.textCase(nil)` on the headers so Vietnamese
  isn't uppercased. Messages and Calls: a plain `List`.
- Search in Messages with `searchable` right on the list. Swipe left on a conversation to "Mark as
  Read".
- Go back with the standard button at the leading end of the bar or by swiping from the left edge;
  don't draw your own back button.
- Hit targets ≥ `size-hit-ios`; margins `margin-compact` (iPhone) and `margin-regular` (iPad) when
  building custom views, otherwise the system's `layoutMargins`.

## Sheets

| Sheet | Detent | Buttons |
|---|---|---|
| Pairing (`PairingCard`) | large | "Cancel" at the leading end of the toolbar; closes itself once paired |
| New message | large only (compose frame) | "Cancel" at the leading end of the toolbar; sent with the send button in the compose field |

- Per the HIG update of March 24, 2026: a single-screen sheet puts "Cancel" at the leading end and
  "Done" at the trailing end of the toolbar; "Done" always comes with "Cancel" or "Back"; never all
  three. Multiple steps: the first step has "Cancel" and "Done" (disabled), middle steps "Back" and
  "Done" (disabled), the last step "Back" and "Done".
- Resizable sheets have a grabber (`.presentationDragIndicator(.visible)`,
  `.presentationDetents([.medium, .large])` — iOS 16). Swipe down to close; if there's a message
  draft, ask with an action sheet.
- iPad: the form sheet style. One sheet at a time.

## Clipboard (CLIP-04)

- Sending: `PasteButton` (SwiftUI) or `UIPasteControl` on the `PasteCard` send card; one tap sends,
  with no "Allow Paste" dialog. The app never reads `UIPasteboard` in code; it only reads
  `changeCount`, `hasStrings`, `hasImages`, `hasURLs` to show hints.
- Receiving: only while the app is open and has a session; written with `setItems(_:options:)` using
  `.localOnly` (not shared through Universal Clipboard) and `.expirationDate` according to
  `clip.auto_clear_s`.
- Not connected: the Paste button is disabled, with the line "Not connected to the phone". Once sent:
  the `Feedback` HUD "Sent to Lan's Pixel 8" and a `success` haptic.

## Pairing and notifications

- iPhone and iPad show a QR code for the Android phone to scan; the iOS app doesn't request camera
  permission.
- New SMS: a communication notification (`INSendMessageIntent`) with "Reply" and "Mark as Read"; the
  Notification Service Extension decrypts it while the device is unlocked; when the device is locked,
  only "New SMS message" is shown.
- Incoming call: a time-sensitive communication notification (`INStartCallIntent`) with only
  "Decline"; no PushKit or CallKit (C7); the iPhone can't answer on the phone's behalf.
- When the app is open, there are no notifications: an incoming call shows an in-app banner (CALL-01
  step 8). The app icon badge is the number of unread conversations.

## iPad

- Messages uses `NavigationSplitView`: the list and the conversation side by side in regular width,
  one column in compact width (narrow Split View, Slide Over).
- iPadOS 18+: the tab bar near the top of the screen, with `.tabViewStyle(.sidebarAdaptable)` to let
  it turn into a sidebar; iPadOS 16–17: a plain `TabView`.
- Windowed mode (iPadOS 26+): the window controls sit at the leading end of the toolbar, so don't put
  buttons right at the leading edge of the toolbar.
- External keyboard: ⌘N new message, ⌘F search, Return send. The HandLive › Settings menu opens the
  app's page in the system Settings; the in-app settings are a separate item right below it.
- The clipboard works the same in Split View and Stage Manager while the HandLive window is in front.

## iPhone Duo

- Lay out by size class: the outer display is compact width, the inner display regular width. No
  fixed widths, no separate layout for each posture.
- Use the system tab bar and toolbar so the system moves the bars to the vertical edge itself; don't
  override where the bars go.
- Every toolbar button has both a title and a symbol (`Label`); along the vertical axis, back or close
  comes first at the top, then the primary actions.
- The inner display shows the list and the conversation side by side; the outer display shows one
  column, with the same functions.
- Alerts, sheets, and split views avoid the camera and the fold on their own; only custom views need
  `ReservedRegion` (iOS 27.1, in beta).

## Platform limits

- No reading the clipboard in the background. Moving to the background closes the session; coming back
  reconnects and receives the latest clip if it's still within 120 s.
- When the app is closed, SMS and calls arrive through APNs and the Notification Service Extension; no
  content while the device is locked.
- No call audio (Apple doesn't open up the Hands-Free role), no virtual camera.

## Fallbacks for iOS 16

| Feature | Since | On iOS 16 |
|---|---|---|
| `PasteButton`, `NavigationSplitView`, `presentationDetents`, `presentationDragIndicator` | 16 | Available |
| `ContentUnavailableView`, `.sensoryFeedback`, `symbolEffect`, TipKit | 17 | Custom empty states; `UINotificationFeedbackGenerator`; no effects, no tips |
| `Tab`, `.sidebarAdaptable` | 18 | `TabView` with `.tabItem` |
| `glassEffect(_:in:)`, `.glassProminent`, `ConcentricRectangle` | 26 | `.regularMaterial`, `.borderedProminent`, `radius-*` corners |

Text follows text styles and Dynamic Type; test at the AX5 size. At accessibility sizes, `ThreadRow`
and `DeviceRow` stack vertically instead of truncating text. Brand titles use
`Font.custom(_:size:relativeTo:)`.

## Deviations

- Synced with the detailed design (September 25, 2026): CALL-01 API 6 — the I-NSE builds an
  `INStartCallIntent` and calls `content.updating(from:)` to make a communication notification
  (decision 15).
- Synced with the detailed design (September 25, 2026): CLIP-04 field 1 "Send to \<phone name>";
  SET-03 field 11 drops the sentence about paste permission.

## Dos and don'ts

| Do | Don't |
|---|---|
| Send the clipboard with the system Paste button | Read the clipboard when the app opens |
| Keep the tab bar visible at all times, even when a tab is empty | Hide the Calls tab when the feature is off |
| Use size classes and standard components | Build a separate layout for each iPhone model |
