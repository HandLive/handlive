# Phase 2 — shared sync 1: catalog, schemas and vectors after spec sync 1

Follow-up of `phase-02-spec-sync-1.md` (hub main up to 427d911) and the relay reports `phase-02-R2.1.md` /
`phase-02-R2.2.md`. Repository handlive-shared, branch `feat/phase-02-sms-ios-relay`, all commits pushed under the
workspace lock (work done in a private git worktree, pushed from there, main `shared/` checkout fast-forwarded).
CI `ci-shared` green on the new head (see Checks).

## Commits (handlive-shared)

| Commit | Message |
|--------|---------|
| 2dd4a46 | feat(shared): record the specs that now quote existing catalog strings |
| ac85789 | feat(shared): add the texts the specs define for settings, setup, relay, clipboard and SMS |
| 5b3abdb | feat(shared): use the generic APNs thread and message_key collapse keys for pushes |
| 66d0fe9 | feat(shared): never echo a destination with a relay BAD_REQUEST error |
| b843623 | feat(shared): allow only the HL_SMS and HL_SMS_GROUP notification categories |
| 8020d98 | docs: describe the push, relay error and SMS notification schema rules |
| 622610f | feat(shared): add push vectors for the SMS text cut |
| 6ad236e | test(shared): check the SMS text cut of push vectors independently |
| 68d9508 | docs: describe the SMS text cut vectors and the push collapse keys |
| c24614d | docs: state the ttl_s the phone sends with each push reason |
| 2a221e9 | feat(shared): pin the ttl_s the phone sends with each push reason |
| 13e6536 | feat(shared): refuse spaces in a push collapse_key |
| b07271f | docs: say that a push collapse_key has no spaces |

c24614d (docs) landed one push before its feat commit 2a221e9 because a failed shell step skipped the first commit;
pushed history not rewritten, the pair is consistent from 2a221e9 on.

## 1. UI string catalog (`strings/ui-strings.json`, 288 → 304 strings)

New keys (16 from the spec-sync tables + the SET-02 field 28 confirm buttons):

| Key | en / vi | Platforms | Spec |
|-----|---------|-----------|------|
| `settings.remove_from_server_confirm` | Remove from Server / Xóa khỏi máy chủ | all | SET-02 field 28 |
| `settings.delete_all_confirm` | Delete All / Xóa toàn bộ | all | SET-02 field 28 |
| `setup.notifications_denied_ios` | SET-03 E3 iPhone/iPad text | ios | SET-03, CONN-04 |
| `setup.local_network_denied_ios` | SET-03 E4 iPhone/iPad text | ios | SET-03, CONN-01 |
| `permission.local_network_primer` | body of the local network primer | macos, ios | SET-03 |
| `error.relay_rate_limited` | Too many requests. Trying again in {duration}. (arg `duration`) | macos, ios | CONN-03 E6 |
| `error.relay_pin_mismatch` | certificate not trusted | macos, ios | CONN-03 E7 |
| `clipboard.paste_hint` | Tap Paste to send what you just copied. | ios | CLIP-04 field 1 |
| `clipboard.nothing_received_body` | empty-state sentence | ios | CLIP-04 field 10 |
| `error.sms_sync_storage` | Couldn't save messages on this device | macos, ios | SMS-01 E7 |
| `sms.empty_body` | empty-state sentence | macos, ios | SMS-03 E1 |
| `error.sms_history_failed` | Couldn't load older messages | macos, ios | SMS-03 E4 |
| `a11y.sms_bubble_received` | {sender}, {time} | macos, ios | SMS-03 |
| `a11y.sms_bubble_sent` | You, {time}, {status} / Bạn, {time}, {status} | macos, ios | SMS-03 |
| `sms.recipient_label` | To: / Đến: | macos, ios | SMS-04 field 1 |
| `sms.choose_sim` | Choose SIM / Chọn SIM | macos, ios | SMS-04 field 4, E6 |

