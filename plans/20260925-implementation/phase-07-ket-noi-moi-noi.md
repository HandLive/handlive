English | [Tiếng Việt](phase-07-ket-noi-moi-noi.vi.md)

# Phase 7 — Connect anywhere

**Goal:** after the first QR pairing, the phone and the Mac near each other connect by themselves when neither has a
network (scenario X, the case the owner needs solved) — with no manual network step and **without either device ever
leaving or changing its current Wi-Fi**. A secured Bluetooth link carries the control channel when there is no LAN; a
bulk lane carries images over the fastest path allowed (LAN, Wi-Fi Direct only on demand while the Mac's Wi-Fi is idle,
Bluetooth in the background). The same Bluetooth path also covers scenario Y (phone on mobile data, Mac on another
Wi-Fi) while the two are near each other. No relay and no HFP bonding in this phase (scope cut below).

Status: **started on 2026-10-28 by owner decision, without waiting for gates G4, G5 and G6** (Validation Session 2).
Proposed by the project owner on 2026-10-01 (design in `reports/phase-07-brainstorm.md`, research in
`reports/research-direct-wifi-link-2026-10-01.md`), revised the same day after a red-team review (section at the end).
The 2026-10-01 rule "starts only after G4, G5 and G6 are closed" is withdrawn. Planned tests-first: every
implementation card writes its tests before its code.

**Scope cut 2026-10-28** (owner decision: no relay deployment; Phase 4 stopped on 2026-10-12, so no HFP):
- **Dropped — relay:** R7.1; every relay route in the routing table; the scenario-Y relay part of AC3; the relay parts
  of A7.4/M7.4 (bulk over the relay, bulk-demand op, relay hold rule) and of D7.1. The existing relay code (CONN-03)
  is left untouched and is not tested by this phase.
- **Dropped — HFP bonding:** SP5 (A7.6/M7.6), AC5, AC10, the bonding question of G7, the "during an HFP call"
  measurement of G7, the AUDIO-01 change of D7.1 and the `link.auto_bond` setting. Reopens only with Phase 4.
- Rows below are kept and marked so the red-team history stays readable.

## Gate G7 — spike (about one week, before any other task card)

Questions: which Bluetooth bearer meets the targets between a Samsung phone and a Mac, how the Bluetooth link is
secured, can the Mac use the phone's Wi-Fi Direct group safely, and at what cost?
- **Bearer:** BLE L2CAP CoC (`listenUsingInsecureL2capChannel` ↔ `CBPeripheral.openL2CAPChannel`) versus classic RFCOMM
  (`listenUsingRfcommWithServiceRecord` ↔ `IOBluetoothDevice.openRFCOMMChannelSync`): 1 KB one-way latency p50/p95, 1 MB
  and 5 MB throughput, reconnect time; screen off 10 minutes, Doze, and with a bulk transfer running. (*Dropped
  2026-10-28:* "during an HFP call" — no HFP after Phase 4 stopped.)
  **RFCOMM counts as viable only with a proven way for the Mac to reach the phone without any bond** (Android apps
  cannot read their own Bluetooth address; the BLE address is random; HandLive no longer starts a bond, SP5 dropped).
  Otherwise BLE carries SP1/SP2.
- **Background:** A-SVC (foreground service `connectedDevice`) keeps advertising and accepting on One UI with the screen
  off; the Mac central reconnects after sleep/wake.
- **Security questions:** does an unbonded L2CAP CoC have link-layer encryption (expected: no → the link-security layer
  of D7.1 is mandatory); what a BLE sniffer sees with the prototype link-security layer; does macOS keep the
  `DIRECT-hl-…` network in its known networks after leaving; can it be removed.
- **Bonding (for HFP) — Dropped 2026-10-28 (SP5 dropped, Phase 4 stopped; kept for history):** flow (b) phone `createBond` to the Mac address sent over E2E (`IOBluetoothHostController.addressAsString`)
  and flow (c) cross-transport key derivation from a BLE bond. **Flow (a) — the phone made discoverable — is dropped**
  (it broadcasts the device name and lets a spoofed name in). Check whether the Android app can read the pairing value
  (`ACTION_PAIRING_REQUEST`) without a system permission; check `replyUserConfirmation` on the Mac.
- **Wi-Fi Direct:** autonomous group with a fixed `DIRECT-hl-…` SSID on the S25 while the phone stays on its own Wi-Fi
  (STA + P2P); the Mac joins with CoreWLAN from the notarized, hardened-runtime build with Location granted (entitlement
  `com.apple.security.personal-information.location`); join time; prompts; does macOS move back to another network.
  **Pass criterion:** "associated vs idle" and "our group vs another network" are detected correctly on macOS 27 and on
  macOS 13 or 14, with Location granted, from the app (not a CLI). `networksetup` with a passphrase on its argument list
  is not an option.
- Results in `reports/phase-07-spike-g7.md`: bearer, join path, link-security prototype, measured numbers against
  AC1–AC4 and AC6–AC9 (the owner confirms or adjusts AC6). **No bearer meets AC1 on an established link → stop
  Phase 7** and report; the product then stays LAN only (no relay deployed, so there is no fallback).

## Context

- Design: `reports/phase-07-brainstorm.md` (sections 3–8; partly superseded by the red-team review below — this file is
  authoritative), research `reports/research-direct-wifi-link-2026-10-01.md`.
