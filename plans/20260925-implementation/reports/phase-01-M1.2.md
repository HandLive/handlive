# Phase 1 — M1.2 [macOS]: real networking in HLTransport

Card M1.2 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-apple, branch `feat/phase-01-clipboard`.
The app wiring (menu bar status, settings) is part of M1.1; this card delivers the package.

## What was done

- **Discovery** (`LANDiscovery.swift`): `BonjourDiscovery` runs `NWBrowser` for `_handlive._tcp` with TXT
  records (`v`, `h`, `pr`, `pm`) and reports a local-network denial (`kDNSServiceErr_PolicyDenied`,
  SET-03 E4 / CONN-01 E8). `PathMonitor` wraps `NWPathMonitor` (network up, down, changed).
- **Hints** (`HLCrypto/DiscoveryHint.swift`): `K_disc` = HKDF(`PRK`, `handlive/v1/discovery`), hint = first
  8 hex of HMAC(`K_disc`, `"HLDISC1"` ‖ int64 BE hour); the previous, current and next hour are accepted
  (controller update after hub d1f52c9: 0.4.1, CONN-01 step 3); TXT `h` matched case-insensitively. Tested against
  `shared/test-vectors/discovery-hint.json` (shared 4b2e397, 12cfae3): every `K_disc`, hour message and hint, the
  hint advertised and the three accepted at each clock value, the five match scenarios (phone clock 1 ms and one
  hour behind or ahead) and the six negatives (two hours away, LE/int32 hour, `HLDISC1|` label, HMAC keyed with PRK).
- **Channels** (`MessageChannel`, `WebSocketChannel`, `WebSocketConnector`, `CertificateCheck`): WebSocket over
  Network.framework with TLS 1.3 minimum; the verify block hashes the leaf certificate (DER, SHA-256) and
  compares it with the pin (`/v1/ctl`) or records it (`/v1/pair`, for PAIR-01 step 8). A pin failure is
  reported as `ConnectError.pinMismatch`, apart from other errors. A Bonjour service is resolved to its IPv4
  address with a short TCP connection first, because a WebSocket path can only be given through a URL
  endpoint. Automatic pong replies, 8-byte ping payloads with a pong deadline, close codes 1000/4xxx.
- **Session** (`ControlSession*`, `SessionCipher`, `PendingAck`, `SessionTypes`): `session/hello` →
  `welcome`/`error` → `capability/hello` both ways within `HANDSHAKE_TIMEOUT` (4408 on timeout, 4401 on a bad
  welcome, `session/error` → reaction incl. `min_protocol`); directional keys; requests with a caller-started
  `REQUEST_TIMEOUT` (so a chunked push can count from its last chunk); `DEDUP_WINDOW` with the stored ack
  resent for repeats; unknown requests answered `UNSUPPORTED_TYPE`, unknown events ignored, unknown `type`
  ignored (forward compatibility); `pair/revoke` acknowledged before it is reported; `capability/update`;
  `session/bye`; WebSocket keepalive every 15 s with a 10 s pong deadline plus an immediate probe after a
  network change; rekey after `REKEY_AFTER` as initiator or responder, simultaneous requests resolved by
  the smaller `device_id`, keys switched in receive order, old key kept 30 s, 4410 on failure; 4400 after
  `DECRYPT_FAILED`.
- **Connection manager** (`ConnectionManager*`, `ConnectionTypes`, `SignalQueue`): drives the 0.11 machine —
  `last_host` fast path (its failure is not an error), mDNS candidates with a current hint, pinned TLS and
  handshake, Needs re-pairing when every hint-matching instance fails the pin (no retries until Reconnect
  Now or a new pairing), `RECONNECT_BACKOFF` (reset on success), five minutes after `AUTH_FAILED`, no
  automatic retry after `UNSUPPORTED_VERSION` (update this app / the phone, from `min_protocol`), early
  retry when the network changes or the phone reappears on mDNS, Idle without a network, `session/bye
  {shutdown}` before sleep and an immediate retry on wake, pair removal on `PAIR_UNKNOWN`, 4403 or a revoke
  (then `bye {revoked}`). It publishes `LinkStatus` (state, derived `ConnectionStatus`, next retry, issue) for
  the StatusIndicator, `connected` with host/port/capability for `last_host`/`features_json`, feature
  messages, capability updates and pair removals. The relay (CONN-03) is Phase 2: the discovery grace ends
  in Backoff.
