# Phase 6 — spike G6 (gate G6): reading the open web page on Android and on the Mac

Question (`plans/20260928-web-handoff/plan.md` W3, W4, W8): can an Android AccessibilityService limited to the
browsers read the page address and tell private tabs apart, at an acceptable cost; can the Mac read the front
browser tab through Apple Events, detect private windows (Safari is the open case), and how does the Automation (TCC)
permission behave; and what does Google Play's Accessibility policy ask of this use? No other WEB card starts before
this answer.

## Prepared (2026-09-28)

### Android probe — handlive-android `feat/phase-06-web-handoff`, `tools/web-spike/`

- **Standalone build:** own `settings.gradle.kts`, reuses `gradle/libs.versions.toml` (AGP 9.4.1, Kotlin 2.4.20),
  not in the root build or CI. Package `app.handlive.spike.web`, no INTERNET permission, no AndroidX. Build:
  `./gradlew -p tools/web-spike testDebugUnitTest assembleDebug`.
- **Service "HandLive Browser Pages (spike)":** `canRetrieveWindowContent=true`, `flagReportViewIds`,
  `packageNames` = Chrome, Samsung Internet, Firefox, Edge, Brave, Opera, Vivaldi, DuckDuckGo, only
  `typeWindowStateChanged|typeWindowContentChanged`, `notificationTimeout=500`, `isAccessibilityTool=false`.
  Also `canTakeScreenshot` for a spike-only FLAG_SECURE probe (API 34+ `takeScreenshotOfWindow` fails with
  `ERROR_TAKE_SCREENSHOT_SECURE_WINDOW`; the picture is discarded at once).
- **Adapters (strategy):** a table per browser — known URL bar ids (`url_bar`, `location_bar_edit_text`,
  `mozac_browser_toolbar_url_view`, `url_field`, `omnibarTextInput`…) then a fallback (first editable field holding
  an address); private markers per browser (incognito / secret / InPrivate / private in view ids or descriptions).
  Found by fallback and no marker → `private=unknown` (the product would not send).