- Current transport: common specs 0.4.1 (LAN, TLS mandatory — it also hides identifiers and metadata), 0.4.3 (relay,
  TLS to the relay, `rv_id` for the rendezvous), 0.6.3 (session handshake authenticated by `PRK`), 0.6.3 step 7 (stream
  keys, only `camera`/`call-audio` today), 0.11 (state machine: leaves `Idle` only with a network, drops every session
  on network loss); CONN-01 E4 and CONN-03 E9 (pre-auth errors: only the pinned-TLS LAN may unpair); PAIR-01; CLIP-03;
  AUDIO-01 (rule "never pair over Bluetooth on the user's behalf" — the 2026-10-01 change is dropped with SP5 on
  2026-10-28, so the rule stays as is).
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
| AC1 | Text envelopes (clipboard text; SMS and call notifications ride the same lane), copy to available, 95th percentile: **LAN < 50 ms (Phase 1 target, unchanged)**; **Bluetooth ≤ 200 ms on an established link, also while a bulk transfer runs**; ~~relay best effort~~ (relay dropped 2026-10-28) |
| AC2 | Reconnect ≤ 3 s after a network change or after the Bluetooth peer is seen again (bench events `bt_seen`/`bt_lost`) |
| AC3 | 5 MB image: ≤ 2 s on the LAN; in X the first image ≤ 10 s (it includes the on-demand Wi-Fi Direct join) and the next ones ≤ 2 s while the group stays open; ~~in Y bounded by the phone's mobile upload over the relay~~ (Dropped 2026-10-28, no relay: in Y near each other images go over Bluetooth); Bluetooth only: background transfer, no time target and no Bluetooth-specific size cap (the CLIP-03 image limit applies) <!-- Updated: Validation Session 1 - AC3 relaxed for the first image in X; no size cap over Bluetooth --> |
| AC4 | Invariant: no device changes or loses its current Wi-Fi association. The Mac joins Wi-Fi Direct only when an image is waiting, its Wi-Fi has been unassociated for ≥ `DIRECT_WIFI_IDLE_MIN` and a scan shows no known network; it stays on the group for further images and leaves when a periodic scan shows a known network or after `DIRECT_WIFI_MAX`; HandLive never toggles radio power and never stays on the group without a reason |
| AC5 | **Dropped 2026-10-28 (SP5 dropped, no HFP).** Was: HFP bonding started by HandLive: ≤ 1 tap on the phone; the Mac confirms by itself only when the pairing value matches the value received over E2E, otherwise the user compares one code |
| AC6 | First pairing with both devices offline (QR over BLE): ≤ 15 s from scan to Paired (confirmed or adjusted by G7) |
| AC7 | Only one-time OS prompts: Mac — Local Network, Bluetooth, Location; Android 12+ — Nearby devices; **Android 10–12 — also Location with location services on, for Wi-Fi Direct (owner decision 2026-10-01)**; plus the existing ones; plus a one-tap system request to turn Bluetooth on when no other path exists, at most once a day <!-- Updated: Validation Session 1 - Bluetooth-off prompt --> |
| AC8 | No pre-authentication message on a route without pinned TLS to the phone (Bluetooth; also the existing relay route) changes pair state, removes a pair or stops reconnecting |
| AC9 | A BLE sniffer sees no stable identifier (`pair_id`, `device_id`, keys, names, `pr`) and no envelope `type`, `id` or timing per type |
| AC10 | **Dropped 2026-10-28 (SP5 dropped, HandLive starts no bond).** Was: no Bluetooth bond is confirmed automatically without a pairing value verified over E2E |

Routing rules (2026-10-28: control lane LAN > Bluetooth; bulk lane LAN > Wi-Fi Direct (X only, AC4 rules) > Bluetooth
in the background). The 2026-10-01 relay steps (control "> relay", bulk "> relay >") are dropped.

| Situation | Control lane | Bulk lane |
|---|---|---|
| Same LAN | LAN | LAN |
| X, Mac Wi-Fi idle, image waiting | Bluetooth | Wi-Fi Direct (on demand, AC4 rules), else Bluetooth (background) |
| X, Mac on a Wi-Fi without Internet | Bluetooth | Bluetooth (background) |
| Y, near each other | Bluetooth | Bluetooth (background) — *was relay on a bulk demand, dropped 2026-10-28* |
| Far apart | No path in this phase — *was relay, dropped 2026-10-28* | No path |

## Task cards

Code letters as in plan section 3, plus **D** = hub documents. "Tests first" lists what is written and committed (red)
before the code of the card.

