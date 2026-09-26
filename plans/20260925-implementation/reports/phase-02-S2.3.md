# Phase 2 — S2.3 [shared]: push envelope and relay frame test vectors

Card S2.3 of `phase-02-sms-ios-relay.md`: test vectors for the `K_push` derivation and envelopes encrypted with
`K_push` (CONN-04 step 5b, decrypted by I-NSE), and for the `HR` binary routing frame of 0.4.3 with the text wrapper
`to` → `from` rewrite. Built with `tools/vectors/build_*.py` + `generate_vectors.py`, checked independently by
`verify_vectors.py`. Branch `feat/phase-02-sms-ios-relay` of handlive-shared, pushed; CI `ci-shared` green (run
36220390240 on d4ca32a; later pushes too). Committed under the workspace lock.

## New files — Android, Apple and relay: load these

- **`shared/test-vectors/push-envelope.json`** (5 vectors, 9 negative vectors):
  - `kind = "key"` for both pairs of `pair-prk.json`: `k_push` = HKDF-SHA256(`PRK`, empty salt, info
    `"handlive/v1/push"`, L = 32) — salt and L exactly as the other HKDF vectors (0.6.3 step 8).
    Pair 1 → `e82ec406…`, pair 2 → `c7551cfb…`.
  - `kind = "envelope"` (pair 2, whose client `dac073e0-…` is the iPhone of `relay-auth.json`): an `sms/new` in
    Vietnamese, an `sms/new` from the sender name `VIETTEL` (no contact, `sub_id` and `ts_sent` null) and a
    `call_event/state` ringing (CALL-01 example). Each has every field of an encrypted `envelope.json` vector (key =
    `k_push`, nonce 24 bytes, AAD `"1|<type>|<id>|<ts>"`, `payload_b64`, `envelope`), plus `env_b64` (standard base64
    with padding of the UTF-8 envelope string), `push_request` (the `POST /v1/push` body: `alert`, `sms_new` /
    `call_incoming`, `collapse_key` `sms:sms:12847` / `call:<call_id>`, `ttl_s` 86,400 / 30), `apns_payload`
    (`loc-key` `push.<reason>`, `mutable-content` 1, `thread-id` `sms:<thread_id>` or `calls`, `active` or
    `time-sensitive`, `p` = `pair_id`, `hl` = `env_b64`) and `apns_headers` (`apns-push-type` alert, `apns-topic`
    `app.handlive.ios`, `apns-priority` 10, `apns-collapse-id`).
  - `invalid_vectors` I-NSE must refuse, each with its evidence: `wrong_key` (K_push of pair 1, the `PRK` itself,
    `K_disc`), `tag_mismatch`, `aad_mismatch` (`ts` changed, `type` changed, sealed with the AAD written with spaces
    — `aad_used`), `stale` (decrypts but `received_at_ms` > `ts` + 24 h, CONN-04 E7), `not_b64` (base64url without
    padding).
- **`shared/test-vectors/relay-frame.json`** (9 vectors, 8 negative vectors), device_ids of pair 1 (Mac
  `21fe31df-…`, phone `39f713d0-…`):
  - `kind = "frame"`: `"HR"` ‖ ver `0x01` ‖ op `0x01` (forward) ‖ 16-byte `device_id` ‖ the intact HL frame (the two
    call-audio frames of `hl-frame.json`), in both directions (`device_to_relay`: `device_id` = destination;
    `relay_to_device`: `device_id` = source). Example header `4852010139f713d0a644853f84529421b9f51b9b`.
  - `kind = "rewrite"`: outbound and inbound frames that differ only in the 16 device_id bytes.
  - `kind = "text_rewrite"`: `{"to","env"}` (compact; env first with spaces and an indented env; and a wrapper
    where the device also sent a `from`, `spoofed_from`) → `{"from":"<sender>","env":<env byte for byte>}` — a
    device's `from` is ignored like any unknown field (0.5.1 rule 6) and never trusted.
  - `invalid_vectors` with `expected_error`: `bad_magic`, `unsupported_version`, `unknown_op`, `truncated` (×2) →
    `BAD_REQUEST`; text wrappers with a `to` that is not a device_id or without `env` → `BAD_REQUEST`; `to` = the
    sender → `NOT_PAIRED`. The relay checks only the 20-byte `HR` header and that a frame follows; it never inspects
    the HL frame (the receiving device does, 0.5.2).
  - This matches the relay agent's implementation on the branch (`relay/crates/relay-server/src/relay/wire.rs`
    `parse_hr`, `forwarded_text`; malformed frames answered with `error` `BAD_REQUEST`). A first version of the file
    (1cf87ce) also refused inner frames that are not HL and a wrapper carrying `from`; 3e0e822 dropped those two
    rules as stricter than the spec.
