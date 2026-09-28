English | [Tiếng Việt](phase-06-web-handoff.vi.md)

# Phase 6 — Continue Browsing

**Goal:** the web page open on one device continues on another with one click or tap: the phone's
page on the Mac (menu item) and on iPhone/iPad (banner while the app is open), the Mac's page on the
phone (notification). The open page is detected automatically; private pages are never sent and no
page is ever stored.

Status: proposed by the project owner on 2026-09-28 (`plans/20260928-web-handoff/plan.md`). Phase 6
needs only the Phase 1 infrastructure (session, E2E, capability) and does not depend on Phases 4 and
5. Owner decision of 2026-09-28: Phases 5 and 6 are done before Phase 4 finishes (Phase 4 waits for the
G4 HFP hardware spike).

## Gate G6 — spike (3–5 days, before any other task card)

Questions: can each candidate browser's open page be read reliably, and can private pages always be
told apart?
- Android: the address bar node ids and incognito detection for Chrome, Samsung Internet, Firefox,
  Edge and Brave on API 29 and API 35; how the service learns that the browser left the foreground
  with the `android:packageNames` filter (WEB-01 API 3 logic 4); battery and CPU cost of the service
  with the filter on.
- Mac: Apple Events for Safari, Chrome and Arc on macOS 13 and macOS 26; detection of Safari private
  windows (and Arc's); the TCC prompt and its denial codes for a Developer ID signed build with the
  hardened runtime.
- Google Play: the current Accessibility policy text for this use and the declaration it needs.
- Results in `reports/phase-06-spike-g6.md`: a go/no-go table per browser and platform, the address
  bar ids, the private-state signal, the battery figures. Browsers that fail are written into
  `docs/detailed-design/09-web-handoff.md` (both languages) before any other card starts. No browser
  passes → stop Phase 6 and report.

## Context

- Leaf functions: `09-web-handoff.md` WEB-01…05 (group rules QW1–QW9); `01-setup-settings.md` SET-01
  part B, SET-02 fields 34–37 and API 1 (capability mapping); common specs 0.7.1 (`web` type, browser
  ids), 0.7.2 (`features.web`), 0.9.5 (`feature.web`, `web.*`), 0.10 (`WEB_*`).
- Decisions: C21 (README §5), C15 (the Accessibility disclosure pattern), C20 (strings).
- Design system: `MenuBarMenu` (a badge variant of the status icon and a first item for the page),
  `Notification` (channel `hl_web`), `PermissionPrimer`/disclosure screen, `Toggle` (settings rows).
- Proposal: `plans/20260928-web-handoff/plan.md` W1–W9.

## Requirements and measurable criteria

- A page is sent only after its URL has been stable for `WEB_SETTLE` (1.5 s) and never while the
  address bar has focus; the Mac polls every `WEB_POLL_MAC` (1.5 s) only while a supported browser is
  frontmost and the direction is in effect; while the same page stays open, the sender re-sends it
  every `WEB_REFRESH` (5 minutes) with the same `page_id`.
- Zero private or incognito pages sent across the whole test matrix; an unknown private state is
  never sent.
- The receiver forgets the page after `WEB_PAGE_TTL` (10 minutes) without a refresh, on
  `web/inactive` and when the session ends; nothing is written to disk or logs (checked by review and
  a test that greps the logs).
- The receivers open only `http`/`https`, only on a click or tap, and show the host in full with
  punycode for mixed-script labels.
- The feature is off by default on every platform; the battery cost of the Android service is
  recorded in G6 and accepted by the project owner.

## Task cards

| Code | Task | Outputs | Acceptance criteria |
|------|------|---------|---------------------|
| T6.0 [test] | Gate G6 spike (above): throwaway probes for Android (an `AccessibilityService` dumping the address bar node and the private signal per browser) and for the Mac (the WEB-03 API 1 scripts and `AEDeterminePermissionToAutomateTarget`); Play policy check. Inputs: plan W8, WEB-01 API 3–4, WEB-03 API 1–3 | `reports/phase-06-spike-g6.md`; probes on the spike branch only, never merged | Go/no-go per browser recorded; the spec lists the rejected browsers; the leave-foreground mechanism for Android is chosen |
| S6.1 [shared] | Contract data: `web-active.schema.json`, `web-inactive.schema.json`, `web` in the envelope `type` enum, `features.web {enabled, send, receive}` in the capability schema, the browser id enum; positive and negative samples; `check_schemas.py` validates the `web` examples of `09-web-handoff.md`; UI strings of group 9 and SET-02 fields 34–37 in `ui-strings.json` (group `web` added to the catalog rules). Inputs: 0.7.1, 0.7.2, 0.12, WEB-01…05 | `shared/schemas/`, `shared/tools/schemas/`, `shared/strings/` | `check_schemas.py` and `check_strings.py` green against the hub `main`; the other platforms are told to re-run their tests |
| A6.1 [android] | Protocol and receiving: `web/active` and `web/inactive` models, validation (QW7, QW8), latest-wins store per pair in memory with `WEB_PAGE_TTL`, the `hl_web` channel and the WEB-04 notification (`ACTION_VIEW`, lock-screen version), settings keys `feature.web`, `web.notify`, capability mapping (SET-02 API 1). Inputs: WEB-04, 0.7, 0.9.5 | `android/feature/web`, `android/core/protocol` | WEB-04 E1–E4 have tests; punycode and scheme tests; `receive = false` when notifications are off |
| A6.2 [android] | Sending: `BrowserPagesAccessibilityService` (`@xml/a11y_browser_pages`, package filter from G6), one `BrowserAdapter` per browser that passed G6, normalization, `WEB_SETTLE`, private detection, `web/inactive` rules, re-send after the capability exchange; the disclosure (WEB-01 fields 2–4), the feature card, SET-02 fields 34, 35, 37, `web.a11y_consent_at`. Inputs: WEB-01, SET-01 part B | `android/feature/web`, `android/app` (manifest, xml) | WEB-01 E1–E10 have tests or a recorded manual test; the clipboard service still has `canRetrieveWindowContent = false`; no event is processed when no session is in effect |
| M6.1 [macOS] | Receiving: WEB-02 — the badge variant of the menu bar icon, the first menu item with the host line and ⌘O, the optional notification (`web.notify`), `NSWorkspace.open`, TTL and session-end cleanup; Settings rows for `feature.web` and `web.notify`. Inputs: WEB-02, SET-02 | `apple/macOS/HandLive`, `apple/Packages/…` (web models shared with iOS) | WEB-02 E1–E6 have tests; VoiceOver reads the item and the badge label |
| M6.2 [macOS] | Sending: WEB-03 — activation, lock and sleep observers, polling lifecycle, the per-browser scripts that passed G6, private-mode checks, `WEB_SETTLE`, Automation status and "Open System Settings", `NSAppleEventsUsageDescription`, entitlement `com.apple.security.automation.apple-events`; Settings rows for `web.send` and `web.browsers`. Inputs: WEB-03, SET-02 | `apple/macOS/HandLive`, `apple/project.yml` | WEB-03 E1–E7 have tests or a recorded manual test; no polling while no supported browser is frontmost |
| I6.1 [iOS] | WEB-05: the banner laid over the top of the visible tab, closable until a new `page_id` arrives, `UIApplication.open`, cleanup on background and TTL; the "Continue Browsing" switch; capability `send = false`, `receive = feature.web`. Inputs: WEB-05, SET-02 | `apple/iOS/HandLive` | WEB-05 E1–E3 have tests; Dynamic Type AX5 and VoiceOver checked |
| T6.1 [test] | End-to-end matrix: Android → Mac, Android → iPhone, Mac → Android over the LAN and the relay; private tabs in every supported browser; screen off, lock, sleep; reconnect re-send; TTL; the page opens only on a tap; TalkBack/VoiceOver; en and vi | `shared/tools/e2e/` scenarios, `reports/phase-06-T6.1.md` | Every criterion above met; zero private pages sent |

## Branch and work order

- Branch `feat/phase-06-web-handoff` in handlive-shared, handlive-android and handlive-apple (and the hub
  for spec changes found during the work). handlive-relay needs no change: it relays `web` envelopes
  like any other type and never pushes them.
- T6.0 first and alone. Then S6.1 (every UI card waits for its strings), then in parallel Android (A6.1 →
  A6.2) and Apple (the shared `web` models, then M6.1 → M6.2 → I6.1), then T6.1.

## Testing

- Unit: URL normalization and validation, punycode display, the settle timer, latest-wins by
  `observed_at`, TTL expiry, the capability mapping per platform.
- Manual: each supported browser with normal and private tabs; a browser update that moves the address
  bar (E5); Automation denied then allowed in System Settings.

## Risks and rollback

- Google Play refuses the Accessibility use → the Android sending side ships only in the F-Droid and APK
  builds (plan W3); receiving on Android still works everywhere.
- Browser updates change the address bar views → adapters fail closed (nothing sent, E5); fix per
  browser without touching the protocol.
- Safari private windows cannot be detected → Safari stays unsupported on the Mac (never send an
  unknown state).
