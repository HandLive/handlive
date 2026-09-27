# Phase 3 — S3.2 [shared]: JSON Schemas for calls

Card S3.2 of `phase-03-cuoc-goi.md`: JSON Schemas (draft 2020-12) for the `call_event` ops of CALL-01…04 and the
call notification content, wired into `tools/schemas/check_schemas.py` so that every JSON example of
`06-call-control.md` (English and Vietnamese) is validated. Branch `feat/phase-03-calls` of handlive-shared, pushed
under the workspace lock; CI `ci-shared` green (run 36295428294 on e38abbf). `check_schemas.py` prints `XANH`.

## What was done

New schemas (`shared/schemas/`), same style and `$defs` reuse as the SMS ones:

| File | Content |
|------|---------|
| `call_event-common.schema.json` | `$defs` only: `call-id` (UUIDv7), `number` (e164 or original string, null), `display-name` (non-empty or null), `sub-id` (int32 ≥ 0 or null), `entry-id` (int64 ≥ 1), `call-type` (the six types), `entry` (the CALL-04 shared object, all 7 fields required) |
| `call_event-state.schema.json` | `call_event/state` (also the plaintext of the `call_incoming` push and of the flow-A `call_missed` push); `$defs/state-data`, `$defs/controls`, `$defs/hfp-control` |
| `call_event-action.schema.json` | `call_event/action` (`audio` only with `answer`); `$defs/ack` = success with empty `data`; `$defs/ack-failure` = the CALL-02 API 1 codes (+ `INTERNAL`) with required details: `CALL_HFP_REQUIRED` → `details.action` ∈ hold/unhold/dtmf/mute, `PERMISSION_MISSING` → `details.permission` = `android.permission.ANSWER_PHONE_CALLS`, `CALL_ACTION_NOT_ALLOWED` → `details` `{state, reason}` (`waiting`/`platform` only while ringing, `system` while ringing or offhook) |
| `call_event-log_sync.schema.json` | `call_event/log_sync` (`limit` 1–500, opaque b64u `cursor`); `$defs/ack` = page `{entries ≤ 500, cursor, has_more, reset}`; `$defs/ack-failure` = FEATURE_DISABLED, PERMISSION_MISSING (`details.permission` = `android.permission.READ_CALL_LOG`), BAD_REQUEST, INTERNAL |
| `call_event-log_new.schema.json` | `call_event/log_new` `{entry, call_id | null}` (also the plaintext of the `call_missed` push with `READ_CALL_LOG`) |
| `call-notification.schema.json` | Local content, not a wire message (like `sms-notification`): `$defs/incoming` (HL_CALL_INCOMING / HL_CALL_INCOMING_MAC, thread `calls`, Mac identifier = `call_id`, `interruptionLevel` passive/timeSensitive, `userInfo {pair_id, call_id, started_at}`) and `$defs/missed` (identifier `call-missed:<pair_id>:<entry_id|call_id>`, thread `calls:<pair_id>` or the push's `calls`, HL_CALL_MISSED only with a number, `userInfo {pair_id, entry_id, call_id, number, sub_id}` all present, at least one of `entry_id`/`call_id` non-null) |

`call_event/state` restates the context rules of CALL-01 API 1 (logic 2 and 5) as `allOf` rules, so a sender cannot
emit an impossible state: `ended_at`/`end_reason` exactly when `idle`; a number exactly when `presentation = allowed`,
a name only with a number (also for the waiting caller); `waiting = true` only while `state = ringing`, `waiting_*`
null otherwise; `sim_label` only with a `sub_id`; outgoing → `presentation = unknown`; outgoing/unknown → no
`answered_at`, end only as `ended`; incoming and (offhook, waiting or ended) → `answered_at`; ringing without a
waiting call, or missed/rejected/answered elsewhere → no `answered_at`; `controls.answer`/`reject` need ringing
without a waiting call and `answer` implies `reject`; `end` needs offhook; `hold` = `dtmf` = `hfp` exactly when
offhook with `hfp_connected`; `mute` = `hfp` exactly when also `audio_on = mac`.

`call_event/hfp_status` has **no schema**: its fields are defined only in AUDIO-02 API 3 (`07-call-audio.md`), not in
00-common-specs or CALL-03 API 4 (see deviation 1).

Checker wiring (`tools/schemas/`):
- `doc_examples.py`: `call_event` added to the scoped heading types (`WS call_event/<op>`); an error ack under such a
  heading uses `<type>-<op>#ack-failure` when it exists; the call notification content is recognized by its
  `HL_CALL_INCOMING…` category, its `call-missed:` identifier or `HL_CALL_MISSED`.
- `call_spec_checks.py` (new): `call_event` ops vs 0.7.1 (one file each, `$defs/ack` for the ops with an ack,
  `hfp_status` deferred), `CALL_ACTION_NOT_ALLOWED` `details.reason` vs 0.8.1, `call-type` vs the 0.9.3
  `call_log_entry.type` CHECK, and from `06-call-control.md`: state data fields and required list, `controls`
  fields and enums (CALL-01 API 1), action fields, `action`/`audio` enums and error codes in check order (CALL-02
  API 1), the `entry` fields and type enum, log_sync request/ack fields and error codes, log_new fields (CALL-04 API
  1–2), and the `userInfo` fields of both notifications (CALL-01 API 6, CALL-04 API 4). 25 checks; a scratch
  mutation run (field dropped, not required, renamed or added; enum value added, removed or reordered; ack or
  schema file removed) was caught 18/18.
- `sample_messages_call.py` (new): 48 positive samples (every state/direction/end reason, HFP and non-HFP controls,
  call waiting, all actions and error acks, log_sync pages including an empty log and a reset, log_new
  matched/unmatched, incoming notifications on iPhone and Mac and a late push, missed notifications with and
  without the call log and from a push) and 75 negatives, each breaking exactly one rule.
- `check_schemas.py`: calls `call_spec_checks` and loads the new samples.

Every ```json example of `06-call-control.md` and `.vi.md` is now validated by a specific schema (12 per language:
3 × `call_event-state`, 4 × `call_event-action` + 2 acks + 2 error acks, 2 × `call_event-log_sync` + 2 acks,
`call_event-log_new`, `call-notification#incoming`, `call-notification#missed`; plus `sms-send` and the two
```http push bodies, which were already checked). The CALL-01 API 4 / CALL-04 API 5 push bodies keep a `<b64: …>`
placeholder that the checker fills with a generic envelope; the real call push envelopes are pinned by the S3.3
vectors.

Existing push schemas were re-checked against CALL-01 API 4, CALL-04 API 5 and CONN-04: `relay-rest#push-request`
already pins `call_incoming` → `collapse_key` `call:<UUIDv7>` (41 characters, within 1–64 visible ASCII) and
`ttl_s` 30; `call_missed` → `call:<UUIDv7>` or `calllog:<digits>` and `ttl_s` 86,400; `push#apns-payload` →
`push.call_incoming` time-sensitive and `push.call_missed` active, both in thread `calls`. No change needed.

## Commits (handlive-shared, branch `feat/phase-03-calls`)

| Hash | Subject |
|------|---------|
| 2c7fe0b | feat(shared): add JSON Schemas for the call_event messages |
| cdb701b | feat(shared): add the call notification content schema |
| f25a290 | test(shared): check the call examples, spec tables and samples against the call schemas |
| e38abbf | docs: describe the call schemas and their checks |

Each commit was checked in isolation (`check_schemas.py` → XANH with only its files staged). All signed off;
`.githooks/check-commits.sh origin/main..HEAD` → "commit sạch: đã kiểm 9 commit".

## Files

Created: `shared/schemas/call_event-common.schema.json`, `call_event-state.schema.json`,
`call_event-action.schema.json`, `call_event-log_sync.schema.json`, `call_event-log_new.schema.json`,
`call-notification.schema.json`; `shared/tools/schemas/call_spec_checks.py`, `sample_messages_call.py`.
Changed: `shared/tools/schemas/doc_examples.py`, `check_schemas.py`, `README.md`, `README.vi.md`;
`shared/schemas/README.md`, `README.vi.md`; `shared/README.md`, `README.vi.md`, `CLAUDE.md`.

**Shared change for the other platforms:** new schemas only (no existing schema changed). Android (`core/protocol`
tests) and Apple (`HLProtocol` tests) should validate the `call_event` messages they emit against them:
Android → `call_event-state`, `call_event-action#ack`/`#ack-failure`, `call_event-log_sync#ack`/`#ack-failure`,
`call_event-log_new`; Apple → `call_event-action`, `call_event-log_sync`, and the notification content against
`call-notification#incoming`/`#missed` if their tests build it as JSON.

## Tests (real output, from `shared/`)

```text
$ tools/.venv/bin/python tools/schemas/check_schemas.py | tail -15
== Tổng kết
  schema hợp lệ metaschema: 45
  $ref phân giải được: 250
  enum khớp bảng spec: 41
  loc-key có trong catalog: 3
  ví dụ 00-common-specs: 6
  ngoài phạm vi S0.2 (bỏ qua): 39
  ví dụ 01–08: 215
  payload bắt tay giải từ envelope: 2
  envelope trong env_b64/hl: 31
  mẫu dương tự viết: 117
  mẫu âm bị từ chối: 232
  ví dụ catalog chuỗi giao diện: 1
  tin trong test vector: 52
  XANH: mọi kiểm tra đạt
```

Before this card: 39 schemas, 16 table checks, 191 doc examples (the call ones were skipped or only checked as a
generic ack), 69 positive / 157 negative samples. `check_strings.py --docs`: 373 strings, 0 errors, 0 warnings.
CI `ci-shared` run 36295428294 on e38abbf: success.

## Spec deviations and proposals (hub not edited)

1. **`call_event/hfp_status`** is listed in 0.7.1 but its fields (`connected`, `audio_connected`,
   `mac_is_active_device`, optional `active_device_name`, `codec`) exist only in AUDIO-02 API 3
   (`07-call-audio.md`); CALL-03 API 4 refers there. Per the card, no schema now. Proposal: add the schema with the
   call-audio phase, or list the fields in 0.7 if Phase 3 clients must read it.
2. **CALL-02 API 1 error table** lists six codes; any request may also fail with `INTERNAL` (0.8.1), which CALL-04
   API 1 lists for `log_sync`. The schema allows `INTERNAL`. Proposal: add `INTERNAL` to the CALL-02 API 1 table.
3. **`waiting = true` implies `state = ringing`** follows from API 1 logic 2 (OFFHOOK → RINGING sets `waiting`,
   RINGING → OFFHOOK clears it) and is enforced; the field table does not say it. Proposal: write it in the
   `waiting` row. Likewise the other `allOf` rules above are readings of logic 2 and 5 — if Android finds a device
   that breaks one, the spec (and then the schema) must say what to send.
4. **Missed-call `userInfo`** (CALL-04 API 4) lists the keys without saying which can be null. The schema requires
   all five keys, allows null for `entry_id` (flow A), `call_id` (no match), `number`, `sub_id`, and requires one of
   `entry_id`/`call_id`. Proposal: say so in the table.
5. **Notification enum spelling**: the spec writes Swift values (`.passive`, `.timeSensitive`); the JSON form uses
   `passive`, `timeSensitive`. The incoming content has no `sound` (CALL-01 API 6/7 tables list none), the missed
   content has `sound: default` (CALL-04 API 4).
6. `entry_id` ≥ 1 (the provider's `_ID`); the empty-log cursor `{"v":1,"id":0}` only appears inside the opaque
   cursor, so it is not affected.

## Pending manual checks

- None for the schemas themselves. The platform agents' tests should validate their emitted `call_event` messages
  against these schemas; the call push envelopes of S3.3 are validated by `check_schemas.py` step 5.

Status: DONE
Summary: Six call schemas (state, action with success and error acks, log_sync with page and error acks, log_new, the shared entry, the notification content) and a table checker are pushed on feat/phase-03-calls; every JSON example of 06-call-control is validated, check_schemas prints XANH and CI is green.
Concerns/Blockers: call_event/hfp_status has no schema because only AUDIO-02 defines its fields (deviation 1).
