# Phase 3 — S3.3 [shared]: call push test vectors

Card S3.3 of `phase-03-cuoc-goi.md`: `call_event` envelopes encrypted with `K_push` for the `call_incoming` and
`call_missed` pushes, with their `POST /v1/push` bodies and APNs payloads, built by the existing
`tools/vectors/build_*.py` + `generate_vectors.py` and checked independently in `verify_vectors.py`. Only what the
Phase 2 vectors did not cover was added. Branch `feat/phase-03-calls` of handlive-shared, pushed under the workspace
lock; CI `ci-shared` green (run 36295926106 on 5b901a2). `verify_vectors.py` → `0 lỗi`, `generate_vectors.py
--check` → `0 lệch`, `check_schemas.py` → `XANH`.

## What was done

`test-vectors/push-envelope.json`: 10 → 14 vectors (2 keys + 12 envelopes), 9 → 12 negatives; the order of the
existing vectors and negatives is unchanged (new ones are appended).

**Fix of an existing vector** (commit fb2b6c9): the Phase 2 call vector `pair 2 / call_event/state ringing` carried
`controls.answer = true`, but a push only goes to an iPhone/iPad and only a Mac may answer (CALL-01 API 1 logic 4).
It now carries `answer = false`; its `plaintext`, `ciphertext`, `tag`, `payload_b64`, `envelope`, `env_b64`,
`push_request` and `apns_payload` changed (same `id`, `ts`, nonce, collapse key).

**New call envelopes** (pair 2, whose client is the iPhone of `relay-auth.json`; all `thread-id` `calls`):

| Vector name | op | reason | `collapse_key` | `ttl_s` | envelope `id` | `ts` | `env_b64` length |
|-------------|----|--------|----------------|---------|---------------|------|------------------|
| `pair 2 / call_event/state ringing` (existing, fixed) | state | call_incoming | `call:0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90` | 30 | 0192f3f0-6a2c-7d3e-9f40-5a6b7c8d9eaf | 1727150400400 | 1152 |
| `pair 2 / call_event/state ringing without the caller's number` | state | call_incoming | `call:01922232-afbb-72ea-8e21-e52ac96058ff` | 30 | 01922232-b0d0-7d80-a9d8-18bac7cb15eb | 1727150600400 | 1116 |
| `pair 2 / call_event/log_new missed call` | log_new | call_missed | `call:0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90` | 86400 | 01922230-0984-7b0a-b799-bcc59502a73b | 1727150426500 | 596 |
| `pair 2 / call_event/log_new missed call without a matching call` | log_new | call_missed | `calllog:5121` | 86400 | 01922234-ae94-76cf-bd4e-7c59250134e8 | 1727150730900 | 524 |
| `pair 2 / call_event/state missed without the call log` | state | call_missed | `call:01922232-afbb-72ea-8e21-e52ac96058ff` | 86400 | 01922233-1340-7944-8e09-853b3877e678 | 1727150625600 | 1132 |

- Ringing without the number: `number = null`, `display_name = null`, `presentation = unknown` (the phone lacks
  `READ_CALL_LOG`), ringing SIM not determined (`sub_id = sim_label = null`), controls of an iOS client
  (`answer = false`, `reject = true`, the rest off), `hfp_connected = false`, `audio_on = phone`. I-NSE shows
  `call.unknown_caller` · `call.incoming_body` (no SIM label).
- Missed `log_new`: exactly the CALL-04 API 2 example (entry 5120, matched with the first call); its collapse key
  equals the first call's `call_incoming` key, so the missed-call notification replaces the incoming one on the
  iPhone. The unmatched `log_new` (entry 5121, `display_name = null`, `sub_id = null`, `call_id = null`) uses
  `calllog:5121`.
- Flow A: the second call ends as `state = idle`, `end_reason = missed`, `ended_at` 1727150625456, no number, all
  controls off, under the same collapse key as its incoming push.
- Envelope ids of the new vectors are UUIDv7s of their `ts` (`push_sms_truncation.uuid7`); nonces come from
  `test_bytes("push nonce <id>")` as before. The plaintext is compact UTF-8 JSON with the field order of CALL-01
  API 1 / CALL-04 API 2.