Changed keys (text unchanged, metadata only): `common.on`, `common.off`, `settings.auto_send`,
`settings.sms_messages` (+SET-01, feature card); `settings.calls` (platforms android + macos, +SET-01);
`common.delete` (now only the SET-02 E7 alert; field 28 uses the two confirm keys); `sms.compose_placeholder`
(+SMS-02 quick reply); `pairing.reason_missing_sms_permission` (+SMS-04); `sms.unread_count` (+SMS-05);
comments of `sms.sync_downloaded` (no digit grouping), `sms.char_counter` (`{limit}` = capacity of the current number
of parts: 160 or 153 × parts, 70 or 67 × parts) and `sms.char_count`.
SET-02 E7 buttons reuse `common.delete` + `common.cancel`. Mac SET-03 E3/E4 texts already equal
`setup.notifications_denied_mac` / `setup.local_network_denied_mac` (checked word for word).

## 2. Schemas

- `push.schema.json`: APNs `thread-id` ∈ {`sms`, `calls`} (sms_new → `sms`); FCM `android.ttl` `0s`–`60s`
  (min(ttl_s, 60)), `android.collapse_key` required and always `wake`.
- `relay-rest.schema.json` `push-request`: `ttl_s` 0–86,400; `collapse_key` 1–64 chars of 0x21–0x7E; per reason:
  `sms_new` → `sms:<digits>` (the message_key) and `ttl_s` 86,400; `call_incoming` → `call:<uuidv7>` and `ttl_s` 30;
  `call_missed` → `call:<uuidv7>` or `calllog:<digits>` and `ttl_s` 86,400; wakes keep the plain range.
  409 `PUSH_TOKEN_MISSING` was already in the error codes (checked against 0.8.2).
- `relay-error.schema.json`: codes `NOT_PAIRED`, `NOT_CONNECTED`, `PAYLOAD_TOO_LARGE`, `RATE_LIMITED`, `BAD_REQUEST`
  (descriptions per CONN-03 API 6); `BAD_REQUEST` never carries `to`.
- `sms-notification.schema.json`: `categoryIdentifier` ∈ {`HL_SMS`, `HL_SMS_GROUP`}; I-NSE sets `threadIdentifier`
  after decrypting.
- Already in place since S2.2, re-checked: `unread_count ≥ 1` in sync `unread`, `pair/error` `attempts_left` 0–3 iff
  `PIN_INVALID`, clipboard images require `width`/`height`.
- Samples (checker counts 63 → 69 positive, 138 → 157 negative): new positives for an incoming call push, a missed
  call push keyed by the call log, a wake with a collapse key and a group SMS notification; new negatives (doubled `sms:sms:` prefix, per-thread collapse key, call-log key on an incoming call, SMS key on a
  missed call, ttl_s 86,401 / −1 / 60 on a call / 3,600 on an SMS / 30 on a missed call, non-ASCII, space and tab in
  collapse_key, BAD_REQUEST echoing `to`, FCM ttl `86400s`, FCM collapse key not `wake` or missing, APNs SMS in
  `calls`, APNs `sms:42`, undefined notification category).

## 3. Vectors (`test-vectors/push-envelope.json`, 5 → 10 vectors, 9 negatives unchanged)

- Existing SMS pushes: `collapse_key` / `apns-collapse-id` `sms:12847` and `sms:12850` (was `sms:sms:…`), APNs
  `thread-id` `sms` (was `sms:42` / `sms:57`). Call push unchanged (`call:<call_id>`, `ttl_s` 30, `calls`).
- Five new `kind = "envelope"` sms/new pushes (pair 2) carrying a `truncation` object (`original_body`,
  `original_snippet`, `steps`, `body_code_points`, `body_utf16_units`, `snippet_code_points`, `env_b64_length`, and
  after a fit step `one_more_code_point_env_b64_length`):

