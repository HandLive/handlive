English | [Tiếng Việt](phase-03-cuoc-goi-app.vi.md)

# Phase 3 extension — Calls from other apps on the Mac (CALL-05)

**Goal:** when a calling app (Telegram first; Zalo, WhatsApp later) rings on the phone, the Mac shows who calls and
from which app, and the user can answer, decline or end from the Mac — with the audio on the Mac when Bluetooth HFP
allows it, otherwise on the phone.

Status: design approved by the project owner on 2026-10-01 (`reports/phase-03-app-calls-brainstorm.md`). Branch
`feat/phase-03-app-calls`. Not blocked by G4/G5/G6; only the audio-on-the-Mac part depends on the spike below and on
the Phase 4 HFP audio path. Planned tests-first.

## Spike T3.2 (1–2 days, before any other card; owner places Telegram calls)

Questions, each with its own go/no-go:
1. A `NotificationListenerService` sees Telegram's `CallStyle` notifications (incoming `callType=1`, ongoing
   `callType=2`) with caller, `declineIntent`, `answerIntent`, `hangUpIntent`, and their removal at the end. The
   2026-10-01 watch showed that during the call Telegram posts a channel `Other3` notification without `CallStyle` →
   check the End action among that notification's ordinary actions.
2. Sending `declineIntent`, `answerIntent` (an activity start, sent with
   `ActivityOptions.setPendingIntentBackgroundActivityStartMode(ALLOW_ALWAYS on API 36+, ALLOWED on 34–35)`) and `hangUpIntent` from HandLive in the
   background works — screen on, screen off, locked.
3. After answering, `AudioManager.setCommunicationDevice(<the Mac's bt_sco device>)` from HandLive while Telegram owns
   the call opens SCO to the Mac (`HFPSpike` connected: `sco_opened`, Core Audio device) and both sides hear each other.
4. Timings for AC1–AC4 (notification posted → listener; intent sent → state change; route request → SCO open).

Results in `reports/phase-03-app-calls-spike.md`. Probe: `android/tools/call-spike/` (debug build only, like
`tools/web-spike`). Question 1 or 2 fails → stop and report. Question 3 fails → v1 ships with audio on the phone (AC4
fallback) and the audio part waits for another path.

## Context

- Design: `reports/phase-03-app-calls-brainstorm.md`. Leaf functions: `06-call-control.md` CALL-01…04 (group rules,
  no `InCallService`, C12); common specs 0.7.1 (`call_event` ops), 0.7.2 (`features.call`), 0.8 (`CALL_*` errors), 0.9.5
  (`feature.call`, `call.notify`); SET-01/SET-02; `07-call-audio.md` AUDIO-02 (Mac HFP).
- Code: Android `feature/call` (`module/CallActions.kt`, `CallBroadcaster.kt`, `CallModule.kt`, `CallAccess.kt`),
  `core/transport` capability (`EffectiveFeatures.kt`); Apple `Packages/HLCalls` (`CallsModel.swift`) and the macOS
  call panels; `shared/schemas/call_event-*.schema.json`, `capability` schema, `shared/strings/ui-strings.json`.
- Evidence (2026-10-01, S25 Android 16 + macOS 27): Telegram posts `CallStyle` with decline (broadcast) and answer
  (activity) intents; its call is not reported over HFP and its audio stays on the phone; VoIP audio cannot be
  captured by another app.

## Requirements and measurable criteria (LAN, 95th percentile)

| # | Criterion |
|---|---|
| AC1 | Mac panel ≤ 400 ms after the app's call notification is posted (Android alone takes 215–232 ms to deliver it, spike T3.2), with app name and caller name |
| AC2 | Decline or End from the Mac takes effect on the phone ≤ 500 ms |
| AC3 | Answer from the Mac answers on the phone ≤ 1 s when HandLive is exempt from background activity start limits (its accessibility service is on); otherwise the phone shows a HandLive "tap to answer" notification |
| AC4 | HFP connected and spike question 3 passed: audio on the Mac ≤ 1.5 s after Answer; otherwise audio on the phone, and the panel says so |
| AC5 | No other notification leaves the phone; logs never contain names or numbers |
| AC6 | Without Notification access the feature is off and explained; cellular call features (CALL-01…04) unaffected |

Relay: best effort. Out of scope: iPhone/iPad, starting app calls from the Mac, an app-call log, video calls.

## Task cards

"Tests first" lists what is written and committed (red) before the code of the card.