**New negatives** (reasons already known to every platform, so no new reason handling):

| Name | reason |
|------|--------|
| `pair 2 / call_event/state ringing / K_push of pair 1` | `wrong_key` |
| `pair 2 / call_event/state ringing / sealed with the AAD type written callEvent` | `aad_mismatch` (`aad_used` = `1|callEvent|<id>|<ts>`: the AAD is always rebuilt from the envelope's own `type`, `call_event`) |
| `pair 2 / call_event/log_new missed call / type changed to sms after encryption (AAD)` | `aad_mismatch` |

No second `stale` negative was added: the Android test takes the single `stale` vector with `.single`.

**Generator** (`tools/vectors/`): `push_call_messages.py` (new) holds the call plaintexts and spec tuples;
`build_push_relay_vectors.py` appends them after the SMS cut vectors and adds `_call_push_negatives`.

**Independent checks**: `verify_push_call_checks.py` (new) re-derives each push's reason (ringing state →
`call_incoming`; idle state with `end_reason = missed` or a `log_new` of type `missed` → `call_missed`) and collapse
key (`call:<call_id>`, else `calllog:<entry_id>`) from the decrypted plaintext; `verify_push_relay_checks.py` now takes
the `ttl_s` per reason (86,400 for `call_missed`) and checks for every call push: the controls of an iOS client
(`answer = false`, `hfp_connected = false`, `audio_on = phone`), no waiting call pushed, a flow-A state only without a
number and with `presentation = unknown` and no action left, sent after the call started/ended; across vectors: a
missed push keyed `call:` replaces an existing incoming push, a `log_new` names a call started within 5 s with the
same number (CALL-04 API 2 logic 2); coverage of both reasons, both missed sources, both collapse forms and an
incoming call without the number. A scratch mutation run (answer true, waiting pushed, HFP on, flow-A number set,
flow-A control left, entry not missed, entry 10 s off, different number, wrong collapse form, `ttl_s` 30, thread
`sms`, wrong reason, unmatched `call_id`, and the flow-A, unmatched and no-number cases removed) was caught 16/16.
`tools/schemas/relay_sms_spec_checks.py` validates the `call_event/state` and `call_event/log_new` plaintexts of the
vectors against the S3.2 schemas (12 plaintexts now, 7 `sms/new` + 5 call).

## Commits (handlive-shared, branch `feat/phase-03-calls`)

| Hash | Subject |
|------|---------|
| fb2b6c9 | fix(shared): give the call push vector the controls of an iPhone |
| deef3aa | feat(shared): add push vectors for missed calls and unknown callers |
| b429cfc | test(shared): check the call pushes independently |
| 5b901a2 | docs: describe the call push vectors and their checks |

Each commit was checked in isolation (`verify_vectors.py`, `generate_vectors.py --check`, `check_schemas.py`). All
signed off; `.githooks/check-commits.sh origin/main..HEAD` → "commit sạch: đã kiểm 13 commit".

## Files

Created: `shared/tools/vectors/push_call_messages.py`, `verify_push_call_checks.py`.
Changed: `shared/test-vectors/push-envelope.json` (generated), `README.md`, `README.vi.md`;
`shared/tools/vectors/build_push_relay_vectors.py`, `verify_push_relay_checks.py`, `README.md`, `README.vi.md`;
`shared/tools/schemas/relay_sms_spec_checks.py`, `check_schemas.py` (docstring), `README.md`, `README.vi.md`.

## What the platforms must change (shared change: re-run the tests)

**Android**
- `core/crypto` `PushEnvelopeVectorTest`: `assertEquals(8, envelopes.size)` → 12; `assertEquals(9, invalid.size)` → 12
  (the new negatives are `wrong_key` and `aad_mismatch`; the single `stale` stays single).
- `core/protocol` `PushRequestVectorTest`: `assertEquals(8, requests.size)` → 12; the new requests use
  `reason = call_missed`, `ttl_s = 86400`, `collapse_key` `call:<call_id>` or `calllog:5121`.