| Name (after "pair 2 / sms/new, ") | Steps | Result |
|------|-------|--------|
| Vietnamese body over 1,000 characters, cut further until env_b64 fits | body_to_1000, body_to_fit | 1,257 → 818 code points (817 + "…"), env_b64 3,000 (one more → 3,004) |
| ASCII body over 1,000 characters, cut at 1,000 | body_to_1000 | 1,229 → 999 + "…", env_b64 2,832 |
| body of exactly 1,000 characters, not cut | — | kept, env_b64 2,832 |
| emoji at the 1,000-character cut (code points, not UTF-16 units) | body_to_1000 | 997 ASCII + 🎉🎉 + "…" = 1,000 code points = 1,002 UTF-16 units |
| crowded group conversation: body down to "…", then the snippet cut | body_to_ellipsis, snippet_to_fit | 42 addresses; body "…", snippet 160 → 89 (88 + "…"), env_b64 3,000 (one more → 3,004) |

- Rule pinned (generator `tools/vectors/push_sms_truncation.py`): lengths in code points; cut(text, m) = text if ≤ m
  code points else first m − 1 + "…"; body > 1,000 → cut(body, 1000); while env_b64 > 3,000 → largest m below the
  current length that fits; if not even "…" fits → body "…", snippet cut the same way; snippet itself = newest body
  cut to 160 code points without "…" (SMS-01). A Python port of Android `PushEnvelopeBuilder.fit` (binary search on
  `cut(max)`) gives the same five results.

## Checks (final head b07271f, local; CI same steps)

- `check_strings.py`: `== 304 strings, 0 errors, 0 warnings`; `--self-test`: `96 passed, 0 failed`;
  `--docs`: `== 304 strings, 0 errors, 12 warnings` — same 12 as at 335018c (before this work), none added.
- `check_schemas.py`: `XANH: mọi kiểm tra đạt` — doc examples 00: 6, 01–08: 191; positive samples 69; negative
  samples rejected 157; catalog example 1; wire messages in vectors 52 (push-envelope: 8 push_request, 8 apns_payload,
  7 sms/new plaintexts); envelopes inside env_b64/hl 31. Before 5b3abdb it failed on 03-connectivity.md:880 and
  .vi.md:867 (`thread-id` `sms`) — the two CI failures of runs 36223683048 and 36224359330.
- `verify_vectors.py`: `Tổng: 1397 phép kiểm, 0 lỗi` (push-envelope.json 10 vectors, 9 negatives, 207 checks).
- `generate_vectors.py --check`: `check: 20 file, 0 lệch`.
- Mutation tests (scratch, not committed): 18/18 cut mutations caught (cut keeping m code points, cut without "…",
  UTF-16 cut, limit 999, fit one code point short, snippet with "…", edited steps/lengths/original texts, dropped
  cases, removed truncation object); 20/20 earlier push/relay mutations still caught with the new expectations.
- CI `ci-shared`: 36225277136 (68d9508) success, 36225432990 (2a221e9) success, 36225551006 (b07271f, head)
  success; 36225409778 (c24614d) cancelled by the next push.

## What the platforms must change

**Android**
- Regenerate string resources: new all-platform keys `settings.remove_from_server_confirm`,
  `settings.delete_all_confirm` (SET-02 field 28 buttons); `common.delete` only for the SET-02 E7 alert;
  `settings.calls` now android + macos (feature card name).
- `PushEnvelopeVectorTest` (`assertEquals(3, envelopes.size)`) and `PushRequestVectorTest`
  (`assertEquals(3, requests.size)`) now see 8; `theSmsPushCollapsesPerMessageAndLivesADay` can assert
  `collapseKey == "sms:12847"` exactly (the doubled-prefix comment is obsolete).
- Add a vector test for `PushEnvelopeBuilder`: for each vector with `truncation`, put `original_body` /
  `original_snippet` back into the decoded plaintext, run the cut, compare body and snippet with the vector plaintext.
  Needs the same compact UTF-8 bytes as the vectors (non-ASCII unescaped, `display_name` null written, `ts_sent` /
  `sub_id` written).
- Pushes must satisfy the pinned schema: `ttl_s` 86,400 (sms_new, call_missed), 30 (call_incoming); `collapse_key`
  `sms:<_id>` / `call:<call_id>` / `calllog:<entry_id>`, no spaces.

