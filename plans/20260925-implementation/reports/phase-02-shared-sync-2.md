# Phase 2 — shared sync 2: catalog rows of spec sync 1, batches 6 and 7

Applies the table "Batches 6 and 7 — final rows for the shared catalog" of `phase-02-spec-sync-1.md` (Batch 7 —
Shared). Repository handlive-shared, branch `feat/phase-02-sms-ios-relay`, committed and pushed under the workspace
lock (taken 10:34:26Z, released 10:36:21Z). Catalog 304 → 312 strings.

## Commits (handlive-shared)

| Commit | Message |
|--------|---------|
| 3b979ea | feat(shared): point the data rows and View Instructions to their new alerts |
| e944c14 | feat(shared): add the unread badge, confirmation titles and SMS permission alert texts |
| 3cb90b8 | fix(shared): name the field 28 buttons in the confirmation message comments |

## Catalog changes

New keys (texts, platforms, args, specs and comments as in the table):

| Key | en / vi | Platforms | Specs |
|-----|---------|-----------|-------|
| `a11y.unread_conversations` | one "{count} unread conversation", other "{count} unread conversations" / other "{count} hội thoại chưa đọc" (arg `count` int) | macos, ios | SMS-02, SMS-05 |
| `setup.ios_limits_title` | How HandLive Works on iPhone and iPad / Cách HandLive hoạt động trên iPhone và iPad | ios | SET-03 |
| `common.close` | Close / Đóng | ios | CLIP-04 |
| `sms.permission_instructions_title` | Grant SMS Permission on Your Phone / Cấp quyền SMS trên điện thoại | macos, ios | SMS-01, PAIR-02 |
| `sms.permission_instructions_body` | On your phone, open HandLive and go to Settings › Permissions & Background. … / Trên điện thoại, mở HandLive và vào Cài đặt › Quyền và chạy nền. … | macos, ios | SMS-01, PAIR-02 |
| `common.ok` | OK / OK | macos, ios | SMS-01, PAIR-02 |
| `settings.remove_from_server_title` | Remove This Device from the Server? / Xóa thiết bị này khỏi máy chủ? | android, macos, ios | SET-02 |
| `settings.delete_all_data_title` | Delete All HandLive Data? / Xóa toàn bộ dữ liệu HandLive? | android, macos, ios | SET-02 |

Updated (text and platforms unchanged):
- `settings.remove_from_server`, `settings.delete_all_data`: comment "Row/button label of field 26/27 in Settings ›
  Data; the confirmation title is settings.…_title"; platforms stay android, ios (no `macos`: the Mac buttons are the
  `…_ellipsis` keys).
- `pairing.reason_missing_sms_permission`: specs + SMS-01; comment gets "; also the SMS-01 field 7 reason for E2".
- `common.view_instructions`: comment "Opens the SMS-01 field 7 alert (sms.permission_instructions_title / _body,
  common.ok)".
- Outside the table (3cb90b8): `settings.remove_from_server_warning` and `settings.delete_all_data_warning` still said
  "buttons common.cancel and common.delete", stale since sync 1 moved `common.delete` to the SET-02 E7 alert; they now
  name the question title and the `settings.*_confirm` + `common.cancel` buttons.

## Checks (real output, head 3cb90b8)

- `check_strings.py`: `== 312 strings, 0 errors, 0 warnings`
- `check_strings.py --docs`: `== 312 strings, 0 errors, 0 warnings` (no WARN line; the 12 of sync 1 are gone too)
- `check_strings.py --self-test`: `self-test: 96 passed, 0 failed`
- Every new en and vi text found quoted in `docs/detailed-design` + `docs/design-system` before writing (dry run:
  "8 new, 4 changed, 0 problems").
- Apple generator `apple/Packages/HLLocalization/Scripts/generate-strings.py` rendered in memory from the new catalog:
  11 files, accessors such as `unreadConversations(count: Int)`, `iosLimitsTitle`, `close`, `ok`,
  `permissionInstructionsTitle`, `removeFromServerTitle`, `deleteAllDataTitle` (apple repo not touched).
- `check_schemas.py`: `XANH: mọi kiểm tra đạt`; `verify_vectors.py`: `Tổng: 1397 phép kiểm, 0 lỗi`;
  `generate_vectors.py --check`: `check: 20 file, 0 lệch`.
- CI `ci-shared` run 36236296782 on 3cb90b8: success (both jobs, 28 s).

## Keys for the platforms

**Apple (regenerate with `generate-strings.py`; `--check` drifts until then)**
- `a11y.unread_conversations(count)`: Mac menu bar icon label, after the connection status; iOS Messages tab badge.
- `setup.ios_limits_title`: title above `setup.ios_limits` (SET-03 field 11).
- `common.close`: VoiceOver label of the new-content banner's `xmark` (CLIP-04 field 3).
- `sms.permission_instructions_title` / `sms.permission_instructions_body` / `common.ok`: the alert opened by View
  Instructions (`common.view_instructions`, SMS-01 field 7, E2) and by a missing `READ_SMS`/`SEND_SMS` in the device
  details (PAIR-02 field 9).
- `settings.remove_from_server_title` / `settings.delete_all_data_title`: titles of the Mac alerts and the iOS
  confirmation dialogs (today `settings.remove_from_server` / `settings.delete_all_data`); message
  `settings.*_warning`; buttons `settings.remove_from_server_confirm` / `settings.delete_all_confirm` +
  `common.cancel`. Row labels (iOS) and `…_ellipsis` buttons (Mac) unchanged.

**Android (regenerate the string resources)**
- `settings.remove_from_server_title` / `settings.delete_all_data_title`: titles of the SET-02 fields 26–27
  confirmations (field 28), message `settings.*_warning`, buttons `settings.*_confirm` + `common.cancel`.
- `pairing.reason_missing_sms_permission`: spec list only, text unchanged. The other new keys are macOS/iOS only.

## Spec deviations and proposals

1. Comments are the table's text with key names written without the Markdown backticks and "View Instructions" in
   curly quotes, as the catalog writes comments (no backticks anywhere in it).
2. `pairing.reason_missing_sms_permission`: the table's comment "Also the SMS-01 field 7 reason for E2" is appended to
   the existing one (a comment starting with "Also" alone would drop what the key is).
3. The extra comment fix of 3cb90b8 (not in the table), see above.

## Unresolved questions

None.

Status: DONE
Summary: The eight keys and four updates of the batches 6–7 table are in the catalog (312 strings), pushed with a
comment fix; check_strings 0 errors / 0 warnings, --docs 0 warnings, self-test green, CI green.
Concerns/Blockers: none.