- **Bench hooks** (controller request): `BenchLog` writes `HLBENCH/1` lines (shared/tools/bench/README.md) in
  DEBUG builds only, via `Logger(subsystem: "app.handlive.mac", category: "bench")` with `privacy: .public`:
  `state` on every transition (with `channel` when connected), `net` (up/down/changed) and `wake`.
- Also: `PairRevokeData` (HLProtocol); controller requests handled in this stretch: strings regenerated from
  shared d92eebe (`pairing.phone_not_found`, `clipboard.image_receiving`; `pairing.add_phone` used instead
  of `pairing.pair_phone`), strict Ed25519 verification with the `ed25519.json` and `relay-auth.json` vectors
  (see below).

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 7786521 | feat(apple): derive the hourly mDNS discovery hints |
| e2be090 | feat(apple): open pinned TLS 1.3 WebSocket channels with Network.framework |
| a799747 | feat(apple): run the /v1/ctl session with capability exchange, acks and rekey |
| 34a9351 | test(apple): check the control session against an independent fake phone |
| 4e63c0a | feat(apple): regenerate the strings for the phone-not-found and image-receive texts |
| 60fc6a6 | feat(apple): verify Ed25519 strictly and build the relay authentication messages |
| a567bee | test(apple): run the Ed25519 and relay authentication vectors |
| 73e3107 | feat(apple): browse for the phone with NWBrowser and watch the network path |
| 94af5f8 | feat(apple): write HLBENCH/1 benchmark lines in debug builds |
| 1f52205 | feat(apple): keep the Mac connected with a connection manager |
| a0e3331 | test(apple): drive the connection manager with fake discovery, network and phone |
| 2f6f2c5 | test(apple): run the transport over a real TLS 1.3 WebSocket on loopback |
| f6ecb3f | docs: describe the transport package's connection manager and channels |
| 4ae9a7a | feat(apple): accept the previous, current and next hour's discovery hint |
| 63535cc | test(apple): check the discovery hints against discovery-hint.json |