- A3.2 (push builder): the `call_incoming` push must carry the controls of the iPhone (`answer = false`,
  `hfp_connected = false`, `audio_on = phone`); byte-exact envelopes for the five call vectors can be rebuilt from
  `plaintext`, `id`, `ts`, `nonce` like the SMS ones; `call_missed` uses the `log_new` envelope with
  `READ_CALL_LOG` and the idle `state` without it; `calllog:<entry_id>` only when no call matched.

**Apple**
- `HLCrypto` `PushEnvelopeVectorTests`: envelope count 8 → 12, `invalidVectors.count` 9 → 12. SMS decoder tests
  already filter `type == "sms"`.
- I3.1 (I-NSE): the five call vectors decrypt to the CALL-01/CALL-04 plaintexts to build `HL_CALL_INCOMING` and
  missed-call content (`call.incoming_body`/`_sim`, `call.unknown_caller`, `call.missed_body`/`_sim`,
  `call.no_caller_id`); the missed push shares the incoming push's collapse key, so APNs replaces the notification.

**Relay**: `crates/relay-push/tests/shared_push_vectors.rs` (`sent >= 8`) still holds with 12 push requests; the
two `call_missed` collapse keys and the 86,400 `ttl_s` are already accepted by the relay (Phase 2 schemas).

## Tests (real output, from `shared/`)

```text
$ tools/.venv/bin/python tools/vectors/verify_vectors.py | grep "push-envelope\|Tổng"
OK  push-envelope.json         14 vector, 12 vector âm, 295 phép kiểm
Tổng: 1485 phép kiểm, 0 lỗi

$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check
check: 20 file, 0 lệch

$ tools/.venv/bin/python tools/schemas/check_schemas.py | grep "push-envelope\|XANH"
  PASS push-envelope.json: 12 × push_request
  PASS push-envelope.json: 12 × apns_payload
  PASS push-envelope.json: 12 × plaintext
  XANH: mọi kiểm tra đạt

$ gh run list -R HandLive/handlive-shared --branch feat/phase-03-calls --limit 1
completed  success  docs: describe the call push vectors and their checks  ci-shared  push  36295926106
```

Before this card: `push-envelope.json` 10 vectors, 9 negatives, 207 checks; `verify_vectors.py` 1397 checks.

## Spec deviations and proposals (hub not edited)

1. **The Phase 2 call vector contradicted CALL-01 API 1 logic 4** (`controls.answer = true` for an iPhone) —
   fixed in the vector, no spec change needed.
2. **What I-NSE may show for a missed call is under-specified**: CALL-04 API 4 sets `HL_CALL_MISSED` only when
   `features.sms.can_send = true`, but I-NSE cannot open the database that holds the phone's capability (0.9.3) and
   the push plaintext does not carry it. Proposal: I-NSE reads a copy of `features.sms.can_send` that I-APP keeps in
   the App Group `UserDefaults` (like `sms.preview`), or the category is always set when there is a number and the
   action reports failure. Please decide in CALL-04 API 4 / CONN-04 step 9b.
3. **CALL-01 E7 ("Incoming call at <time>")** is a display rule of I-NSE based on `now − started_at > 60 s`; it is not
   a vector (no negative), since the decrypted content is valid. The late-push threshold is only in the prose of
   CALL-01 API 6 logic 2.

## Pending manual checks

- On a real iPhone: the missed-call push replacing the incoming-call notification through the shared
  `apns-collapse-id`, and the time-sensitive incoming push during Focus.

Status: DONE
Summary: push-envelope.json now pins the call pushes CALL-01/CALL-04 need (ringing with and without the number, missed from the call log with and without a matching call, missed without the call log, three call negatives) and fixes the iPhone controls of the Phase 2 call vector; verify_vectors 0 errors, generate --check 0 mismatches, check_schemas green, CI green.
Concerns/Blockers: Android and Apple vector tests pin the old counts (8 envelopes, 9 negatives) and must move to 12 and 12; deviation 2 needs a decision before I-NSE builds the missed-call category.
