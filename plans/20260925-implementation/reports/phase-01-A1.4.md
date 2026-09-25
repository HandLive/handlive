# Phase 1 — A1.4 [android]: Screens (SET-01, SET-02, Devices, pairing, ConsentSheet, Feedback)

Card A1.4 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-android, branch `feat/phase-01-clipboard`, pushed; CI `ci-android` green on 58ffe4e; one catalog commit in handlive-shared (under the workspace lock). Built on the APIs of A1.1–A1.3; the pairing screens A1.2 left for this card are included.

## What was done

- **Design components** (`core/design`, all texts passed in from the catalog): floating `HLTabBar` (glass capsule, filled symbol when selected, opaque on API 29–30 and in increased contrast), `HLAlert` ("Cancel" left, action right, destructive colour), `HLActionSheet` (actions group + separate Cancel), `HLFeedbackHost` HUD (glass pill at the top for 1.5 s, CONFIRM haptic, polite live region, no motion when animations are off), `HLStepScreen` (primer/onboarding layout: symbol in an `accent-tint` circle, heading, scrolling text, buttons at the bottom), `HLScreenHeader` (large title as a heading, `chevron_left` + previous screen's name), list rows `valueRow`, `checkRow` (radio semantics), switch descriptions, and `HLLabelValueLayout` (label and value on one line while they fit, stacked otherwise — found by the 200 % test, see below).
- **SET-01 part A** (`ui/onboarding`): welcome ("Welcome to HandLive", the privacy text, "Get Started"; identity keys created in the background, `setup.started_at`) → notifications primer on Android 13+ (one "Continue", then the system dialog) → service start with one automatic retry in the foreground and "Couldn't Start the Connection Service" + "Try Again" (E2) → background primer ("Continue" opens `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, falls back to the list) → "Keep HandLive Running" with the Xiaomi / OPPO / Samsung instructions, "Open Manufacturer Settings" (Xiaomi's AutoStart screen, others App info), "Pause app activity if unused" (Android 11+, `PackageManagerCompat`), "Done" / "Skip" → `setup.completed_at` → the pairing screen (step 7). Every step skips itself when already satisfied; the environment is read again on every resume.
- **Main app** (`ui/main`): Devices and Settings tabs under the floating tab bar, subscreens on a back stack with the system back gesture and predictive back (`enableOnBackInvokedCallback`), edge-to-edge, the HUD, E1 banner "Notifications are off…" with "Open Notification Settings", E2 banner with "Try Again", service restarted on resume when stopped or failed, `refreshEnvironment()` on resume, the clipboard focus hooks of A1.3, "<name> unpaired this device" as a HUD (PAIR-03 field 5).
- **Devices (PAIR-02)**: `DeviceRow` (72 dp, platform symbol tile, one-line name with "…", `HLStatusIndicator`, chevron), empty state "No Devices Yet" + sentence + "Add Device"; details: status, Model, Last Connected (ICU relative time in the app language), App Version, Features › Clipboard ("On", "Off on <device>", "Off"), Security Code in two groups (`fc64 7e0b`, selectable, mono), "Unpair" behind an action sheet (PAIR-03 field 3) → HUD "Unpaired" or "Unpaired; <device> will clean up when it reconnects".
- **Pairing (PAIR-01 on the phone)**: "Pair a Device" with "Scan QR Code" / "Enter PIN"; camera primer (one "Continue") → CameraX + ZXing scanner full screen with the hint; E9 camera denied → "Enter PIN" and "Open Settings" (E5); "Pair with <name>?" alert ("Pair" right, "Cancel" left); "Pairing…" with Cancel (E5); PIN entry (6 digits, numeric keyboard) with the wrong-PIN text and "N attempts left"; result "Paired with <name>" + Security Code; E1/E2/E4/E6 texts; leaving cancels the window.
- **Settings (SET-02 Phase 1 scope)**: Clipboard group — Sync Clipboard, Auto-Send on Copy, Sync Images, Block Sensitive Content (each with its one-line description), Auto-Clear Received Clipboard (Off / After 1 Minute / After 5 Minutes subscreen with the footnote); Internet Connection; Permissions & Background; Language (Android 13+ opens the system per-app language page, 10–12 an in-app list applied through AppCompat). Auto-send status: "Agreed on <date> at <time>" (field 3) or "Auto-send isn't on yet" (E8).
- **ConsentSheet** (CLIP-01 fields 2–3, SET-01 field 13): full screen, the feature's name, the four disclosure statements with symbols, "Agree" full width and "Send Manually"; Agree records `clip.a11y_consent_at` and opens Settings › Accessibility, after the "Restricted setting" help on Android 13+ when not installed from Google Play (field 14, E7); Send Manually turns auto-send off (E6).
- **Permissions & Background** (SET-02 field 23 → SET-01 fields 3, 6–9, 15): Notifications, Run in Background (with the E3 warning under it), Pause app activity if unused, the manufacturer instructions with their button, and the auto-send state; each row opens the page that changes it.

## Catalog change (handlive-shared, `feat/phase-01-clipboard`, under `.locks/shared`)

| Hash | Subject |
|------|---------|
| 2f2c4bb | feat(shared): add Android strings for primers, device details and setting descriptions |

17 Android-only keys, all marked "Proposed text": `permission.notifications_primer_title_android`, `permission.background_primer_title`, `permission.camera_qr_primer_title`, `setup.autostart_title`, `pairing.empty_body_android`, `pairing.model`, `pairing.last_connected`, `pairing.app_version`, `pairing.features`, `pairing.pin_entry_hint`, `settings.notifications`, `settings.run_in_background`, `settings.{sync_clipboard,auto_send,sync_images,block_sensitive,internet_connection}_description`. `check_strings.py`: 205 strings, 0 errors, 0 warnings; `--self-test` 96 passed. **Shared change: the Apple agent does not need to regenerate (no macos/ios entry changed).**

## Commits (handlive-android)

| Hash | Subject |
|------|---------|
| fd202d0 | feat(android): add tab bar, alert, action sheet, feedback HUD, step screen and list rows |
| 1bdbff9 | test(android): check roles, states and callbacks of the navigation components |
| 191b83a | feat(android): lay out label and value rows so large text is never squeezed |
| d822604 | feat(android): let the UI wait for the outcome of a service start |
| ed6686d | fix(android): keep a failed identity preload of the clipboard quiet |
| e82b3bc | feat(android): run the first-run setup with primers, service start and autostart help |
| 07430de | feat(android): list paired devices with details, Security Code and unpairing |
| 5f0f191 | feat(android): pair a Mac or iPhone from the phone by QR code or PIN |
| e9a14b9 | feat(android): add Settings with the clipboard options, permissions and language |
| 3b63929 | feat(android): put the tabs, subscreens and feedback HUD together in the app |
| 559c409 | test(android): check the setup order, text fit at 200 percent and TalkBack headings |
| 80111af | docs: describe the app screens of Phase 1 |
| 58ffe4e | feat(android): offer App info when the camera permission is denied |

## Files

Created: `app/src/main/kotlin/app/handlive/android/ui/**` — `AppDependencies.kt`, `HandLiveApp.kt`, `system/{PhoneEnvironment,SystemPages}.kt`, `onboarding/{SetupSteps,SetupScreens,OnboardingFlow}.kt`, `main/{MainScreen,MainContext,Route,ResumedState,StatusBanners,TabRoutes,SubscreenRoutes,SettingsActionsImpl}.kt`, `devices/{DeviceRows,DevicesScreen,DeviceDetailsScreen,RelativeTime}.kt`, `pairing/{PairingScreens,PairingFlow}.kt`, `settings/{SettingsModel,SettingsScreen,ChoiceScreens,PermissionsScreen,ConsentScreen}.kt`; tests `ui/{UiSamples,ScreenCatalog,ScreenTextFitTest,ScreenSemanticsTest}.kt`, `ui/onboarding/SetupStepsTest.kt`; `core/design/.../component/{HLTabBar,HLTabItem,HLAlert,HLActionSheet,HLSheetAction,HLFeedback,HLStepScreen,HLScreenHeader,HLLabelValueLayout}.kt` + `HLNavigationComponentsTest`.
Changed: `MainActivity.kt` (edge-to-edge, theme, root), `AndroidManifest.xml` (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `enableOnBackInvokedCallback`), `app/build.gradle.kts` (lifecycle-runtime-compose, DataStore, Compose UI test), `HLGroupedList*.kt`, `ConnectionRuntime`/`ServiceLauncher`/`HandLiveService` (`markLaunch`), `ClipboardModule` (quiet preload), `README.md`, `README.vi.md`.

## Tests (real output)

```text
$ ./gradlew check        # JDK 21, platforms;android-37.0
BUILD SUCCESSFUL
$ ./gradlew :app:assembleDebug   # merged manifest: clipfiles provider, tile, share alias, a11y service
app-debug.apk 57.3 MB
app tests=12, failures=0:
  ScreenTextFitTest 3   22 screens × {en 411 dp, vi 411 dp, vi 320 dp} at 200 % text (native graphics):
                        no line wider than its box, taller than its box or ellipsized, except the device
                        name in its row (one line with "…" by design)
  ScreenSemanticsTest 3 every screen has a heading; Settings switches read Role.Switch + "Bật"; tabs selected
  SetupStepsTest 3      step order and skips; manufacturer table
  AppLanguageSettingTest 3
core:design HLNavigationComponentsTest 5 (tabs, alert, action sheet, HUD live region and 1.5 s, check/value rows)
```

The 200 % test found a real defect before commit: a value row gave its label the leftover width, so "Clipboard" wrapped one letter per line next to "Off on MacBook của Lan". `HLLabelValueLayout` now stacks label and value when both do not fit.

## Spec deviations and proposals

1. **Proposed texts.** 17 strings the specs do not spell out (primer titles, device-detail labels, setting descriptions, empty-state sentence, PIN hint) were added as "Proposed text"; they need to go into SET-01, SET-02, PAIR-01 and PAIR-02 (both languages).
2. **Welcome privacy link** is not shown: SET-01 field 1 and the Onboarding component name a privacy page, but neither its text nor its URL exists. Proposal: define the page (catalog keys or a URL).
3. **ConsentSheet is full screen** as SET-01 field 13 says ("Shown full screen"); the component README describes a bottom sheet with a drag handle (swipe down = Cancel). The two documents disagree; the detailed design was followed.
4. **Glass** uses the `glass-fill` token without a real backdrop blur (Compose has no backdrop blur); the large title does not collapse into the top bar on scroll. Both are visual refinements for later.
5. **E2 retry**: the setup retries the service start once automatically, then shows the error; the app retries whenever it comes to the foreground and the service is stopped or failed.
6. **PAIR-01 failures without their own text** (`DISCONNECTED`, `INTERNAL`) show "The QR code has changed…" because a fresh code is what the user needs; proposal: a generic "Pairing didn't finish. Try again." key.
7. **Relative time** uses ICU `RelativeDateTimeFormatter` with the app's locale, not `DateUtils` (which follows the system language and would ignore the per-app language on Android 10–12).
8. **Out of Phase 1 scope** (listed for completeness): SET-01 part B feature cards for SMS/calls (fields 10–11), relay registration at step 7, "Remove Device from Server" and "Delete All HandLive Data" (SET-02 fields 26–30), feature toggles other than the clipboard.

## Pending manual checks (no device here)

- System setting names in English and Vietnamese on Pixel and Samsung (Accessibility / "Hỗ trợ tiếp cận", App info, battery pages, "Pause app activity if unused"), and the OEM pages on Xiaomi and OPPO.
- TalkBack walk-through of setup, pairing, Devices and Settings; 200 % text and Bold Text on a phone (Android 14 nonlinear scaling); the tab bar and HUD over real content in Light/Dark/increased contrast.
- Notification permission denial (E1 banner), battery exemption dialog, restricted-setting flow for an APK install on Android 13+, predictive back gesture.
- Pairing on a real phone with the Mac (M1.3): scanner, confirmation alert, PIN entry, result and Security Code on both screens.

```text
Status: DONE_WITH_CONCERNS
Summary: SET-01 part A, the Devices tab with details and unpairing, the PAIR-01 screens, Settings (clipboard group, Internet Connection, Permissions & Background, Language), the Accessibility ConsentSheet and the Feedback HUD are built from catalog strings in English and Vietnamese, with tests for 200 % text and TalkBack semantics; ./gradlew check green.
Concerns/Blockers: 17 proposed texts await the specs; no real-device run yet (TalkBack, OEM pages, system setting names); the privacy page is undefined.
```

## Follow-up (controller update: catalog keys and privacy page decided from this report)

Repository handlive-android, branch `feat/phase-01-clipboard` (after the S1.3 commits up to 0dc94dd), pushed; CI `ci-android` run 36180009175 green on 4f40e22 (`gradlew check` 4 min, commit author check).

- **`error.pairing_failed`** (PAIR-01 field 10): a lost connection (`DISCONNECTED`) or an internal error now shows "Pairing didn't finish. Try again." (with "Try Again"); "The QR code has changed…" stays for the expired window (E2) only.
- **Privacy link** (SET-01 field 1): the welcome screen shows "HandLive and Your Privacy" as a plain button under the text; it opens https://github.com/HandLive/handlive/blob/main/docs/privacy.vi.md when the app's display language (the activity configuration, so the per-app language counts) is Vietnamese, https://github.com/HandLive/handlive/blob/main/docs/privacy.md otherwise; without a browser nothing happens.
- **Spec clarifications verified against the code, no change needed:**

| Clarification | Where it is |
|---------------|-------------|
| Clipboard channel `IMPORTANCE_LOW`, catalog descriptions for all three channels | `NotificationChannels` (comment now cites SET-01 fields 5, 17 and CLIP-01 field 8); new test checks the three descriptions |
| Too-large toast on both paths | `LocalClipIntake.send`; test covers the automatic and manual path (A1.3 follow-up) |
| Lowercase Security Code shown after pairing | `PairStore.safetyCode` (8 lowercase hex), shown on the pairing result and in the details as `fc64 7e0b`; new `SecurityCodeTest` |
| IP blocking counts every `AUTH_FAILED` hello | `ConnectionAdmission` / `ControlConnectionHandler` since A1.0 (`ControlChannelLimitsTest`) |
| Keyset names `hl_secret_keyset` in `handlive_keyset` | `AndroidKeystoreSecretStore` (`KEYSET_NAME`, `KEYSET_PREFS`) |
| ZXing core in PAIR-01 field 4 | `feature/pairing/scan` (CameraX + ZXing core, no ML Kit) |

| Hash | Subject |
|------|---------|
| c6eee69 | feat(android): show the generic pairing error for lost connections and internal failures |
| 79fb1e8 | test(android): check the pairing error texts and fit the generic one at 200 percent |
| 92b666e | feat(android): open the privacy page in the app's language from the welcome screen |
| 21d6619 | test(android): check the privacy link and the page chosen for each language |
| 4f40e22 | test(android): check the channel descriptions and the Security Code form |

```text
$ ./gradlew check
BUILD SUCCESSFUL
app tests=19, failures=0 — new: PairingFailureMessageTest 2 (E1–E9 texts kept; DISCONNECTED and INTERNAL →
  error.pairing_failed), PrivacyPageTest 2 (vi, vi-VN → privacy.vi.md; en, en-US, en-XA, fr → privacy.md),
  WelcomeScreenTest 2 (link is a button, both callbacks; Vietnamese text), SecurityCodeTest 1;
  ScreenTextFitTest now covers 23 screens (the welcome screen with its link, "pairing lost") at 200 % in en and vi
```

The 17 proposed texts of this card are now in the specs (controller), so that concern is closed; the privacy page exists and is linked.

```text
Status: DONE_WITH_CONCERNS
Summary: The generic pairing error and the privacy link are adopted, the six spec clarifications match the build (checked by tests where they are UI-visible); ./gradlew check and CI green.
Concerns/Blockers: no real-device run yet (TalkBack, OEM pages, system setting names, pairing with the Mac).
```
