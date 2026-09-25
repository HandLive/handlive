# Phase 1 — M1.3 [macOS]: pairing (PAIR-01) on the Mac

Card M1.3 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-apple, branch `feat/phase-01-clipboard`.
Includes the controller updates on pairing: the shared vectors `pair-handshake.json` (card S1.3) and the byte-exact
rules now in the spec (labels without spaces, 16-byte `pair_id`, int64 BE `created_at`, raw 64-byte `sig`, no
Unicode normalization, RFC 3986 percent-encoding of `d`, `K_pin` over the UTF-8 digits with Argon2id v0x13).

## What was done

- **Crypto** (`HLCrypto`):
  - `Blake2b` (RFC 7693) and `Argon2id` v0x13 (RFC 9106; lanes filled one after the other, memory wiped afterwards):
    CryptoKit has neither. `K_pin` with the 0.6.2 parameters (t 3, 64 MiB, p 4) takes about 0.1 s in a release
    build and 7 s in a debug test build.
  - `PairingAuthDerivation`: `K_pa`, `K_pin`, `T_offer`, offer/confirm/done MACs, `prk_check` of both sides,
    attestation, TXT `pr`; byte forms identical to the Android `PairingAuthDerivation` (its fixed expected values
    are reproduced).
  - `PairingCodes`: 256-bit `pairing_secret`, a uniform 6-digit PIN (rejection sampling), `nonce_c`.
  - `HMACSHA256.constantTimeEquals` for every MAC and `prk_check` comparison.
- **Messages** (`HLProtocol/PairMessages.swift`): `pair/hello|offer|confirm|done|error` with the wire names;
  `attempts_left` only with `PIN_INVALID`.
- **Exchange** (`HLTransport`):
  - `PairingExchange`: `pair/hello` → offer checks in the API 3 order (MAC → `device_id` from `ik_sig_pub` → TLS
    certificate of this connection) → `PRK` → `pair/confirm` (UUIDv4 `pair_id`, attestation signed with `ik_sig`)
    → done checks (MAC → `prk_check` → strict Ed25519) → close 1000.
  - A failed check sends `pair/error` (`AUTH_FAILED`, or `PIN_INVALID` with the attempts left) and closes; the
    check that failed is recorded for tests only, never on the wire. Nothing is stored by the exchange.
  - `PairingSearch`: browses for the phone's window (TXT `pr` = SHA-256 of `pk` for a QR code, `pm = 1` for a PIN),
    opens `/v1/pair` with `CertificatePolicy.recordAny`, retries dropped connections and `PAIRING_CLOSED` every
    second while the window is visible, reports `waitingForPhone` / `connecting` / `verifying`,
    `localNetworkDenied` and E3 (`phoneUnreachable`: the window visible for 20 s but no connection works).
  - `PairingInvite`: the QR URI with the device name fitted to ≤ 64 code points and ≤ 300 URI characters (whole
    characters removed), everything outside the RFC 3986 unreserved set percent-encoded; the same fitted name goes
    into `pair/hello`, so `d`, the hello and `T_offer` agree.
