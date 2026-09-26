# Phase 2 — I2.1 [iOS]: the iPhone and iPad app

Card I2.1 of `phase-02-sms-ios-relay.md`. Repository handlive-apple, branch `feat/phase-02-sms-ios-relay`.

## What was done

- **Targets** (`project.yml`): `HandLiveiOS` (`app.handlive.ios`, iPhone and iPad, iOS 16+, generated Info.plist with
  `iOS/Info.plist` for the purpose strings, `NSBonjourServices`, `NSUserActivityTypes`) embedding
  `HandLiveNotificationService` (I2.2); entitlements for `aps-environment`, the App Group and keychain group
  `group.app.handlive`, communication and time-sensitive notifications (active once signed; nothing about signing
  is committed). The app sources are one file, `iOS/HandLive/HandLiveIOSApp.swift`; everything else is in the new
  package `HLiOSUI`. The string generator now writes `iOS/Info.plist`, `iOS/HandLive/Resources/InfoPlist.xcstrings`
  and the `push.*` loc-keys (`Localizable.xcstrings`).
- **Model** (`IOSAppModel`, builds for macOS too so its tests run with the Command Line Tools): keys and settings in
  the App Group suite, keys in the shared keychain group; the pair store and the SQLCipher SMS database in the app's
  own container; the connection manager with the relay services (LAN and relay, CONN-01/03) only while the scene is
  active — `session/bye {shutdown}` in the background (CONN-02 E3); the capability with `sms.notify`; unread count on
  the Messages tab and the app icon badge; notifications of conversations read here or on the phone removed; the push
  token (I2.2); unpair with tombstones; Remove from Server and Delete All (`group.app.handlive` suite wiped);
  `PairingHost` for the shared pairing controller with the relay rendezvous; `HLBENCH/1` role `ios`.
- **Clipboard (CLIP-04)**: `ClipboardEngine` with `platform: .ios` never reads the clipboard — `IOSPasteboard`
  returns nothing for reads and writes clips with `.localOnly` and `.expirationDate` (`clip.auto_clear_s`); a new
  `changeCount` HandLive did not write (compared with `clip.seen_change_count`) marks unsent content and shows the
  banner "The iPhone clipboard has new content — paste to send it to <phone>" (`{device_type}` from
  `UIDevice.current.model`, "…a new image…" with `hasImages`); the system `PasteButton` hands the content over (text,
  URL, PNG/JPEG kept, other images to PNG; images only with Sync Images, E7) and it is sent at once with `source =
  ios`; a push in the first 5 s of a session keeps unsent content (`ignored`/`conflict`, E2); no `ack` → "Couldn't
  send. Try again.", never replayed (E9); the last received clip with "From <phone> · <time>", "Copy" and "Sensitive
  content hidden"; the conflict card with "Send Again"; the `Feedback` HUD and a success haptic.
- **Screens** (all text from `L10n`): setup (SET-03) — welcome with the privacy link, the notification primer
  (asked once), the local network primer (the first Bonjour browse asks), the guides with "Open Settings" after a
  refusal (E3, E4), the limits of iPhone and iPad, then `setup.completed_at`, push registration and the pairing sheet
  opening by itself; the pairing sheet (QR code, "Can't Scan? Use a PIN", countdown, errors in the sheet, closes
  itself once paired); tabs Clipboard, Messages (badge) and Settings; Messages as a `NavigationSplitView` (list and
  conversation side by side in regular width, one column in compact width) with `searchable`, All/Unread, swipe to
  Mark as Read, New Message as a large sheet (⌘N); Settings as a `GroupedList`: Phone (status, Unpair with its
  confirmation), Clipboard, Messages (switches, Resync All SMS with its confirmation, last sync, contacts hint), Internet
  Connection (with the relay's problem), Permissions (Notifications, Local Network → Settings), Data (Remove Device
  from Server, Delete All HandLive Data, E7). `ThreadRow` stacks at accessibility text sizes so names wrap.
- **Reuse**: the pairing controller, the notification and local network permission helpers and the privacy link moved
  to `HLAppCore`; the SMS notification response to `HLSMSNotifications`; the Messages screens are the shared
  `HLSMSUI`.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 422d7e9 | refactor(apple): share the notification and local network permission helpers |
| a134cef | feat(apple): run the clipboard engine on iPhone and iPad without reading the clipboard |
| d3deb2e | test(apple): test the clipboard engine on iPhone and iPad |
| 2d82634 | feat(apple): keep the last received clip for the iPhone and iPad card |
| f3caf7d | test(apple): test the last received clip and copying it again |
| 4717b81 | refactor(apple): share the privacy page link with the iPhone app |
| a89c62f | fix(apple): take AppKit colors only on macOS |
| 01ef006 | feat(ios): generate the iPhone app's purpose strings and push loc-keys |
| 6ec27b0 | feat(ios): add the iPhone and iPad app model |
| a892154 | test(ios): test the iPhone and iPad app model and setup |
| 0167089 | feat(ios): add the setup, pairing, Clipboard, Messages and Settings screens |
| a92a1c5 | feat(ios): add the iOS app target |
| 61fda7c | docs(apple): describe the Phase 2 layout, SQLCipher fetch and iOS targets |
| 6197021 | feat(apple): stack ThreadRow at accessibility text sizes |
| 8cac84a | docs(apple): note the SQLCipher fetch, the iOS targets and the Catalyst type-check |
| acceda9 | ci(apple): test HLSMS through its package scheme |
| 57a9f3d | fix(ios): build the iOS app without an app icon set for now |
| b7bf88f | feat(apple): register with the relay when setup finishes |
| bc5cae8 | test(apple): wait for the badge that follows the end of the first sync |

