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

## Emulator run (hl-api29, Chrome 91)

2026-09-29, emulator `emulator-5590` (AVD `hl-api29`, google_apis arm64, API 29), Chrome 91.0.4472.114, spike
built from `feat/phase-06-web-handoff`. On this disposable emulator the service was turned on with `adb shell
settings put secure enabled_accessibility_services …` + `accessibility_enabled 1` (owner's approval for this device
only). Chrome's first-run screen was skipped with the debug command-line file
(`/data/local/tmp/chrome-command-line`: `--disable-fre --no-first-run --no-default-browser-check`), so no terms were
accepted and no account was used. Only public test pages were opened.

**Host condition:** the Mac was overloaded the whole time (load 20–60: `fileproviderd`, Synology Drive, Time
Machine, Spotlight). The emulator froze for up to 7 minutes, `am start` took 10 s to 9 min, and from about 09:00
`system_server` was killed by the Android watchdog every 4–15 minutes (`Watchdog: *** GOODBYE!` at 09:11, 09:30,
09:45, 09:53, 10:00, 10:04, 10:17, 10:21). The spike process was killed once too (pid 3538 → 6062). Timings and
`cpu_ms` from this run do not count, and the incognito, screen-off and tab-switch steps could not be run (below).

### 1. URL bar node and what it shows

- Found by id: `com.android.chrome:id/url_bar` (`EditText`, editable), inside `id/location_bar`, next to
  `id/location_bar_status_icon`. `via=id` on every page; no `nobar`, no `fallback`.