No change in handlive-shared by this card (the discovery vectors are card S1.3's).

## Files

Created in `apple/Packages/HLTransport/Sources/HLTransport/`: `TransportConstants`, `MessageChannel`,
`WebSocketChannel`, `WebSocketConnector`, `CertificateCheck`, `SessionCipher`, `SessionTypes`, `PendingAck`,
`ControlSession`, `ControlSession+Handshake`, `ControlSession+Receiving`, `ControlSession+Rekey`,
`LANDiscovery`, `BenchLog`, `ConnectionTypes`, `SignalQueue`, `ConnectionManager`, `ConnectionManager+Run`,
`ConnectionManager+Backoff` (`.swift`). Tests: `InMemoryChannel`, `FakePhone`, `SessionTestSupport`,
`ControlSession{Handshake,Messaging,Rekey}Tests`, `ManagerTestSupport`, `ConnectionManager{,Failure}Tests`,
`TLSTestServer`, `WebSocketIntegrationTests`. HLCrypto: `DiscoveryHint`, `RelayAuthMessage`, `Ed25519` (strict),
tests `DiscoveryHintTests`, `SignatureVectorTests`. HLProtocol: `PairMessages.swift`. README, README.vi.

## Tests (real output)

```text
$ cd apple/Packages/HLTransport && HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=…/MacOSX26.sdk swift test   (run 6 times, all green)
✔ Suite "Control session: handshake (0.6.3, CONN-01)" passed
✔ Suite "Control session: envelopes, acks and endings (0.5.1, CONN-02)" passed
✔ Suite "Control session: rekey (0.6.3 step 6, CONN-02 API 3)" passed   (incl. collision, both winners)
✔ Suite "Connection manager (CONN-01, CONN-02, 0.11)" passed
✔ Suite "Connection manager: rejections, losses, sleep (CONN-01 E3–E5, CONN-02)" passed
✔ Suite "WebSocket over TLS 1.3 on loopback" passed
✔ Suite "Connection state machine (0.11)" passed
✔ Test run with 50 tests in 8 suites passed after 0.538 seconds.
HLCrypto   ✔ Test run with 27 tests in 7 suites passed   (discovery hints; ed25519.json, relay-auth.json incl. every invalid vector)
Later, after the three-hour window (63535cc), with the pairing work of M1.3:
HLCrypto    ✔ Test run with 39 tests in 10 suites passed after 6.560 seconds.   (4 discovery-hint.json tests)
HLTransport ✔ Test run with 65 tests in 12 suites passed after 6.695 seconds.
HLProtocol ✔ Test run with 25 tests in 6 suites passed
swiftlint --strict: 0 violations
```

The fake phone implements the server side of 0.6.3 (handshake, rekey) with HLCrypto primitives, so the
session is checked against an independent implementation; the loopback suite runs the real Network.framework
stack with a throwaway RSA identity made by `/usr/bin/openssl` and imported in memory (`kSecImportToMemoryOnly`,
macOS 15+; the suite returns early on macOS 13–14), no keychain touched.

Exceptions: CONN-01 E1/E7 (grace → Backoff), E2 (mismatch → next instance; all → Needs re-pairing), E3, E4,
E5, E6 (4408), E8 (denial reported as an issue) and CONN-02 E1, E2, E4, E5, E7 each have a test; E3 of CONN-02
(iOS background) and E6 (OEM kills the service) are the phone's/iOS's and appear to the Mac as a loss (tested).

## CI

- https://github.com/HandLive/handlive-apple/actions/runs/36161812994 — success; the loopback TLS suite ran on
  the macos-15 runner (50 HLTransport tests).
- https://github.com/HandLive/handlive-apple/actions/runs/36183079256 — success with the three-hour window and the
  discovery vectors (HLCrypto 39, HLTransport 65 tests).

## Spec deviations and proposals

1. **Network.framework instead of `URLSessionWebSocketTask`** (CONN-01 API 3): same TLS delegate idea (pin in
   the verify block), plus TLS 1.3 minimum, close codes and ping/pong control. A Bonjour service is resolved
   to IPv4 with a short TCP connection before the WSS connection, because Network.framework only takes the
   request path from a URL endpoint; the phone sees one extra connection that closes before TLS. Proposal:
   say so in CONN-01 API 2/3.
2. **Fast path failures are silent**: a stale `last_host` (DHCP) or a pin mismatch there is dropped and mDNS
   continues; only mDNS candidates (proved ours by the hint) lead to Backoff or Needs re-pairing.
3. **Early retry**: a matching mDNS instance appearing during Backoff ends the wait (like a network change),
   except after `AUTH_FAILED`. Proposal: add "or the phone reappears on mDNS" to the Backoff → Discovering edge.
4. **Link probe on network change**: a WebSocket ping with a 2 s deadline right after the default network
   changes, so a dead socket is noticed in about 2 s instead of up to 25 s (reconnect < 3 s target).
5. **`UNSUPPORTED_VERSION`**: no automatic retry (Reconnect Now still works); the issue says which side must
   update (`min_protocol` > ours → this app).
6. **Rekey keys switch in receive order**: the initiator installs the new keys while reading the `ack`, before the
   next envelope, which may already use them — the spec's "switch on ack" made exact.
7. **Ed25519 signing is hedged in CryptoKit**: signatures are valid RFC 8032 signatures but not byte-identical to
   `ed25519.json`/`relay-auth.json`; tests check that the vector signatures and fresh ones verify. Proposal: the
   vector README should say determinism is not required of signers.
8. ~~No discovery-hint vector~~ — resolved: `discovery-hint.json` (S1.3) now drives the Apple tests; the values
   the Apple test had hard-coded before match it.
9. The relay is Phase 2: `relayAvailable = false`, so the grace always ends in Backoff (0.11's
   "relay.enabled = false" edge).

## Pending manual checks

- Real phone on the same Wi-Fi: discovery < 2 s, reconnect < 3 s after a Wi-Fi change (R1–R4 of
  shared/tools/bench, reading the `HLBENCH/1` lines), bye on lid close, reconnect on wake.
- Local network prompt on macOS 15+ and the denied path (System Settings › Privacy & Security › Local Network).
- Android A-SVC interop: close codes 4409/4410/4411/4429 and a rekey after 10 000 envelopes against Ktor.

Status: DONE
Summary: HLTransport now discovers the phone by hourly hint, connects over pinned TLS 1.3 WebSockets, runs the
/v1/ctl session (handshake, capability, acks, dedup, rekey, keepalive) and keeps the link up with a connection
manager that implements the 0.11 machine, backoff and sleep/network handling; 50 tests incl. a loopback TLS suite
pass locally and on CI.
Concerns/Blockers: none in code; all interop and latency checks need a real phone.
