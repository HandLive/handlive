# Web Handoff: continue the web page open on the other device

**Status:** proposal written into the roadmap and the specs (no code yet) · **Asked by:** the project owner,
2026-09-28, choosing automatic detection of the open tab (Accessibility on Android, Automation on the Mac) over a
share-only flow.

Apple Handoff shows a Safari icon on the other device's Dock or app switcher when a page is open on the iPhone or
Mac. HandLive cannot use Apple's Handoff surface (Continuity between devices on one iCloud account, not open to
third-party apps or Android), so it shows its own indicator. Names below are the decisions for the spec agents.

## Decisions

### W1 — Name, phase and scope

- Feature id `web`; UI name "Web Handoff" is avoided (Apple term). English UI: "Continue Browsing"; Vietnamese:
  "Duyệt web tiếp". Function group 9, file `docs/detailed-design/09-web-handoff.md` (+ `.vi.md`), leaf ids `WEB-01`…
  `WEB-05`.
- Roadmap: **Phase 6**, built on Phase 1 infrastructure only (session, E2E, capability), independent of Phases 4 and
  5. It may start while Phase 4 waits for gate G4; the owner decides the order. It starts with a gate **G6 spike**
  (3–5 days, W8).
- Directions: Android → Mac, Android → iPhone/iPad (shown only while the app is open), Mac → Android. iPhone/iPad
  cannot read Safari's tab (no API): iOS → Android is out of scope (a Share Extension is a later option). No sending
  to or from the relay-only push path: the page is live state, not worth a push.

### W2 — Protocol

- New envelope type `web`, E2E like every other type, over LAN or relay sessions:
  - `web/active` `{page_id (uuid-v7, new per page), url, title?, browser, observed_at (ms)}` — the page now open in
    the foreground browser of the sender. `url`: `http`/`https` only, at most 8 KiB (UTF-8, as the browser shows it,
    fragment kept); `title` at most 256 characters or absent; `browser`: an id from a fixed list (`chrome`,
    `samsung`, `firefox`, `edge`, `brave`, `opera`, `vivaldi`, `duckduckgo`, `safari`, `arc`, `other`).
  - `web/inactive` `{page_id}` — the browser left the foreground, the screen locked, the device slept, or the page
    became private or unsupported.
- Latest wins, no `ack` (fire-and-forget like call state updates); after a (re)connect the sender re-sends its
  current `web/active` once the capability exchange ends. The receiver keeps only the latest page per pair in memory,
  never on disk, and forgets it after `WEB_PAGE_TTL` (10 minutes) without a refresh, on `web/inactive`, or when the
  session ends.
- Capability `features.web {enabled, send, receive}`; the feature is in effect per direction only when the sender has
  `send` and the receiver `receive`, both `enabled`.
- Errors: none on the wire (no `ack`); invalid payloads are dropped silently (and counted in the bench log in debug).

### W3 — Android sends (WEB-01)

- A **separate** AccessibilityService "HandLive Browser Pages" (the clipboard service keeps
  `canRetrieveWindowContent=false`): `canRetrieveWindowContent=true`, `android:packageNames` limited to the supported
  browsers (so it receives nothing from other apps), event types `TYPE_WINDOW_STATE_CHANGED` and
  `TYPE_WINDOW_CONTENT_CHANGED` only, notification timeout ≥ 500 ms.
- Per-browser adapters (strategy pattern, like the OEM Bluetooth adapters) find the URL bar node (view id per
  browser version; fallback: the `EditText` of the toolbar) and turn its text into a URL (add `https://` when the bar
  shows the host only, as Chrome does; drop it when it is not a valid http/https URL).
- Debounce: send when the URL has been stable for `WEB_SETTLE` (1.5 s), not while the URL bar is focused (the user is
  typing). Never send for incognito/private tabs: the adapter must detect them (Chrome/Edge/Brave incognito toolbar
  state, Samsung secret mode, Firefox private) and any window with `FLAG_SECURE`; unknown → do not send.
