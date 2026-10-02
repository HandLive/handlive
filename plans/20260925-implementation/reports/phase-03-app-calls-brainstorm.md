---
type: brainstorm-report
date: 2026-10-01
status: approved-design
branch: feat/phase-03-app-calls
---

# Brainstorm: calls from other apps (Telegram, Zalo, WhatsApp…) on the Mac

Vietnamese twin: `phase-03-app-calls-brainstorm.vi.md`.

## 1. Problem

The owner sat at the Mac while a Telegram call rang on the S25 (2026-10-01): HandLive showed nothing. Phase 3 only sees
cellular calls (CALL-01…04 read the aggregate telephony state; no `InCallService`, decision C12), and VoIP apps run
self-managed calls that public telephony APIs do not show. Goal: see who calls from any calling app and handle it on
the Mac — including **answering and talking on the Mac** — like iPhone's "Calls on Other Devices".

## 2. Evidence gathered on the S25 (Android 16, One UI) + this Mac (macOS 27), Telegram

| Check | Result |
|---|---|
| HFP link Mac (HF) ↔ S25 | Service-level connection in 0.8–1.2 s once the Mac's SDP cache was refreshed |
| Telegram call over HFP | **Not reported** (no `+CIEV call/callsetup`; `AT+CLCC` fails on the phone) |
| Telegram audio | Stays on the phone earpiece; Telegram offers no Bluetooth route although AudioService lists the Mac as `bt_sco`; no SCO attempt from the phone |
| Telegram incoming notification | **`CallStyle`**: `category=call`, `android.callType=1`, `android.callPerson`, `android.declineIntent` (broadcast), `android.answerIntent` (activity) |
| Capture of VoIP audio by another app | Not possible (Android blocks `VOICE_COMMUNICATION` capture) → Opus/WS cannot carry app-call audio |

## 3. Approaches

| Approach | Verdict |
|---|---|
| **A. NotificationListenerService on `CallStyle` notifications**, actions through the notification's own PendingIntents | **Chosen** — one mechanism for every app that posts `CallStyle`; keeps C12 |
| B. `InCallService` via the CompanionDeviceManager "watch" role | Rejected — reverses C12, Play-policy risk |
| C. Rely on the apps' own Mac clients | Rejected — no unified HandLive experience |

## 4. Approved design (v1, Mac only)

- **Android (A-CALL):** a new `NotificationListenerService` in `feature/call` processes only notifications with
  `category=call` or `CallStyle` extras; everything else is dropped at once, never stored or logged. It keeps one
  app-call context per notification key: app package and label, caller name (`callPerson`/title), state from
  `callType` (1 ringing, 2 ongoing), ended when the notification is removed. Actions send the app's own intents:
  reject → `declineIntent`, answer → `answerIntent` (activity start from the background, sent with the background
  activity start option; HandLive's bound accessibility service is expected to allow it — spike), end →
  `hangUpIntent`.
- **Audio on the Mac (answer with audio = mac):** after answering, A-CALL asks Android to route communication audio to
  the Mac's Bluetooth HFP device (`AudioManager.setCommunicationDevice`), and the Mac plays it through the HFP stack.
  Conditional on (1) the spike showing Android honours HandLive's request while Telegram owns the call, (2) Phase 4's
  Mac HFP audio path (G4: SCO still untested without a SIM). Otherwise the call is answered with audio on the phone and
  the Mac panel says so.
- **Protocol:** new op `call_event/app_call` (S→C; own schema), sent only to clients whose capability has
  `features.call.app_calls = true` — `call_event/state` is untouched (its schema has `additionalProperties: false`;
  released Phase 3 clients stay compatible). Actions reuse `call_event/action` (`answer` with `audio`, `reject`, `end`)
  keyed by the app-call `call_id`; one new error code for "the notification has no such action". Settings key
  `call.app_calls`; Android onboarding asks for Notification access with a privacy primer (SET-01/SET-02).
- **Mac (M-APP):** reuse the incoming-call and in-call panels with the app's name; Answer (audio on the Mac when HFP is
  connected and routing works), Decline, End.

## 5. Acceptance criteria (LAN, 95th percentile)

| # | Criterion |
|---|---|
| AC1 | Mac panel ≤ 200 ms after the app's call notification is posted, with app name and caller name |
| AC2 | Decline or End from the Mac takes effect on the phone ≤ 500 ms |
| AC3 | Answer from the Mac answers on the phone ≤ 1 s |
| AC4 | With HFP connected and the spike passed: audio on the Mac ≤ 1.5 s after Answer; otherwise audio stays on the phone and the panel says so |
| AC5 | No other notification leaves the phone; logs never contain names or numbers |
| AC6 | Without Notification access the feature is off and explained; cellular call features are unaffected |

Relay: best effort. Out of scope: iPhone/iPad, starting app calls from the Mac, an app-call log, video calls; Zalo and
WhatsApp are verified later (owner has only Telegram today).

## 6. Order of work

1. **Spike (S25 + Telegram, owner places calls):** listener sees the `CallStyle` notifications; decline/answer/hang-up
   sent from the background; `setCommunicationDevice` to the Mac during an answered Telegram call with `HFPSpike`
   connected (does SCO open, does the Mac get audio); timings for AC1–AC4.
2. Spec: CALL-05 in `06-call-control` (+ `.vi.md`), `00-common-specs` (op, capability, error, setting, strings).
3. `shared`: schema for `call_event/app_call`, capability and action updates, strings.
4. Android, then Mac; tests first for the parser, the action dispatcher and the capability gating.
5. Real-device e2e with Telegram; G4/Phase 4 decides the audio-on-Mac part.

## 7. Risks

- Activity start from the background for `answerIntent` blocked → open HandLive's own trampoline or a full-screen hint;
  measured in the spike.
- Apps without `CallStyle` → fall back to `category=call` + action titles; otherwise not supported (listed per app).
- Android ignores HandLive's communication-device request → no audio on the Mac for app calls (AC4 fallback).
- Notification access is a broad permission → strict filter, disclosure, Play declaration text.

## Unresolved questions

1. Does Android 16 honour `setCommunicationDevice` from a non-owner app during another app's call? (spike)
2. Does sending Telegram's `answerIntent` from HandLive in the background start the call UI on a locked phone? (spike)
3. Zalo/WhatsApp `CallStyle` shapes (later, owner devices).