**Apple**
- Regenerate String Catalogs: `setup.notifications_denied_ios`, `setup.local_network_denied_ios`,
  `permission.local_network_primer`, `error.relay_rate_limited` (`{duration}`), `error.relay_pin_mismatch`,
  `clipboard.paste_hint`, `clipboard.nothing_received_body`, `error.sms_sync_storage`, `sms.empty_body`,
  `error.sms_history_failed`, `a11y.sms_bubble_received` (`{sender}`, `{time}`), `a11y.sms_bubble_sent` (`{time}`,
  `{status}`), `sms.recipient_label`, `sms.choose_sim`, `settings.remove_from_server_confirm`,
  `settings.delete_all_confirm`.
- SET-02 field 28 confirm buttons → the two new keys; E7 alert → `common.delete` + `common.cancel`.
- Notifications: `HL_SMS_GROUP` category (only `HL_SMS_MARK_READ`) for conversations with several addresses; I-NSE
  sets `threadIdentifier` `sms:<pair_id>:<thread_id>` after decrypting; the vectors' APNs `thread-id` is now `sms`.
- `PushEnvelopeVectorTests` iterate all envelope vectors: the five cut vectors must decrypt (body can be "…", snippet
  cut; emoji body = 1,002 UTF-16 units).

**Relay**
- `crates/relay-push/tests/shared_push_vectors.rs`: drop the `thread.starts_with("sms:")` assert and the rewrite to
  `sms` — the vectors now carry `sms`; 8 push requests instead of 3 (`sent >= 3` still holds).
- No code change needed for the schemas: `BAD_REQUEST` without `to`, `collapse_key` visible ASCII ≤ 64
  (`is_ascii_graphic`), `ttl_s` 0–86,400, FCM ttl min(ttl_s, 60) and collapse `wake` already match. The per-reason
  `ttl_s` pins are a sender profile; the relay keeps accepting the whole range.

## Spec deviations and proposals

1. SET-02 field 28 "Delete All": the brief said "Xóa tất cả", the spec (01-setup-settings.vi.md field 28) says
   "Xóa toàn bộ" → catalog follows the spec.
2. `collapse_key` "printable ASCII": the schema uses 0x21–0x7E (no space) like the relay (`is_ascii_graphic`),
   because HTTP/2 forbids a header value that starts or ends with a space. Proposal: CONN-04 API 2 says "visible ASCII
   (0x21–0x7E)".
3. SMS cut (CONN-04 step 5b): the spec does not say how far each step shortens. Vectors pin "the longest cut that
   fits", "shortened" = strictly fewer code points (cut(text, m), m below the current count, as Android implements),
   body down to "…" before the snippet, snippet from SMS-01 cut to 160 code points without "…". Proposal: write these
   four points into step 5b and SMS-01 (snippet), plus "nothing fits → no push, SMS-01 catches up" (Android does this).
4. Per-reason `ttl_s` pinned in `push-request` (86,400 / 30 / 86,400) because SMS-02 API 2, CALL-01 API 4 and
   CALL-04 API 5 fix them; the API table still says the field is optional with defaults, which stays true for the
   relay.
5. The 12 `--docs` warnings (6 keys × 2 languages: `pairing.pin_instructions`, `setup.applications_drag_hint`,
   `setup.keys_failed`, `setup.login_item_approval_mac`, `status.connected_internet_to`, `status.connected_usb_to`)
   are texts the specs describe in prose, not quote. Proposal: quote them in PAIR-01, SET-03 and 0.11 so the check
   reaches 0.
6. Checker note: jsonschema (Python `re`) lets `$` match before a final newline, so a collapse_key ending in "\n"
   would pass the Python checker; platforms validating with full-match regex are stricter. Negatives use a tab inside
   the value.

## Unresolved questions

- Confirm the SMS cut reading of item 3 (especially body down to "…" before touching the snippet).
- Confirm "visible ASCII" for `collapse_key` (item 2) or ask the relay to accept inner spaces.

Status: DONE
Summary: Catalog (+16 keys, metadata changes), push/relay/notification schemas and push vectors (generic thread-id,
message_key collapse keys, pinned ttl_s, five SMS cut vectors with an independent checker) are pushed; all local
checks green, CI green.
Concerns/Blockers: none; items 2–3 need a spec confirmation.
