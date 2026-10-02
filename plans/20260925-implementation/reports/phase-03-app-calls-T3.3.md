# Phase 3 extension — T3.3 end-to-end run 1: Telegram calls on the Mac (2026-10-02)

Phase file: `phase-03-cuoc-goi-app.md`. Builds: uncommitted `feat/phase-03-app-calls` (android foss debug, Mac
`app.handlive.mac.localtest` signed with team 3S93UPADXV). Review/fixes: `phase-03-app-calls-review.md`.

## Setup

- Phone: Galaxy S25 Ultra, Android 16, **no SIM**, Wi-Fi; HandLive installed over USB; Notification access and the
  clipboard Accessibility service on (so `answer_mode = direct`). Call spike probe uninstalled.
- Mac: MacBookPro18,3, macOS 27.0.1, same Wi-Fi, paired again with the PIN flow (security code matched on both sides).
- Calls: Telegram, from the owner's iPhone to the S25's account. Actions clicked on the Mac panel.
- Measurement: `HLBENCH` lines (logcat tag `HLBENCH`, Mac unified log category `bench`). Clock offset per call from the
  `call_event/action` exchange (NTP formula, `shared/tools/bench/README.md`): phone − Mac = −14.6 ms (call 1, RTT
  117 ms), −41.8 ms (answer, RTT 53 ms), −43.2 ms (end).

## Results

| AC | Target | Call 1 (decline) | Call 2 (answer, end) | Verdict |
|---|---|---|---|---|
| AC1 panel after the notification `postTime` | ≤ 400 ms | 328 ms (OS delivery 224 ms) | 341 ms (OS delivery 229 ms) | Met |
| AC2 Decline / End on the phone | ≤ 500 ms | tap → ringing removed 68 ms; tap → `ended` on Mac 132 ms | End: tap → removed 73 ms; tap → `ended` on Mac 167 ms | Met |
| AC3 Answer (direct) | ≤ 1 s | — | tap → in-call notification posted 211 ms; tap → `ongoing` on Mac 455 ms | Met |
| AC4 audio | panel says where | — | panel "Audio: Phone"; audio on the phone | Met (v1 fallback; owner confirmed phone-only for VoIP, 2026-10-02) |
| AC5 privacy | no name in logs | 0 lines with the caller name (HandLive logcat, Mac unified log, bench lines) | same | Met |
| AC6 permission / telephony | — | not run (permission already granted; no SIM) | — | Open |

Other observations:
- `end_reason`: call 1 `declined`, call 2 `ended`; the in-call notification (`Other3`, single action) was linked and its
  action used as End (`mode=plain`); answer used `mode=direct`.
- Telegram re-posts its ringing notification once right after Answer (`app_call_changed state=ringing`), then the
  in-call notification arrives 77 ms later; the panel switched correctly.
- The Mac did not ring: `call_alert focus=unknown ring=false`. HandLive was not listed in System Settings › Privacy &
  Security › Focus because the local build is signed without the Communication Notifications capability (personal
  team), so it can never ask. Owner decision 2026-10-02: such a build alerts as with Focus off. Implemented: new
  `FocusState.unavailable` (read from the code signature), ringtone allowed, Focus hint hidden; CALL-01 API 5 logic 3
  (en, vi), bench `focus=unavailable`, `call_latency.py` rule; HLMacUI tests 69 pass; Mac rebuilt and reinstalled.
- No crash: the HandLive process kept the same pid through both calls.

## Found during the run (not CALL-05)

- Mac pairing one-sided (`saveFailed`): after a build without the Keychain entitlement, the app regenerated its keys but
  kept `paired-devices.bin` sealed with the old key, so every new pair failed to save while the phone reported success.
  Worked around by moving the file aside; product fix spun off as a separate task.

## Not tested yet

- Tap-to-answer (`answer_mode = tap`, Accessibility off); screen off / locked.
- Review scenarios: cellular call on a phone with a SIM (no `app_call`), decline on the phone, caller hangs up while
  ringing, unrelated ongoing notification of the same app, sideloaded restricted setting, permission missing.
- Relay path; Zalo, WhatsApp; macOS 26 and 13/14.

Status: DONE_WITH_CONCERNS
Summary: First real-device run: AC1, AC2, AC3, AC4, AC5 met for Telegram on the S25 + this Mac (LAN, direct answer).
Concerns/Blockers: AC6 and the review scenarios still need runs (a SIM phone for the cellular exclusion); only two
calls measured, so no p95 yet.
