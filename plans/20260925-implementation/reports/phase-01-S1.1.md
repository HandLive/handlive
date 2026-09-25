# Phase 1 — S1.1: signature vectors, session/error rule, close codes

Card S1.1 of `phase-01-bang-nho-tam-mvp.md` (left over from Phase 0): vectors `relay-auth.json` and `ed25519.json`, `session/error` requiring `min_protocol` with `UNSUPPORTED_VERSION`, and the close codes 4410/4411/4429 of 00-common-specs 0.8.3. Branch `feat/phase-01-clipboard` of handlive-shared, pushed; CI `ci-shared` green (run 36156439860 on 96bab40). Committed under the workspace lock `.locks/shared`.

## What was done

- **`test-vectors/ed25519.json`** — RFC 8032 §7.1 TEST 1–3 (`seed`, `public_key`, `message`, `signature`), the same keys as `device-id.json`; Ed25519 is deterministic, so every platform re-signs and compares. Six `invalid_vectors` every verifier must reject: tampered message (`message_tampered`), a bit flipped in R or in S (`signature_mismatch`), a valid signature checked with another key (`wrong_key`), S replaced by S + L (`signature_not_canonical` — a lax verifier accepts it; RFC 8032 §5.1.7 requires S < L), a 63-byte signature (`signature_length`). The RFC signatures were checked to be reproduced bit for bit by both `cryptography` (OpenSSL) and libsodium, and both reject every negative vector.
- **`test-vectors/relay-auth.json`** — for each RFC key (TEST 1 macos, TEST 2 android, TEST 3 ios) one `register` vector (`POST /v1/devices`: message `"HLREG1"` ‖ device_id 16 ‖ ik_sig_pub 32 ‖ UTF-8(platform) ‖ ts int64 BE, CONN-03 API 1) and one `auth` vector (`POST /v1/auth/token`: `"HLAUTH1"` ‖ challenge 32 ‖ device_id 16, 0.6.4 and CONN-03 API 3), with `message`, `sig` and the exact wire `request` (compact JSON, b64u without padding). Ten `invalid_vectors` the relay must reject: ts, platform or challenge changed after signing (`message_tampered`, with `signed_message`), device_id not derived from the key but correctly signed (`device_id_mismatch`), the other label signed (`wrong_label`, both directions), another key signed (`wrong_key`, with `signer_pub`), 63-byte sig (`signature_length` → 400 `BAD_REQUEST`), S + L (`signature_not_canonical`). `device_id`s match `device-id.json`.
- **Builders and verifier** — `tools/vectors/build_signature_vectors.py` (signs with `cryptography`, asserts the RFC values and that `cryptography` rejects the ed25519 negatives), RFC 8032 messages, signatures and the group order L added to `rfc_source_values.py`, `registration_message`/`auth_message`/`ed25519_sign` in `handlive_protocol_derivations.py`; `tools/vectors/verify_signature_checks.py` recomputes everything with libsodium (pynacl) and checks each negative vector fails **for its stated reason** (for example the `device_id_mismatch` signature is itself valid; `signature_not_canonical` becomes valid once S is reduced mod L). A mutation test (corrupted signature, wrong reason, a negative made valid) makes the verifier fail as expected.
- **`schemas/session-error.schema.json`** — `min_protocol` is now required when `code = UNSUPPORTED_VERSION` (it was only allowed) and still forbidden otherwise; new negative sample "UNSUPPORTED_VERSION thiếu min_protocol" in `tools/schemas/sample_messages.py`.
- **Close codes** — no schema enumerated close codes before. Added `common.schema.json#/$defs/ws-close-code` = [1000, 4400, 4401, 4403, 4408, 4409, 4410, 4411, 4426, 4429, 4500] and a check in `check_schemas.py` that it equals the table of 0.8.3 (like the error codes of 0.8.1; a mutation test confirms it fails on a mismatch).
- **Docs** — `test-vectors/README.md` (two new sections, new `reason` values), `schemas/README.md` (`ws-close-code`, the min_protocol rule), `tools/schemas/README.md` (step 1 lists 0.8.3), top-level README counts 16 vector files.

## Commits (handlive-shared, branch `feat/phase-01-clipboard`)

| Hash | Subject |
|------|---------|
| c563149 | feat(shared): require min_protocol with UNSUPPORTED_VERSION in session/error |
| cdf4b2d | feat(shared): add the WebSocket close codes of 0.8.3 to common.schema.json |
| ea38d2a | feat(shared): generate Ed25519 and relay authentication signature vectors |
| f30c1cd | test(shared): verify the signature vectors with libsodium |
| 96bab40 | docs: describe the signature vectors, close codes and session/error rule |

## Files — for Android, Apple and relay to pick up

New: `shared/test-vectors/ed25519.json`, `shared/test-vectors/relay-auth.json`, `shared/tools/vectors/build_signature_vectors.py`, `shared/tools/vectors/verify_signature_checks.py`.
Changed (contract): `shared/schemas/session-error.schema.json` (min_protocol rule), `shared/schemas/common.schema.json` (`$defs/ws-close-code`).
Changed (tools, docs): `shared/tools/vectors/{rfc_source_values,handlive_protocol_derivations,generate_vectors,verify_vectors}.py`, `shared/tools/schemas/{check_schemas,sample_messages}.py`, `shared/test-vectors/README.md`, `shared/schemas/README.md`, `shared/tools/schemas/README.md`, `shared/README.md`, `shared/README.vi.md`.

