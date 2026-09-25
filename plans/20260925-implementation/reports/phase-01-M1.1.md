# Phase 1 — M1.1 [macOS]: the menu bar app

Card M1.1 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-apple, branch `feat/phase-01-clipboard`.
Everything the app runs lives in two new packages so it builds and is tested with Command Line Tools; the app target
itself (`macOS/HandLive`) is a thin entry point that only CI can build (no Xcode on this machine).

## What was done

- **`HLAppCore`** (platform-neutral, Mac and iOS):
  - `AppSettings`: the 0.9.5 keys the Apple apps use, defaults registered at every launch, `clip.auto_clear_s`
    limited to 0/60/300, `setup.started_at`/`completed_at`.
  - `DeviceIdentityKeys`: SET-03 step 2 — a fresh install (no `setup.started_at`) first deletes every Keychain
    item of the service `app.handlive.keys` (the Keychain survives an uninstall), then creates `ik_sig`, `ik_dh`,
    `db_key`; later launches load them; a missing key after setup started starts setup over; any Keychain error is E1.
  - `LocalDevice.capability`: Phase 1 advertises only what exists (clipboard with limits and MIME types, relay switch).
  - `PairedDeviceStore`: the `paired_device` records in one file sealed with `db_key` (XChaCha20-Poly1305).
