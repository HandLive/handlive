# Phase 3 — shared sync 1: checker fix and catalog rows of call spec sync 1

Follow-up of `phase-03-spec-sync-1.md` (hub `main` up to a00681b). Repository handlive-shared, branch
`feat/phase-03-calls`. Every commit was made and pushed under the workspace lock `.locks/shared`, which was
released after each batch. CI `ci-shared` is green on the new head (see Checks).

## 1. Schema checker fix (urgent)

The CALL-02 API 1 error table now lists `INTERNAL` as its last row. `tools/schemas/call_spec_checks.py` appended
`INTERNAL` again before it compared the table with the `call_event/action` error enum, so `check_schemas.py` failed
with `INTERNAL` listed twice. The checker now compares the table codes alone. The enum stays as it was: the table
order is unchanged and `INTERNAL` is last. The description of `call_event-action#ack-failure` now says "INTERNAL
last" instead of "plus INTERNAL (0.8.1)". No schema rule and no example changed.

The spec sync also added `INTERNAL` to the prose error list of CALL-03 API 1 (same op). The schema already allows it.
`call_spec_checks` compares only the CALL-02 table; a comparison with the CALL-03 list can be added if you want one.

## 2. Catalog (`strings/ui-strings.json`, 373 → 393 strings)

The "New or changed UI texts for the catalog" table was applied exactly. The `en` and `vi` texts were taken from the
specs as they read at a00681b. Before writing, each new text was found verbatim in the English and Vietnamese docs
(dry run: "20 texts checked against the docs, 0 problems"). The file is written with the serializer that
round-trips the old file byte for byte. It also round-trips cc9bc2f, a commit another agent made on this branch
that widens `pairing.reason_missing_permission` to Android; that commit is untouched.

### New keys (20)

| Key | en | vi | Platforms | Specs |
|-----|----|----|-----------|-------|
| `permission.calls_primer_title` | See Calls on Your Mac and iPhone | Xem cuộc gọi trên Mac và iPhone | android | SET-01 |
| `notification.permission_call` | {device_name} needs call permission on this phone — tap to allow | {device_name} cần quyền cuộc gọi trên điện thoại — chạm để cho phép | android | SET-01 |
| `call.permission_instructions_title` | Grant Call Permission on Your Phone | Cấp quyền cuộc gọi trên điện thoại | macos, ios | PAIR-02 |
| `call.permission_instructions_body` | On your phone, open HandLive and go to Settings › Permissions & Background. Tap Grant Permission under Calls, or Open Settings if the permission was denied, and allow Phone, Call logs, and Contacts. | Trên điện thoại, mở HandLive và vào Cài đặt › Quyền và chạy nền. Chạm Cấp quyền ở mục Cuộc gọi, hoặc Mở cài đặt nếu quyền đã bị từ chối, rồi cho phép Điện thoại, Nhật ký cuộc gọi và Danh bạ. | macos, ios | PAIR-02 |
| `call.answer_tooltip` | Answer the call | Trả lời cuộc gọi | macos | CALL-01 |
| `call.decline_tooltip` | Decline the call | Từ chối cuộc gọi | macos | CALL-01 |
| `call.end_tooltip` | End the call | Kết thúc cuộc gọi | macos | CALL-03 |
| `settings.focus_permission_hint` | To ring, allow HandLive to read your Focus status in System Settings › Privacy & Security › Focus. | Để đổ chuông, hãy cho phép HandLive đọc trạng thái Tập trung trong Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Tập trung. | macos | SET-02, CALL-01 |
| `settings.quick_reply_add` | Add Quick Reply | Thêm tin trả lời nhanh | macos | CALL-02 |
| `settings.quick_reply_remove` | Remove Quick Reply | Xóa tin trả lời nhanh | macos | CALL-02 |
| `settings.quick_replies_footer` | Up to 6 replies of 160 characters. Choose one when you decline a call on this Mac. | Tối đa 6 tin, mỗi tin 160 ký tự. Chọn một tin khi từ chối cuộc gọi trên Mac này. | macos | CALL-02 |
| `call.empty_title` | No Calls Yet | Chưa có cuộc gọi | macos, ios | CALL-04 |
| `call.empty_body` | Calls from your phone appear here after the first sync. | Cuộc gọi từ điện thoại sẽ hiện ở đây sau lần đồng bộ đầu tiên. | macos, ios | CALL-04 |
| `call.type_incoming` | Incoming call | Cuộc gọi đến | macos, ios | CALL-04 |
| `call.type_outgoing` | Outgoing call | Cuộc gọi đi | macos, ios | CALL-04 |
| `call.type_missed` | Missed call | Cuộc gọi nhỡ | macos, ios | CALL-04 |
| `call.type_rejected` | Declined call | Cuộc gọi bị từ chối | macos, ios | CALL-04 |
| `call.type_blocked` | Blocked call | Cuộc gọi bị chặn | macos, ios | CALL-04 |
| `call.type_voicemail` | Voicemail | Thư thoại | macos, ios | CALL-04 |
| `a11y.missed_calls` | one "{count} missed call", other "{count} missed calls" | other "{count} cuộc gọi nhỡ" | macos, ios | CALL-04 |

