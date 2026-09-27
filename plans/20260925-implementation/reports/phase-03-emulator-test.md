# Phase 3 — emulator test (2026-09-27)

First run of HandLive on Android virtual devices. Unit tests and CI covered the code before; nothing had run on an
Android runtime. Owner-facing page (Vietnamese): https://claude.ai/artifact/XtBdMsaXojeZhZYKthxES6

## Environment

- Mac Apple silicon, 32 GB; Command Line Tools only (no Xcode → no Mac app, no iOS Simulator locally).
- Android Emulator 37.1.11; Google APIs arm64 images: Android 15 (API 35, Pixel 8 profile), Android 10 (API 29,
  Pixel 4 profile). Emulators run with a window (owner request).
- Code: `feat/phase-03-calls` — android `eccf499`, apple `fdbac16`, shared `2d4eaeb`; relay `main` `ee0532e`. App: `foss`
  debug.

## CI at those heads

| Repository | Commit | Result |
|------------|--------|--------|
| handlive-android | eccf499 | green (run 36306893438) |
| handlive-apple | fdbac16 | green (run 36306282473) |
| handlive-shared | 2d4eaeb | green (run 36305851961) |
| handlive-relay | ee0532e (`main`) | green; local run against Phase 3 shared data: 67 tests + 36 integration tests (PostgreSQL 18, Redis), 0 failures |
| hub | 54e5df1 | green (run 36306896797) |

## Instrumented tests (`connectedDebugAndroidTest`)

| Test | Android 15 | Android 10 |
|------|------------|------------|
| `feature/call` `CallSystemDeviceTest` | 3/3 | 3/3 |
| `feature/connection` `ServiceDiscoveryDeviceTest` | 1/1 | 1/1 |
| `core/transport` `NettyTlsSmokeTest` | 0/4, then 4/4 after the fix | 4/4 |

Fix: the `core/transport` test APK had no INTERNET permission (`SocketException: Operation not permitted` from
`NioServerSocketChannel`). The app itself is not affected (INTERNET comes from `feature/connection` and
`feature/relay`). Commit android `eccf499` "test(android): let the transport device tests open sockets".

## Manual run on Android 15 (window, adb)

| # | Step | Result |
|---|------|--------|
| 1 | First run: Welcome → notification primer + system prompt → background primer + battery prompt → Keep HandLive Running → Pair a Device (Cancel) → Devices | PASS; foreground service up right after notifications allowed |
| 2 | Settings: SMS Messages and Calls show "Needs permission" + "Grant Permission" | PASS |
| 3 | Call primer "See Calls on Your Mac and iPhone" → 3 system dialogs → READ_CALL_LOG, READ_CONTACTS, READ_PHONE_STATE, ANSWER_PHONE_CALLS granted | PASS |
| 4 | `adb emu gsm call` (fake +1 555-555-0123): `call_changed ringing trigger=listener` 15 ms after the OS callback; `trigger=broadcast … settled=true` 93 ms after the broadcast | PASS (see issue 4) |
| 5 | `gsm accept`, then `gsm cancel`: `offhook` 1 ms, `idle end=ended` 1 ms | PASS |
| 6 | Missed call (ring, caller hangs up): `idle end=missed` | PASS |
| 7 | SMS primer → system dialog → READ_SMS, SEND_SMS; `adb emu sms send`: `sms_detected box=inbox` 159 ms after the provider write | PASS |

HLBENCH lines carry `number=known|none` only (checked in `CallBenchTrace.kt`); no number, name or text. No crash.

## Issues

1. Fixed — transport test APK without INTERNET (above).
2. To fix — Devices empty state "Pair a Mac, iPhone, or iPad to share the clipboard with this phone." (PAIR-02 field 11,
   catalog) still names only the clipboard; should name messages and calls too.
3. Device check — emulator data network goes down/up when a call goes off hook (`net change=down/up`); networks without
   simultaneous voice and data (3G without VoLTE) may drop the Mac session during calls.
4. Device check — first contact lookup 93 ms vs the ≤ 30 ms target (uncached first lookup; emulator slower).
5. Proposal — "Keep HandLive Running" on non-Xiaomi/OPPO/Samsung devices shows only the title and the "Pause app activity
   if unused" button; SET-01 fields 7–9 give no sentence saying why.

## In progress

- LAN: fake Mac (Python, shared crypto code) pairs by PIN with the real app, then calls, SMS, clipboard end to end
  (`shared/tools/e2e/`, own emulator with a window).
- Relay and push: local relay with PostgreSQL, Redis, TLS front with a pinned certificate, mock APNs/FCM
  (`RELAY_APNS_URL`, `RELAY_APNS_SANDBOX_URL`, `RELAY_FCM_URL`), APK built with `handlive.relayHost` and
  `handlive.relayExtraPins`; checks registration, forwarding, and `POST /v1/push` reaching the mock APNs with a
  decryptable `hl` (`shared/tools/e2e/relay_stack/`).

## Not testable on this machine

- Mac and iPhone apps: need Xcode (owner installs it with their Apple ID).
- Real APNs/FCM: need the `.p8` key, the Firebase project and the relay host.
- p95 latency targets, OEM behavior, two SIMs: need a real Pixel and Samsung.

Status: DONE_WITH_CONCERNS
Summary: The Android app runs on Android 15 and 10 emulators; all 16 device tests pass after a test-manifest fix, and call
and SMS detection work with the expected states and privacy of the bench logs.
Concerns/Blockers: delivery to other devices and to the relay is still being tested; Apple apps cannot run without Xcode.

Unresolved questions: none.