- **Who uses what:**
  - Apple (I-NSE, `HLCrypto`): derive `K_push` from the key vectors; decode `hl`, decrypt each envelope vector and
    compare with `plaintext`; refuse every negative vector (and treat `stale` by `received_at_ms`).
  - Android (A2.2): derive `K_push`, re-encrypt each envelope vector's `plaintext` with its `nonce` and compare
    `payload_b64`/`envelope`/`env_b64`; build `push_request` byte-equal (compact JSON, same key order).
  - Relay (R2.1/R2.2): parse/emit `relay-frame.json` frames and text rewrites exactly, answer the negatives with the
    given error; send `apns_payload` + `apns_headers` for each envelope vector's `push_request`.

## Checks

- `verify_push_relay_checks.py` (independent of the generator):
  - `K_push` recomputed with `hashlib`/`hmac` and chained to `pair-prk.json`.
  - Envelopes decoded as I-NSE does (strict standard base64 → UTF-8 JSON → AAD rebuilt from parsed fields) and
    decrypted with libsodium and with HChaCha20 + ChaCha20-Poly1305 (the Apple path); Apple-style re-encryption
    compared.
  - `push_request`, `apns_payload` and `apns_headers` rebuilt from the plaintext (reason, collapse key, TTL, thread,
    interruption level, sizes ≤ 3,000 / 4 KB); no `local_id` in push plaintexts.
  - Each negative must fail for its stated reason only: the wrong key is shown to differ from `K_push`, which opens
    the envelope; `aad_used` opens the spaced-AAD case; `stale` decrypts.
  - `HR` frames parsed with `struct`, the inner frame equal to its `hl-frame.json` vector and still decryptable with
    that stream key; the device_id is the inner frame's recipient outbound and its sender inbound.
  - Text rewrite rebuilt with a small top-level JSON scanner that keeps the raw `env`; the spoofed `from` must not
    survive.
- `check_schemas.py` section 5 now also validates the vectors' `push_request` (`relay-rest#push-request`),
  `apns_payload` (`push#apns-payload`, with `hl` decoded into an envelope), the `sms/new` plaintexts (`sms-new`),
  the text wrappers (`relay-wrapper`, except the deliberately non-conforming `spoofed_from` input), and requires the
  malformed wrappers to fail the wrapper schema.
- Mutation test (scratch script, 20 single corruptions: K_push, info label, ciphertext, swapped env_b64, edited
  plaintext, collapse key by thread, TTL, APNs thread-id, call level, AAD field, a negative's reason, stale within
  24 h, canonical `aad_used`, untampered tag, swapped frame device_id, inner byte, frame reason, re-serialized env,
  a kept spoofed `from`, text error): all caught.

## Commits (handlive-shared, branch `feat/phase-02-sms-ios-relay`)

| Hash | Subject |
|------|---------|
| 1cf87ce | feat(shared): generate the push envelope and relay routing frame vectors |
| e087179 | test(shared): verify the push envelope and relay frame vectors independently |
| ea74953 | test(shared): check the push and relay vector messages against their schemas |
| d4ca32a | docs: describe the push envelope and relay frame vectors |
| 3e0e822 | fix(shared): let the relay check only the HR header and ignore a device's from |
| 7627f96 | docs: describe the header-only relay checks and the ignored from |

## Files

New: `shared/test-vectors/push-envelope.json`, `shared/test-vectors/relay-frame.json`,
`shared/tools/vectors/build_push_relay_vectors.py`, `shared/tools/vectors/verify_push_relay_checks.py`.
Changed: `shared/tools/vectors/generate_vectors.py`, `verify_vectors.py`, `shared/tools/schemas/relay_sms_spec_checks.py`,
`test-vectors/README.md` + `.vi.md` (both files, two interpretation rows, new reasons), `tools/vectors/README.md` +
`.vi.md`, `tools/schemas/README.md` + `.vi.md`, `README.md` + `.vi.md` (20 vector files). No existing vector changed.