- Relay: R1.0 runs its verification against both files (report `phase-01-R1.0.md`).
- Android (Tink `Ed25519Verify`) and Apple (CryptoKit `Curve25519.Signing.PublicKey.isValidSignature`) should load `ed25519.json` for the attestation signature of PAIR-01 and `relay-auth.json` for the relay client (P2); both libraries reject S ≥ L, so every negative vector must fail. Platforms that validate `session/error` against the schema must now emit `min_protocol` with `UNSUPPORTED_VERSION`; close codes can be checked against `ws-close-code`.

## Tests (real output, from `shared/`)

```text
$ tools/.venv/bin/python tools/vectors/verify_vectors.py
OK  ack.json                    3 vector,  2 vector âm,  33 phép kiểm
OK  chacha20-poly1305.json      2 vector,  4 vector âm,  10 phép kiểm
OK  clipboard-chunk.json        2 vector,  2 vector âm,  24 phép kiểm
OK  device-id.json              3 vector,  0 vector âm,  15 phép kiểm
OK  ed25519.json                3 vector,  6 vector âm,  23 phép kiểm
bỏ qua (không có bộ kiểm): envelope-roundtrip-apple.json
bỏ qua (không có bộ kiểm): envelope-roundtrip.json
OK  envelope.json               5 vector,  5 vector âm,  38 phép kiểm
OK  hchacha20.json              3 vector,  0 vector âm,   6 phép kiểm
OK  hkdf-sha256.json            3 vector,  0 vector âm,   6 phép kiểm
OK  hl-frame.json               4 vector,  2 vector âm,  32 phép kiểm
OK  pair-prk.json               2 vector,  0 vector âm,  23 phép kiểm
OK  relay-auth.json             6 vector, 10 vector âm, 100 phép kiểm
OK  session-handshake.json      2 vector,  4 vector âm,  44 phép kiểm
OK  session-rekey.json          2 vector,  0 vector âm,  18 phép kiểm
OK  stream-keys.json            2 vector,  3 vector âm,  27 phép kiểm
OK  x25519.json                 6 vector,  0 vector âm,   6 phép kiểm
OK  xchacha20-poly1305.json     3 vector,  4 vector âm,  22 phép kiểm
Tổng: 491 phép kiểm, 0 lỗi

$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check
check: 16 file, 0 lệch

$ tools/.venv/bin/python tools/schemas/check_schemas.py | grep -E 'enum|UNSUPPORTED_VERSION thiếu|XANH'
== 1. Metaschema, $id, $ref, enum khớp spec
  REJECT session/error UNSUPPORTED_VERSION thiếu min_protocol: 'min_protocol' is a required property
  enum khớp bảng spec: 3
  XANH: mọi kiểm tra đạt

$ gh run list -R HandLive/handlive-shared --branch feat/phase-01-clipboard --limit 1
completed success docs: describe the signature vectors, close codes and session/error rule ci-shared feat/phase-01-clipboard push 36156439860
```

## Spec deviations and proposals

1. **The challenge of the CONN-03 API 2 example is not canonical b64u.** `"0tXoN3f1C9aYQbJ8kVw2mZr5uHs7pLd4gEi6cBy0xQa"` decodes to 32 bytes, but its last character carries non-zero padding bits, so re-encoding gives a different string and a strict decoder (the `b64u-32` pattern of `common.schema.json`) rejects it. The vectors use generated challenges instead. Proposal: replace the example with a canonical value (last character in `AEIMQUYcgkosw048`).
2. **"Close codes into the schema and catalog".** No schema listed close codes, so they now live in `common.schema.json#/$defs/ws-close-code`, checked against 0.8.3. Close codes have no user-facing text (the UI shows the 0.11 states), so no catalog entry was added; the session/error texts are `error.session_auth_failed`, `error.update_phone_app`, `error.update_this_app` (S1.2).
3. **Strict Ed25519 is part of the contract.** The negative vectors require S < L (RFC 8032 §5.1.7) and exact 64-byte signatures. The relay already uses `verify_strict`; Tink and CryptoKit (BoringSSL) enforce S < L. Proposal: say "kiểm chặt (S < L)" in 0.6.4 and PAIR-01 API 4–5 so no platform picks a lax verifier.
4. **The ±5 minute `ts` window of CONN-03 API 1 is not in the vectors** (the `ts` values are fixed in 2024); relay tests check the signature path with an injected clock or call the verification function directly.

## Pending manual checks

None for this card; Android and Apple still have to wire the two files into their test suites (their cards).

Status: DONE
Summary: ed25519.json (RFC 8032 TEST 1–3 + 6 negative vectors) and relay-auth.json (HLREG1/HLAUTH1 for three keys + 10 negative vectors) are generated, independently verified and pushed; session/error now requires min_protocol with UNSUPPORTED_VERSION and the 0.8.3 close codes (with 4410/4411/4429) are a schema definition checked against the spec.
Concerns/Blockers: none; the CONN-03 example challenge is not canonical b64u (proposal 1).
