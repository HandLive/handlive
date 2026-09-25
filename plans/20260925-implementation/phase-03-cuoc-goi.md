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

- `call_event/state` reaches the Mac in < 200 ms on the LAN; answer < 500 ms end to end.
- No ringing while the Focus status cannot be read; Focus on → communication notification only.
- Never log phone numbers or names.

## Task cards

| Code | Task | Outputs | Acceptance criteria |
|------|------|---------|---------------------|
| A3.1 [android] | `TelephonyCallback`/`PhoneStateListener` + the `PHONE_STATE` broadcast, the `call_id` context, `PhoneLookup` name lookup (LRU cache), `controls` by permission, `call_event/state` per session (CALL-01); `acceptRingingCall`/`endCall` (CALL-02, CALL-03 E2 `CALL_HFP_REQUIRED`); `CallLog` call log (CALL-04) | `android/feature/call` | A number that arrives after the first `RINGING` is still re-sent (E10); both SIMs labeled; tests with a fake Telephony |
| A3.2 [android] | Push `call_incoming` and `call_missed` via the relay for iPhone (CALL-01 step 5, CALL-04 API 5); open the relay to wait for a decline command | `android/feature/call` | Push within < 300 ms after the number is known |
| M3.1 [macOS] | `CallPanel`: a non-activating `NSPanel` floating on every Space, ringing/in-call/ended states, Return/⌘⌫/Esc keys, `NSSound` ringtone per `call.ringtone`, `INFocusStatusCenter` (`NSFocusStatusUsageDescription`), VoiceOver | `apple/macOS/HandLive` | Panel < 300 ms after `RINGING`; Focus on → no panel, no ringtone |
| M3.2 [macOS] | `INStartCallIntent` communication notification (CALL-01 API 7): passive while the panel shows, time-sensitive during Focus; "Answer" and "Decline" actions; removed when `state` changes; missed calls with "Message" (CALL-04 API 4) | app | Never two alert layers for one call; actions run without opening a window |
| M3.3 [macOS] | Decline with a message (`call.quick_replies` templates, CALL-02 API 5), the Calls item in the Messages window sidebar (CALL-04), the Calls settings pane, the call item in the menu bar menu after "Ignore" | app | Strings and button positions per the `CallPanel` README |
| I3.1 [iOS] | Incoming-call notification: I-NSE builds `INStartCallIntent`, category `HL_CALL_INCOMING` with "Decline" (CALL-02 B), an in-app banner while the app is open; a Calls tab with the call log and missed calls | `apple/iOS` | Decline from the notification reaches the phone in < 2 s via the relay; a locked device shows generic content |
| T3.1 [test] | Bench the `RINGING → panel` and `answer → OFFHOOK` latency; scenarios: call waiting (E9), two SIMs, Focus on | `tools/bench/`, `reports/` | Targets met on Pixel and Samsung |

## Testing

- Unit: the call-context state machine (`ringing → offhook → idle`, `waiting`), computing `controls`,
  `call_id` deduplication.
- Manual: real calls between two SIMs; AirPods connected (no effect in this phase).

## Risks and rollback

- `acceptRingingCall` /`endCall` are deprecated since API 29 but still work; if an OEM blocks them →
  only decline/end over HFP remain (Phase 4); record it per device in deployment-guide.
- No `READ_CALL_LOG` (Play rejects it) → "Unknown Caller" (E2), still usable.
