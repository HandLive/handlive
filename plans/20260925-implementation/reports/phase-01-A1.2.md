# Phase 1 — A1.2 [android]: Pairing (PAIR-01 LAN, PAIR-02, PAIR-03 flow A)

Card A1.2 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-android, branch `feat/phase-01-clipboard`, pushed; CI green. The pairing *screens* (scanner screen, confirmation, PIN entry, Devices tab and details) were built in A1.4 on top of the state machine below (commits 5f0f191, 07430de; see `phase-01-A1.4.md`).

## What was done

- **Crypto** (`core/crypto`): `PairingAuthDerivation` — `K_pa`, `T_offer` (raw bytes, `str(x)` = uint16 BE length ‖ UTF-8), offer/confirm/done MACs, both `prk_check`s, the `HLPAIR1` attestation, `K_pin`. `K_pin` = Argon2id (t=3, m=64 MiB, p=4, L=32): Tink and Android have no Argon2, so `core/crypto` now has BLAKE2b (RFC 7693) and Argon2id v0x13 (RFC 9106), written after the reference `fill_segment`. ~0.35 s on the JVM for the spec parameters.
- **Protocol** (`core/protocol`): `pair/hello|offer|confirm|done|error|revoke` models; `UnencryptedEnvelopes` (handshake payloads, 0.5.1 exception 1) shared by session and pair.
- **QR code** (`PairingInvite`, PAIR-01 API 1): `handlive://pair?v=1&pk&ps&d[&rv]`; unknown parameters ignored; wrong scheme/host/`v`, missing or wrong-length `pk`/`ps`/`rv`, name > 64 → invalid (E1). TXT `pr` = 8 hex of SHA-256 over the 32 bytes of `pk`.
- **Exchange** (`PairingExchange`, API 2–6, Android as S): hello checks in API order (window open and of the right mode → `PAIRING_CLOSED`; key equal to the scanned `pk`, `device_id` = UUIDv8(SHA-256(`ik_sig_pub`)), known platform, name ≤ 64 → `AUTH_FAILED`; one client per window); offer with `tls_sha256` under the MAC; confirm checks MAC (constant time) → `PRK` → `prk_check_c` → client Ed25519 signature over the rebuilt attestation; only then the pair is stored (sealed `PRK`, attestation, both signatures) and `pair/done` sent. Any failure answers `pair/error` without saying which check failed and stores nothing. PIN windows wait for the typed PIN (the Mac's connection stays open), derive `K_pin` off the main thread, and reopen after the client reports `PIN_INVALID {attempts_left}`.
- **Coordinator** (`PairingCoordinator`, the phone's PAIR-01 state machine): `Idle → Confirm("Pair with <name>?") → Waiting → Verifying → Paired(name, Security Code) | Failed(reason)`, plus `EnterPin(attemptsLeft)`; E1 (invalid code), E6 (8 pairs, checked at scan and before a PIN window), E5 (cancel drops the secret and the window), E2 (window expiry after 120 s), E9 (camera denied → PIN offered); TXT `pr`/`pm=1` only while a window is open; outside a window `/v1/pair` answers `pair/error PAIRING_CLOSED`.
- **Devices (PAIR-02)** `DeviceListModel`: stored pairs joined with live sessions and their capability (link Wi-Fi/Internet/USB/disconnected, last seen, peer app version, clipboard availability with its reason, Security Code); updates on session, capability or setting changes without polling.
- **Unpair (PAIR-03 flow A)** `UnpairController`: initiator sends `pair/revoke {pair_id, reason: user}`, waits 10 s for the `ack`, then wipes the `PRK` and closes with `session/bye {revoked}` → `DONE`; no session or no `ack` → cleans up alone → `DONE_PENDING_REMOTE` (the Mac cleans up on its next `PAIR_UNKNOWN`). Receiver: `ack` first, then cleanup, `bye revoked`, and the notice "<name> unpaired this device"; a `pair_id` of another pair → `BAD_REQUEST`; `session/bye {revoked}` alone also cleans up (API 2).
- **Scanner** (I8: no ML Kit/Play Services): `QrScanner` composable (CameraX preview + four-corner viewfinder with the dark layer of PairingCard) and `QrImageAnalyzer`/`QrCodeDecoder` on ZXing core (Y plane with row stride, inverted codes too).
- `PairingFeature.install` plugs the coordinator into `/v1/pair`, the revoke handler into the router and the bye listener into the runtime.

## Commits (handlive-android)

| Hash | Subject |
|------|---------|
| 18bad92 | feat(android): derive the pairing keys, MACs and attestation |
| be0cea3 | test(android): check Argon2id and the pairing derivations |
| aa16e8e | feat(android): add pair message models and an unencrypted envelope builder |
| 1487dfb | feat(android): expose the peer's bye reason on control sessions |
| 226295b | feat(android): report ended sessions with the peer's bye reason |
| 6b8b7b1 | feat(android): pair a Mac or iPhone over the LAN with a QR code or a PIN |
| bb91171 | feat(android): list paired devices and unpair them (flow A) |
| a3a77fe | feat(android): scan pairing codes with CameraX and ZXing core |
| f22d1be | feat(android): wire the pairing feature into the connection runtime |
| 477aabd | test(android): cover pairing, unpairing and scanning against a spec client |

## Files

Created: `core/crypto/.../primitives/{Blake2b,Argon2id}.kt`, `derivation/PairingAuthDerivation.kt`, tests `Argon2idTest`, `PairingAuthDerivationTest`; `core/protocol/.../pairing/PairMessages.kt`, `envelope/UnencryptedEnvelopes.kt`; `feature/pairing/**` (`invite/PairingInvite`, `exchange/{PairingWindow,PairingExchange,PairingWire,PairingCoordinator}`, `devices/DeviceListModel`, `revoke/UnpairController`, `scan/{QrCodeDecoder,QrImageAnalyzer,QrScanner}`, `PairingFeature`, manifest with `CAMERA` and optional camera feature, tests with `testing/PairingTestKit.kt`).
Changed: `core/transport/.../handshake/HandshakeEnvelopes.kt`, `settings.gradle.kts`, `gradle/libs.versions.toml` (CameraX 1.6.2, ZXing 3.5.4, lifecycle-runtime-compose), `app` (dependency, `PairingFeature.install`).

## Tests (real output)

```text
$ ./gradlew :feature:pairing:check
BUILD SUCCESSFUL in 16s
PairingExchangeTest tests=11      (QR and PIN pairing against an independent client: same PRK and Security Code on
                                   both sides, row stored; wrong PIN → PIN_INVALID with attempts left and the window
                                   reopens; E2 expired window, PIN hello on a QR window, second client →
                                   PAIRING_CLOSED; E4 other key, device_id not derived from the key, tampered confirm
                                   MAC, wrong prk_check, bad signature → AUTH_FAILED and nothing stored)
PairingCoordinatorTest tests=8    (E1, E2 after exactly 120 s, E5, E6 at scan and PIN, E9, pr/pm adverts, closed
                                   window → PAIRING_CLOSED)
UnpairControllerTest tests=6      (flow A with ack → DONE; no session / no ack in 10 s → DONE_PENDING_REMOTE;
                                   receiver acks first then cleans up and notifies; wrong pair_id → BAD_REQUEST;
                                   bye revoked fallback)
DeviceListModelTest tests=3, PairingInviteTest tests=3, QrCodeDecoderTest tests=3
$ ./gradlew :core:crypto:testDebugUnitTest --tests '*Argon2idTest' --tests '*PairingAuthDerivationTest'
pinKeyWithTheSpecParametersMatchesOpenSsl 0.332 s; argon2idMatchesRfc9106Vector; blake2b512OfAbcMatchesRfc7693;
offer/confirm/done/prk_check/attestation match values computed independently in Python
```

Independent values (Python `hmac`/`hashlib`/`cryptography` 50 on OpenSSL 3): with nonce_c = 00…1f, nonce_s = 20…3f, keys filled with 0x11/0x22/0x33/0x44, tls 0x55…, secret 0x66…, names "MacBook của Lan"/"Pixel của Lan": `T_offer` 302 bytes, SHA-256 `e8671206…1caa0`, `K_pa` `681841cf…1e03f`, offer MAC `c8523197…16eb3`; `K_pin`("042917") `a3c171d4…8bc88`; Security Code of the sample attestation `fc647e0b`.

## Spec deviations and proposals

1. **Label bytes.** PAIR-01 API 4–5 show `"HL1 | confirm | "`, `"HL1 | prk-check-c | "` with spaces around `|` inside table cells. As with the envelope AAD of 0.5.1 (where the shared vectors fix `"<v>|<type>|<id>|<ts>"` without spaces), this is Markdown escaping: Android uses `"HL1|confirm|"`, `"HL1|done|"`, `"HL1|prk-check-c|"`, `"HL1|prk-check-s|"`. `confirm` MAC input: `pair_id` as 16 bytes, `created_at` int64 BE, `sig` 64 raw bytes. **Proposal (important for G1):** add a `pair-handshake.json` vector (T_offer, K_pa, K_pin, MACs, prk_check, attestation) to shared so Apple and Android cannot diverge; the values above can seed it.
2. **`pr` input.** "SHA-256(`pk` in the QR)" is taken over the 32 decoded bytes, not the b64u text. Proposal: say "32 bytes of `pk`".
3. **Security Code at scan time.** PairingCard shows the device name and the Security Code "once the code is scanned", but the code depends on `pair_id`/`created_at` chosen in `pair/confirm`, so it exists only after pairing; the phone shows it on the result and in the device details.
4. **Malformed `pair/hello`** closes 4400 without `pair/error` (the error enum has no `BAD_REQUEST`), like `session/hello`.
5. **PIN retry timing.** After `PIN_INVALID` the phone keeps the window (and its 120 s deadline) and waits for a new PIN; a Mac that reconnects before the user types it waits on the open connection. Proposal: state the Mac-side offer timeout (the phone waits up to the window end).
6. Argon2id lanes run sequentially (deterministic, 0.35 s on a laptop JVM, expected 1–3 s on phones); PIN is the fallback path.

## Pending manual checks

- Pair with the real Mac (M1.3) by QR and by PIN on a Pixel and a Samsung: same Security Code on both screens, ≤ 5 s from scan to "Paired with …" on the LAN, wrong PIN three times → the Mac shows a new PIN.
- Scanner on real cameras (Dark appearance of the Mac, glare, small codes), CONFIRM haptic; camera permission denied → PIN.
- Unpair from each side with and without a connection.

```text
Status: DONE_WITH_CONCERNS
Summary: PAIR-01 (QR and PIN on the LAN), PAIR-02 data and PAIR-03 flow A are implemented and tested against an independent client written from the spec, with Argon2id and the pairing derivations checked against RFC and independent values; CameraX + ZXing scanning without ML Kit.
Concerns/Blockers: no shared pairing vector yet (interop with the Mac unproven until M1.3); the label spacing reading must match Apple.
```