- **Flow:** events coalesced to one window read per 250 ms; focused bar = typing, ignored; `WEB_SETTLE` 1.5 s
  debounce; private check at settle time; `inactive` on leaving the browser (polled every 2 s while a page is active,
  since `packageNames` hides other apps' events), screen off, or private.
- **Log:** `HLWEB` lines to logcat and `/sdcard/Android/data/app.handlive.spike.web/files/hlweb.log`: browser,
  version, API, host only, 12-hex salted SHA-256 of the full URL (per-install salt), `host_only`, private flag and
  marker, `via` id/fallback, source view id, `secure`; `stats` every 5 min (events, main-thread CPU ms, nodes read).
  Private pages log no host. Activity shows the log, exports CSV (system file picker), and triggers a **dump**
  (node tree: classes, ids, flags; text/descriptions redacted to length, plus `url=host_only|full` and
  `private_hint`). Dumps can also be triggered by `adb shell am broadcast -a app.handlive.spike.web.DUMP`.
- **Runbook:** `android/tools/web-spike/README.md` (build, browsers to install, turning the service on by hand
  incl. Android 13+ "Allow restricted settings", log format, dump mode, W8 matrix, CPU/battery commands, results
  tables).

### Mac probe — handlive-apple `feat/phase-06-web-handoff`, `Tools/WebSpike/`

- **SwiftPM, no app bundle needed for the logic:** library `WebSpikeCore` (URL normalization with an RFC 3492
  Punycode encoder since macOS 13 Foundation has no IDNA API, browser table and AppleScripts, settle gate, log
  lines, Safari bounds parsing) + executable `WebSpike` + tests. Info.plist (with `NSAppleEventsUsageDescription`)
  embedded in the binary like HFPSpike. Not added to ci-apple (HFPSpike is only built there on its own branch);
  SwiftLint in CI does lint `Tools/` and passes.
- **Commands:** `permissions` (Automation state per running browser via `AEDeterminePermissionToAutomateTarget`,
  never prompts), `ask <browser>`, `once <browser>`, `watch [--log] [--interval 1.5]` (NSWorkspace activation, session
  resign/active, screen sleep, system sleep, screen lock/unlock; polls only while a supported browser is frontmost),
  `ax-dump` (AX tree of the front browser window outside `AXWebArea`, values redacted).
- **Scripts:** Safari `current tab of front window` (URL, name, window bounds); Chromium (Chrome, Edge, Brave,
  Vivaldi, Opera) `active tab` + window `mode`; Arc `active tab` + a guarded `incognito` read. `with timeout of 2
  seconds`, `tell application id`.
- **Safari private detection (spike question):** two probes logged per page — `bounds_match` (scripted front window
  vs frontmost on-screen Safari window from `CGWindowListCopyWindowInfo`; a mismatch suggests a window hidden from
  scripting) and, if the process is Accessibility-trusted, an AX search for "private" in the window chrome. No
  evidence → `private=unknown`.
- **TCC answer (from the platform rules, to confirm on devices):** run from a terminal, the *terminal* is the
  responsible app and gets the prompt and the Automation entry; the embedded Info.plist does not change that. To test
  what the product will see, `Support/make-app.sh` wraps the binary into `WebSpike.app` (LSUIElement), signs it with
  hardened runtime + `com.apple.security.automation.apple-events` (ad-hoc, or `SIGN_IDENTITY=` Developer ID;
  `NO_ENTITLEMENT=1` for the negative case, expected `-1743` without prompt). Ad-hoc signatures change per build, so
  TCC re-asks after rebuilds; Developer ID keeps the grant.
- **Runbook:** `apple/Tools/WebSpike/README.md` (build, who gets the permission, commands, log format, Safari probes,
  W8 matrix, TCC cases, CPU, results tables).

## Checked here

- Android: 21 JVM unit tests pass (URL normalization: host-only → `https://host`, paths/query/fragment kept,
  host:port and localhost, non-http(s) schemes and search terms rejected, user info rejected, IDN → punycode incl. a
  Cyrillic look-alike, 8 KiB limit; adapter selection by package, wire ids, `packageNames` in the XML matches the
  adapter table; id-first and fallback bar search; private markers and unknown; settle gate; log/CSV/hash). ktlint
  clean. Debug APK built (2.9 MB), installed on emulator `hl-api29` (booted headless on port 5590, then shut down):
  the activity starts and the service is registered (`cmd package query-services`), status "Service: off". The
  service was **not** enabled (security setting, owner only); `hl-claude-api35` was not touched.
- Browsers on the emulators: `hl-api29` (google_apis, no Play Store) has only Chrome 91.0.4472.114 and the WebView;
  `hl-claude-api35` is the same image type (not booted). Samsung Internet, Firefox, Edge, Brave (and optional Opera,
  Vivaldi, DuckDuckGo) must be installed by the owner from the Play Store on real phones — none was downloaded.
- Mac: `swift build` (debug and release) with Xcode's Swift 6.4, 13 Swift Testing tests pass (normalization incl.
  punycode vectors checked against Python's codec, rejection list, 8 KiB, browser table, scripts, Chromium/Arc/Safari
  verdicts, Safari bounds, settle gate, log lines), `swiftlint lint --strict` clean. `make-app.sh` builds an ad-hoc,
  hardened-runtime bundle with the entitlement. `WebSpike permissions` ran on this Mac (macOS 27): Safari and Chrome
  `not_determined` (-1744) for the terminal, others not running — no prompt shown, no Apple Event sent to a browser.
  `watch`, `once`, `ask` and `ax-dump` were **not** run.
- CI: both branches pushed; ci-android `36451617796` and ci-apple `36451611473` fail in one product test each
  (`ErrorCodeAndTypeCatalogTest.messageTypesMatchSchemaInOrder`, `MessageType … envelope.schema.json`): handlive-shared
  `main` now lists the `web` type and the product code does not yet. `main` fails the same way (runs `36450699324`,
  `36450704048`); another agent's `fix/web-message-type` branches cover it. The spikes are not in these builds;
  ci-apple stopped before SwiftLint, so the local `swiftlint --strict` run is the only lint result for `Tools/WebSpike`.

## Google Play policy (checked 2026-09-28)