- **`HLMacUI`** (the Mac app's model and views):
  - `AppModel`: keys, pair, link status (StatusIndicator states of 0.11), settings mirrors, login item and paste
    access state, first-run progress; unpairing (PAIR-03 flow A with the 10 s ack wait, flow B otherwise).
  - Menu bar: `MenuBarIcon` (template symbol, `variableColor` while connecting, checkmark feedback with Magic Replace
    on macOS 14+ and a plain swap on 13) and `MenuBarMenu` per `MenuBarMenu` README (phone and colored status row,
    Reconnect Now when disconnected, Add Phone… when unpaired, Send Clipboard to Phone, status line, transfer
    progress with Cancel, Settings… ⌘, and Quit HandLive ⌘Q).
  - `HandLiveScenes`: `MenuBarExtra(isInserted:)` bound to "Show HandLive in Menu Bar" (removing the icon turns the
    setting off), the `Settings` scene, and the app menu items "Add Phone…" (after Settings…, dimmed when paired)
    and "Send Clipboard to Phone" (Edit, after the pasteboard items).
  - Activation policy: `.accessory` while the menu bar icon is shown, `.regular` (Dock icon, app menu bar, Dock menu)
    when it is off (SET-03 step 6, SET-02 field 31).
  - Settings: General (menu bar icon, Open at Login through `SMAppService` with the approval guide, Internet
    connection), Devices (device row with StatusIndicator, Details… with the Security Code and feature reasons,
    Unpair… with the destructive alert, or the empty state with Add Phone…), Clipboard (Sync Clipboard, images,
    sensitive content, auto-clear, the phone's auto-send state, the paste permission guide).
  - Welcome window (`Onboarding`, 520 × 560, closable): welcome with the app name in `brand-fire`, the two
    checkboxes and the privacy link → move to /Applications (with the drag hint when it cannot move itself) →
    notification primer and guide → local network primer (macOS 15+, a real Bonjour browse) and guide → paste
    permission guide (macOS 15.4+ when asked or refused) → pairing sheet → Paired (name and Security Code).
    Every permission screen has a single Continue (SET-03 field 14).
  - `WindowPresenter` (welcome window, Settings from code), `WindowKeyMonitor` (⌘W and Esc close the welcome and
    Settings windows in `.accessory` mode, where there is no menu bar), `AppCoordinator` (launch, reopen from
    Finder, sleep/wake to the connection manager and the clipboard, `session/bye {shutdown}` on quit within 2 s,
    Dock menu), `PrivacyPage` (hub `docs/privacy.md` / `privacy.vi.md` by display language, as on Android).
- **App target**: `HandLiveMacApp` + `AppDelegate` forward to `AppCoordinator`; `project.yml` adds `HLAppCore`,
  `HLMacUI` and `macOS/HandLive.entitlements` (`keychain-access-groups`); the workspace lists the new packages; CI
  tests them; README, README.vi and `apple/CLAUDE.md` describe the packages and the Command Line Tools workflow.

## Commits

| Repository | Hash | Subject |
|------------|------|---------|
| handlive-shared | 0f0c997 | feat(shared): add the Mac setup guidance, keychain error and PIN instruction strings |
| handlive-apple | 1211961 | feat(apple): regenerate the strings for the Mac setup guidance and PIN instruction |
| handlive-apple | 23695c7 | feat(apple): clear every key of the service on a fresh install |
| handlive-apple | ad9b0c9 | feat(apple): add HLAppCore with settings, identity keys and the pair store |
| handlive-apple | 15f1952 | test(apple): test settings, identity keys, capability and the pair store |
| handlive-apple | b977026 | feat(apple): add the Mac app model with login item, paste access and unpairing |
| handlive-apple | 69a5ece | feat(apple): add the menu bar menu and the Settings panes |
| handlive-apple | ab345e0 | feat(apple): add the first-run flow of SET-03 on the Mac |
| handlive-apple | d5970d8 | test(apple): test the Mac app model: launch, keys failure, settings, status, unpairing |
| handlive-apple | 9a2c74f | feat(apple): open the welcome window and Settings from code |
| handlive-apple | 15c8353 | feat(apple): coordinate launch, reopen, sleep, wake, quit and the Dock menu |
| handlive-apple | 5a97ab5 | feat(apple): declare the menu bar extra, Settings and the app menu commands |
| handlive-apple | 97fe4dd | test(apple): test the Dock menu and the window keys |
| handlive-apple | c29afc3 | feat(apple): run the Mac app from the coordinator with the app and UI packages |
| handlive-apple | 5a7e3b2 | ci(apple): test the HLAppCore and HLMacUI packages |
| handlive-apple | 565dbc2 | docs(apple): describe the app and UI packages, pairing and the command line workflow |
| handlive-apple | 2ff73f6 | fix(apple): keep the pair store writable while the screen is locked |
| handlive-apple | 1483d5a | feat(apple): link the welcome screen to the privacy page |
| handlive-apple | be86f6b | test(apple): check the privacy page follows the display language |
| handlive-apple | a21bd0e | fix(apple): show the Security Code as 8 lowercase hex characters |
| handlive-apple | 7f8aa97 | feat(apple): show the Security Code on the paired step |

## Files

- `apple/Packages/HLAppCore/` (new): `AppSettings`, `DeviceIdentityKeys`, `LocalDevice`, `PairedDeviceRecord`,
  `PairedDeviceStore`; `Tests/HLAppCoreTests/AppCoreTests.swift`.
- `apple/Packages/HLMacUI/` (new): `AppModel` (+`Link`, `Settings`, `Pairing`, `Clipboard`), `AppActions`,
  `AppCoordinator`, `HandLiveScenes`, `WindowPresenter`, `MenuBarViews`, `SettingsView`, `DevicesSettingsPane`,
  `OnboardingFlow`, `OnboardingView`, `OnboardingPage`, `MacSystem`; tests `TestSupport`, `AppModelTests`,
  `AppCoordinatorTests` (+ pairing and clipboard tests of M1.3/M1.4).
- `apple/macOS/HandLive/HandLiveMacApp.swift`, `apple/macOS/HandLive.entitlements`, `apple/project.yml`,
  `apple/HandLive.xcworkspace`, `.github/workflows/ci-apple.yml`, `README.md`, `README.vi.md`, `CLAUDE.md`.
- `apple/Packages/HLCrypto`: `SecretStore.deleteAll()` (Keychain and in-memory).

## Tests (real output)

```text
$ cd apple/Packages/HLAppCore && HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk swift test
✔ Test run with 40 tests in 10 suites passed after 2.176 seconds.        (settings, keys, capability, pair store + clipboard)
$ cd apple/Packages/HLMacUI && HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=…/MacOSX26.sdk swift test
✔ Test run with 17 tests in 4 suites passed after 1.802 seconds.
$ cd apple && TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict
Done linting! Found 0 violations, 0 serious in 189 files.
```

The app entry point was also compiled locally as an executable against HLMacUI (scratch SwiftPM package, `Build
complete!`), and CI builds the real app target with Xcode.

Covered by tests: launch creates the keys and reaches ready; a Keychain that refuses (−34018) → E1 with Try Again;
fresh install clears old Keychain items; settings persist and clamp; StatusIndicator mapping of every 0.11 state;
unpairing without a session (flow B); Dock menu items and dimming; ⌘W/Esc handling; privacy page language; the
paired pair store and polling state (M1.4). SET-03 exceptions: E1 tested; E2–E6 are guidance screens that need a
real Mac (below); E7 is Phase 2 (relay).

## CI

- https://github.com/HandLive/handlive-apple/actions/runs/36183079256 — success on 0039d94: xcodebuild test of all
  7 packages incl. HLAppCore (35) and HLMacUI (17), SwiftLint 0 violations, `xcodebuild build -scheme HandLive`
  (unsigned) succeeded.
- 36180758861 — success on 927fb6b (first run with the app target on HLAppCore/HLMacUI).
- https://github.com/HandLive/handlive-apple/actions/runs/36185259682 — success on 7f8aa97 (Security Code, privacy
  link): HLAppCore 40, HLMacUI 17 tests, SwiftLint 0 violations in 189 files, app build succeeded.

## Spec deviations and proposals

1. **Pair store is a sealed file, not SQLCipher (0.9.3).** Phase 1 keeps only `paired_device`; the file is sealed with
   `db_key` (XChaCha20-Poly1305, AAD `handlive/v1/paired-devices`) behind the same store API. The SQLCipher database
   comes with the SMS tables in Phase 2 (Apache-2.0 compatible build needed). Proposal: accept the file for Phase 1.
2. **File protection class C, not "complete".** A test failed while this Mac's screen was locked: complete protection
   refuses every write then, and the menu bar app keeps connecting and updating the pair while locked. Class C
   (until first unlock) keeps the file protected at rest; the content is sealed with `db_key` anyway.
3. **Three Settings panes in Phase 1** (General, Devices, Clipboard); Messages, Calls and Camera come with their
   features. The card says six panes.
4. **Settings from code**: macOS 14+ ignores `showSettingsWindow:`, so reopening opens Settings through the app
   menu's own "Settings…" item (⌘,) and uses the action only on macOS 13.
5. **Reopen while paired opens Settings**: Phase 1 has no Messages window (03-platforms/01-macos.md says Messages).
6. **Welcome window without feature rows**: the catalog has no texts for the rows (SET-03 field 1 defines only the
   introduction); the "HandLive and Your Privacy" link is there. Proposal: add the four Mac feature rows to the
   catalog or drop them from the Onboarding README.
7. **Keychain and signing**: the data-protection keychain needs `keychain-access-groups`, which needs a signed app
   with a team. CI builds unsigned; an unsigned or ad-hoc local build hits SET-03 E1 (−34018) by design. The
   Developer ID team must be set in the signing setup (docs/deployment-guide.md).
8. **Time-sensitive notifications** entitlement (SET-03 special requirements) is not added yet: it only matters for
   incoming calls (Phase 3).
9. **Security Code format**: fixed to 8 lowercase hex characters (PAIR-02 field 10, as on Android) — it was shown as
   two uppercase groups before a21bd0e.

## Pending manual checks

- Menus: with "Show HandLive in Menu Bar" off, Dock icon and the HandLive · File · Edit · View · Window · Help menu
  bar; run with `-AppleLanguages (vi)` and check Tệp/Sửa/Xem/Cửa sổ/Trợ giúp and every HandLive string in Vietnamese.
- ⌘W and Esc close the welcome and Settings windows in `.accessory` mode (the design system asks for a real Mac).
- Settings opens from Finder reopen on macOS 13, 14, 15 and 26.
- Login item: register, `requiresApproval` guide, System Settings › General › Login Items.
- Move to /Applications from a disk image and from Downloads (App Translocation → drag hint).
- Local network prompt on macOS 15+ (first browse), notification prompt, paste permission guide on macOS 15.4+.
- Menu bar icon: Magic Replace of the checkmark on macOS 15/26, variable color while connecting (off with Reduce
  Motion), plain swap on macOS 13.
- A signed build (Developer ID) to check the Keychain entitlement.

Status: DONE_WITH_CONCERNS
Summary: The Mac app runs from HLMacUI: menu bar menu and icon, activation policy, welcome window through pairing,
Settings (General, Devices, Clipboard), login item, local network and paste permission guides, Dock menu, reopen,
sleep/wake and quit; packages tested locally and on CI, the app target builds on CI.
Concerns/Blockers: three of six Settings panes (the others belong to later phases); the UI itself (menus, languages,
⌘W/Esc, prompts) still needs a pass on a real Mac, and a signed build for the Keychain.
