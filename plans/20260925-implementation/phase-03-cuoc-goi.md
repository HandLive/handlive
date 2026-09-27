English | [Tiếng Việt](phase-03-cuoc-goi.vi.md)

# Phase 3 — Call information and control

**Goal:** the Mac and iPhone/iPad know who is calling; the Mac answers, declines, declines with a
message and ends calls over Wi-Fi; the call log and missed calls are synced. Hold, DTMF and mute wait
for Phase 4 (HFP).

## Context

- Leaf functions: `06-call-control.md` CALL-01 (including API 7, the communication notification on
  the Mac), CALL-02, CALL-03 (the WebSocket part), CALL-04.
- Design system: components `CallPanel`, `Notification`, `MenuBarMenu`;
  `2-patterns/03-thong-bao.md`; `3-platforms/01-macos.md` (Focus, keyboard shortcuts).
- Decisions: D9/C12 (public Telecom APIs, no `InCallService`), C19 (Focus → no panel; the panel is a
  deliberate deviation from the HIG).

## Requirements and measurable criteria

- `call_event/state` reaches the Mac in < 200 ms on the LAN; answer < 500 ms at the 95th percentile, from
  the click on the Mac until `state = offhook` is back on the Mac (CALL-02).
- No ringing while the Focus status cannot be read; Focus on → communication notification only.
- Never log phone numbers or names.

## Task cards

| Code | Task | Outputs | Acceptance criteria |
|------|------|---------|---------------------|
| S3.1 [shared] | UI string catalog for Phase 3 (0.12, C20): every user-facing string of CALL-01…04 (the Mac `CallPanel`, the communication notifications and their actions, the iOS banner and `HL_CALL_INCOMING`, the missed-call notifications, the Calls item of the Messages window, the iOS Calls tab), SET-01 part B for the call permissions, SET-02 fields 10–12 and the Mac Calls pane, the default `call.quick_replies` templates, the texts of the `CALL_*` errors; check the existing `push.call_*` and `infoplist.focus_status_usage` keys | `shared/strings/ui-strings.json` | `check_strings.py` and `--docs` clean; `en` and `vi` match the leaf specs; lands before any Phase 3 UI code |
| S3.2 [shared] | JSON Schemas: the `call_event` ops `state`, `action` (with its ack), `log_sync` (with its ack data) and `log_new`, and the shared `entry` object (CALL-04) | `shared/schemas/` | `check_schemas.py` green, including every JSON example of `06-call-control.md` |
| S3.3 [shared] | Test vectors: `call_event/state` envelopes encrypted with `K_push` for the `call_incoming` and `call_missed` pushes (decrypted by I-NSE), with the `call:<call_id>` collapse key | `shared/test-vectors/` | `verify_vectors.py` 0 errors, `generate_vectors.py --check` 0 mismatches; the Android and Apple tests load them |
| A3.1 [android] | `TelephonyCallback`/`PhoneStateListener` + the `PHONE_STATE` broadcast, the `call_id` context, `PhoneLookup` name lookup (LRU cache), `controls` by permission, `call_event/state` per session (CALL-01); `acceptRingingCall`/`endCall` (CALL-02, CALL-03 E2 `CALL_HFP_REQUIRED`); `CallLog` call log (CALL-04) | `android/feature/call` | A number that arrives after the first `RINGING` is still re-sent (E10); both SIMs labeled; tests with a fake Telephony |
| A3.2 [android] | Push `call_incoming` and `call_missed` via the relay for iPhone (CALL-01 step 5, CALL-04 API 5); open the relay to wait for a decline command | `android/feature/call` | Push within < 300 ms after the number is known |
| M3.1 [macOS] | `CallPanel`: a non-activating `NSPanel` floating on every Space, ringing/in-call/ended states, Return/⌘⌫/Esc keys, `NSSound` ringtone per `call.ringtone`, `INFocusStatusCenter` (`NSFocusStatusUsageDescription`), VoiceOver | `apple/macOS/HandLive` | Panel < 300 ms after `RINGING`; Focus on → no panel, no ringtone |
| M3.2 [macOS] | `INStartCallIntent` communication notification (CALL-01 API 7): passive while the panel shows, time-sensitive during Focus; "Answer" and "Decline" actions; removed when `state` changes; missed calls with "Message" (CALL-04 API 4) | app | Never two alert layers for one call; actions run without opening a window |
| M3.3 [macOS] | Decline with a message (`call.quick_replies` templates, CALL-02 API 5), the Calls item in the Messages window sidebar (CALL-04), the Calls settings pane, the call item in the menu bar menu after "Ignore" | app | Strings and button positions per the `CallPanel` README |
| I3.1 [iOS] | Incoming-call notification: I-NSE builds `INStartCallIntent`, category `HL_CALL_INCOMING` with "Decline" (CALL-02 B), an in-app banner while the app is open; a Calls tab with the call log and missed calls | `apple/iOS` | Decline from the notification reaches the phone in < 2 s through the relay when the phone already opened the relay after the push; a locked device shows generic content |
| T3.1 [test] | Bench the `RINGING → panel` latency and the answer latency: click → `state = offhook` back on the Mac (CALL-02, < 500 ms at the 95th percentile), with click → `OFFHOOK` on the phone also reported; scenarios: call waiting (E9), two SIMs, Focus on | `tools/bench/`, `reports/` | Targets met on Pixel and Samsung |

## Branch and work order

- Branch `feat/phase-03-calls` in handlive-shared, handlive-android and handlive-apple, created from `main`
  after the Phase 2 merge (2026-09-27). handlive-relay needs no change: its push proxy already sends
  `call_incoming` as time-sensitive and `call_missed`, both in the `calls` thread. The hub and
  `HandLive/.github` stay on `main`.
- One agent per repository, started in parallel: shared (S3.1 → S3.2 → S3.3 → T3.1), Android (A3.1 →
  A3.2), Apple (the `call_event` models and the call store in the packages first, then M3.1 → M3.2 → M3.3 →
  I3.1). S3.1 comes first because every UI card waits for its strings; until it lands, the platform agents
  build the parts without UI.
- The project owner started Phase 3 on 2026-09-27 while gates G1 and G2 and the Phase 2 real-device checks
  are still open (plan decision I3).
- The Mac app, the iOS app and the Notification Service Extension build only on CI (macOS runner with
  Xcode); the development machine has only the Command Line Tools.

## Testing

- Unit: the call-context state machine (`ringing → offhook → idle`, `waiting`), computing `controls`,
  `call_id` deduplication.
- Manual: real calls between two SIMs; AirPods connected (no effect in this phase).

## Risks and rollback

- `acceptRingingCall` /`endCall` are deprecated since API 29 but still work; if an OEM blocks them →
  only decline/end over HFP remain (Phase 4); record it per device in deployment-guide.
- No `READ_CALL_LOG` (Play rejects it) → "Unknown Caller" (E2), still usable.