| Code | Task | Tests first | Outputs | Acceptance criteria |
|------|------|-------------|---------|---------------------|
| T3.2 [test] | Spike (above) | — (measurement) | `reports/phase-03-app-calls-spike.md`; `android/tools/call-spike/` | Go/no-go per question; timings recorded |
| D3.1 [docs] | Spec, both languages: CALL-05 leaf in `06-call-control.md` (5 sections; group rule exception for app calls: notifications only, no `InCallService`); common specs: op `call_event/app_call` (S→C) and its data, `call_event/action` for app `call_id`s, capability `features.call.app_calls`, error code for a missing notification action, setting `call.app_calls`, constants (route timeout), SET-01 Notification access primer, SET-02 row, UI strings | — (contract) | `docs/detailed-design/06-call-control*.md`, `00-common-specs*.md`, `01-setup-settings*.md` | `validate_design_docs.py` `problems=0`; `check_bilingual_docs.py` green |
| S3.4 [shared] | `call_event-app_call.schema.json`, capability and error enums, positive/negative samples, UI strings (en, vi) | Samples are the tests; `check_schemas.py`, `check_strings.py` | `shared/schemas/`, `shared/strings/` | Both checks green; platforms told to re-run |
| A3.3 [android] | `AppCallListenerService` (`NotificationListenerService`): filter excludes default dialer, system dialer, InCallService apps and telecom service (cellular calls stay in CALL-01…04); from others takes only `CallStyle` to create contexts, but accepts `category=call` during link window for in-call; parser to an app-call context (package, label, caller, state, available actions), store keyed by notification key, ended on removal | Parser tests on bundled fixtures (Telegram incoming/ongoing, `category=call` without `CallStyle` before link window, ordinary notification ignored); privacy test (no caller name in logs) | `android/feature/call` (new `appcall/` package), manifest service with `BIND_NOTIFICATION_LISTENER_SERVICE`, class `AppCallListenerService` | Tests green; no cellular notifications read; non-call notifications never leave the listener |
| A3.4 [android] | Dispatcher and broadcast: `call_event/app_call` to sessions with `app_calls` in effect; `call_event/action` routed by `call_id` (telephony vs app); PendingIntent send with the background-start option; answer with `audio = mac` → `setCommunicationDevice` (if T3.2 Q3 passed) with timeout fallback | Regression tests for telephony actions (`CallActions`) before routing changes; dispatcher tests with fake intents; capability gating tests (`FEATURE_DISABLED`) | `android/feature/call`, `android/core/transport` (capability) | Telephony call tests unchanged; AC2/AC3 measured on the S25 |
| A3.5 [android] | Onboarding and settings: Notification access primer and deep link, `call.app_calls` toggle, capability `app_calls` = setting ∧ permission | Tests for capability computation (permission on/off, setting on/off) | `android/app`, `android/feature/call` | AC6 |
| M3.4 [macOS] | `HLCalls`: decode `call_event/app_call`, app-call model and state transitions, send actions, advertise `app_calls` | Decoding tests on the `shared` samples; state-transition tests | `apple/Packages/HLCalls`, `apple/Packages/HLTransport` (capability) | Tests green; iOS advertises `app_calls = false` |
| M3.5 [macOS] | Panels: incoming/in-call variants with the app name; Answer (audio on the Mac when HFP is connected and routing works, else a note), Decline, End; Settings row; strings; VoiceOver | UI model tests for button availability per state and per available action | `apple/macOS/HandLive`, `apple/Packages/HLMacUI` | AC1, AC4 note; VoiceOver reads the panel |
| T3.3 [test] | End-to-end with Telegram on the S25 and this Mac: AC1–AC6 timed with the bench log; log grep for names; permission missing (also a sideloaded install on Android 13+: restricted setting); relay path. Scenarios: decline on the phone; the caller hangs up while ringing; an unrelated ongoing notification of the same app during ringing is not linked; the panel shows the app label ("Telegram"), not the package; on a phone **with a SIM**, a cellular call produces no `app_call` | e2e scenarios written first | `reports/phase-03-app-calls-T3.3.md` | AC1–AC6 met or measured shortfall reported |

## Branch and work order

- `feat/phase-03-app-calls` in the hub, handlive-shared, handlive-android, handlive-apple.
- T3.2 first and alone → D3.1 → S3.4 → A3.3 ∥ M3.4 → A3.4 → A3.5 ∥ M3.5 → T3.3.
- One commit per logical step; `shared/` before the platforms; never across repositories.

## Testing

- Tests first per card (red commit before the code); regression tests for telephony call behaviour before any change
  to `CallActions`/routing.
- Regression gate after every card: Android `./gradlew check`; Apple `swift test` (HLCalls, HLMacUI, HLTransport) and
  `xcodebuild test`; hub `validate_design_docs.py`, `check_bilingual_docs.py`; shared `check_schemas.py`,
  `check_strings.py`.

## Risks and rollback

- Background activity start refused for `answerIntent` → HandLive trampoline activity or a full-screen notification on
  the phone; decided by T3.2.
- Android ignores HandLive's communication-device request → no audio on the Mac for app calls (AC4 fallback).
- Apps without `CallStyle` → not supported until a per-app adapter exists; listed in the spike report.
- Notification access is broad → strict filter, primer text, Play declaration; the feature can be turned off with
  `call.app_calls`.
