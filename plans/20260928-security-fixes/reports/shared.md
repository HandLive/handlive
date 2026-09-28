# shared: security scan fixes (D2, D9, D8 check, D11)

Repo `handlive-shared`, branch `fix/security-scan-findings` from `origin/main` (`fceca48`), pushed.

## Changes

### D2: revoke vector (`test-vectors/revoke.json`)
- New builder `tools/vectors/build_revoke_vectors.py`. New independent checker `tools/vectors/verify_revoke_checks.py`, which uses libsodium and reimplements the relay's and the receiver's decisions. Both are wired into `generate_vectors.py` and `verify_vectors.py`. `revoke_message()` was added to `handlive_protocol_derivations.py`.
- The message is `"HLREVOKE1"` ‖ pair_id (16 raw) ‖ by = device_id (16 raw) ‖ revoked_at u64 BE ms, 49 bytes in total. It matches 00-common-specs 0.6.2 as the hub now states it.
- 3 valid vectors use the RFC 8032 TEST 1–3 keys, and their device_id matches `device-id.json`:
  - macOS (TEST 1, `21fe31df-…`) revokes pair `3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d` at 1727160000000. sig starts with `4e19faec…`.
  - Android (TEST 2, `39f713d0-…`) revokes the same pair at 1727160000123.
  - iOS (TEST 3, `dac073e0-…`) revokes pair `7a1e2b3c-4d5e-4f60-9172-83a4b5c6d7e8` at 1727170000456.
- Fields in each vector:
  - `ik_sig_seed`, `ik_sig_pub`, `device_id`, `pair_id`, `revoked_at`;
  - `message`, `sig` (hex), `sig_b64u`;
  - `peer_device_id`, `peer_ik_sig_pub`, `relay_now`;
  - wire forms: `revoke_request` (POST body), `revocation` (DELETE item) and `pair_revoked` (frame).