- **Mac UI** (`HLMacUI`, `HLDesignSystem`):
  - `PairingQRCode` (design system): `qr-ink` on `qr-paper` in every appearance, `size-qr`, `radius-card`, level M,
    modules drawn at a whole number of points without smoothing.
  - `PairingController`: a code lives 120 s and is replaced without an error ("Code changes in 1:42"); a scanned QR
    code that is being verified finishes first; "Can't Scan? Use a PIN" switches to a PIN ("482 915",
    `code-pin`); a wrong PIN keeps the PIN until the third wrong attempt, then a new PIN (E7); `AUTH_FAILED` shows
    "Pairing isn't secure — try again" in the sheet with a new code (E4); E3 and the local network guide ("Open
    System Settings") in the sheet; "Pairing…" while a QR code is verified.
  - `AppModel.completePairing`: `PRK` into the Keychain (account `pair_id`), then the record, then success
    (API 5 logic 2); the connection manager connects at once (step 12 → CONN-01) and clipboard polling starts.
  - `PairingSheet` over the welcome window (step 7 of SET-03: the sheet opens by itself; after Cancel the page
    offers "Add Phone…" again; on success the Paired step with the Security Code) and over Settings › Devices (on
    success a "Paired with <name>" line for a few seconds). Esc cancels the sheet (Cancel is the cancel action);
    the welcome pages have their prominent button as the default action (Return).
  - Security Code (PAIR-02 field 10): the first 8 lowercase hex characters of SHA-256(`attestation`), as on Android
    and in the vectors, on the Paired step and in the device details.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 5d6b7e8 | feat(apple): add BLAKE2b and Argon2id for the PIN pairing key |
| f681de9 | test(apple): check BLAKE2b and Argon2id against RFC 7693, RFC 9106 and the Android K_pin |
| 5d1b613 | feat(apple): derive the pairing MACs, prk_check and attestation |
| 874a0fc | test(apple): match the pairing derivations with the Android expected values |
| 5e5b939 | feat(apple): add the pair/hello, offer, confirm, done and error messages |
| 1b9604c | test(apple): decode the PAIR-01 payload examples and check the wire names |
| d843736 | feat(apple): compare MACs in constant time |
| 678563b | test(apple): check the constant-time comparison |
| f5dd015 | feat(apple): run the client side of the pairing exchange |
| 3ac6627 | feat(apple): build the pairing QR URI with a fitted device name |
| ac65f0b | feat(apple): find the phone's pairing window on the LAN |
| 199aca0 | test(apple): pair against a phone written from the PAIR-01 spec |
| cbf75aa | test(apple): test finding the pairing window, retries and E3 |
| 0d41caf | feat(apple): let the pairing screen depend on a pairing search protocol |
| 099dedd | feat(apple): draw the pairing QR code in qr-ink on qr-paper |
| 78c4a4f | test(apple): decode the rendered pairing QR code and check its colors |
| bac4b0a | feat(apple): store a new pair and present this Mac for pairing |
| eab8627 | feat(apple): drive the pairing sheet: codes, countdown, PIN attempts and errors |
| 8f69737 | feat(apple): show the pairing sheet over the welcome window and Settings |
| 65fb298 | test(apple): test the pairing controller with a scripted search |
| 17deb9e | feat(apple): name the pairing check that refused a message |
| e176b4b | test(apple): run the client pairing against pair-handshake.json |
| 927fb6b | test(apple): wait for the pairing search's progress instead of sleeping |
| 430ddac | feat(apple): tell missing keys from a pairing that did not finish |
| a21bd0e | fix(apple): show the Security Code as 8 lowercase hex characters |
| 7f8aa97 | feat(apple): show the Security Code on the paired step |

The device row, Details… with the Security Code and Unpair… with its alert (the rest of this card) were built with
the Settings panes of M1.1 (b977026, 69a5ece; see that report).

handlive-shared: 0f0c997 `feat(shared): add the Mac setup guidance, keychain error and PIN instruction strings`
(adds `pairing.pin_instructions` and the Mac setup texts; strings regenerated in handlive-apple 1211961).

## Files

- HLCrypto: `Blake2b`, `Argon2id`, `Argon2SegmentFiller`, `PairingAuthDerivation`, `PairingCodes`, `CryptoError`
  (`fieldTooLong`), `HMACSHA256` (`constantTimeEquals`); tests `Argon2idTests`, `PairingAuthDerivationTests`.
- HLProtocol: `PairMessages`; test `PairMessagesTests`.
- HLTransport: `PairingTypes`, `PairingExchange`, `PairingLink`, `AcceptedOffer`, `PairingInvite`, `PairingSearch`;
  tests `FakePairingPhone` (Android's side written from the spec), `PairingExchangeTests`, `PairingSearchTests`,
  `PairingVectorTests`, `PairingVectorExchangeTests`.
- HLDesignSystem: `Components/PairingQRCode`; test `PairingQRCodeTests` (CIDetector decodes the rendered code back
  to the URI; only the two token colors).
- HLMacUI: `PairingController`, `PairingView` (`PairingSheet`, `PairingCardView`), `AppModel+Pairing`
  (`pairingIdentity`, `completePairing`), `OnboardingView` (`PairingStep`), `DevicesSettingsPane`, `MacSystem`
  (`MacHardware.modelIdentifier`); test `PairingControllerTests`.

## Tests (real output)

```text
$ cd apple/Packages/<Pkg> && HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk swift test
HLCrypto       ✔ Test run with 39 tests in 10 suites passed after 6.560 seconds.
HLProtocol     ✔ Test run with 33 tests in 8 suites passed after 0.016 seconds.
HLTransport    ✔ Test run with 65 tests in 12 suites passed after 6.695 seconds.
HLDesignSystem ✔ Test run with 23 tests in 6 suites passed after 0.126 seconds.
HLMacUI        ✔ Test run with 17 tests in 4 suites passed
swiftlint lint --strict: Done linting! Found 0 violations, 0 serious in 188 files.
```

What the pairing tests cover:

- `pair-handshake.json` (all 3 vectors): identities, QR URI (`&` → `%26`, `rv`) and `pr`, `K_pa`, `T_offer` (NFD
  phone name kept as sent), offer/confirm/done MACs, attestation, Security Code, `PRK` and both `prk_check`.
  `K_pin` of the PIN vector with the real parameters (and ≠ the `p = 1` and `"42917"` values).
- The client exchange replays each vector's `offer_envelope` and `done_envelope`: the hello it sends equals
  `hello_plaintext`; its confirm has the vector's `pair_id`, `created_at` and `prk_check`, a signature that
  verifies over the vector's attestation and a MAC over exactly that signature; the result stores the vector's
  `PRK`, attestation, `sig_s`, TLS pin and names; the client closes with 1000.
- All 13 negatives with `checked_by` `client` or `both` fail at their `check` (`offer_mac` incl. the MITM
  `tls_sha256` and the wrong PIN — whose `pair/error` reply equals `client_reply_plaintext` with
  `attempts_left` 2 — `done_mac`, `prk_check_s`, `sig_s`, `k_pin`, `pr`).
- Exchange against `FakePairingPhone`: QR and PIN pairing, E4 for a wrong offer MAC, wrong `device_id`, a TLS
  certificate that differs from `tls_sha256`, a wrong done signature / `prk_check` / MAC, `PAIRING_CLOSED`, a
  silent phone (offer timeout), E7 attempts 3 → 2 → 0.
- `PairingSearch`: only the instance whose `pr` matches; `pm = 1` for a PIN; `PAIRING_CLOSED` and dropped
  connections retried; wrong PIN and `AUTH_FAILED` returned to the caller; local network denied; E3 after the
  grace period.
- `PairingController`: QR code with this Mac's key and the search's secret, countdown "2:00"; PIN attempts and E7;
  E4 notice with a new code, E3 and local network notices; the pair stored (record + `PRK`) before success; a code
  replaced at 0:00 without an error, but not while a scanned QR code is verified; keys missing.

Exceptions of PAIR-01 on the Mac: E3 (tested, see deviation 2), E4 (tested at every check), E7 (tested). E1, E2,
E5, E6, E9 happen on the phone; for the Mac they look like a window that never opens or closes (`PAIRING_CLOSED`,
tested as retried). E8 is the relay (Phase 2).

## CI

- https://github.com/HandLive/handlive-apple/actions/runs/36183079256 — success on 0039d94: xcodebuild test of all
  7 packages (HLProtocol 33, HLCrypto 39, HLTransport 65, HLDesignSystem 23, HLLocalization 9, HLAppCore 35,
  HLMacUI 17 tests), `swiftlint --strict` 0 violations, app build succeeded.
- https://github.com/HandLive/handlive-apple/actions/runs/36185259682 — success on 7f8aa97 (Security Code fixes):
  same packages, HLAppCore 40 tests.
- Earlier run 36174772107 failed on a timing assumption in `PairingSearchTests` (a 50 ms sleep before reading the
  local-network-denied progress); fixed in 927fb6b by polling, green since.

## Spec deviations and proposals

1. **`sig_c` is not byte-identical to the vector.** CryptoKit signs Ed25519 with added randomness (hedged
   signatures, documented by Apple), so the Mac cannot reproduce `sig_c`; everything else is byte-identical. The
   tests verify `sig_c` and `sig_s` strictly and check that the Mac's own signature verifies over the vector's
   attestation and that the confirm MAC covers exactly that signature. The protocol never needs determinism (Android
   and the relay verify). Proposal: `shared/test-vectors/README.md` should require "a valid strict signature over
   the attestation", not identical bytes, for signers. Writing an RFC 8032 signer by hand only for the vectors would
   add risk without a protocol benefit.
2. **E3 without a relay.** The Mac cannot know that the phone scanned the code until it sees TXT `pr`. So E3 ("Couldn't
   find the phone…") shows when the phone's window has been visible for 20 s without a working connection, or when
   the Mac has no local network access (the guide). A phone on another network never appears; the code then refreshes
   every 120 s with no error, as the design system asks. Proposal: define E3 for LAN-only pairing this way in PAIR-01
   step 7.
3. **PIN mode timing.** The Mac connects as soon as a `pm = 1` window appears and sends `pair/hello`; the phone answers
   once the user typed the PIN, so the offer timeout is the PIN's lifetime. After `PIN_INVALID` the Mac connects again
   for the next attempt. At 0:00 a PIN is replaced even while the phone waits for it; a QR code already being
   verified finishes first.
4. **One fitted name.** The name in `d`, in `pair/hello` and in `T_offer` is the same string, fitted to 64 code points
   and a 300-character URI.
5. **"Add Phone…" while paired** is dimmed (app menu), and the menu bar and Settings show it only without a pair
   (PAIR-01 step 1: unpair first, from Settings › Devices).
6. **Texts.** A pair that could not be stored shows `error.pairing_failed` ("Pairing didn't finish. Try again.",
   added to the catalog by the Android agent); missing keys show `setup.keys_failed`.
7. **Android observation (not changed by me).** `PairingWindow.release()` runs only for PIN windows, so after a Mac
   drops its connection mid-exchange a QR window stays claimed and answers `PAIRING_CLOSED` until it expires; the Mac
   keeps retrying every second meanwhile. Proposal for Android: release the claim on `DISCONNECTED` for QR windows
   too (the coordinator already returns to `Waiting` in that case).
8. **After E4 the Mac makes a new QR code** (the phone has to scan again); the old secret is dropped.

## Pending manual checks

- Real phone: scan the QR code (contrast in light and dark), confirm, "Paired with <name>" on both devices within 5 s,
  the same Security Code on both (PAIR-02 field 10), CONN-01 right after.
- PIN flow with a wrong PIN once and three times (new PIN), and a PIN that expires while the phone waits.
- Local network prompt and the denied guide on macOS 15+; E3 with the phone on a guest Wi-Fi (client isolation).
- VoiceOver reads the title, instructions, the PIN digit by digit and the countdown.

Status: DONE_WITH_CONCERNS
Summary: The Mac pairs by QR code or PIN: Argon2id, every PAIR-01 derivation and check, the /v1/pair exchange,
discovery of the phone's window and the pairing sheet over the welcome window and Settings; all of
pair-handshake.json passes except that CryptoKit's randomized Ed25519 signature cannot equal `sig_c` byte for byte.
Concerns/Blockers: the byte-identical `sig_c` requirement of the vectors (deviation 1) needs a decision; real-device
pairing with the Android app is untested.
