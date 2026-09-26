# Phase 2 summary (2026-09-26)

The project owner started Phase 2 on 2026-09-26 while gate G1 was still open (plan decision I3, gate G1 row). The
code of every Phase 2 card is written, tested with fakes and green on CI on the branch
`feat/phase-02-sms-ios-relay` of the four code repositories. **Nothing is merged into `main`**: the real-device,
real-relay, APNs and FCM checks below come first, as does gate G1.

## Cards

| Card | Repository | Status | Report |
|------|------------|--------|--------|
| S2.1 UI strings | handlive-shared | DONE (the concerns were settled by the spec syncs) | `phase-02-S2.1.md`, `phase-02-shared-sync-1.md`, `phase-02-shared-sync-2.md` |
| S2.2 JSON Schemas | handlive-shared | DONE | `phase-02-S2.2.md` |
| S2.3 test vectors | handlive-shared | DONE | `phase-02-S2.3.md` |
| T2.1 bench and relay load test | handlive-shared | DONE_WITH_CONCERNS: device measurements pending | `phase-02-T2.1.md` |
| R2.1 relay REST and `/v1/relay` | handlive-relay | DONE | `phase-02-R2.1.md` |
| R2.2 push proxy (APNs, FCM) | handlive-relay | DONE: a real push is pending | `phase-02-R2.2.md` |
| A2.1 SMS | handlive-android | DONE_WITH_CONCERNS: two SIMs and devices | `phase-02-A2.1.md` |
| A2.2 relay, push, FCM | handlive-android | DONE_WITH_CONCERNS: real relay and FCM | `phase-02-A2.2.md` |
| M2.1 Mac Messages | handlive-apple | DONE_WITH_CONCERNS: devices | `phase-02-M2.1.md` |
| M2.2 Mac Internet Connection | handlive-apple | DONE_WITH_CONCERNS: real relay | `phase-02-M2.2.md` |
| I2.1 iPhone/iPad app | handlive-apple | DONE_WITH_CONCERNS: devices | `phase-02-I2.1.md` |
| I2.2 Notification Service Extension | handlive-apple | DONE_WITH_CONCERNS: signed build, APNs | `phase-02-I2.2.md` |
| T2.2 release documents | hub | DONE_WITH_CONCERNS: gate G2 is the owner's | `phase-02-T2.2.md` |

Spec work: seven sync batches applied the agents' deviations and proposals to the detailed design, the design
system and the plan in both languages (`phase-02-spec-sync-1.md`); the design system artifact was republished
(`phase-02-ds-sync-1.md`, `phase-02-ds-sync-2.md`).

## Branch heads

| Repository | Head | Commits over `main` |
|------------|------|---------------------|
| handlive-shared | 9014a1d | 41 |
| handlive-relay | f87b18b | 42 |
| handlive-android | a5f8644 | 71 |
| handlive-apple | 5a73597 | 107 |

## Checks at those heads

- Shared: 313 catalog strings with 0 errors and 0 warnings, also against the docs; schemas XANH; vectors 0 errors,
  regenerated vectors 0 mismatches; CI green.
- Relay: `cargo fmt`, `clippy -D warnings`, 67 tests without services and 36 integration tests with PostgreSQL and
  Redis; CI green with PostgreSQL 16 and Redis 7. A log-capture test shows no payload, id, token or query string.
- Android: `./gradlew check` with 500+ JVM tests, Android Lint, ktlint and detekt; both flavors build; CI green.
- Apple: every package test and SwiftLint `--strict`; the Mac app, the iOS app and its extension build on CI
  (unsigned); CI green.
- Hub: `validate_design_docs.py` and `check_bilingual_docs.py` print `problems=0`.

## Measurable criteria

| Criterion | State |
|-----------|-------|
| New SMS notification on the Mac < 500 ms (LAN, p95) | Not measured: the apps emit the `HLBENCH/1` SMS events; `sms_latency.py` needs real devices |
| Reply confirmed as "Sent" < 2 s (p95) | Not measured, same reason |
| Relay never decrypts or logs payloads | Tested (log capture at TRACE level) |
| Relay stable at 1,000 connections | Passed on one local instance: 10,000 frames, none lost, forwarding p95 4.0 ms text / 8.1 ms binary |
| Session data deleted after 30 days | Implemented and tested (cleanup job, 0.9.4) |
| Locked iPhone shows generic `loc-key` content | Implemented; needs a signed build and a real push |

## Still open before merging Phase 2

1. **Gate G1** (Phase 1): the device matrix of `shared/tools/bench/README.md` on real phones and Macs.
2. **Gate G2**: the Play Console Permissions Declaration Form and the Data safety form (`docs/deployment-guide.md`).
3. **Owner inputs**: the relay host and a backup certificate pin (Android `handlive.relayHost`,
   `handlive.relayExtraPins`; Apple `HLRelayHost`); the APNs `.p8` key; the Firebase project and service account;
   registering `app.handlive.ios`, its extension and the App Group; the user-assigned device name entitlement; a logo
   and an app icon.
4. **Real-device checks**: two SIMs; the SMS latency targets; LAN ↔ relay switching; a push to a real iPhone in
   < 2 s; FCM wake-ups; the extension locked and unlocked and under 30 MB; TalkBack, VoiceOver, 200 % text and AX5
   in both languages; Delete All on Android 10–15; the system setting names (macOS 15 calls the pane "Login Items &
   Extensions").
5. **Relay at scale**: a load test across two relay instances and a VPS run with TLS.

Merging then follows the Phase 1 order (handlive-shared first, since the platform CIs check out shared `main`), and
Phase 3 (calls) starts from `main`.

Status: DONE_WITH_CONCERNS
Summary: Every Phase 2 card is implemented and green on CI on `feat/phase-02-sms-ios-relay`; the specs, the design
system and the docs follow the code in both languages.
Concerns/Blockers: real-device, relay, APNs and FCM checks, gates G1 and G2, and the owner inputs listed above.
