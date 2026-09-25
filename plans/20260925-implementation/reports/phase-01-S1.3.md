# Phase 1 — S1.3 [shared]: pairing and discovery test vectors

Card (new): cross-platform test vectors for PAIR-01/PAIR-02 and the 0.4.1 mDNS discovery hints, so the Android and
Apple implementations cannot diverge before gate G1; Android consumer tests against every positive and negative vector.

## What was done

- **`shared/test-vectors/pair-handshake.json`** (new, generated): the whole PAIR-01 exchange, QR and PIN, 3 vectors +
  27 negative vectors.
  - `QR cặp 1` and `QR cặp 2` are pairs 1 and 2 of `pair-prk.json` exactly (same RFC 8032 / RFC 7748 keys,
    `pairing_secret`, `pair_id`), so their `prk` equals the existing `pair-prk.json` value (chain checked). The client
    `device_id` is the smaller in one and the larger in the other.
  - `PIN cặp 3` reuses the keys of pair 1 with a new UUIDv4 `pair_id`, PIN `042917` (leading zero on purpose) and `K_pin`
    in place of `pairing_secret`.
  - `QR cặp 2` has `rv`, a client name with `&` (must be `%26` in the QR) and an **NFD** phone name, which pins "no
    Unicode normalization in `str()`".
  - Every vector carries: QR URI fields and `pr`, `K_pin` with its Argon2id parameters, `K_pa`, `T_offer` (+ parts),
    `offer_mac`, the attestation (+ parts), `sig_c`/`sig_s`, the Security Code (PAIR-02 field 10), the confirm and done
    MAC inputs (+ parts: `pair_id` 16 bytes, `created_at` int64 BE, `sig` 64 raw bytes) and MACs, `PRK` with its salt,
    both `prk_check`, the four `pair/*` plaintexts and envelopes, and the API 8 `POST /v1/pairs` body.
  - Negative vectors name the **first check that must fail in the receiver's spec order** (`check`), who runs it
    (`checked_by`), the `pair/error` code (`expected_error`), the `reason` and the evidence of the mistake:
    - Spaced labels `"HL1 | offer | "` (offer, confirm, done) and the other side's `prk-check` label.
    - Wrong byte order: little-endian `str()` lengths, `created_at` LE in the confirm MAC and in the signed
      attestation, `K_pa` salt `nonce_s ‖ nonce_c`, `PRK` salt larger ‖ smaller.
    - Wrong encoding: `sig` as b64u text and `pair_id` as 36-char text in the confirm MAC, `pr` over the b64u text of
      `pk`, the PIN turned into an integer (`"42917"`).
    - Wrong field order: attestation signed with the client's fields first.
    - Flipped MAC / `prk_check` / signature (for signatures the MAC is recomputed so only the signature check fails).
    - S + L (non-canonical signature).
    - `tls_sha256` replaced in transit (MITM).
    - Wrong PIN typed on the phone, with the client's `PIN_INVALID` reply (`attempts_left` 2).
    - `K_pin` with p = 1 (what libsodium's `crypto_pwhash` would give).
    - `ik_dh_pub` ≠ scanned `pk`, and `device_id` not derived from `ik_sig_pub`.
- **`shared/test-vectors/discovery-hint.json`** (new, generated) from the `prk` of `pair-prk.json` pairs 1 and 2:
  - `key` vectors: `K_disc`, the hint of hours −1, 0, 1, 479762–479764, and per clock value (0, 3 599 999, 3 600 000,
    1 727 150 000 123, 1 727 150 399 999, 1 727 150 400 000) the hour, the advertised hint and the accepted
    `[current, previous]`.
  - `match` vectors: TXT `h` with both pairs; one matches the current hour, one the previous hour (phone behind across
    the boundary).
  - 6 negatives a client must not match: phone clock ahead across the boundary or two hours behind
    (`hint_outside_window`), hour int64 LE, hour int32 BE, label `"HLDISC1|"`, HMAC keyed with `PRK`.
  - The generated values equal the ones the Android (`DiscoveryHintsTest`) and Apple (`DiscoveryHintTests`) agents had
    computed independently and hard-coded earlier.
- **Generator** (`cryptography` only, OpenSSL Argon2id): `pairing_discovery_derivations.py`,
  `pair_handshake_messages.py`, `build_pair_handshake_vectors.py`, `build_pair_handshake_negative_vectors.py`,
  `build_discovery_hint_vectors.py`. `build_identity_session_vectors.py` now also passes the `pair-prk.json` pairs to the
  new builders (its output is byte-identical; no existing vector file changed).
- **Independent checker** (`verify_vectors.py`):
  - Libraries: hashlib/hmac, libsodium (pynacl) and **argon2-cffi** (PHC reference C code, newly pinned:
    `argon2-cffi==25.1.0`, `argon2-cffi-bindings==26.1.0`).
  - It rebuilds `T_offer`, the MAC inputs and the attestation from the JSON fields of the messages rather than from the
    hex fields, parses the QR URI with `urllib`, and chains the keys to `pair-prk.json` / `device-id.json`.
  - It runs the receiver's checks in spec order, so every negative vector must fail exactly at its `check` with its
    `expected_error`, and it reproduces each mistake from the evidence.
  - Mutation test (scratch script, 16 single-field corruptions across both files, including a negative's `check` or
    `reason`, a `mac_input`, the QR `%26`, the accepted-hint order): every one is caught.
- **Docs**: `test-vectors/README.md` + `README.vi.md` (both files' fields, new reasons, 6 new interpretation rows),
  `tools/vectors/README.md` + `.vi.md` (modules, argon2-cffi), top `README.md` + `.vi.md` (18 generated files).
- **Android consumer tests** (branch `feat/phase-01-clipboard`), all JVM:
  - `core/crypto` `PairHandshakeVectorTest` (6 tests):
    - Recomputes with the Android code every identity, `K_pin`, `K_pa`, `T_offer`, MAC, attestation, Ed25519
      signature, `PRK` from both sides and `prk_check`, and decodes the `pair/*` envelopes with the Android codec.
    - Runs the client's offer and done checks (built on the Android primitives, spec order) on the positive vectors
      (must pass) and on the client-checked negatives (must fail at their `check`).
    - Reproduces the p = 1 and `"42917"` `K_pin` values with the Android Argon2id.
  - `feature/pairing` `PairingExchangeVectorTest` (4 tests, Robolectric):
    - With each vector's identity, `nonce_s` and TLS pin, `PairingExchange` answers the vector's `hello_envelope` with
      exactly `offer_plaintext` and its `confirm_envelope` with exactly `done_plaintext` (compared as JSON).
    - It stores the same peer keys, attestation, `sig_self`/`sig_peer`, `created_at` and `PRK`, and reports the same
      Security Code.
    - Every Android-checked negative (hello, confirm) gets `pair/error AUTH_FAILED` and stores nothing.
    - A mistyped PIN gives exactly the vector's wrong offer MAC, then `PIN_INVALID` with 2 attempts and a reopened
      window.
    - The QR URIs parse (via `PairingInvite`) to the vector's keys, `rv` and `pr`, and the wrong `pr` differs.
  - `feature/connection` `DiscoveryHintVectorTest` (3 tests):
    - `K_disc`, hint of every hour, `hourIndex`, the TXT `h` of `DiscoveryHints.forPairs` + `MdnsTxtRecord` at each
      clock value.
    - The match scenarios, with the client rule (current + previous hour) built from the same primitives.
    - No negative TXT value is taken for its pair.
  - `VectorFileCoverageTest` maps both new files. The KDoc of `PairingAuthDerivationTest` and `DiscoveryHintsTest` no
    longer says "no shared vector covers them".

## Commits

| Repository | Hash | Subject |
|---|---|---|
| handlive-shared | 637902a | build(shared): pin argon2-cffi to check Argon2id apart from OpenSSL |
| handlive-shared | a725c54 | feat(shared): derive the pairing and discovery values for the vectors |
| handlive-shared | 552d8d7 | feat(shared): generate the PAIR-01 handshake vectors with negative cases |
| handlive-shared | 3f85261 | feat(shared): generate the hourly mDNS discovery hint vectors |
| handlive-shared | 6db48bd | test(shared): verify the pairing handshake vectors independently |
| handlive-shared | 8219491 | test(shared): verify the discovery hint vectors independently |
| handlive-shared | c252120 | docs: describe the pairing handshake and discovery hint vectors |
| handlive-android | 0f5a41d | test(android): check the pairing derivations against the handshake vectors |
| handlive-android | 47a8b70 | test(android): run the phone's pairing exchange against the handshake vectors |
| handlive-android | de57dd5 | test(android): check the discovery hints against the discovery vectors |

All signed off (`-s`), no AI trailers (`.githooks/check-commits.sh`: "commit sạch" for both ranges). Shared lock taken
with `mkdir` before the shared commits and removed after the push. Nothing in `apple/` or the hub was touched.

## Files

shared (`/Users/hxd/HandLive/shared`):
- New `test-vectors/pair-handshake.json`, `test-vectors/discovery-hint.json`.
- New `tools/vectors/pairing_discovery_derivations.py`, `pair_handshake_messages.py`, `build_pair_handshake_vectors.py`,
  `build_pair_handshake_negative_vectors.py`, `build_discovery_hint_vectors.py`, `verify_pairing_common.py`,
  `verify_pair_handshake_checks.py`, `verify_pair_handshake_negative_checks.py`, `verify_discovery_hint_checks.py`.
- Changed `tools/vectors/generate_vectors.py`, `verify_vectors.py`, `build_identity_session_vectors.py`,
  `requirements.txt`, `test-vectors/README.md` + `.vi.md`, `tools/vectors/README.md` + `.vi.md`, `README.md` + `.vi.md`.

android (`/Users/hxd/HandLive/android`):
- New `core/crypto/src/test/kotlin/app/handlive/android/core/crypto/PairHandshakeVectorTest.kt`.
- New `feature/pairing/src/test/kotlin/app/handlive/android/feature/pairing/exchange/PairingExchangeVectorTest.kt`.
- New `feature/connection/src/test/kotlin/app/handlive/android/feature/connection/discovery/DiscoveryHintVectorTest.kt`.
- Changed `core/crypto/.../VectorFileCoverageTest.kt`, `core/crypto/.../PairingAuthDerivationTest.kt` (KDoc),
  `feature/connection/.../discovery/DiscoveryHintsTest.kt` (KDoc), `feature/pairing/build.gradle.kts` (`hl.shared.dir`,
  test input, `testFixtures(:core:protocol)`), `feature/connection/build.gradle.kts` (test input
  `discovery-hint.json`).

## Test commands and real output

From `shared/` at c252120:

```
$ tools/.venv/bin/python tools/vectors/verify_vectors.py
OK  discovery-hint.json         4 vector,  6 vector âm,  80 phép kiểm
OK  pair-handshake.json         3 vector, 27 vector âm, 527 phép kiểm
OK  pair-prk.json               2 vector,  0 vector âm,  23 phép kiểm
...
Tổng: 1106 phép kiểm, 0 lỗi
$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check
check: 18 file, 0 lệch
$ tools/.venv/bin/python tools/schemas/check_schemas.py
  XANH: mọi kiểm tra đạt
```

ci-shared on c252120: run 36176803047, **success**.

From `android/` (`export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home`) at de57dd5:

```
$ ./gradlew check
BUILD SUCCESSFUL in 4s          (second run; first full run after the changes: BUILD SUCCESSFUL in 38s)
debug unit tests (from the JUnit XML): 330 run, 0 failed, 0 skipped
PairHandshakeVectorTest        tests="6" failures="0" errors="0"
PairingExchangeVectorTest      tests="4" failures="0" errors="0"
DiscoveryHintVectorTest        tests="3" failures="0" errors="0"
VectorFileCoverageTest         tests="1" failures="0" errors="0"
```

`gh run list -R HandLive/handlive-android --branch feat/phase-01-clipboard`: ci-android run 36177575352 on de57dd5 —
**success** (jobs: commit-policy success, `gradlew check` success; the run checked out handlive-shared `feat/phase-01-clipboard` with the new files).

## Android deviations found and fixed

None. Every positive vector is reproduced byte for byte by the Android code, including the real exchange
(`PairingExchange` emits exactly the vector's `pair/offer` and `pair/done`) and the discovery TXT record. Every
Android-checked negative vector is refused with `AUTH_FAILED` and nothing stored. Android's own Argon2id reproduces
argon2-cffi's `K_pin` for p = 4, p = 1 and the unpadded PIN. No Android code was changed.

Observation, not a deviation: Android accepts any canonical uuid as `pair_id` without checking for version 4. The spec
only says the client generates a UUIDv4 and does not require Android to reject others.

## Spec deviations and proposals (hub not edited)

The vectors follow the spec where it is explicit. Where it is silent they fix the choice already made by the Android
(and, read-only, Apple) code. These choices are written into `shared/test-vectors/README.md` "Interpretations". They
should go into the spec:

1. **0.4.1 hint window vs. a phone clock that is ahead.** The client accepts only its current and previous hour. If the
   phone's clock is ahead of the client's by δ, then for δ before every hour boundary (client time) the phone
   advertises hour H+1 and the client does not match (negative vector `cặp 1 / đồng hồ điện thoại nhanh hơn, đã qua mốc
   giờ`); only the `last_host` fast path still works.
   - Proposal: also accept H+1 (three HMACs per pair), or state the gap as accepted.
   - If the spec changes, that negative vector becomes a match vector.
2. **0.6.2 `K_pin` encoding.** The spec gives t/m/p/L but not:
   - the password encoding: UTF-8 of the six digit characters, leading zeros kept, never an integer;
   - the Argon2 version: 0x13;
   - that there is no secret and no associated data.

   Proposal: add these. Note for any future implementation that libsodium's `crypto_pwhash` cannot compute this KDF
   (fixed p = 1, 16-byte salt); the negative vector `K_pin: Argon2id với p = 1` guards this.
3. **PAIR-01 API 4/5 byte forms.** The MAC formulas write `pair_id ‖ created_at ‖ sig` without byte forms. The vectors
   (and both platforms) use `pair_id` 16 bytes, `created_at` int64 BE, `sig` 64 raw bytes, and `pair_id` 16 bytes in
   `prk_check`. Proposal: state this in "Authentication strings", as 0.6.3 step 8 does for `T1`/`T2`.
4. **`str(x)` and Unicode normalization.** Proposal: add "the UTF-8 bytes of the string exactly as sent in JSON, no
   Unicode normalization" (vector `QR cặp 2` has an NFD phone name).
5. **0.4.1 `pr` wording.** The TXT table says "SHA-256(`pk` in the QR)"; PAIR-01 step 6 says "over the 32 decoded
   bytes, lowercase". Proposal: align the 0.4.1 table with step 6 (negative vector `pr: SHA-256 trên chuỗi b64u của
   pk`).
6. **0.4.1 `h` format.** Proposal: say lowercase hex and `,` without spaces. Apple matches case-insensitively, which is
   harmless.
7. **API 1 `d` encoding.** The spec gives only an example. A name with `&`, `=`, `+`, `#` or `%` breaks the URI unless
   it is percent-encoded. Proposal: require UTF-8 percent-encoding of everything outside the RFC 3986 unreserved set
   (the vectors' generator form; receivers parse).
8. **Note, no change needed.** In PIN mode every offer MAC failure, an active attacker included, is answered with
   `PIN_INVALID` (A5) and uses up an attempt. After 3 attempts the Mac makes a new PIN, so an attacker on the LAN can
   only force PIN refreshes. The vectors encode `expected_error = PIN_INVALID` for this case.

## For the other agents

- **Apple:** consume `pair-handshake.json` and `discovery-hint.json` (field list in the hand-off message and in
  `shared/test-vectors/README.md`). Apple's hard-coded discovery values already equal the vectors. No Apple coverage
  test lists vector files, so the new files break nothing there.
- **Relay (P2):** `pairs_request` in `pair-handshake.json` is the API 8 body with a valid attestation and both
  signatures.
- **Running `verify_vectors.py` locally** needs `pip install -r tools/vectors/requirements.txt` (argon2-cffi). The shared
  venv on this machine already has it. Its `pip` launcher points to a moved interpreter, so use
  `tools/.venv/bin/python -m pip`.

Status: DONE
Summary: Added generated, independently verified `pair-handshake.json` (3 vectors, 27 negatives) and `discovery-hint.json` (4 vectors, 6 negatives) to handlive-shared, plus Android JVM tests that run the real pairing exchange and discovery code against every vector; Android matched the spec everywhere, no fixes needed.
Concerns/Blockers: 0.4.1 does not tolerate a phone clock that is ahead across the hour boundary (proposal 1); spec wording gaps 2–7 should be written into the hub docs.

## Follow-up (controller request after hub d1f52c9)

The spec now makes the client accept the hints of the previous, current **and** next hour (0.4.1, CONN-01 step 3 and
API 2). It also states the other gaps reported above (lowercase hex joined by commas, `pr` over the 32 decoded bytes,
`K_pin` encoding, MAC byte forms, no Unicode normalization, the QR name encoding). Proposals 1–7 above are therefore
settled in the hub.

What changed:
- **`discovery-hint.json`** (regenerated through `build_discovery_hint_vectors.py`):
  - `accepted` is now `[previous, current, next]`; `hours` covers −1…2 and 479762…479765.
  - New `match` scenarios: the phone's clock 1 ms and exactly one hour behind and ahead across the hour boundary
    (`matched_as` = `previous` / `next`), plus the same-hour case.
  - `hint_outside_window` now means an hour two away: the phone ahead by one hour and 1 ms across two boundaries, or
    behind by exactly two hours. The former "phone ahead across the boundary" negative is now a match.
  - `pair-handshake.json` is unchanged.
- **Checker** (`verify_discovery_hint_checks.py`, hashlib/hmac): same three-hour rule, plus coverage checks (skews ±1 ms
  and ±1 h present, `hint_outside_window` on both sides at exactly two hours). A 7-mutation scratch test on the new
  rules caught every one.
- **`test-vectors/README.md` + `.vi.md`**: the discovery section is updated. The interpretation rows that the spec now
  states point to the spec; the order of `accepted` stays only a vector convention.
- **Android**: `DiscoveryHintVectorTest` rebuilds the client rule as previous/current/next. No production code changed:
  the phone still advertises only its current hour.

Commits:

| Repository | Hash | Subject |
|---|---|---|
| handlive-shared | 4b2e397 | feat(shared): accept the previous, current and next hour's discovery hint |
| handlive-shared | 12cfae3 | docs: describe the three-hour discovery window of the vectors |
| handlive-android | 0dc94dd | test(android): accept the previous, current and next hour in the discovery vector test |

Real output:
- shared: `verify_vectors.py` → `OK  discovery-hint.json  7 vector,  6 vector âm, 102 phép kiểm` … `Tổng: 1128 phép kiểm,
  0 lỗi`; `generate_vectors.py --check` → `check: 18 file, 0 lệch`; `check_schemas.py` → `XANH: mọi kiểm tra đạt`.
  ci-shared run 36178723504: success. The shared lock was taken for the commits and released after the push.
- android: `DiscoveryHintVectorTest` 3/3 and `DiscoveryHintsTest` 3/3 pass against the new file; `./gradlew check` →
  BUILD SUCCESSFUL, 330 debug unit tests, 0 failures. ci-android run 36178810912: success (commit-policy and
  `gradlew check`).

For Apple:
- Its `DiscoveryHintTests.acceptedHints` still expects two hints `[current, previous]`; 0.4.1 now needs three.
- The vectors list them as `[previous, current, next]`; compare as a set if the implementation orders them
  differently.

Status: DONE