- [Use of the AccessibilityService API](https://support.google.com/googleplay/android-developer/answer/10964491):
  `isAccessibilityTool="true"` only for apps built primarily for people with disabilities (screen readers, switch,
  voice, Braille) — not HandLive. Every other use must have an in-app **prominent disclosure** and **affirmative
  consent**, and a **Play Console accessibility declaration** (required since 2021 for apps using the API; a demo
  video is asked). Undisclosed or deceptive use can lead to suspension. The declaration lists the data accessed —
  "web browsing" is one of the categories, so Continue Browsing must be declared as reading the page address.
- [Permissions and APIs that access sensitive information](https://support.google.com/googleplay/android-developer/answer/16558241):
  the API may not be used to change settings without permission, work around platform security, or for apps that
  "autonomously initiate, plan, and execute actions"; Continue Browsing only reads and does not act, so it is outside
  those bans.
- [Best practices for prominent disclosure](https://support.google.com/googleplay/android-developer/answer/11150561):
  in the app, shown right before the permission request, not only in the privacy policy or store listing, not mixed
  with other disclosures; says what data (page addresses and titles of the listed browsers), why and how it is used
  (sent end-to-end encrypted to the user's paired devices, never stored or sent to the relay in clear); two choices
  (agree / not now); no imitation of system dialogs.
- Consequences for the spec: a separate disclosure for the "HandLive Browser Pages" service (not reused from the
  clipboard one), the declaration and demo video in Play Console (gate G2), Data safety to be reviewed for "web
  browsing" even though data only goes E2E to the user's own devices; if Play refuses, the F-Droid / direct APK
  fallback of the SMS risk applies (W3). Note: `canTakeScreenshot` is a spike-only probe and must not ship unless the
  spike shows it is the only reliable FLAG_SECURE/private detector (it widens the consent dialog).

## To run (owner, with real devices)

- Android: a Pixel or other stock phone on Android 15 (API 35) and one on Android 10 (API 29), ideally a Samsung for
  Samsung Internet; install the browsers; install the APK; turn the service on by hand (runbook); run the matrix and
  the 30-minute CPU/battery check; send the log/CSV and the dumps for browsers with `nobar`/`fallback`.
- Mac: Macs on macOS 26 and on 13 or 14 (this Mac, macOS 27, as a third point); Safari, Chrome, Arc (+ others if
  installed); run `watch` from the terminal, then from `WebSpike.app` (ad-hoc, no entitlement, Developer ID if an
  identity is available); Safari private windows with and without Accessibility trust, plus `ax-dump`.

## Results

Fill in the tables in `android/tools/web-spike/README.md` and `apple/Tools/WebSpike/README.md` and copy the summary
here:

| Platform | Browser | Normal page found | Full URL or host only | Private detected | Cost | Go / no-go |
|----------|---------|-------------------|-----------------------|------------------|------|------------|
| Android 35 / 29 | Chrome | | | | | |
| Android 35 / 29 | Samsung Internet | | | | | |
| Android 35 / 29 | Firefox | | | | | |
| Android 35 / 29 | Edge | | | | | |
| Android 35 / 29 | Brave | | | | | |
| macOS 26 / 13–14 | Safari | | — | | | |
| macOS 26 / 13–14 | Chrome | | — | | | |
| macOS 26 / 13–14 | Arc | | — | | | |

## Decision rule

Per browser: go when the page is found by a known id (Android) or by Apple Events (Mac) on both OS levels and private
tabs/windows are never reported as active; otherwise the browser is listed as unsupported in `09-web-handoff.md`.
Chrome on Android showing only the host in its bar is a likely finding: the owner then decides whether origin-only
Continue Browsing is acceptable for it. Safari goes only if a probe detects private windows without Accessibility, or
the owner accepts the Accessibility permission; otherwise Safari sends nothing.

## Commits

handlive-android, `feat/phase-06-web-handoff` (from `origin/main` `41f905e`, pushed):
- `5a476f5` feat(android): add the web spike build and browser adapters
- `692d0ae` test(android): cover URL normalization, adapters and the settle gate of the web spike
- `997e502` feat(android): add the browser pages accessibility service and log screen to the web spike
- `6dc492b` docs(android): add the web spike runbook and results table

handlive-apple, `feat/phase-06-web-handoff` (from `origin/main` `6487c16`, pushed; built in a temporary worktree,
removed afterwards; the `apple/` and `android/` checkouts were not switched):
- `ade3a86` feat(apple): add the web spike package with URL normalization and the browser table
- `92ebc87` test(apple): cover the web spike's normalization, browser table and settle gate
- `088e294` feat(apple): add the web spike watcher, Apple Events reader and Safari private probes
- `556bd61` feat(apple): add the web spike Info.plist, entitlement and app bundle script
- `6a57e6a` docs(apple): add the web spike runbook and results tables

No change in shared/, relay/ or hub docs.

Status: BLOCKED
Summary: Both probes and their runbooks are built, unit-tested and pushed, and the Play policy is summarized; gate G6 itself needs the owner's phones with the browsers installed, the accessibility service turned on by hand, Automation grants on Macs running macOS 26 and 13/14.
Concerns/Blockers: only Chrome 91 is available on the emulators (no Play Store); Android Chrome likely shows the host only in its bar (origin-only pages) — to confirm; Safari private-window detection has no documented API and may need the Accessibility permission; the spike service declares `canTakeScreenshot` for the FLAG_SECURE probe, which the product should not ship without a decision; CI on both branches is red for the same reason as `main` (shared `web` type not yet in the product code; being fixed on `fix/web-message-type`), not because of the spikes.