| Code | Task | Tests first | Outputs | Acceptance criteria |
|------|------|-------------|---------|---------------------|
| T7.0 [test] | Gate G7 spike (above): throwaway probes on Android and macOS | — (measurement) | `reports/phase-07-spike-g7.md`; probes on the spike branch only, never merged | Bearer, join path and link-security prototype chosen; AC numbers measured; AC6 confirmed by the owner (bonding flow and AC5 dropped 2026-10-28) |
| ~~T7.0a~~ [test] | *(Added 2026-10-28, lead decision.)* Scan-response probe: the throwaway probes of T7.0 with the 0.4.5 layout (128-bit `BT_SERVICE_UUID` in the advertisement, service data in the scan response) on the S25 + Mac, Mac scanning in the foreground and in the background | — (measurement) | A section in `reports/phase-07-spike-g7.md`; probes on the spike branch only, never merged | **Dropped 2026-10-28 (owner decision): scan response checked in A7.1b/M7.1c on real devices.** Was: service data received on the Mac in both cases; otherwise the advertisement layout of 0.4.5 changes (D) before S7.1a freezes its vectors |
| D7.1 [docs] | Spec first, both languages. **0.11 and CONN:** start condition "a network or Bluetooth on and authorized"; network loss ends LAN/relay sessions only; pre-auth reactions only on routes with pinned TLS to the phone (`phoneAuthenticatedByTLS`), CONN-01 E4 and CONN-03 E9 rewritten as that rule. **0.4.5 Bluetooth link:** advertisement (service UUID, rotating hint; address rotated with the hint); link-security layer before any identifier (e.g. a Noise-style handshake keyed by `K_auth`, or a blinded identifier over a phone-issued nonce) and one generic pre-auth error; admission (global cap, one pre-auth link, phone nonce challenge, key-confirmation failures counted as `AUTH_FAILED`); frame = channel id ‖ length ‖ bytes, control before bulk, bulk fragments of a few KB, no close codes (end with encrypted `session/bye`). **Pairing over BLE:** `pr` = HMAC(`ps`, …), first frame MAC'd with a `ps` key before a slot is granted, one global slot with a short timeout; ~~PIN refused per transport~~ *changed 2026-10-28 (owner decision): the PIN pairs over Bluetooth through CPace (`CPACE-X25519-SHA512`), one online guess per channel, 3 per PIN, lockout (D7.1e, PAIR-01 flow C)*. **Bulk:** stream handshake for `bulk` with per-connection keys (`K_stream` + both nonces), whole transfer (push, chunks, ack) on the bulk lane over LAN, Wi-Fi Direct or Bluetooth (*dropped 2026-10-28:* bulk inside relay HL binary frames, bulk-demand op, relay hold rule). **Wi-Fi Direct (0.4.6):** SSID/passphrase (random per group, ≥ 128-bit passphrase), entry/exit rules of AC4, remove the saved network after leaving, HandLive socket bound to the P2P interface only. ~~**Bonding (AUDIO-01)**~~ *dropped 2026-10-28 with SP5; AUDIO-01 unchanged.* Plus constants, settings keys, error codes, SET-01/02/03, CONN-05/CONN-06 leaves, PAIR-01, CLIP-03 | — (contract; the vectors of S7.1 are its tests) | `docs/detailed-design/*.md` + `.vi.md` | `validate_design_docs.py` prints `problems=0`; `check_bilingual_docs.py` green; every new message type, error code, constant and string defined before code; AC8–AC9 traceable to spec rules |
| S7.1a [shared] | *(Split 2026-10-28, lead decision; was S7.1.)* For SP1, link contract: link-security handshake (`challenge`, `noise1`, `noise2`, prologue bound to `n_s`, `K_bt_disc`/`K_bt_link`), record codec (`rlen` bounds; 272, 1,040, 4,112) and frame codec (channel ids, `more`/`long`, short and long control lanes, padding) with negative samples (`rlen` over its bound, unknown `chan`, `more` without `long`, a long-lane fragment over `BT_BULK_FRAGMENT_MAX`, a message over `BT_MESSAGE_MAX`), advertisement service data (frozen now from the 0.4.5 table; checked on real devices in A7.1b/M7.1c); UI strings for the Bluetooth prompts and the Bluetooth-off line; bench events `bt_seen`/`bt_lost` and a `reconnect_time.py` trigger for them | Vectors and negative samples are the tests: generators produce them, `check_*` validate them | `shared/test-vectors/`, `shared/strings/`, `shared/tools/` (incl. `bench/`) | Generators reproducible; `check_schemas.py`, `check_strings.py` green; other platforms told to re-run |
| S7.1b [shared] | For SP2, made while SP1 runs: `pr_bt` HMAC, `K_bt_pdisc`/`K_bt_plink`, `BT_PIN_HINT`; CPace for the Bluetooth PIN (`cpace.json`, Kotlin and Swift: the draft's own `CPACE-X25519-SHA512` vectors, then the HandLive cases and negatives of 0.6.1), `K_bt_pinlink`/`K_bt_pin`; schemas for the pairing envelopes on a Bluetooth link; strings for the PIN over Bluetooth and `BT_PIN_LOCKOUT` | Vectors and negative samples are the tests: generators produce them, `check_*` validate them | `shared/test-vectors/`, `shared/schemas/`, `shared/strings/` | Generators reproducible; `check_schemas.py`, `check_strings.py` green; other platforms told to re-run; the pentester has reviewed `cpace.json` before A7.2a/M7.2a start |
| S7.1c [shared] | For SP3: per-connection `bulk` keys (`K_bulk` from `K_stream` and both nonces, 0.4.7); schemas for `bulk/stream_hello` and `bulk/stream_welcome` | Vectors and negative samples are the tests: generators produce them, `check_*` validate them | `shared/test-vectors/`, `shared/schemas/` | Generators reproducible; `check_schemas.py`, `check_strings.py` green; other platforms told to re-run |
| S7.1d [shared] | For SP4: Wi-Fi Direct `ssid` and `passphrase` are random for every group (0.4.6), so no derivation vectors: format and charset samples, positive and negative (prefix `DIRECT-`, length, alphabet, passphrase entropy); schemas for `direct/start`, `direct/stop`, `direct/want` and the `direct/start` ack `{ssid, passphrase, host, port}` (00-common-specs 0.7.1); bench event `wifi_assoc`; strings for the Location prompts | Vectors and negative samples are the tests: generators produce them, `check_*` validate them | `shared/test-vectors/`, `shared/schemas/`, `shared/strings/`, `shared/tools/bench/` | Generators reproducible; `check_schemas.py`, `check_strings.py` green; other platforms told to re-run |
| A7.1a [android] | *(Split 2026-10-28, lead decision; was A7.1.)* Link core, no radio: record and frame codecs with every length checked before allocating, short and long control lanes with reassembly, the scheduler of 0.4.5 "Priority" (short control > long control > bulk, `BT_BULK_INFLIGHT`; moved here from A7.4 because G7 condition 1 makes it part of the control lane), link-security layer (Noise responder, trial of each pair psk, link rekey), Bluetooth admission for the whole listener (`BT_LINK_LIMIT`, `BT_PREAUTH_LIMIT`, `BT_PREAUTH_TIMEOUT`, `BT_AUTH_FAIL_BLOCK`; never keyed by address) | Codec and link-security vectors of S7.1a; fake-pipe tests: handshake, a replayed `noise1` on a new channel, link rekey, pre-auth cap, block after `BT_AUTH_FAIL_BLOCK`, oversized `rlen`, a short envelope sent after a 256 KiB one arrives first, two envelopes of the same `type` keep their order, inflight bound | `android/core/transport` | All tests green |
| A7.1b [android] | Radio and wiring: advertiser and L2CAP server in A-SVC (rotation every `BT_HINT_PERIOD`, rebuilt on `STATE_ON`, independent of the LAN server and of the network), `SessionTransport.BLUETOOTH` and every `when` on it (`PeerSession.Channel` and its users in the feature modules), `BluetoothPeerSocket` (virtual `WebSocketSession` like `RelayPeerSocket`) served by `ControlServer.serveBluetoothPeer`, `session/bye` before every close on Bluetooth; a **debug-build-only loopback shim** for the e2e harness (not needed for the SP1 measurement, may land last) | Regression tests for `serveRelayPeer`; session tests over the fake pipe; rotation and `STATE_ON` rebuild with a fake adapter; a release-build test asserting the shim is absent | `android/core/transport`, `android/feature/connection`, `android/feature/*` (route mapping only), `android/app` | All tests green; CONN-05 exceptions covered; AC1 (Bluetooth) measured on the S25, idle and under a debug-only long-control load through the scheduler; scan response contains service data read on Mac, even when app is in background |
| M7.1a [macOS] | *(Split 2026-10-28, lead decision; was M7.1.)* State machine of 0.11, pure logic, first card of SP1: route `.bluetooth` and `ConnectingBT`; start without a network when Bluetooth is usable; network loss ends LAN/relay sessions only; `phoneAuthenticatedByTLS` instead of `route == .relay` (`ConnectionManager+Run`, `ConnectionManager+Supervise`, `ControlSession`); priority LAN > Bluetooth with upgrades (the existing relay route stays in the code untouched, last, and is not deployed); exhaustive route switches in the packages that read the route (`HLMacUI`, `HLiOSUI`, `HLSMS`, `HLDesignSystem`, `Tools/HandLiveDevClient`) | Red first: `networkLost` while `connected(.bluetooth)` stays connected; `idle(noNetwork)` + peer seen → connecting; forged `PAIR_UNKNOWN`/`PAIR_REVOKED`/`UNSUPPORTED_VERSION`/`AUTH_FAILED` before authentication over Bluetooth never unpairs or stops reconnecting; a LAN session replaces the Bluetooth one | `apple/Packages/HLTransport`, `apple/Packages/HLMacUI`, `apple/Packages/HLiOSUI`, `apple/Packages/HLSMS`, `apple/Packages/HLDesignSystem`, `apple/Tools/HandLiveDevClient` | All tests green; iOS builds and behaves as before |
| M7.1b [macOS] | Link core, no radio, initiator side of A7.1a: record and frame codecs, short and long control lanes, the scheduler, link-security initiator (`noise1`, `noise2` check, link rekey), `BluetoothChannel: MessageChannel` over an in-memory pipe | Codec and link-security vectors of S7.1a; in-memory channel tests (the list of A7.1a, initiator side) | `apple/Packages/HLTransport` | All tests green |
| M7.1c [macOS] | Radio and wiring: CoreBluetooth central (scan with the `BT_SERVICE_UUID` filter, hints over `e − 4`…`e + 4`, `openL2CAPChannel`), created and injected by the macOS app only (iOS never creates it), route `.bluetooth` live in `ConnectionManager` | Fake-central tests: hint match, rotated PSM, next candidate after a `noise2` failure (CONN-05 E3), disconnect → `Backoff` | `apple/Packages/HLTransport`, `apple/macOS/HandLive` | All tests green; iOS builds and behaves as before; AC1 (Bluetooth), AC2, AC8 measured; scan response contains service data read on the Mac, even when app is in background |
| A7.2a [android] | *(Added 2026-10-28, lead decision.)* CPace primitive `CPACE-X25519-SHA512`, no Bluetooth: own field arithmetic mod 2^255 − 19 in constant time (no `BigInteger`, no branch or table index on secret data), Elligator2 map of RFC 9380, `calculate_generator`, `ISK` | All `cpace.json` vectors of S7.1b, negatives included | `android/core/crypto` | All vectors pass; the pentester has reviewed the constant-time code |
| A7.2 [android] | Offline first pairing: advertise `pr` (HMAC form) during QR mode; grant the single pairing slot only after a valid `ps`-MAC'd first frame; PAIR-01 over the secured Bluetooth link; PIN over Bluetooth through CPace on the primitive of A7.2a (PAIR-01 flow C: `BT_PIN_HINT` advertising, `cpace1`/`cpace2`, attempt counting, `BT_PIN_LOCKOUT`) — *changed 2026-10-28 by owner decision, was "PIN refused on Bluetooth explicitly"* | PAIR-01 vectors over the fake pipe; CPace vectors of S7.1 (`cpace.json`); negative tests: wrong PIN (3 attempts then lockout), low-order `Ya`, `cpace1` outside a PIN window, `mode` not matching the link, missing/invalid first-frame MAC, slot hogging, second claimant | `android/feature/pairing`, `android/core/transport` | PAIR-01 exceptions over Bluetooth covered; AC6 measured |
| M7.2a [macOS] | *(Added 2026-10-28, lead decision.)* CPace primitive, same scope as A7.2a (CryptoKit has no field arithmetic) | Same as A7.2a | `apple/Packages/HLCrypto` | Same as A7.2a |
| M7.2 [macOS] | Offline first pairing: scan for `pr`, try every candidate with the same `pr`, run PAIR-01 over the secured `BluetoothChannel`, then pin and store as today; PIN: scan for `BT_PIN_HINT`, CPace initiator on the primitive of M7.2a, count wrong PINs, new PIN at 3 (*added 2026-10-28, owner decision*) | Same vectors plus `cpace.json`; timeout, wrong `pr`, spoofed advertiser with the right `pr`, a phone in PIN mode with another PIN, an attacker answering `cpace1` | `apple/Packages/HLTransport` (`Pairing*`) | AC6 measured; no QR format change |
| A7.3 [android] | Stream channel infrastructure: `/v1/stream/*` server on A-SVC (`stream_hello`/`stream_welcome`, 0.6.3 step 7) — **reuse it if a Phase 4 or 5 product card built it first** (plan decision I9) | Stream handshake vector tests (written first) | `android/core/transport`, `android/core/crypto` | Stream handshake works on the LAN; `camera`/`call-audio` unaffected |
| M7.3 [macOS] | Stream channel client, same scope and reuse rule as A7.3 | Same | `apple/Packages/HLTransport` | Same |
| R7.1 [relay] | **Dropped 2026-10-28 (no relay deployment).** Was: confirm the relay carries bulk unchanged: `HR` binary frames of bulk size at the existing cap; no wire or cap change | Forwarding tests for bulk-sized `HR` frames (red if the relay misbehaves) | `relay/` tests only | `cargo test`, `cargo clippy` green; no change to `wire.rs` or the cap |
| A7.4 [android] | Bulk lane: `bulk` stream with per-connection keys; the whole CLIP-03 transfer on the bulk lane; path selection per the routing table (LAN > Wi-Fi Direct > Bluetooth); bulk channel `0x02` plugged into the scheduler of A7.1a (the scheduler moved to A7.1a on 2026-10-28). *Dropped 2026-10-28:* bulk over the relay split in `RelayPeerMux`, bulk-demand op, relay hold rule | CLIP-03 regression over `/v1/ctl` first; then red: chunks before push, AC1 under a 5 MB bulk transfer, a 10 MiB image over Bluetooth only completes in the background (*dropped:* the two relay tests) | `android/core/transport`, `android/feature/clipboard` | CLIP-03 exceptions pass on every path; AC1 (LAN) unchanged; AC3 (LAN) unchanged |
| M7.4 [macOS] | Bulk lane on the Mac side, same scope as A7.4, on the scheduler of M7.1b (`ClipboardPeer` seam; the `RelayLink`/`RelayPeerChannel` split is dropped 2026-10-28) | Same order as A7.4 | `apple/Packages/HLTransport`, `apple/Packages/HLAppCore` (clipboard) | Same as A7.4 |
| A7.5 [android] | Wi-Fi Direct host (X only, on demand): group with an SSID and passphrase drawn at random for every group (0.4.6), `LEGACY_OR_R2` on API 36, started/stopped on request over the control lane, STA kept; `NEARBY_WIFI_DEVICES` (13+), `ACCESS_FINE_LOCATION` + location services (10–12); Wi-Fi off → report, never toggle | Format and charset vectors of S7.1d (*changed 2026-10-28: there is no derivation*); lifecycle tests with a fake `WifiP2pManager` (start, stop, crash, STA unchanged, stop after `DIRECT_WIFI_MAX`) | `android/feature/connection` (or a new `feature/directlink`) | AC4 verified on the S25; AC3 in X measured |
| M7.5 [macOS] | Wi-Fi Direct join (X only): entry/exit rules of AC4 (on demand, idle ≥ `DIRECT_WIFI_IDLE_MIN`, no known network visible, periodic scan, `DIRECT_WIFI_MAX`), CoreWLAN join, gateway connect with the pinned certificate, socket bound to the P2P interface, saved network removed after leaving | Red first: never join while associated, never join when a known network is visible (deauth case), leave on known network, leave at max duration, saved network removed | `apple/Packages/HLTransport`, `apple/macOS/HandLive` | AC4 verified incl. the deauth scenario; AC3 in X ≤ 2 s |
| A7.6 [android] | **Dropped 2026-10-28 (SP5; Phase 4 stopped, no HFP).** Was: automatic classic bonding, **started right after QR pairing** (and once for existing pairs when the feature ships, or whenever the bond is missing) <!-- Updated: Validation Session 1 - bonding trigger -->, flow from G7 ((b) or (c)): bonding request over E2E, `createBond` to the Mac address received over E2E, pairing value sent over E2E when readable | Fake-adapter tests per state; never bond without an authenticated session; no discoverable request | `android/feature/call` or `android/feature/connection` | AC5, AC10 measured; refusal and timeout covered |
| M7.6 [macOS] | **Dropped 2026-10-28 (SP5; Phase 4 stopped, no HFP).** Was: automatic classic bonding: `IOBluetoothDevicePair`; auto-confirm only when the value matches the E2E value, otherwise show the code for one comparison; hand the bonded device to the HFP stack | Confirm/reject decision tests with a fake delegate (match, mismatch, missing value) | `apple/Packages/…` (call audio), `apple/macOS/HandLive` | AC5, AC10; mismatch or missing value never auto-confirmed |
| A7.7a [android] | *(Split 2026-10-28, lead decision; was A7.7.)* Bluetooth prompts, SP1 (owner of AC7 on Android, Bluetooth part): SET-01 prompt for Nearby devices (12+) with its primer; Bluetooth-off request (`ACTION_REQUEST_ENABLE`) only when no LAN path exists, at most once a day | Prompt-count tests per API level (31, 33, 37) | `android/app`, `android/feature/connection` | AC7 (Bluetooth) per API level |
| A7.7b [android] | Location prompts, SP4 (Wi-Fi Direct): Location + location services (10–12) with their primer | Prompt-count tests per API level (29, 31, 33, 37) | `android/app`, `android/feature/connection` | AC7 per API level |
| M7.7a [macOS] | *(Split 2026-10-28, lead decision; was M7.7.)* Bluetooth prompts, SP1 (owner of AC7 on the Mac, Bluetooth part): Bluetooth primer (SET-03), `NSBluetoothAlwaysUsageDescription`; Bluetooth-off status line with a button to Bluetooth settings, same rule as A7.7a | Prompt-sequence tests (Bluetooth) | `apple/macOS/HandLive` | AC7 (Bluetooth) on the Mac |
| M7.7b [macOS] | Location prompts, SP4: Location primer (SET-03), Location usage text, entitlement `com.apple.security.personal-information.location`, release signing step | Prompt-sequence tests; release-build entitlement check | `apple/macOS/HandLive`, `apple/macOS/HandLive.entitlements`, `docs/deployment-guide.md` (via D) | AC7 on the Mac; Location works in the notarized build |
| T7.1 [test] | End-to-end matrix: X and Y (near each other) with S25 + Mac, same LAN; screen off, sleep/wake, Bluetooth off, phone Wi-Fi off, Location denied; **adversarial:** cloned advertiser, BLE sniff (AC9), replayed hello, forged pre-auth errors (AC8), pairing-slot hogging, deauth of the Mac's Wi-Fi (AC4); first and next image timing in X; a 10 MiB image over Bluetooth only with AC1 held; Bluetooth off on each side; Android 10–12 prompt count; en and vi; TalkBack/VoiceOver. *Dropped 2026-10-28:* far apart, relay down, bonding MITM (AC10) | `shared/tools/e2e` scenarios through the debug shim of A7.1, written first | `shared/tools/e2e/`, `reports/phase-07-T7.1.md` | AC1–AC4 and AC6–AC9 met; Wi-Fi association recorded from the app's debug log before/after on both devices |

## Branch and work order

- Branch `feat/phase-07-connect-anywhere` in the hub, handlive-shared, handlive-android, handlive-apple (handlive-relay
  no longer takes part: R7.1 dropped 2026-10-28).
- T7.0 first and alone (from 2026-10-28, no wait on G4/G5/G6). Then D7.1, then each shared card S7.1a–d just before
  the sub-project that uses it (every platform card waits for its spec, vectors, strings). Platform cards are created
  only after the G7 numbers are in.
- Then in sub-project order (*split 2026-10-28, lead decision*):
  1. SP1: S7.1a (T7.0a dropped 2026-10-28); M7.1a right away (pure state machine, needs no vectors); then A7.1a ∥ M7.1b, then
     A7.1b ∥ M7.1c, with A7.7a ∥ M7.7a. On Android, A7.1b and A7.7a both touch `android/app` and
     `feature/connection`: one after the other. S7.1b runs during SP1, so `cpace.json` is reviewed before SP2.
  2. SP2: A7.2a ∥ M7.2a (may start as soon as S7.1b is reviewed), then A7.2 ∥ M7.2.
  3. SP3: S7.1c; A7.3 ∥ M7.3 unless already built, then A7.4 ∥ M7.4.
  4. SP4: S7.1d; A7.5 ∥ M7.5, with A7.7b ∥ M7.7b.
  5. T7.1.
- Each sub-project ends with a measurement on the S25 + Mac before the next one opens: SP1 AC1 (idle and under load),
  AC2, scan response; SP2 AC6.
- *Dropped 2026-10-28:* SP5 (A7.6 ∥ M7.6) and the rule "if RFCOMM needs a bond, SP5 moves before SP1" — an RFCOMM
  bearer that needs a bond now fails G7 (see Bearer above).
- One commit per logical step, `shared/` before the platform, never across repositories.

## Testing

- Tests first (per card, committed red before the code): vectors from S7.1a–d, regression tests for the code a card
  refactors (`serveRelayPeer`, CLIP-03 over `/v1/ctl`, `ConnectionStateMachine`), then the new behavior, then the
  adversarial cases.
- Regression gate after every card: Android `./gradlew check`; Apple `swift test` in the touched packages and
  `xcodebuild test` for the app targets; hub `python3
  tools/docs/validate_design_docs.py` and `tools/docs/check_bilingual_docs.py`; shared `check_schemas.py`,
  `check_strings.py`.
- Real devices: S25 Ultra + this Mac (macOS 27) for X and Y near each other, plus a Mac on macOS 13 or 14 and an Android 10–12 phone
  for the prompt and idle-detection checks; AC timings from `BenchLog` and the bench events of S7.1.

## Risks and rollback

- **G7 fails (no bearer meets AC1) → stop Phase 7, and there is no fallback:** the relay is not deployed (owner
  decision 2026-10-28), so the product stays LAN only and scenarios X and Y keep "no connection". Reported to the owner
  with the G7 numbers.
- **Security:** an attacker in BLE range can try to clone the advertiser, replay hellos, hog pairing slots or forge
  pre-auth errors → covered by the link-security layer, the Bluetooth admission policy and the route-based pre-auth rule
  (AC8, AC9), and tested adversarially in T7.1. (The bond risk behind AC10 is gone with SP5.)
- One UI throttles background BLE → classic page-scan path or a visible "nearby" notification; measured in G7.
- IOBluetooth fragility → bearer behind the `MessageChannel` / `WebSocketSession` seam; BLE fallback.
- macOS prompts on joining or moves back to another network → Wi-Fi Direct stays opportunistic; images fall back to
  Bluetooth; AC3 in X reported as measured.
- *Dropped 2026-10-28:* "relay upload too slow on mobile data" (no relay).
- Each sub-project ships behind a setting (`link.bluetooth`, `link.direct_wifi`, names fixed in D7.1; `link.auto_bond`
  dropped with SP5) so it can be turned off without a release.

## Red Team Review

### Session — 2026-10-01

**Findings:** 15 after deduplication of 18 (15 accepted, 0 rejected) · **Severity:** 2 Critical, 9 High, 4 Medium ·
Reviewers: Security Adversary (fact checker), Assumption Destroyer (scope auditor); evidence re-checked in the code.

| # | Finding | Severity | Disposition | Applied to |
|---|---------|----------|-------------|------------|
| 1 | Forged pre-auth errors over Bluetooth could unpair or stop reconnecting (Mac code exempts only `route == .relay`) | Critical | Accept | D7.1 (route rule), M7.1a, AC8, T7.1 |
| 2 | Scenario X blocked: the Mac leaves `Idle` only with a network and drops every session on network loss | Critical | Accept | D7.1 (0.11), M7.1a |
| 3 | Unbonded BLE exposes identifiers, metadata and the pairing transcript; `pr` is a stable id | High | Accept | D7.1 (link-security layer, `pr` HMAC), AC9 |
| 4 | Pre-auth admission keyed by IP or `device_id` does not work on BLE; hellos replayable | High | Accept | D7.1 (admission), A7.1a |
| 5 | Automatic bonding reverses AUDIO-01; MITM defence relied on an unproven capability | High | Accept (owner: verified auto-confirm only, flow (a) dropped) | G7, D7.1, A7.6, M7.6, AC5, AC10 |
| 6 | Bulk over the relay had no channel split; cap raise needless; stream keys not bound per connection | High | Accept | D7.1 (bulk framing, keys), R7.1 (tests only), A7.4, M7.4, AC3 |
| 7 | In Y the phone never joins the relay while a Bluetooth session exists | High | Accept | D7.1 (bulk demand), A7.4, M7.4 |
| 8 | No stream channel infrastructure exists; chunks before push are dropped | High | Accept | A7.3, M7.3, plan decision I9, A7.4, M7.4 |
| 9 | Control and bulk shared one Bluetooth link without priority; AC1 never measured under load | High | Accept | D7.1 (channel ids, scheduler, control lanes), AC1, A7.1a, M7.1b |
| 10 | RFCOMM needs the phone's address or a bond before SP1/SP2 | High | Accept | G7, work order |
| 11 | "Wi-Fi idle" unreliable without Location; deauth could push the Mac onto Wi-Fi Direct and keep it there | High | Accept | G7, AC4, A7.5, M7.5, M7.7b, T7.1 |
| 12 | Offline pairing over BLE open to slot hogging; PIN blocked only indirectly (2026-10-28: the PIN now runs over Bluetooth through CPace, online guessing only, 3 per PIN plus lockout) | Medium | Accept | D7.1, A7.2, M7.2 |
| 13 | The e2e harness had no way to reach a Bluetooth pipe in the real app | Medium | Accept | A7.1b (debug shim), T7.1 |
| 14 | AC7 broken on Android 10–12 by Wi-Fi Direct's Location need | Medium | Accept (owner: relax AC7 for Android 10–12) | AC7, A7.5, A7.7b |
| 15 | AC1 loosened the LAN target; AC2 unmeasurable for Bluetooth; no security criteria | Medium | Accept | AC1, AC2, AC8–AC10, S7.1a, G7, T7.1 |

*Note 2026-10-28:* findings 5 (bonding) and 6, 7 (bulk over the relay) no longer apply — the cards they changed are
dropped (Validation Session 2). Finding 10 now resolves as "RFCOMM needing a bond fails G7". The table is kept as is.

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
- HFP bonding starts right after QR pairing. *(Superseded 2026-10-28: SP5 dropped, see Session 2.)*

#### Impact on Phases
- AC3, AC4 (stay for further images), AC7 (Bluetooth-off request), A7.4 (10 MiB over Bluetooth), A7.6 (trigger), A7.7,
  M7.7 (Bluetooth-off handling), T7.1 (new scenarios); `plan.md` row 7 and `docs/project-roadmap*` criteria.

### Whole-Plan Consistency Sweep
- Searched all plan files, the roadmap and the brainstorm note for "2 s … offline", "on demand", "bonding", "Bluetooth
  off"; updated `plan.md`/`plan.vi.md` row 7, `docs/project-roadmap*`, the brainstorm notes. Unresolved contradictions:
  none.

### Session 2 — 2026-10-28 (owner decision)
**Trigger:** the owner reported that HandLive is unusable when a device has no network; the lead asked three questions
(team chat, 2026-10-28). **Questions asked:** 3.

#### Questions & Answers (owner's answers verbatim)

1. Which case is the owner facing? — Options: Mac/iPhone fully offline, phone on 4G | Phone offline, Mac online | Both
   on the same Wi-Fi without Internet | Phone on 4G, Mac on another Wi-Fi | Both offline
   - **Answer:** «Cả hai đều không có mạng» (both offline).
2. Which direction? — Options: Short term, deploy the relay + hotspot guidance / gateway candidate | Hotspot only, no
   relay yet | Reopen Phase 7 BLE now, skip the G4/G5/G6 condition | Report only
   - **Answer:** «Mở lại Phase 7 BLE ngay, bỏ qua điều kiện G4/G5/G6» (reopen Phase 7 BLE now, skip the G4/G5/G6
     condition).
3. If the relay is deployed: does the owner have a VPS, an APNs key and a Firebase (FCM) project? — Options: All, will
   send | Not yet, the team writes a preparation guide | No relay deployment
   - **Answer:** «Không deploy relay» (no relay deployment).

#### Confirmed Decisions
- Scenario X (both offline) is the target; Y is covered only while the devices are near each other, over Bluetooth.
- Phase 7 started on 2026-10-28; the 2026-10-01 rule "after G4, G5 and G6" is withdrawn.
- No relay in this phase: R7.1, relay routes, the relay parts of AC1/AC3, A7.4/M7.4 and D7.1 dropped.
- Phase 4 stopped (2026-10-12) → SP5 (A7.6/M7.6), AC5, AC10, G7 bonding and "during an HFP call" dropped; Session 1
  question 4 no longer applies.
- Order: T7.0 → D7.1 → S7.1 → SP1 (with A7.7/M7.7) → SP2 → SP3 → SP4 → T7.1; platform cards created after G7.

#### Impact on Phases
- This file (goal, status, G7, AC1/AC3/AC5/AC8/AC10, routing, D7.1, S7.1, M7.1, R7.1, A7.4, M7.4, A7.6, M7.6, A7.7,
  T7.1, work order, risks); `plan.md`/`plan.vi.md` status, row 7, effort line, gate G7; `docs/project-roadmap*`
  row 7 and Phase 7 section.
- Risk accepted: if G7 fails there is no relay fallback; the product stays LAN only.

### Card split — 2026-10-28 (lead decision, team chat)
- The scheduler (control before bulk) belongs to the control lane (G7 condition 1): moved from A7.4/M7.4 to
  A7.1a/M7.1b. Long control envelopes (up to 256 KiB, about 20 s on the air) get their own long lane in 0.4.5, so they
  never hold back a short one beyond AC1.
- SP1 split into M7.1a → A7.1a ∥ M7.1b → A7.1b ∥ M7.1c; S7.1 split into S7.1a–d, one per sub-project; CPace primitive
  in its own cards A7.2a/M7.2a; A7.7/M7.7 split into the Bluetooth part (SP1) and the Location part (SP4); T7.0a
  (scan-response probe) added before the advertisement vectors are frozen.
- Wi-Fi Direct `ssid`/`passphrase` are random per group (0.4.6): S7.1d and A7.5 check format and charset, no
  derivation vectors.