`a11y.missed_calls` takes one `int` argument `count`, printed without digit grouping (0.12.1). `call.type_incoming` and
`call.type_missed` repeat the texts of `call.incoming_body` and `call.missed_call`. They are separate keys because the
meaning differs: a call type in a list row, not a notification body or placeholder.

### Existing keys changed (metadata only, no text changed)

- `permission.calls_primer`: the comment drops "Proposed text…" (the text is adopted in SET-01 field 12) and names
  its title key.
- `call.unknown_caller`: CALL-04 added to `specs`; the comment adds "the missed-call notification title without the
  call log, flow A (CALL-04 field 8, API 4)".
- `call.no_caller_id`: the comment now says "the missed-call notification title of a call log entry without number",
  to match the new CALL-04 field 8 rule.
- `call.missed_body`, `call.missed_body_sim`: the comments add the Mac menu bar's recent item for a missed call
  (CALL-04 API 4 logic 5).
- `call.missed_call`: the comment now cites CALL-04 API 4 for the `hiddenPreviewsBodyPlaceholder` instead of the
  design system.
- `call.mute_tooltip`: the comment now cites CALL-03 field 9 instead of the design system.
- `settings.quick_replies`: the comment now cites SET-02 field 33 and names the add, remove and caption keys.
- Unchanged, per the table: `call.incoming_body` (its comment already names `HL_CALL_INCOMING_MAC` and cites CALL-01
  API 6 and API 7), `push.call_incoming`, `push.call_missed`, `call.waiting_handle_on_phone` (already `macos`).

Keys for the platforms:
- **Android** (regenerate string resources): `permission.calls_primer_title`, `notification.permission_call`
  (`{device_name}`).
- **Apple** (regenerate with `generate-strings.py`; I rendered it in memory from the new catalog and all 11 files
  render; accessors include `L10n.A11y.missedCalls(count:)`, `L10n.Call.typeRejected`,
  `L10n.Call.permissionInstructionsBody`, `L10n.Settings.focusPermissionHint`): every other new key above.

## Commits (handlive-shared, branch `feat/phase-03-calls`)

| Hash | Subject |
|------|---------|
| 75128f8 | fix(shared): compare the call action error codes with the spec table as written |
| 64a73dd | feat(shared): add the call permission primer title, suggestion and instructions |
| ce5d151 | feat(shared): add the call panel tooltips and the Calls settings texts |
| 1a87a80 | feat(shared): add the call list empty state, call type labels and missed-call badge |

Every commit is signed off with no AI attribution. `.githooks/check-commits.sh origin/main..HEAD` printed "commit
sạch: đã kiểm 22 commit". Each catalog commit was checked with `check_strings.py --docs` before it was committed.

## Checks (real output, head 1a87a80)

```text
$ tools/.venv/bin/python tools/strings/check_strings.py
== strings/ui-strings.json: 393 strings, languages en, vi
== 393 strings, 0 errors, 0 warnings
OK

$ tools/.venv/bin/python tools/strings/check_strings.py --docs | tail -4
  en: 393 of 393 texts found in 50 English docs
  vi: 393 of 393 texts found in 50 Vietnamese docs
== 393 strings, 0 errors, 0 warnings
OK

$ tools/.venv/bin/python tools/strings/check_strings.py --self-test
self-test: 96 passed, 0 failed

$ tools/.venv/bin/python tools/schemas/check_schemas.py | tail -1
  XANH: mọi kiểm tra đạt

$ tools/.venv/bin/python tools/vectors/verify_vectors.py | tail -1
Tổng: 1485 phép kiểm, 0 lỗi
$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check
check: 20 file, 0 lệch
$ python3 tools/bench/self_test.py
bench self-test: 65 passed, 0 failed
$ tools/.venv/bin/python tools/bench/relay_load_self_test.py | tail -1
relay load self-test: 10 passed, 0 failed
```

CI `ci-shared`: run 36298126526 on 75128f8 (the checker fix, green), run 36298316595 on 1a87a80 (head, green).

## Spec deviations and proposals

None new. The texts match the specs word for word. Two notes:
- `settings.quick_reply_add` and `settings.quick_reply_remove`: the comments say "the add/remove button's label, or
  its accessibility label and tooltip when the button only shows + / −", because CALL-02 field 8 names the actions
  but not the control.
- The "please confirm" items of the spec sync report (the PAIR-02 permission set and the singular title, the App
  Group copy of `features.sms.can_send`) are not catalog questions. The catalog follows the specs as written.

Status: DONE
Summary: The call_spec_checks fix for INTERNAL is pushed (check_schemas XANH, CI green). The 20 new catalog texts and 8 metadata updates of call spec sync 1 are pushed; the catalog now has 393 strings with 0 errors and 0 warnings, --docs included, and CI is green on 1a87a80.
Concerns/Blockers: none.
