# Phase 2 — S2.2 [shared]: JSON Schemas for SMS, relay and push

Card S2.2 of `phase-02-sms-ios-relay.md`: JSON Schemas (draft 2020-12) for the `sms` ops and their ack data, the
relay routing wrapper and control messages (0.4.3, 0.7.3), the relay REST bodies and error body (0.7.4, 0.8.2) and
the push bodies (`POST /v1/push`, FCM, APNs — 0.4.4, CONN-04), wired into `tools/schemas/check_schemas.py` so that
every JSON example of the Phase 2 leaf specs is validated. Branch `feat/phase-02-sms-ios-relay` of handlive-shared,
pushed; CI `ci-shared` green (run 36219897826 on 131da2f). Committed under the workspace lock `.locks/shared`
(taken, `git pull --rebase`, released after the push).

## What was done

- **27 new schema files** (39 in total), same conventions as the existing ones (`$id` =
  `https://handlive.app/schemas/v1/<file>`, `$defs` reuse, `#/$defs/ack` for ops that ack with data, strict
  `additionalProperties: false`, sender-side strictness per 0.5.1 rule 6). New descriptions are in English.
  - `common.schema.json` + `b64u-16` (rv_id), `b64u-64` (Ed25519 signatures), `platform`; both new b64u patterns
    require the canonical last character.
  - **SMS:** `sms-common` (`$defs` thread, message, `synced-message` = message without `local_id`, `unread-entry`,
    `message-key` `^sms:[0-9]+$`, `thread-id`, `address`, `sub-id`), `sms-sync` (+ `ack`: `page_token` iff
    `has_more`, `unread` with `unread_count ≥ 1` only on the last page, ≤ 500 messages), `sms-history` (+ `ack`),
    `sms-new` (`local_id` allowed; also the push envelope content), `sms-send` (+ `ack` `{accepted: true, parts ≥ 1}`;
    exactly one address, body 1–1,600 characters and not whitespace only), `sms-status` (`error_code` iff
    `failed`, only the four sending errors), `sms-read_changed`, and `sms-notification` (the SMS-02 API 4
    notification content: identifier patterns and the `userInfo` M-APP, I-APP and I-NSE share — local, not a wire
    message, added because it is a ```json example of SMS-02).
  - **Relay:** `relay-wrapper` (`oneOf` `$defs/outbound` `{to, env}` / `$defs/inbound` `{from, env}`, `env` =
    envelope), one file per 0.7.3 control op — `relay-presence`, `relay-error` (codes of CONN-03 API 5),
    `relay-rv_join`, `relay-rv_joined`, `relay-rv_msg` (only `pair` envelopes), `relay-pair_revoked` — and
    `relay-rest` (`$defs` for every body of 0.7.4: `devices-request/response`, `auth-challenge-request/response`,
    `auth-token-request/response` (`expires_in` = 900), `push-token-request` (`topic` exactly with APNs, lowercase
    hex APNs token), `pairs-request` (attestation = b64u of 127 bytes starting with `HLPAIR1`), `pairs-response`,
    `pairs-list-response`, `pair-revoke-request`, `push-request` (wake ↔ wake reasons and no `env_b64`; alert ↔
    alert reasons and `env_b64` ≤ 3,000 characters), `push-response`, and `error-response` / `error-code` of 0.8.2).
  - **Push:** `push` (`$defs` `fcm-data` `{t: wake, p, r}`, `fcm-request` (HIGH priority, no `notification` block),
    `fcm-response`, `apns-payload`: `loc-key` ∈ {`push.sms_new`, `push.call_incoming`, `push.call_missed`}, no title
    or text, `mutable-content` 1, `thread-id` `sms:<n>` or `calls`, `time-sensitive` only with
    `push.call_incoming`, `hl` = b64 envelope).
  - **To cover every example of the Phase 2 leaf specs** (PAIR-01 over the rendezvous, PAIR-03, CONN-02 through the
    relay, CLIP-04): `pair-hello`, `pair-offer`, `pair-confirm`, `pair-done`, `pair-error` (`attempts_left` iff
    `PIN_INVALID`), `pair-revoke` (+ empty ack), `ping-ping` (+ ack), `clipboard-push` (+ ack; exactly one of
    `text`/`transfer`, images need `transfer`, `width`, `height`), `clipboard-conflict`, `clipboard-cancel`.
- **Checker** (`check_schemas.py`, `doc_examples.py`, new `relay_sms_spec_checks.py`):
  - Every `$defs` gets a validator `<file>#<def>` (`sms-sync#ack`, `relay-rest#push-request`, `push#apns-payload`).
  - Examples: scoped ops now include `sms`, `pair`, `ping`, `clipboard`; an ok ack under `WS <type>/<op>` uses that
    op's `#ack`; relay frames are recognized by shape (`{op, …}` without `data`, `{to|from, env}`, `{error}`), REST and
    push bodies by the heading of their API section and their fields, the SMS notification by its `HL_SMS` category;
    JSON bodies inside ```http blocks are read too (SMS-02 API 2, PAIR-01 API 8, PAIR-03 API 3); `env_b64`/`hl`
    must decode to a valid envelope. New placeholder rules: `sig`, `sig_a`, `sig_b`, `attestation`, `access_token`,
    `token`, `env_b64`, `hl`, `prk_check`, `by`, `code`, `message`.
  - **Result: every JSON example of 01–05 (English and Vietnamese) is classified and validated** — 191 examples in
    01–08; the 63 still skipped are the call, call audio and camera examples of later phases.
  - Table checks against the specs: the 7 `sms` ops of 0.7.1 = the `sms-<op>` files and the "with data" rows have
    `$defs/ack`; the 6 ops of 0.7.3 = the `relay-<op>` files; the 10 endpoints of 0.7.4 = the endpoint → body map
    and every `relay-rest` body is mapped; 0.8.2 codes = `error-code`; CONN-04 API 2 `reason` enum; CONN-04 API 4
    `loc-key`s = the APNs enum and each is an iOS `push.*` key of the catalog.
  - Section 5: wire messages of the test vectors — `relay-auth.json` requests (6), and `pairs_request`,
    `hello/offer/confirm/done_plaintext` of `pair-handshake.json` (3 × 5) — pass their schemas.
  - Samples: `sample_messages_sms.py` (22 positive, 49 negative) and `sample_messages_relay.py` (30 positive, 52
    negative); every negative sample breaks exactly one rule.
  - Mutation test (scratch script on a copy of the docs, `HANDLIVE_DOCS_DIR`): 15 single mutations — an sms ack
    without `has_more`, a failed status without `error_code`, a draft box, `limit` 500, an APNs `push.generic`
    loc-key, a renamed loc-key in the CONN-04 table, a wake with an alert reason, a wrapper `to` that is not a
    UUIDv8, FCM `NORMAL` priority, a 21-character `rv_id`, an unknown `peer_platform`, an extra 0.8.2 code, an extra
    0.7.3 op, an extra 0.7.4 endpoint, an extra `sms` op in 0.7.1 — are all caught; the unmutated control passes.
- **Docs:** `schemas/README.md` + `.vi.md` (file table, usage on `/v1/relay`, strict conventions for SMS,
  clipboard, relay, push), `tools/schemas/README.md` + `.vi.md` (steps 1, 2, 3, 5, placeholder table), top-level
  `README.md` + `.vi.md` and `CLAUDE.md` (schema list).

## Commits (handlive-shared, branch `feat/phase-02-sms-ios-relay`)

| Hash | Subject |
|------|---------|
| 33af9ba | feat(shared): add b64u-16, b64u-64 and platform to common.schema.json |
| 6971386 | feat(shared): add JSON Schemas for the sms ops and their ack data |
| 5a12000 | feat(shared): add JSON Schemas for the pairing, ping and clipboard payloads |
| dfcd8d7 | feat(shared): add JSON Schemas for relay frames, relay REST and push bodies |
| 261adf1 | test(shared): check the SMS, relay and push schemas against the specs and vectors |
| 131da2f | docs: describe the SMS, relay and push schemas and their checks |

All signed off; `.githooks/check-commits.sh origin/main..HEAD` → "commit sạch: đã kiểm 10 commit".

## Files

New: `shared/schemas/{sms-common,sms-sync,sms-history,sms-new,sms-send,sms-status,sms-read_changed,sms-notification,
pair-hello,pair-offer,pair-confirm,pair-done,pair-error,pair-revoke,ping-ping,clipboard-push,clipboard-conflict,
clipboard-cancel,relay-wrapper,relay-presence,relay-error,relay-rv_join,relay-rv_joined,relay-rv_msg,
relay-pair_revoked,relay-rest,push}.schema.json`, `shared/tools/schemas/relay_sms_spec_checks.py`,
`sample_messages_sms.py`, `sample_messages_relay.py`.
Changed: `shared/schemas/common.schema.json` (contract: new `$defs` only), `shared/tools/schemas/check_schemas.py`,
`doc_examples.py`, READMEs, `CLAUDE.md`.

**For the other agents (re-run your tests; platform CIs do not run on shared changes):**
- Android (`core/protocol`) and Apple (`HLProtocol`): validate the SMS messages you emit with `sms-*.schema.json`
  (`sms-sync.schema.json#/$defs/ack` for the sync ack…), the clipboard messages with `clipboard-*`, pairing with
  `pair-*`; Apple's notification service extension and apps with `sms-notification.schema.json` (userInfo).
- Relay: control frames `relay-<op>.schema.json`, the wrapper `relay-wrapper.schema.json`, REST bodies
  `relay-rest.schema.json#/$defs/<body>` and error bodies `#/$defs/error-response`, FCM/APNs bodies
  `push.schema.json#/$defs/fcm-request|apns-payload`. Load the whole directory into the validator registry.

## Tests (real output, from `shared/`)

```text
$ tools/.venv/bin/python tools/schemas/check_schemas.py | tail -16
  PASS pair-handshake.json: 3 × done_plaintext
== Tổng kết
  schema hợp lệ metaschema: 39
  $ref phân giải được: 194
  enum khớp bảng spec: 16
  loc-key có trong catalog: 3
  ví dụ 00-common-specs: 6
  ngoài phạm vi S0.2 (bỏ qua): 63
  ví dụ 01–08: 191
  payload bắt tay giải từ envelope: 2
  envelope trong env_b64/hl: 13
  mẫu dương tự viết: 65
  mẫu âm bị từ chối: 138
  ví dụ catalog chuỗi giao diện: 1
  tin trong test vector: 21
  XANH: mọi kiểm tra đạt

$ tools/.venv/bin/python tools/strings/check_strings.py | tail -1        → OK
$ tools/.venv/bin/python tools/vectors/verify_vectors.py | tail -1       → Tổng: 1128 phép kiểm, 0 lỗi
$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check       → check: 18 file, 0 lệch
$ python3 tools/bench/self_test.py                                       → bench self-test: 22 passed, 0 failed
$ gh run list -R HandLive/handlive-shared --branch feat/phase-02-sms-ios-relay --limit 1
completed  success  docs: describe the SMS, relay and push schemas and their checks  ci-shared  push  36219897826
```

## Spec deviations and proposals (hub not edited)

1. **0.7.1 `sms/send` ack.** The table says "Yes", but SMS-04 API 1 returns `ack.data {accepted, parts}`. The schema
   has `sms-send.schema.json#/$defs/ack`. Proposal: "Yes (with data)" in 0.7.1.
2. **`collapse_key` of an SMS push disagrees.** SMS-02 API 2 and the CONN-04 API 4 table: `sms:<message_key>`
   (giving `sms:sms:12847`); CONN-04 step 5b: `sms:<thread_id>`; the CONN-04 API 2 example: `sms:118`. The schema only
   limits it to 64 characters. Proposal: keep `sms:<message_key>` (one notification per message) and fix step 5b
   and the example — and consider `sms:<_id>` to avoid the doubled prefix.
3. **`env_b64` "≤ 3,000 bytes"** does not say bytes of what; the schema limits the b64 text (what goes into the
   4 KB APNs payload as `hl`) to 3,000 characters. Proposal: say "≤ 3,000 characters of b64".
4. **The group-conversation notification category** (SMS-02 API 4 logic 2, "a category without `HL_SMS_REPLY`") has
   no name; `sms-notification` accepts `HL_SMS` and `HL_SMS_<NAME>`. Proposal: name it `HL_SMS_GROUP`.
5. **Unstated but enforced** (sender strictness; say so in the specs or tell me to relax): `unread` entries of the
   sync ack have `unread_count ≥ 1`; `pair/error` `attempts_left` is required with `PIN_INVALID` and ≤ 3; images in
   `clipboard/push` require `width` and `height` ("Images only" in CLIP-01 API 5); `topic` is forbidden with `fcm`;
   the APNs token is lowercase hex; `expires_in` is exactly 900; `ttl_s ≥ 0` (no upper bound given).
6. **PAIR-01 API 7 example:** the `env.payload` of `rv_msg` decodes to `{"op":"hello","data":{}}`, which is not a
   valid `pair/hello`. The checker does not decode nested payloads, so it passes; proposal: use the `hello_envelope`
   of `test-vectors/pair-handshake.json` or `"<b64>"`.
7. **`relay-error` mixes code tables:** `NOT_CONNECTED` is an 0.8.1 code and `NOT_PAIRED` an 0.8.2 code; the
   schema lists exactly the five codes of CONN-03 API 5 (which also cover PAIR-01 API 7). Proposal: list them in
   0.7.3 next to the `error` op.
8. **0.4.3** writes the wrapper as `{"to":"<device_id>","env":{<envelope>}}`, which is not JSON, so it stays
   unchecked (the CONN-03 API 6 examples are checked).

## Pending manual checks

None for the schemas. The Android, Apple and relay agents still have to validate the messages they emit against
these files in their own test suites (their cards).

Status: DONE
Summary: 27 JSON Schemas (SMS ops and acks, pairing/ping/clipboard payloads, relay wrapper and control ops, relay REST and error bodies, FCM and APNs bodies) are committed and pushed; check_schemas.py validates every JSON example of the Phase 2 leaf specs in both languages, cross-checks five spec tables, the push catalog keys and the vector messages, and prints XANH (mutation-tested).
Concerns/Blockers: none; the specs disagree on the SMS push collapse_key (proposal 2).