- `web/inactive` when the browser leaves the foreground, the screen turns off, or the page becomes private.
- Play policy: Accessibility for a non-accessibility purpose needs a prominent disclosure screen and consent, and the
  Play declaration; the SMS fallback (F-Droid, direct APK) applies if it is refused. The feature is **off by default**.

### W4 — Mac sends (WEB-03)

- While a supported browser is frontmost (`NSWorkspace` activation notifications), read the front window's active
  tab URL and title through Apple Events (Safari, Chrome, Edge, Brave, Arc, Vivaldi, Opera): poll every
  `WEB_POLL_MAC` (1.5 s) only while that browser is frontmost and the user session is active; stop otherwise.
- Automation permission per browser (TCC prompt the first time; `NSAppleEventsUsageDescription`; hardened runtime
  entitlement `com.apple.security.automation.apple-events`). Denied → that browser is shown as "Not allowed" in
  settings with a button to System Settings › Privacy & Security › Automation.
- Private windows: Chromium browsers expose the window `mode` (`incognito`) → skip; Safari private windows must be
  detected in the spike (W8); unknown → do not send. Firefox has no URL scripting → unsupported.
- Same debounce (`WEB_SETTLE`) and `web/inactive` rules as Android (browser deactivated, screen locked, sleep).

### W5 — Receivers

- **Mac (WEB-02):** the menu bar icon shows a badge variant while a page from the phone is available; the menu's
  first item is "\<title or host> — from \<phone>" with the browser glyph; choosing it opens the URL in the default
  browser (`NSWorkspace.open`). Optional notification (setting `web.notify`, default off). Shortcut in the menu.
- **Android (WEB-04):** a silent, low-importance notification on a new channel `hl_web` ("Pages from your
  devices"): "\<title or host>" · "Open on this phone"; tapping opens the URL with `ACTION_VIEW`; replaced on each
  new page, removed on `web/inactive`/TTL. Setting `web.notify` (default on when the feature is on).
- **iPhone/iPad (WEB-05):** while the app is in the foreground, a banner at the top of the Devices screen
  "Continue browsing: \<title or host>" → opens in Safari (`UIApplication.open`). No push, no Live Activity.
- Every receiver shows the **host** in full, with IDNs displayed as punycode when mixed scripts are present
  (homograph defense), and opens only `http`/`https`.

### W6 — Settings (SET-02) and keys

- `feature.web` (default `false` on every platform), `web.send` (default `true`), `web.notify` (Android `true`, Mac
  `false`), `web.browsers` (Android/Mac: per-browser allow list, default all supported). Capability keys as W2.
- Android turning it on runs the disclosure screen, then opens Accessibility settings for the new service (SET-01
  part B pattern). Mac turning on `web.send` triggers the Automation prompt for each frontmost browser the first time.

### W7 — Privacy and security

- `docs/privacy.md` (both languages) gains "open web page addresses" in what can travel between paired devices:
  E2E, never stored, never sent to the relay in clear, never in push.
- Pages in private/incognito windows are never sent; the user can exclude browsers.
- The receiver never opens anything automatically; the user always taps.

### W8 — Gate G6 spike (before any other WEB card)

- Android: URL bar node ids and incognito detection for Chrome, Samsung Internet, Firefox, Edge, Brave on API 29 and
  35; battery/CPU cost of the service with `packageNames` filtering.
- Mac: Apple Events for Safari, Chrome, Arc on macOS 13 and 26; Safari private window detection; TCC behavior for
  a Developer ID signed build.
- Play: check the current Accessibility policy text for this use.
- Go/no-go per browser; unsupported browsers are listed in the spec.

### W9 — Effort (added to the roadmap table)

Android 3 weeks, macOS 2 weeks, iOS 0.5 week, test 1 week, spike 1 week: about 1.5 person-months.

## Work order

1. Hub: roadmap, PDR goals, privacy, detailed design (catalog in README, C21 decision, 00 message type/capability/
   settings/constants, new group 09, SET-02 rows), implementation plan `phase-06-web-handoff.md` — both languages.
2. shared: JSON schemas for `web/active`, `web/inactive`, the `type` enum and capability `features.web`; UI strings
   for the texts the specs name (en + vi).
3. Code only after gate G6.