- 13 negative vectors. Each one has a `check` field, which is either `receiver` or `relay`:
  - receiver (7): `by_not_peer`, `wrong_key`, `message_tampered` ×2 (revoked_at changed; another pair's statement), `wrong_label`, `signature_not_canonical`, `missing_statement` (a legacy row);
  - relay (6, each answered with 400): `stale` ×2 (±10 min + 1 ms), `by_not_caller`, `message_tampered`, `signature_length`, `missing_statement`.
- Updated `test-vectors/README(.vi).md` and `tools/vectors/README(.vi).md`.

### D2 / D9 / D8: schemas
- `relay-pair_revoked`: `op, pair_id, by, revoked_at, sig` are all required (`sig` is b64u-64).
- `relay-rest`:
  - `pair-revoke-request` requires `{revoked_at, sig}`. `reason` stays as an optional informational field, because the hub's PAIR-03 API 3 keeps it.
  - New `devices-delete-request` `{revocations: [revocation]}` and `revocation` `{pair_id, revoked_at, sig}`.
  - `pairs-list-response` items get optional nullable `revoked_by` and `revoke_sig`:
    - an unrevoked pair must have them null or absent;
    - a revoked pair must have both keys; `revoke_sig` may be null for legacy rows.
- `sms-send`: new `$defs/ack-failure` and `$defs/error` with codes FEATURE_DISABLED, PERMISSION_MISSING, BAD_REQUEST, PAYLOAD_TOO_LARGE, SMS_INVALID_ADDRESS, SMS_SIM_UNAVAILABLE, RATE_LIMITED and INTERNAL. `RATE_LIMITED` requires `details.retry_after_ms` as an int64 ≥ 1. `RATE_LIMITED` was already in `error.schema.json` (0.8.1).
- Clipboard: `clip_id` and `transfer_id` were already `uuid-v7` in push, conflict and cancel. Verified, no change.
- Schema tools:
  - `relay_sms_spec_checks.py`: DELETE maps to the new defs; the three wire forms of `revoke.json` are validated against the schemas.
  - `doc_examples.py`: classifies revoke bodies and the DELETE body; placeholders for `revoked_by` and `revoke_sig`.
  - Positive and negative samples added in `sample_messages_relay.py` and `sample_messages_sms.py`.
  - `schemas/README(.vi).md` updated.

### D9: UI string
- `sms.send_rate_limited_body` (platform android, spec SMS-04). The placeholder follows the catalog convention, `{device_name}`, not `%1$@`.
  - en: "HandLive stopped sending messages from {device_name} for now. Too many were sent in a short time."
  - vi: "HandLive tạm dừng gửi tin nhắn từ {device_name}. Có quá nhiều tin nhắn được gửi trong thời gian ngắn."
- The vi text follows the hub's SMS-04 field 12 wording ("tạm dừng", "tin nhắn"), not the brief ("tạm ngừng", "tin"). The brief's wording made `check_strings.py --docs` warn.

### D11: CI (`.github/workflows/ci-shared.yml`)
- Actions are pinned to full commit SHAs:
  - `actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5.1.0` (×3);
  - `actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1 # v6.3.0`.
- `persist-credentials: false` on all 3 checkouts.
- The branch lookup no longer calls `git ls-remote https://x-access-token:${GH_TOKEN}@…`. It now calls `gh api repos/<owner>/<repo>/git/matching-refs/heads/<branch>` and filters for an exact ref; `gh` takes GH_TOKEN from the environment. I tested it locally: it finds `main` and `feat/phase-03-calls`, and returns nothing for a missing branch. In CI it resolved correctly.
- Everything else behaves as before. CI still runs only on `main` and `feat/**` pushes, plus dispatch.

## Verification (local, `tools/.venv`)
- `verify_vectors.py`: 1590 checks, 0 errors (revoke.json: 101 checks). `generate_vectors.py --check`: 21 files, 0 differences. A mutation test (tampered `revoked_at` and `peer_device_id`) was caught with 7 errors.
- `check_schemas.py`: XANH (green) against the hub's `main` at `68dc1f8`. Before the hub spec landed it failed only on the old leaf-spec examples, as expected.
- `check_strings.py`: 0 errors. `--docs`: 0 warnings. `--self-test`: 96 passed.
- Other self-tests pass: bench (68), relay_load (10), e2e, relay_stack (21).

## Commits (handlive-shared, `fix/security-scan-findings`)
- `2e1f8b1` test(shared): add the signed revoke statement vectors
- `592b6c3` feat(shared): carry the signed revoke statement in the relay schemas
- `f32a052` feat(shared): describe the sms/send error ack with RATE_LIMITED (also carries the schema README relay line)
- `9d3c224` feat(shared): add the SMS send limit notification text
- `37a403f` ci(shared): pin actions to commit SHAs and keep the token out of URLs
- `6a66c4a` fix(shared): keep the informational reason in the revoke body
- `fa0a96e` fix(shared): match the SMS send limit text to the SMS-04 wording

## CI
- ci-shared does not run on `fix/**` pushes, so I started it by hand (`workflow_dispatch`).
- Run 36369507173 failed on `9d3c224`…`37a403f`. The hub `main` did not yet carry the spec at that point, and the leaf examples still used the old revoke bodies.
- Run 36369832901 passed on `6a66c4a`.
- Run 36369903519 **passed** on head `fa0a96e`, using hub `main` `68dc1f8`.

## For the platform agents (re-run your tests)
- Relay:
  - read `revoke.json`: `revoke_request` and `revocation` must be accepted with `relay_now`, and the `check = relay` negatives must return 400;
  - new schemas: `pair-revoke-request`, `devices-delete-request`, `pairs-list-response` (`revoked_by`, `revoke_sig`), `pair_revoked`.
- Android, Apple: check `revoke.json` for signing, and for the `check = receiver` decisions on `pair_revoked`.
- Android only: `sms-send#ack-failure` with RATE_LIMITED and `retry_after_ms`, and the new string `sms.send_rate_limited_body`.

## Unresolved questions
- Should `GET /v1/pairs` always send `revoked_by` and `revoke_sig` (as null) for unrevoked pairs? The schema currently accepts them either absent or null.
- The GitHub API rate limit (5,000/hr, shared with other agents) was reached at the end of the session. Other agents' `gh` calls may be throttled for a while.

Status: DONE
Summary: Added revoke.json (3 vectors, 13 negatives, independently verified), the revocation and sms/send RATE_LIMITED schemas, the sms.send_rate_limited_body string, and a hardened, pinned CI. The branch is pushed, and ci-shared passes on fa0a96e against hub main 68dc1f8.
Concerns/Blockers: none blocking. The schema allows optional `reason` in the revoke body, following the hub's PAIR-03 API 3.