## Tests (real output, from `shared/`)

```text
$ tools/.venv/bin/python tools/vectors/verify_vectors.py
…
OK  push-envelope.json          5 vector,  9 vector âm,  82 phép kiểm
OK  relay-auth.json             6 vector, 10 vector âm, 100 phép kiểm
OK  relay-frame.json            9 vector,  8 vector âm,  54 phép kiểm
…
Tổng: 1272 phép kiểm, 0 lỗi

$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check
check: 20 file, 0 lệch

$ tools/.venv/bin/python tools/schemas/check_schemas.py | grep -E 'push-envelope|relay-frame|tin trong|XANH'
  PASS push-envelope.json: 3 × push_request
  PASS push-envelope.json: 3 × apns_payload
  PASS push-envelope.json: 2 × plaintext
  PASS relay-frame.json: 2 × outbound
  PASS relay-frame.json: 3 × inbound
  tin trong test vector: 37
  XANH: mọi kiểm tra đạt

$ gh run list -R HandLive/handlive-shared --branch feat/phase-02-sms-ios-relay --limit 1
completed  success  docs: describe the push envelope and relay frame vectors  ci-shared  push  36220390240
```

## Spec deviations and proposals (hub not edited)

1. **The 1,000-character cut does not fit the 3,000 limit.** CONN-04 step 5b cuts SMS content "at 1,000 characters",
   SMS-02 API 2 logic 3 cuts "by UTF-8 bytes", and `env_b64` must stay ≤ 3,000. The envelope is base64'd twice
   (payload inside the JSON, then the JSON as `env_b64`), about 1.8 × the plaintext. Measured with the vector
   builder: a 1,000-character ASCII body gives `env_b64` = 2,860 characters, a 1,000-character Vietnamese body
   (1,311 UTF-8 bytes) gives **3,488** → `413 PAYLOAD_TOO_LARGE`. The vectors therefore do not fix a truncation rule.
   Proposal: "cut `message.body` (then `thread.snippet`) at a code point boundary and append "…" until `env_b64` ≤
   3,000 characters", or carry the envelope JSON as an object in the APNs payload to drop one base64 layer.
2. **`ttl_s` of `call_incoming`:** CONN-04 API 2 says the default is 60, CALL-01 API 4 sends 30. The vector uses 30
   (the function's own value). Proposal: align CONN-04 API 2.
3. **`collapse_key` of an SMS push** (see S2.2 proposal 2): the vectors use `sms:<message_key>` (`sms:sms:12847`)
   per SMS-02 API 2 and the CONN-04 API 4 table, not `sms:<thread_id>` of CONN-04 step 5b.
4. **`env_b64` encoding** was only an example: the vectors fix standard base64 **with padding** of the UTF-8 envelope
   JSON, the same string as APNs `hl`. Proposal: state it in CONN-04 API 2 and 0.4.4.
5. **Relay handling of malformed `HR` frames and wrappers** is not specified (0.4.3 gives only the layout). The
   vectors answer them with the relay `error` op `BAD_REQUEST` (and `NOT_PAIRED` for a `to` that is not a peer),
   check only the header, ignore a device-sent `from`, and require `env` to be re-emitted byte for byte
   (`{"from":…,"env":<raw env>}`) — as the relay implements it. Proposal: add these rules to 0.4.3 / CONN-03 API 6.
6. **`K_push` of a Mac pair.** The key vector exists for pair 1 (a Mac client) although the Mac never receives pushes
   (0.4.4); only the pair-2 envelopes are pushes.

## Pending manual checks

None for the vectors. The platform agents still have to load both files in their test suites (their cards); the real
iPhone check (a push decrypted by I-NSE while unlocked, generic while locked) belongs to I2.2.

Status: DONE
Summary: push-envelope.json (K_push for both pairs, three K_push envelopes with their POST /v1/push body and APNs payload, 9 negatives) and relay-frame.json (HR frames both ways, the device_id swap, the to/from text rewrite with a spoofed from, 8 negatives) are generated, independently verified (0 lỗi, 0 lệch, mutation-tested), schema-checked and pushed.
Concerns/Blockers: the spec's 1,000-character SMS cut can exceed the 3,000-character env_b64 limit for Vietnamese text (proposal 1); malformed-frame handling on the relay is an interpretation (proposal 5).