## Files

`Packages/HLiOSUI/` (`IOSAppModel*.swift`, `IOSNotifying.swift`, `PastedContent.swift`, `IOSSetupFlow.swift`,
`IOSPasteboard.swift`, `IOSAppDelegate.swift`, `IOSRootView.swift`, `IOSSetupView.swift`, `IOSPairingSheet.swift`,
`ClipboardTabView.swift`, `MessagesTabView.swift`, `SettingsTabView.swift`, `DataSettingsSection.swift`, tests);
`Packages/HLAppCore/Sources/HLAppCore/{Clipboard/ClipboardEngine*.swift,SystemPermissions,PrivacyPage,LocalDevice,
AppSettings}.swift`; `iOS/`; `project.yml`; `HandLive.xcworkspace`; `.github/workflows/ci-apple.yml`;
`Packages/HLLocalization/Scripts/`; `README.md`, `README.vi.md`, `CLAUDE.md`.

## Tests

```
HLiOSUI    ✔ Test run with 11 tests in 2 suites passed after 1.090 seconds.   (model on macOS)
HLAppCore  ✔ Test run with 49 tests in 12 suites passed after 2.196 seconds.  (incl. CLIP-04 engine tests)
Mac Catalyst build of HLiOSUI (all iOS views):  swift build --triple arm64-apple-ios16.0-macabi → EXIT 0
Mac Catalyst type-check of iOS/HandLive/HandLiveIOSApp.swift and the extension → no errors
swiftlint lint --strict → no violations; hard-coded text scan (now also iOS/) → passed
```

## CI

- The package step now gets past HLSMS: before, every run stopped for 40 minutes resolving SQLCipher's remote
  binary target and then hit the 45-minute job limit (runs 36228805534, 36226192798, 36227514483). Fixed by the local
  binary target (`fetch.sh`), the `HLSMS-Package` scheme and a 90-minute limit; the workflow tests `HLiOSUI` and
  builds `HandLiveiOS` with the extension for the simulator without signing.
- Run 36233209508 on 57a9f3d: **success** — HLProtocol 51, HLCrypto 46, HLTransport 94, HLDesignSystem 24,
  HLLocalization 9, HLAppCore 49, HLSMS 10 + 24, HLSMSUI 9, HLMacUI 30, HLiOSUI 10 tests passed; SwiftLint "Found 0
  violations, 0 serious in 298 files"; `Build app macOS` and `Build app iOS + Notification Service Extension
  (simulator, unsigned)` both `** BUILD SUCCEEDED **`. Run 36232650399 before it failed only on the missing
  `AppIcon` set (fixed in 57a9f3d); its Swift sources had compiled for the iOS simulator.
- Run 36233855710 on b7bf88f failed on a timing race in one HLSMS test (the badge is published after `done`);
  fixed in bc5cae8.
- **Final head bc5cae8: run 36234320082 — success** (every package test, SwiftLint, the Mac app and the iOS app with
  its extension).

## Spec deviations and proposals

1. **SMS database on iOS**: in the app's own container, not the App Group container of SET-03 step 2 — the extension
   never opens it, and an SQLite file held open in a shared container gets a suspended app killed (0xDEAD10CC).
   Proposal: change SET-03 step 2 for iOS.
2. **No SMS notification while the app is open**, per 02-ios-ipados.md; the tab badge and the list show it.
3. **Device name**: `UIDevice.current.name` is "iPhone"/"iPad" on iOS 16+ without the user-assigned-name
   entitlement, so the phone shows that name at pairing. Proposal: request
   `com.apple.developer.device-information.user-assigned-device-name` or let the user rename the device.
4. **First launch banner**: `clip.seen_change_count` starts at 0, so content already on the clipboard at the first
   launch counts as unsent and shows the banner.
5. **Missing catalog keys** (texts not written in code): a title for the limits screen of setup (only the body
   `setup.ios_limits` exists), and "Close" for the banner's close button (it reads `common.done`). Proposal: add
   `setup.ios_limits_title` and `common.close`.
6. No Calls tab yet (Phase 3).
7. **No app icon** yet: the iOS target builds with `ASSETCATALOG_COMPILER_APPICON_NAME` empty until the icon set
   exists (the Mac target has none either).

## Pending manual checks

- On an iPhone and an iPad (signed build): Paste sends without the "Allow Paste" dialog; the banner after copying in
  another app; clips written from the phone are not offered to other Apple devices (`localOnly`) and expire.
- Dynamic Type AX5 on every screen (no cut text), VoiceOver, Vietnamese; iPad split view, Stage Manager and the
  compact width; iPhone Duo postures.
- Setup: notification and local network prompts and their guides; pairing by QR over the LAN and through the relay
  rendezvous; background → foreground reconnect within 3 s and the clip replay of QC7.

Status: DONE_WITH_CONCERNS
Summary: The iPhone/iPad app exists (setup, pairing, Clipboard with PasteButton, Messages split view, Settings) over a
tested model and the shared packages, type-checked for Mac Catalyst and built by CI for the simulator.
Concerns/Blockers: never run on a device or simulator here (Command Line Tools only); deviations 1, 3 and catalog
proposal 5 need the owner.
