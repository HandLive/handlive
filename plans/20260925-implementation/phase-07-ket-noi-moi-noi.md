English | [Tiếng Việt](phase-07-ket-noi-moi-noi.vi.md)

# Phase 7 — Connect anywhere

**Goal:** after the first QR pairing, the phone and the Mac connect by themselves wherever they are — both offline
(scenario X) or phone on mobile data and Mac on public Wi-Fi (scenario Y) — with no manual network step and **without
either device ever leaving or changing its current Wi-Fi**. A secured Bluetooth link carries the control channel when
there is no LAN; a bulk lane carries images over the fastest path allowed (LAN, Wi-Fi Direct only on demand while the
Mac's Wi-Fi is idle, relay, Bluetooth); HandLive also starts the classic Bluetooth pairing for HFP and confirms it on
the Mac only when the code is verified end to end.

Status: proposed by the project owner on 2026-10-01 (design in `reports/phase-07-brainstorm.md`, research in
`reports/research-direct-wifi-link-2026-10-01.md`), revised the same day after a red-team review (section at the end).
**Starts only after gates G4, G5 and G6 are closed** (owner decision 2026-10-01). Planned tests-first: every
implementation card writes its tests before its code.

## Gate G7 — spike (about one week, before any other task card)

Questions: which Bluetooth bearer meets the targets between a Samsung phone and a Mac, how the Bluetooth link is
secured, can bonding be verified end to end, can the Mac use the phone's Wi-Fi Direct group safely, and at what cost?
- **Bearer:** BLE L2CAP CoC (`listenUsingInsecureL2capChannel` ↔ `CBPeripheral.openL2CAPChannel`) versus classic RFCOMM
  (`listenUsingRfcommWithServiceRecord` ↔ `IOBluetoothDevice.openRFCOMMChannelSync`): 1 KB one-way latency p50/p95, 1 MB
  and 5 MB throughput, reconnect time; screen off 10 minutes, Doze, during an HFP call, and with a bulk transfer running.
  **RFCOMM counts as viable only with a proven way for the Mac to reach the phone before any bond exists** (Android apps
  cannot read their own Bluetooth address; the BLE address is random). Otherwise BLE carries SP1/SP2 and classic is used
  for HFP only.
- **Background:** A-SVC (foreground service `connectedDevice`) keeps advertising and accepting on One UI with the screen
  off; the Mac central reconnects after sleep/wake.
- **Security questions:** does an unbonded L2CAP CoC have link-layer encryption (expected: no → the link-security layer
  of D7.1 is mandatory); what a BLE sniffer sees with the prototype link-security layer; does macOS keep the
  `DIRECT-hl-…` network in its known networks after leaving; can it be removed.
- **Bonding (for HFP):** flow (b) phone `createBond` to the Mac address sent over E2E (`IOBluetoothHostController.addressAsString`)
  and flow (c) cross-transport key derivation from a BLE bond. **Flow (a) — the phone made discoverable — is dropped**
  (it broadcasts the device name and lets a spoofed name in). Check whether the Android app can read the pairing value
  (`ACTION_PAIRING_REQUEST`) without a system permission; check `replyUserConfirmation` on the Mac.
- **Wi-Fi Direct:** autonomous group with a fixed `DIRECT-hl-…` SSID on the S25 while the phone stays on its own Wi-Fi
  (STA + P2P); the Mac joins with CoreWLAN from the notarized, hardened-runtime build with Location granted (entitlement
  `com.apple.security.personal-information.location`); join time; prompts; does macOS move back to another network.
  **Pass criterion:** "associated vs idle" and "our group vs another network" are detected correctly on macOS 27 and on
  macOS 13 or 14, with Location granted, from the app (not a CLI). `networksetup` with a passphrase on its argument list
  is not an option.
- Results in `reports/phase-07-spike-g7.md`: bearer, bonding flow, join path, link-security prototype, measured numbers
  against AC1–AC10 (the owner confirms or adjusts AC5 and AC6). **No bearer meets AC1 on an established link → stop
  Phase 7** (keep LAN + relay) and report.

## Context

- Design: `reports/phase-07-brainstorm.md` (sections 3–8; partly superseded by the red-team review below — this file is
  authoritative), research `reports/research-direct-wifi-link-2026-10-01.md`.
- Current transport: common specs 0.4.1 (LAN, TLS mandatory — it also hides identifiers and metadata), 0.4.3 (relay,
  TLS to the relay, `rv_id` for the rendezvous), 0.6.3 (session handshake authenticated by `PRK`), 0.6.3 step 7 (stream
  keys, only `camera`/`call-audio` today), 0.11 (state machine: leaves `Idle` only with a network, drops every session
  on network loss); CONN-01 E4 and CONN-03 E9 (pre-auth errors: only the pinned-TLS LAN may unpair); PAIR-01; CLIP-03;
  AUDIO-01 (rule "never pair over Bluetooth on the user's behalf" — changed by owner decision, see D7.1).
- **The relay trust model does not carry over to Bluetooth as is:** the relay hides identifiers behind TLS and
  authenticates `device_id` before forwarding; an unbonded BLE link does neither. D7.1 adds a link-security layer, a
  Bluetooth admission policy and a route-based pre-auth rule.
- Seams in the code: Apple `MessageChannel` (`WebSocketChannel`, `RelayPeerChannel`) in `HLTransport`; Android relay
  peers as a virtual Ktor `WebSocketSession` (`RelayPeerSocket`) served by `ControlServer.serveRelayPeer`. No
  `/v1/stream/*` server or client exists yet on either platform (A7.3/M7.3).
- Platform limits (verified): one Wi-Fi radio on the Mac, no Wi-Fi Direct/Wi-Fi Aware API; CoreWLAN shows no SSID
  without Location; Android apps cannot toggle Wi-Fi/Bluetooth silently, cannot confirm pairing without a system
  permission, cannot read their own Bluetooth address; the P2P group owner address is not fixed (use the gateway).

## Requirements and measurable criteria

| # | Criterion |
|---|---|
| AC1 | Text envelopes (clipboard text; SMS and call notifications ride the same lane), copy to available, 95th percentile: **LAN < 50 ms (Phase 1 target, unchanged)**; **Bluetooth ≤ 200 ms on an established link, also while a bulk transfer runs**; relay best effort |
| AC2 | Reconnect ≤ 3 s after a network change or after the Bluetooth peer is seen again (bench events `bt_seen`/`bt_lost`) |
| AC3 | 5 MB image: ≤ 2 s on the LAN; in X the first image ≤ 10 s (it includes the on-demand Wi-Fi Direct join) and the next ones ≤ 2 s while the group stays open; in Y bounded by the phone's mobile upload — relay cap unchanged (2 MiB/s per pair already exceeds typical uplink), measured and reported; Bluetooth only: background transfer, no time target and no Bluetooth-specific size cap (the CLIP-03 image limit applies) <!-- Updated: Validation Session 1 - AC3 relaxed for the first image in X; no size cap over Bluetooth --> |
| AC4 | Invariant: no device changes or loses its current Wi-Fi association. The Mac joins Wi-Fi Direct only when an image is waiting, its Wi-Fi has been unassociated for ≥ `DIRECT_WIFI_IDLE_MIN` and a scan shows no known network; it stays on the group for further images and leaves when a periodic scan shows a known network or after `DIRECT_WIFI_MAX`; HandLive never toggles radio power and never stays on the group without a reason |
| AC5 | HFP bonding started by HandLive: ≤ 1 tap on the phone; the Mac confirms by itself only when the pairing value matches the value received over E2E, otherwise the user compares one code |
| AC6 | First pairing with both devices offline (QR over BLE): ≤ 15 s from scan to Paired (confirmed or adjusted by G7) |
| AC7 | Only one-time OS prompts: Mac — Local Network, Bluetooth, Location; Android 12+ — Nearby devices; **Android 10–12 — also Location with location services on, for Wi-Fi Direct (owner decision 2026-10-01)**; plus the existing ones; plus a one-tap system request to turn Bluetooth on when no other path exists, at most once a day <!-- Updated: Validation Session 1 - Bluetooth-off prompt --> |
| AC8 | No pre-authentication message on a route without pinned TLS to the phone (Bluetooth, relay) changes pair state, removes a pair or stops reconnecting |
| AC9 | A BLE sniffer sees no stable identifier (`pair_id`, `device_id`, keys, names, `pr`) and no envelope `type`, `id` or timing per type |
| AC10 | No Bluetooth bond is confirmed automatically without a pairing value verified over E2E |

Routing rules (control lane LAN > Bluetooth > relay; bulk lane LAN > Wi-Fi Direct > relay > Bluetooth):

| Situation | Control lane | Bulk lane |
|---|---|---|
| Same LAN | LAN | LAN |
| X, Mac Wi-Fi idle, image waiting | Bluetooth | Wi-Fi Direct (on demand, AC4 rules), else Bluetooth (background) |
| X, Mac on a Wi-Fi without Internet | Bluetooth | Bluetooth (background) |
| Y, near each other | Bluetooth | Relay (joined on a bulk demand, D7.1), else Bluetooth (background) |
| Far apart, both online | Relay | Relay |

## Task cards

Code letters as in plan section 3, plus **D** = hub documents. "Tests first" lists what is written and committed (red)
before the code of the card.

| Code | Task | Tests first | Outputs | Acceptance criteria |
|------|------|-------------|---------|---------------------|
| T7.0 [test] | Gate G7 spike (above): throwaway probes on Android and macOS | — (measurement) | `reports/phase-07-spike-g7.md`; probes on the spike branch only, never merged | Bearer, bonding flow, join path and link-security prototype chosen; AC numbers measured; AC5/AC6 confirmed by the owner |
| D7.1 [docs] | Spec first, both languages. **0.11 and CONN:** start condition "a network or Bluetooth on and authorized"; network loss ends LAN/relay sessions only; pre-auth reactions only on routes with pinned TLS to the phone (`phoneAuthenticatedByTLS`), CONN-01 E4 and CONN-03 E9 rewritten as that rule. **0.4.5 Bluetooth link:** advertisement (service UUID, rotating hint; address rotated with the hint); link-security layer before any identifier (e.g. a Noise-style handshake keyed by `K_auth`, or a blinded identifier over a phone-issued nonce) and one generic pre-auth error; admission (global cap, one pre-auth link, phone nonce challenge, key-confirmation failures counted as `AUTH_FAILED`); frame = channel id ‖ length ‖ bytes, control before bulk, bulk fragments of a few KB, no close codes (end with encrypted `session/bye`). **Pairing over BLE:** `pr` = HMAC(`ps`, …), first frame MAC'd with a `ps` key before a slot is granted, one global slot with a short timeout, PIN refused per transport. **Bulk:** stream handshake for `bulk` with per-connection keys (`K_stream` + both nonces), whole transfer (push, chunks, ack) on the bulk lane, bulk inside HL binary frames with an encrypted channel byte (relay wire unchanged), bulk-demand op and relay hold rule while control rides Bluetooth. **Wi-Fi Direct (0.4.6):** SSID/passphrase derivation (≥ 128-bit passphrase), entry/exit rules of AC4, remove the saved network after leaving, HandLive socket bound to the P2P interface only. **Bonding (AUDIO-01, owner decision 2026-10-01):** HandLive may start bonding; the Mac auto-confirms only on an E2E-verified value; address exchange Mac → phone only; disclosure text updated. Plus constants, settings keys, error codes, SET-01/02/03, CONN-05/CONN-06 leaves, PAIR-01, CLIP-03 | — (contract; the vectors of S7.1 are its tests) | `docs/detailed-design/*.md` + `.vi.md` | `validate_design_docs.py` prints `problems=0`; `check_bilingual_docs.py` green; every new message type, error code, constant and string defined before code; AC8–AC10 traceable to spec rules |
| S7.1 [shared] | Contract data: test vectors — link-security handshake, frame codec with channel ids, advertisement service data, `pr` HMAC, Wi-Fi Direct SSID/passphrase, per-connection `bulk` keys, bonding value binding; JSON schemas for the new ops; UI strings; bench events `bt_seen`/`bt_lost`/`wifi_assoc` and a `reconnect_time.py` trigger for them | Vectors and negative samples are the tests: generators produce them, `check_*` validate them | `shared/test-vectors/`, `shared/schemas/`, `shared/tools/` (incl. `bench/`), `shared/strings/` | Generators reproducible; `check_schemas.py`, `check_strings.py` green; other platforms told to re-run |
| A7.1 [android] | Bluetooth control link: advertiser in A-SVC, server for the bearer chosen in G7, link-security layer, Bluetooth admission, `BluetoothPeerSocket` (virtual `WebSocketSession` like `RelayPeerSocket`) served by `ControlServer.serveBluetoothPeer`, frame codec with channel ids; a **debug-build-only loopback shim** for the e2e harness | Regression tests for `serveRelayPeer`; codec and link-security vector tests; fake-pipe tests: handshake, rekey, replayed hello, rotating addresses, pre-auth cap; a release-build test asserting the shim is absent | `android/core/transport`, `android/feature/connection`, `android/app` | All tests green; CONN-05 exceptions covered; AC1 (Bluetooth) measured on the S25 |
| M7.1 [macOS] | Bluetooth control link: central (CoreBluetooth or IOBluetooth per G7), link-security layer, `BluetoothChannel: MessageChannel`, route `.bluetooth`; 0.11 changes (start without a network, per-route network loss, `phoneAuthenticatedByTLS` instead of `route == .relay`); priority LAN > Bluetooth > relay with upgrades; exhaustive route switches in the UI packages | Red first: `networkLost` while `connected(.bluetooth)` stays connected; `idle(noNetwork)` + peer seen → connecting; forged `PAIR_UNKNOWN`/`PAIR_REVOKED`/`UNSUPPORTED_VERSION`/`AUTH_FAILED` before authentication over Bluetooth never unpairs or stops reconnecting; codec vectors; in-memory channel tests | `apple/Packages/HLTransport`, `apple/Packages/HLMacUI`, `apple/Packages/HLiOSUI`, `apple/macOS/HandLive` | All tests green; iOS builds and behaves as before; AC1 (Bluetooth), AC2, AC8 measured |
| A7.2 [android] | Offline first pairing: advertise `pr` (HMAC form) during QR mode; grant the single pairing slot only after a valid `ps`-MAC'd first frame; PAIR-01 over the secured Bluetooth link; PIN refused on Bluetooth explicitly | PAIR-01 vectors over the fake pipe; negative tests: PIN over Bluetooth, missing/invalid first-frame MAC, slot hogging, second claimant | `android/feature/pairing`, `android/core/transport` | PAIR-01 exceptions over Bluetooth covered; AC6 measured |
| M7.2 [macOS] | Offline first pairing: scan for `pr`, try every candidate with the same `pr`, run PAIR-01 over the secured `BluetoothChannel`, then pin and store as today | Same vectors; timeout, wrong `pr`, spoofed advertiser with the right `pr` | `apple/Packages/HLTransport` (`Pairing*`) | AC6 measured; no QR format change |
| A7.3 [android] | Stream channel infrastructure: `/v1/stream/*` server on A-SVC (`stream_hello`/`stream_welcome`, 0.6.3 step 7) — **reuse it if a Phase 4 or 5 product card built it first** (plan decision I9) | Stream handshake vector tests (written first) | `android/core/transport`, `android/core/crypto` | Stream handshake works on the LAN; `camera`/`call-audio` unaffected |
| M7.3 [macOS] | Stream channel client, same scope and reuse rule as A7.3 | Same | `apple/Packages/HLTransport` | Same |
| R7.1 [relay] | Confirm the relay carries bulk unchanged: `HR` binary frames of bulk size at the existing cap; no wire or cap change | Forwarding tests for bulk-sized `HR` frames (red if the relay misbehaves) | `relay/` tests only | `cargo test`, `cargo clippy` green; no change to `wire.rs` or the cap |
| A7.4 [android] | Bulk lane: `bulk` stream with per-connection keys; the whole CLIP-03 transfer on the bulk lane; path selection per the routing table; bulk over the relay as encrypted HL binary frames split in `RelayPeerMux`; bulk-demand op and relay hold rule (both flavors, foss without FCM); Bluetooth scheduler giving control frames priority | CLIP-03 regression over `/v1/ctl` first; then red: chunks before push, bulk over relay reaches the bulk session not the control session, relay joined on a bulk demand while control is on Bluetooth, AC1 under a 5 MB bulk transfer, a 10 MiB image over Bluetooth only completes in the background | `android/core/transport` (incl. `relay/`), `android/feature/clipboard` | CLIP-03 exceptions pass on every path; AC1 (LAN) unchanged; AC3 (LAN) unchanged |
| M7.4 [macOS] | Bulk lane on the Mac side, same scope as A7.4 (`RelayLink`/`RelayPeerChannel` split, `ClipboardPeer` seam) | Same order as A7.4 | `apple/Packages/HLTransport`, `apple/Packages/HLAppCore` (clipboard) | Same as A7.4 |
| A7.5 [android] | Wi-Fi Direct host (X only, on demand): group with derived SSID/passphrase, `LEGACY_OR_R2` on API 36, started/stopped on request over the control lane, STA kept; `NEARBY_WIFI_DEVICES` (13+), `ACCESS_FINE_LOCATION` + location services (10–12); Wi-Fi off → report, never toggle | Derivation vectors; lifecycle tests with a fake `WifiP2pManager` (start, stop, crash, STA unchanged, stop after `DIRECT_WIFI_MAX`) | `android/feature/connection` (or a new `feature/directlink`) | AC4 verified on the S25; AC3 in X measured |
| M7.5 [macOS] | Wi-Fi Direct join (X only): entry/exit rules of AC4 (on demand, idle ≥ `DIRECT_WIFI_IDLE_MIN`, no known network visible, periodic scan, `DIRECT_WIFI_MAX`), CoreWLAN join, gateway connect with the pinned certificate, socket bound to the P2P interface, saved network removed after leaving | Red first: never join while associated, never join when a known network is visible (deauth case), leave on known network, leave at max duration, saved network removed | `apple/Packages/HLTransport`, `apple/macOS/HandLive` | AC4 verified incl. the deauth scenario; AC3 in X ≤ 2 s |
| A7.6 [android] | Automatic classic bonding, **started right after QR pairing** (and once for existing pairs when the feature ships, or whenever the bond is missing) <!-- Updated: Validation Session 1 - bonding trigger -->, flow from G7 ((b) or (c)): bonding request over E2E, `createBond` to the Mac address received over E2E, pairing value sent over E2E when readable | Fake-adapter tests per state; never bond without an authenticated session; no discoverable request | `android/feature/call` or `android/feature/connection` | AC5, AC10 measured; refusal and timeout covered |
| M7.6 [macOS] | Automatic classic bonding: `IOBluetoothDevicePair`; auto-confirm only when the value matches the E2E value, otherwise show the code for one comparison; hand the bonded device to the HFP stack | Confirm/reject decision tests with a fake delegate (match, mismatch, missing value) | `apple/Packages/…` (call audio), `apple/macOS/HandLive` | AC5, AC10; mismatch or missing value never auto-confirmed |
| A7.7 [android] | Permission onboarding (owner of AC7 on Android): SET-01 prompts for Nearby devices (12+), Location + location services (10–12, Wi-Fi Direct), explained by primers; Bluetooth-off request (`ACTION_REQUEST_ENABLE`) only when no LAN or relay path exists, at most once a day | Prompt-count tests per API level (29, 31, 33, 37) | `android/app`, `android/feature/connection` | AC7 per API level |
| M7.7 [macOS] | Permission onboarding (owner of AC7 on the Mac): Bluetooth and Location primers (SET-03), `NSBluetoothAlwaysUsageDescription`, Location usage text, entitlement `com.apple.security.personal-information.location`, release signing step; Bluetooth-off status line with a button to Bluetooth settings, same rule as A7.7 | Prompt-sequence tests; release-build entitlement check | `apple/macOS/HandLive`, `apple/macOS/HandLive.entitlements`, `docs/deployment-guide.md` (via D) | AC7 on the Mac; Location works in the notarized build |
| T7.1 [test] | End-to-end matrix: X and Y with S25 + Mac, same LAN, far apart; screen off, sleep/wake, Bluetooth off, phone Wi-Fi off, Location denied, relay down; **adversarial:** cloned advertiser, BLE sniff (AC9), replayed hello, forged pre-auth errors (AC8), pairing-slot hogging, deauth of the Mac's Wi-Fi (AC4), bonding MITM attempt (AC10); first and next image timing in X; a 10 MiB image over Bluetooth only with AC1 held; Bluetooth off on each side; Android 10–12 prompt count; en and vi; TalkBack/VoiceOver | `shared/tools/e2e` scenarios through the debug shim of A7.1, written first | `shared/tools/e2e/`, `reports/phase-07-T7.1.md` | AC1–AC10 met; Wi-Fi association recorded from the app's debug log before/after on both devices |

## Branch and work order

- Branch `feat/phase-07-connect-anywhere` in the hub, handlive-shared, handlive-android, handlive-apple (and
  handlive-relay only for the R7.1 tests).
- T7.0 first and alone (after G4/G5/G6). Then D7.1 → S7.1 (every platform card waits for its spec, vectors, strings).
- Then in sub-project order: SP1 (A7.1 ∥ M7.1, with A7.7 ∥ M7.7 for the Bluetooth prompts) → SP2 (A7.2 ∥ M7.2) → SP3
  (A7.3 ∥ M7.3 unless already built, R7.1, then A7.4 ∥ M7.4) → SP4 (A7.5 ∥ M7.5) → SP5 (A7.6 ∥ M7.6, after the Phase 4
  HFP product cards) → T7.1. **If G7 chooses RFCOMM and it needs a bond, SP5 moves before SP1** and stops waiting for
  Phase 4.
- One commit per logical step, `shared/` before the platform, never across repositories.

## Testing

- Tests first (per card, committed red before the code): vectors from S7.1, regression tests for the code a card
  refactors (`serveRelayPeer`, CLIP-03 over `/v1/ctl`, `ConnectionStateMachine`, relay peer split), then the new
  behavior, then the adversarial cases.
- Regression gate after every card: Android `./gradlew check`; Apple `swift test` in the touched packages and
  `xcodebuild test` for the app targets; relay `cargo test` and `cargo clippy`; hub `python3
  tools/docs/validate_design_docs.py` and `tools/docs/check_bilingual_docs.py`; shared `check_schemas.py`,
  `check_strings.py`.
- Real devices: S25 Ultra + this Mac (macOS 27) for X and Y, plus a Mac on macOS 13 or 14 and an Android 10–12 phone
  for the prompt and idle-detection checks; AC timings from `BenchLog` and the bench events of S7.1.

## Risks and rollback

- G7 fails (no bearer meets AC1) → stop Phase 7; LAN + relay stay the product answer.
- **Security:** an attacker in BLE range can try to clone the advertiser, replay hellos, hog pairing slots or forge
  pre-auth errors → covered by the link-security layer, the Bluetooth admission policy and the route-based pre-auth rule
  (AC8, AC9), and tested adversarially in T7.1. A bond confirmed without verification would expose call audio → AC10.
- One UI throttles background BLE → classic page-scan path or a visible "nearby" notification; measured in G7.
- IOBluetooth fragility (shared with HFP) → bearer behind the `MessageChannel` / `WebSocketSession` seam; BLE fallback.
- macOS prompts on joining or moves back to another network → Wi-Fi Direct stays opportunistic; images fall back to
  Bluetooth or the relay; AC3 in X reported as measured.
- Relay upload too slow on mobile data → AC3 in Y reported as measured (accepted).
- Each sub-project ships behind a setting (`link.bluetooth`, `link.direct_wifi`, `link.auto_bond`, names fixed in D7.1)
  so it can be turned off without a release.

## Red Team Review

### Session — 2026-10-01

**Findings:** 15 after deduplication of 18 (15 accepted, 0 rejected) · **Severity:** 2 Critical, 9 High, 4 Medium ·
Reviewers: Security Adversary (fact checker), Assumption Destroyer (scope auditor); evidence re-checked in the code.

| # | Finding | Severity | Disposition | Applied to |
|---|---------|----------|-------------|------------|
| 1 | Forged pre-auth errors over Bluetooth could unpair or stop reconnecting (Mac code exempts only `route == .relay`) | Critical | Accept | D7.1 (route rule), M7.1, AC8, T7.1 |
| 2 | Scenario X blocked: the Mac leaves `Idle` only with a network and drops every session on network loss | Critical | Accept | D7.1 (0.11), M7.1 |
| 3 | Unbonded BLE exposes identifiers, metadata and the pairing transcript; `pr` is a stable id | High | Accept | D7.1 (link-security layer, `pr` HMAC), AC9 |
| 4 | Pre-auth admission keyed by IP or `device_id` does not work on BLE; hellos replayable | High | Accept | D7.1 (admission), A7.1 |
| 5 | Automatic bonding reverses AUDIO-01; MITM defence relied on an unproven capability | High | Accept (owner: verified auto-confirm only, flow (a) dropped) | G7, D7.1, A7.6, M7.6, AC5, AC10 |
| 6 | Bulk over the relay had no channel split; cap raise needless; stream keys not bound per connection | High | Accept | D7.1 (bulk framing, keys), R7.1 (tests only), A7.4, M7.4, AC3 |
| 7 | In Y the phone never joins the relay while a Bluetooth session exists | High | Accept | D7.1 (bulk demand), A7.4, M7.4 |
| 8 | No stream channel infrastructure exists; chunks before push are dropped | High | Accept | A7.3, M7.3, plan decision I9, A7.4, M7.4 |
| 9 | Control and bulk shared one Bluetooth link without priority; AC1 never measured under load | High | Accept | D7.1 (channel ids, scheduler), AC1, A7.4 |
| 10 | RFCOMM needs the phone's address or a bond before SP1/SP2 | High | Accept | G7, work order |
| 11 | "Wi-Fi idle" unreliable without Location; deauth could push the Mac onto Wi-Fi Direct and keep it there | High | Accept | G7, AC4, A7.5, M7.5, M7.7, T7.1 |
| 12 | Offline pairing over BLE open to slot hogging; PIN blocked only indirectly | Medium | Accept | D7.1, A7.2, M7.2 |
| 13 | The e2e harness had no way to reach a Bluetooth pipe in the real app | Medium | Accept | A7.1 (debug shim), T7.1 |
| 14 | AC7 broken on Android 10–12 by Wi-Fi Direct's Location need | Medium | Accept (owner: relax AC7 for Android 10–12) | AC7, A7.5, A7.7 |
| 15 | AC1 loosened the LAN target; AC2 unmeasurable for Bluetooth; no security criteria | Medium | Accept | AC1, AC2, AC8–AC10, S7.1, G7, T7.1 |

### Whole-Plan Consistency Sweep

- Decision deltas: Bluetooth no longer reuses the relay trust model as is; relay wire and cap unchanged; bonding
  auto-confirm only with an E2E-verified value; Wi-Fi Direct on demand only; AC7 relaxed for Android 10–12; LAN text
  target stays < 50 ms; card numbering changed (stream infrastructure A/M7.3, bulk A/M7.4, Wi-Fi Direct A/M7.5,
  bonding A/M7.6, permissions A/M7.7).
- Checked: `plan.md` and `plan.vi.md` (row 7, gate G7, decision I9), this file and its Vietnamese twin, the brainstorm
  report (marked as partly superseded), README and `docs/project-roadmap*` (no stale claim). Unresolved contradictions:
  none.

## Validation Log

### Session 1 — 2026-10-01
**Trigger:** `/ck:plan validate` after the red-team review. **Questions asked:** 4. Verification pass: limited to the
names introduced by the red-team rewrite (Red Team Review already holds the evidence) — claims checked 8, verified 8,
failed 0, unverified 0; tier Light.

#### Questions & Answers

1. **[Assumptions]** AC3 (5 MB image ≤ 2 s in scenario X) conflicts with AC4 (the Mac joins Wi-Fi Direct only when an
   image is already waiting, and joining takes 3–8 s). How to resolve it?
   - Options: Pre-join when safe (Mac Wi-Fi idle ≥ N s and no known network visible) | On demand only, relax AC3
   - **Answer:** On demand only, relax AC3
   - **Rationale:** keeps the deauth-resistant entry rule; the first image in X pays the join time.
2. **[Scope]** When Bluetooth is off on the phone or the Mac (so no nearby link), what does HandLive do?
   - Options: One-tap prompt when needed | Silent
   - **Answer:** One-tap prompt when needed
   - **Rationale:** a radio cannot be turned on silently; one system request at most once a day, only without LAN/relay.
3. **[Tradeoffs]** When an image has only the Bluetooth path left (tens of KB/s, a 5 MB image takes 1–4 minutes), how is
   it sent?
   - Options: Cap at 1 MiB, larger waits for a better path | Send the full 10 MiB in the background | No images over
     Bluetooth
   - **Answer:** Other — **Custom input:** "không giới hạn dung lượng" (no size limit)
   - **Rationale:** recorded as "no Bluetooth-specific cap"; the product-wide CLIP-03 image limit (10 MiB) still applies
     — changing that limit would be a CLIP-03 decision outside this phase.
4. **[Architecture]** When should HandLive start the Bluetooth pairing for HFP (one tap on the phone)?
   - Options: When call audio is turned on | Right after QR pairing
   - **Answer:** Right after QR pairing
   - **Rationale:** one setup moment for everything; pairs that already exist get a one-time request when the feature
     ships.

#### Confirmed Decisions
- AC3: LAN ≤ 2 s; X first image ≤ 10 s, next images ≤ 2 s while the group is open; Wi-Fi Direct stays on demand.
- Bluetooth off: one-tap system request (Android) / status line with a settings button (Mac), only without LAN/relay,
  at most once a day.
- Images over Bluetooth: no Bluetooth-specific size cap; the scheduler keeps AC1 during long transfers.
- HFP bonding starts right after QR pairing.

#### Impact on Phases
- AC3, AC4 (stay for further images), AC7 (Bluetooth-off request), A7.4 (10 MiB over Bluetooth), A7.6 (trigger), A7.7,
  M7.7 (Bluetooth-off handling), T7.1 (new scenarios); `plan.md` row 7 and `docs/project-roadmap*` criteria.

### Whole-Plan Consistency Sweep
- Searched all plan files, the roadmap and the brainstorm note for "2 s … offline", "on demand", "bonding", "Bluetooth
  off"; updated `plan.md`/`plan.vi.md` row 7, `docs/project-roadmap*`, the brainstorm notes. Unresolved contradictions:
  none.