- **Idle bar: full address without the scheme** — not host only. Read with `uiautomator dump`:
  `example.com/path?q=1#frag`, `example.com/plain-http`, `en.wikipedia.org/wiki/Handoff`; the root page shows as
  `example.com` (logged `host_only=true`, which is right for a root page: the flag cannot tell "root" from "path
  hidden"). Query and fragment are kept. An IDN shows in Unicode (`bücher.example`) and is logged in punycode
  (`host=xn--bcher-kva.example`).
- **The scheme is hidden for http too:** `http://example.com/plain-http` shows as `example.com/plain-http`, so the
  normalizer built `https://example.com/plain-http` (wrong scheme). The only hint is the status icon's description:
  "Your connection to this site is not secure. Site information" (http) vs "Connection is secure. Site information"
  (https) — localized text, so not a reliable key. Fixed in the probe as a measurement: the active line now says
  `scheme=shown|assumed` (below). For the product (W3/WEB-01): either accept that Chrome http pages are sent as
  https (the receiver's page may then fail or redirect), or read the status icon's description per locale.
- **Focused bar:** when the bar is tapped, Chrome 91 empties the field (the node's text is the 26-character hint
  "Search or type web address"; an empty `EditText` reports its hint as text on API 29) and moves the current address
  to the first suggestion row (`id/line_2`, `url=full`, still without the scheme). The spike ignores a focused bar,
  so this is harmless.
- **Full address with scheme:** no node holds it. The `WebView` node's text is the page title (redacted length 14 on
  example.com), not the URL. The best available is scheme-less full address from `url_bar`.

### 2. Debounce and typing

One `active` line per page, about 1.5 s after `am start` (Chrome writes the address in the bar before the page loads,
so the settle clock starts at once). Typing `example.org/typed` then `x` into the focused bar, waiting 10 s: nothing
logged. In-page address changes (Wikipedia replaces `/wiki/Handoff` with `/wiki/Handover` through the History API)
give a new hash for the same host, as expected.

```
HLWEB ts=2026-09-29T08:32:19.882+07:00 ev=active browser=chrome ver=91.0.4472.114 api=29 host=example.com hash=e2c215b585e0 host_only=true private=false via=id source=com.android.chrome:id/url_bar secure=n/a
HLWEB ts=2026-09-29T08:32:26.27+07:00 ev=active browser=chrome ver=91.0.4472.114 api=29 host=example.com hash=429dc28254c1 host_only=false private=false via=id source=com.android.chrome:id/url_bar secure=n/a
HLWEB ts=2026-09-29T08:32:32.961+07:00 ev=active browser=chrome ver=91.0.4472.114 api=29 host=en.wikipedia.org hash=222981a00eea host_only=false private=false via=id source=com.android.chrome:id/url_bar secure=n/a
HLWEB ts=2026-09-29T08:31:31.77+07:00 ev=active browser=chrome ver=91.0.4472.114 api=29 host=xn--bcher-kva.example hash=2bcd5f49841e host_only=true private=false via=id source=com.android.chrome:id/url_bar secure=n/a
HLWEB ts=2026-09-29T08:42:00.405+07:00 ev=active browser=chrome ver=91.0.4472.114 api=29 host=example.com hash=4ab803e731e4 host_only=false private=false via=id source=com.android.chrome:id/url_bar secure=n/a
HLWEB ts=2026-09-29T08:53:39.751+07:00 ev=active browser=chrome ver=91.0.4472.114 api=29 host=en.wikipedia.org hash=95297c3a9621 host_only=false private=false via=id source=com.android.chrome:id/url_bar secure=n/a
(tap bar 08:53:44, dump 08:53:47, type 08:53:50 and 08:53:56: no active line)
```

The IDN line came late (08:31:31 for a page opened at 08:27:50) because the emulator was frozen; `www.wikipedia.org`
and a second IDN visit were missed during a 7-minute freeze and a spike process restart.

### 3. Incognito and FLAG_SECURE

**Not run.** Opening an incognito tab needs taps in Chrome's menu, and from 09:00 the emulator's `system_server`
restarted every few minutes (launcher ANR, "Can't find service: package/window", `am start` unable to resolve
Chrome). The private-state logic (`incognito` in a view id or description) is unchanged and still unverified on a
device. FLAG_SECURE on API 29: the screenshot probe is API 34+ only, so every line logs `secure=n/a`; on API 29 the
spike has no FLAG_SECURE signal at all, and private detection there rests on the id/description markers alone.

### 4. Page end

- Leaving Chrome with HOME: `inactive reason=left` (08:59:36, 34 s late because of a freeze).
- **False leave found:** closing the keyboard with Back while the bar was focused gave `inactive reason=left`
  although Chrome stayed in front; `rootInActiveWindow` is briefly null during the keyboard/window transition and the
  poll treated null as "left". Fixed in the probe (below): a null root ends the page only when seen twice in a row
  (2 polls, about 4 s), another app's window still ends it at once, and the line says `front=<package>|none`.
  Returning to the tab then logged the page again (08:58:26, same tab, new `active`).
- Screen off (`input keyevent 26`, 09:03:41): no line, because no page was active at that moment (the HOME step had
  ended it and the return to Chrome was not processed before the screen went off during a freeze). Not verified.
- Switching tabs: not run (same reason as incognito). The Back step above switched to the previous tab and logged
  its page (`hash=222981a00eea`), which is the expected tab-switch behavior, but no tab-switcher test was made.
- `uiautomator dump` side effect: on API 29 each `uiautomator dump` connects a UiAutomation, which unbinds the other
  accessibility services for its duration (`ev=disconnected` / `ev=connected` around each dump, and a new service
  instance with a fresh settle gate). Use the spike's own dump mode, not `uiautomator`, while measuring.

```
HLWEB ts=2026-09-29T08:55:34.766+07:00 ev=inactive browser=chrome hash=95297c3a9621 reason=left   (Back closed the keyboard; Chrome still in front: false leave)
HLWEB ts=2026-09-29T08:58:26.472+07:00 ev=active browser=chrome ver=91.0.4472.114 api=29 host=en.wikipedia.org hash=222981a00eea host_only=false private=false via=id source=com.android.chrome:id/url_bar secure=n/a
HLWEB ts=2026-09-29T08:59:36.733+07:00 ev=inactive browser=chrome hash=222981a00eea reason=left   (HOME)
HLWEB ts=2026-09-29T08:25:22.663+07:00 ev=connected api=29
HLWEB ts=2026-09-29T08:25:37.299+07:00 ev=disconnected   (uiautomator dump)
```

### 5. Dump mode (Chrome 91, API 29)

Normal tab on `http://example.com/plain-http` (17 nodes):

```
FrameLayout
  FrameLayout
    WebView focused text_len=14
      View text_len=156 … (7 page text nodes, redacted)
  ImageButton id=com.android.chrome:id/home_button desc_len=4
  FrameLayout id=com.android.chrome:id/location_bar
    ImageButton id=com.android.chrome:id/location_bar_status_icon desc_len=60
    EditText id=com.android.chrome:id/url_bar editable text_len=22 url=full
  ImageButton id=com.android.chrome:id/tab_switcher_button desc_len=32
  ImageButton id=com.android.chrome:id/menu_button desc_len=30
```

Focused bar (13 nodes): `RecyclerView` of suggestions with `id/line_1`, `id/line_2 text_len=29 url=full`, then
`id/location_bar` › `EditText id/url_bar focused editable text_len=26` (the hint) and `id/mic_button`. No incognito
dump (not run).

### 6. Probe fixes (handlive-android `feat/phase-06-web-handoff`, pushed)

- `b64a965` feat(android): add a foreground check that tolerates one missing window in the web spike — pure
  `ForegroundCheck` + 5 unit tests (TDD: failed first, then passed).
- `eec9d1c` fix(android): end a web spike page only when another app is in front or the window stays missing — the
  2-s poll and the event path share it; `inactive reason=left` gains `front=`.
- `ab06a4f` feat(android): log whether the web spike assumed the https scheme — `NormalizedUrl.schemeShown`, test
  first; active lines gain `scheme=shown|assumed`.
- `4658161` docs(android): describe the scheme and front fields of the web spike log (runbook).

All unit tests and ktlint pass. The rebuilt APK was installed on `emulator-5590` at 10:23 and its service connected
(10:25), but no page could be opened before the emulator's system server stalled again, so the two fixes are
verified by unit tests only, not on the device.

### Firefox and Brave

Not installed: the install of the provided APKs (`fenix-156.0.1…apk`, `BraveMonoarm64.apk`) was refused by this
session's permission policy (third-party code), so the owner has to run `adb -s emulator-5590 install -r <apk>` for
both (or allow it), then repeat steps 1–5 per browser. With the emulator in its current state, a quiet host (or a
cold boot of `hl-api29`) is needed first.

### Chrome 91 / API 29 row (partial)

| Browser (version) | API | Mode | Page found (`via`, `source`) | Full address or host only | Private detected | Typing ignored | `inactive` reasons seen | Go / no-go |
|-------------------|-----|------|------------------------------|---------------------------|------------------|----------------|-------------------------|------------|
| Chrome 91.0.4472.114 | 29 | normal | yes, `id`, `com.android.chrome:id/url_bar` | full path, query and fragment; scheme hidden for https **and** http | — | yes | `left` (HOME; one false `left` fixed) | go for normal tabs, pending incognito |
| Chrome 91.0.4472.114 | 29 | incognito | not run | — | not run (`secure=n/a` below API 34) | — | — | open |

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

## Real device and Mac runs (2026-09-29)

### Galaxy S25 Ultra (SM-S938B), Android 16 (API 36)

The owner connected the phone over USB and turned the spike's accessibility service on by hand; the controller drove
the browsers with `adb` (`am start -a VIEW`, `input keyevent`). Log: `hlweb.log` on the phone, host + hash only.

- **Samsung Internet 30.0.0.67:** URL bar `com.sec.android.app.sbrowser:id/location_bar_edit_text`. Its text is
  U+200E (left-to-right mark) + the **host only** (`example.com` for `example.com/path?q=1#frag`), so the first probe
  build rejected it (`nobar`/invalid). Fixed in `1306e78` (bidi controls are dropped before parsing, test first). After
  the fix every page is `host_only=true`: Samsung Internet can only give the site's origin, never the page.
- **Chrome 153.0.8010.53:** `com.android.chrome:id/url_bar` holds host + path + query + fragment **without the
  scheme**, as on Chrome 91 (`scheme=assumed`).
- **http pages** (`http://neverssl.com`): both browsers hide the scheme, so the probe sends `https://…`.
- **Private:** Samsung Secret mode and Chrome incognito are both detected through FLAG_SECURE (the API 34+ screenshot
  probe returns `ERROR_TAKE_SCREENSHOT_SECURE_WINDOW`; an `adb screencap` of the Secret mode window is black), and no
  host is logged for them. Chrome's `id:incognito_button` marker also fired once on a normal tab (tab switcher), which
  is a false positive: FLAG_SECURE is the reliable signal on API 34+.
- **Page end:** screen off → `inactive reason=screen_off` (works). **HOME does not end the page** in either browser:
  the service only receives events from the browser packages and the 2-s poll did not see the launcher. Must be fixed
  before any product code (e.g. listen to `TYPE_WINDOWS_CHANGED` without the package filter for window changes only,
  or check `getWindows()` in the poll).
- **Cost:** 461 events / 379 ms CPU in 30 s while browsing (~1.3 %); 4 events / 10 ms CPU in 5 min idle.
- Each `uiautomator dump` unbinds and rebinds the service (`disconnected`/`connected` lines), as on the emulator.

### This Mac (macOS 27), `WebSpike.app` (ad-hoc, hardened runtime + Apple Events entitlement)

- The owner granted Automation for Chrome and Safari to "Web Spike" (the prompt named the spike, not the terminal).
- Chrome: URL and title read in 80–240 ms per poll; `mode=normal` reported. Safari: read in 79 ms; `private=unknown`
  (no Accessibility trust). Private windows not tested yet.
- **Private windows (2026-09-29, owner opened them):** Chrome incognito → `mode=incognito`, `private=true`, no host
  logged and no `active` event. Safari private window with `example.com` → `ev=active … private=unknown
  bounds_match=yes ax=untrusted`: without Accessibility trust the probe cannot tell a Safari private window from a
  normal one (both are `unknown`), followed by one Apple Events timeout (`-1712`, 2 s). Under the rule "unknown → do
  not send", Safari would send nothing; Safari needs the Accessibility permission (to be tested) or stays unsupported.
- Cost: 3,887 polls in about 70 minutes of real browsing, 25.7 s CPU in total (~0.6 % while a browser is in front).
- Some web apps (Google Docs, internal dashboards) change the URL every few seconds (query/fragment), which gives a
  new `active` every few seconds: the product needs a rule for such churn (for example, keep `page_id` while only the
  fragment or query changes, or a longer settle for the same host).

## Results

Fill in the tables in `android/tools/web-spike/README.md` and `apple/Tools/WebSpike/README.md` and copy the summary
here:

| Platform | Browser | Normal page found | Full URL or host only | Private detected | Cost | Go / no-go |
|----------|---------|-------------------|-----------------------|------------------|------|------------|
| Android 36 (S25 Ultra) / 29 (emu) | Chrome 153 / 91 | yes (`url_bar`) | full path, no scheme | yes (FLAG_SECURE, API 36) | ~1.3 % CPU browsing | go, with the http→https and HOME fixes |
| Android 36 (S25 Ultra) | Samsung Internet 30 | yes (`location_bar_edit_text`, after `1306e78`) | host only | yes (FLAG_SECURE) | same | origin only — owner decides |
| Android 35 / 29 | Firefox | | | | | |
| Android 35 / 29 | Edge | | | | | |
| Android 35 / 29 | Brave | | | | | |
| macOS 27 (this Mac) | Safari | yes (79–117 ms) | — | **no** without Accessibility (`unknown`) | ~0.6 % | no-go unless Accessibility is accepted |
| macOS 27 (this Mac) | Chrome | yes (80–240 ms) | — | yes (`mode=incognito`) | ~0.6 % | go |
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
