# Phase 3 — spec sync 1: call decisions applied to the hub docs

Applies the controller's decisions 1–29 (from the S3.1, S3.2, S3.3 and T3.1 deviations) to the detailed design,
the design system and the Phase 3 phase file, both languages in the same commit. Hub `main`, pushed
(`4da3bff..77704ef`); hub CI `ci-docs` run 36297893509 green. No nested repository was edited.

## Decisions applied

| # | Decision | Where (EN + VI) |
|---|----------|-----------------|
| 1 | `hfp_status` row: fields in AUDIO-02 API 3, Phase 3 clients do not read it | `00-common-specs` 0.7.1 |
| 2 | Call primer: title "See Calls on Your Mac and iPhone", body from the design system | `01-setup-settings` SET-01 field 12 (in the "Titles" list, same pattern as camera) |
| 3 | Suggestion for a missing call permission | SET-01 field 17 (written with the example device, like the SMS text) |
| 4 | "Ring on Mac": stale 0.9.5 note dropped; Focus-status hint added; setting names to check on a real Mac | SET-02 field 12 |
| 5 | Instructions alert for a missing call permission | `02-pairing` PAIR-02 field 9 |
| 6 | Push title = sender's or caller's name or number | `03-connectivity` CONN-04 field 2 (points to CALL-01 API 6 and CALL-04 API 4) |
| 7 | I-APP's App Group copy of `features.sms.can_send`; "Message" only when the copy is `true` and the number is known | CONN-04 step 9b; `06-call-control` CALL-04 API 4 (`categoryIdentifier` row, logic 2) |
| 8 | "Incoming call on your phone" | CALL-01 E6, field 11, API 4 logic 3 (VI already right) |
| 9 | Bluetooth line of a waiting call is Mac only | CALL-01 field 5 |
| 10 | `hiddenPreviewsBodyPlaceholder` "Incoming call" / "Missed call" | CALL-01 API 6 (method), API 7 (`categoryIdentifier` row), CALL-04 API 4 (method) |
| 11 | Push target measured from the number broadcast (or `RINGING` + 300 ms) to the relay's 202 | CALL-01 API 4 logic 2 |
| 12 | Focus status not readable → panel without ringing, passive notification | CALL-01 field 15 |
| 13 | `waiting = true` only with `state = ringing`, plus the other schema rules | CALL-01 API 1 `waiting` row + new logic 8 "Consistency rules" |
| 14 | `INTERNAL` in the action error table | CALL-02 API 1 (last row) |
| 15 | Answer target p95 click → `state = offhook` on the Mac, bench also reports click → `OFFHOOK`; 2 s notification decline; 15 s hard deadline | CALL-02 special requirements |
| 16 | Tooltips "Answer the call", "Decline the call", "End the call" | CALL-01 fields 6, 7; CALL-03 field 5; `CallPanel` README |
| 17 | Quick Replies editing texts; referenced from SET-02 | CALL-02 field 8; SET-02 new row 33 |
| 18 | "Missed call on your phone" | CALL-04 E9, API 4 logic 2, API 5 logic 3 |
| 19 | "Unknown Caller" in flow A, "No Caller ID" only for a hidden number | CALL-04 field 8, API 4 `title` row |
| 20 | Nullable `userInfo` keys, one of `entry_id`/`call_id` not null | CALL-04 API 4 `userInfo` row |
| 21 | Empty state "No Calls Yet" | CALL-04 field 1 |
| 22 | VoiceOver labels of the call type icon | CALL-04 field 3 (mapped per `type` value) |
| 23 | VoiceOver label of the missed-call badge (plural) | CALL-04 field 7 |
| 24 | Missed call in the menu bar menu's recent items, existing texts only | CALL-04 API 4 new logic 5 |
| 25 | `CallPanel` texts aligned; stale deviation sentence removed; keypad "Bàn phím số" | `components/CallPanel/README`; `2-patterns/05-phan-hoi-va-tai.md`; `components/StatusIndicator/README.md` |
| 26 | Decline failure text of CALL-02 field 11 | `2-patterns/03-thong-bao` Deviations |
| 27 | Call primer adopted, no longer "Proposed" | `2-patterns/02-xin-quyen` table + a "Synced (27/09/2026)" deviation bullet |
| 28 | "Bàn phím số" in both pages | `CallPanel/README.vi.md` changed; `08-kha-nang-tiep-can.vi.md` already said it |
| 29 | Answer target and notification decline target | `phase-03-cuoc-goi` requirements, T3.1 row, I3.1 row |

### Closest-correct changes and interpretations (please confirm)

1. **PAIR-02 title** is "Grant Call Permission on Your Phone" (singular), to match "Grant SMS Permission on Your
   Phone" as decision 5 allows; vi "Cấp quyền cuộc gọi trên điện thoại" unchanged.
2. **PAIR-02 permission set**: the SMS alert covers only `READ_SMS`/`SEND_SMS`, so the spec had to say which
   permissions open the call alert. Written: `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, and `READ_PHONE_STATE`,
   `READ_CONTACTS` while the phone's `features.call.enabled` is `true` (the body tells the user to allow Phone,
   Call logs and Contacts, i.e. all four `call` permissions of SET-01 API 2; the two shared ones would be wrong
   while calls are off).
3. **SET-02 reference** is a new row 33 "Quick Replies (`call.quick_replies`)" (Mac, Local, points to CALL-02
   field 8). SET-02 had no row for this 0.9.5 key; rows are appended (31, 32 were too), no renumbering.
4. **Mute tooltip** "Mute the microphone on the Mac" was also written into CALL-03 field 9 (existing catalog text
   `call.mute_tooltip`, specs CALL-03, previously quoted only by the design system), so all round-button
   tooltips sit in the leaf spec. Hold and Keypad still have no tooltip text anywhere.
5. **`INTERNAL`**: the new row says the client handles it as E5 (no automatic re-send), because 0.8.1's generic
   "retry once" conflicts with CALL-02 E5. `INTERNAL` was also added to the error list of CALL-03 API 1 (same op).
6. **Schema rules (decision 13)**: all 11 `allOf` rules of `call_event-state` are written as they are in the
   schema (logic 8, plus the `waiting` row); none was found wrong. They also imply that `waiting` must go back
   to `false` when the context reaches `idle` (e.g. both calls end while one was waiting) — logic 2 did not
   say so, the new rule does.
7. **CALL-04 field 8** uses `entry.number = null` to mean "the caller hid the number" (the entry carries no
   `presentation`); flow A never has `restricted`, so a missed call there without a number is always
   "Unknown Caller".
8. **StatusIndicator**: "Disconnected from the phone" was the call panel's text (section "Where": the call panel
   when the session is lost) → now "Lost connection to the phone". The state row "Disconnected" / "Mất kết nối"
   is the general connection state of 0.11 / PAIR-02 field 4 / CONN-02 → left unchanged.
9. VI twins not edited because their text already matched the spec: `05-phan-hoi-va-tai.vi.md`,
   `StatusIndicator/README.vi.md`, `08-kha-nang-tiep-can.vi.md`; CALL-01 E6, field 11, API 4 logic 3 in
   `06-call-control.vi.md`.
10. `03-thong-bao` (both languages) now cites "CALL-02 E8, field 11"; `CallPanel` README cites CALL-03 E6 for the
    lost-connection text and replaces the stale deviation sentence with "the notification stays passive
    (CALL-01 E4, field 15)".

## Commits (hub `main`, pushed)

| Hash | Subject |
|------|---------|
| 2435018 | docs(spec): point call_event/hfp_status to its fields in AUDIO-02 |
| cd064f9 | docs(spec): add the call permission texts and the Focus hint to the settings |
| 015ee92 | docs(spec): add the instructions alert for a missing call permission |
| 04614d4 | docs(spec): name the push title and the missed-call Message rule of the extension |
| dd81be8 | docs(spec): settle the call texts, targets and state rules |
| b212c12 | docs(design-system): align the call texts with the call specs |
| 77704ef | docs(plans): state where the answer and notification decline targets are measured |

All signed off (`Hồ Xuân Dũng <me@hxd.vn>`), no AI attribution, hooks passed; explicit paths staged only.

## Checks (real output)

```text
$ python3 tools/docs/validate_design_docs.py
files=16 leaves=66 problems=0

$ python3 tools/docs/check_bilingual_docs.py
pairs=67 missing=0 problems=0 warnings=0

$ cd shared && tools/.venv/bin/python tools/strings/check_strings.py --docs
== strings/ui-strings.json: 373 strings, languages en, vi
== --docs: texts quoted in …/docs/detailed-design, …/docs/design-system (warnings only)
  en: 373 of 373 texts found in 50 English docs
  vi: 373 of 373 texts found in 50 Vietnamese docs
== 373 strings, 0 errors, 0 warnings
OK

$ cd shared && tools/.venv/bin/python tools/schemas/check_schemas.py   (exit 1)
  FAIL call_event/action error codes vs CALL-02 API 1: spec ['FEATURE_DISABLED', 'BAD_REQUEST',
  'CALL_HFP_REQUIRED', 'CALL_NOT_FOUND', 'PERMISSION_MISSING', 'CALL_ACTION_NOT_ALLOWED', 'INTERNAL', 'INTERNAL'],
  schema ['FEATURE_DISABLED', 'BAD_REQUEST', 'CALL_HFP_REQUIRED', 'CALL_NOT_FOUND', 'PERMISSION_MISSING',
  'CALL_ACTION_NOT_ALLOWED', 'INTERNAL']
== Tổng kết
  schema hợp lệ metaschema: 45
  $ref phân giải được: 250
  enum khớp bảng spec: 40
  …
  ví dụ 01–08: 215
  THẤT BẠI: 1
```

- `check_strings --docs` only checks catalog → docs, so the new spec texts give no warning; they are listed below.
- **The one schema failure is expected and comes from decision 14.** `shared/tools/schemas/call_spec_checks.py`
  (line 116) compares the CALL-02 API 1 error codes as `codes + ["INTERNAL"]`; now that the table lists
  `INTERNAL`, the checker must compare `codes` alone. Simulated on a scratch copy with only that change:
  `call_spec_checks` 25 ok, 0 fail against the new specs. The schemas themselves need no change (the action
  schema already allows `INTERNAL`; no JSON example changed). **Until the shared agent makes this one-line fix,
  `ci-shared` fails on its next run**, because it checks out hub `main` (no hub branch `feat/phase-03-calls`).
- All 25 call table checks otherwise still pass: the `waiting` row, the `userInfo` rows and the error table keep
  the cell shapes the checker parses.

## New or changed UI texts for the catalog

Keys follow the catalog's naming and S3.1 item 10. "Add" = new key; "none" = the text is already in the catalog.

| Proposed key | en | vi | platforms | Spec ID, field | Catalog action |
|--------------|----|----|-----------|----------------|----------------|
| `permission.calls_primer_title` | See Calls on Your Mac and iPhone | Xem cuộc gọi trên Mac và iPhone | android | SET-01 field 12 | add |
| `permission.calls_primer` | To announce incoming calls and let you answer or decline them on your Mac, HandLive needs to read the phone state, the call log, and your contacts. | Để báo cuộc gọi đến và cho bạn trả lời, từ chối trên Mac, HandLive cần đọc trạng thái điện thoại, nhật ký cuộc gọi và danh bạ. | android | SET-01 field 12 | text unchanged; drop "Proposed" from the comment (adopted) |
| `notification.permission_call` | {device_name} needs call permission on this phone — tap to allow | {device_name} cần quyền cuộc gọi trên điện thoại — chạm để cho phép | android | SET-01 field 17 | add |
| `settings.focus_permission_hint` | To ring, allow HandLive to read your Focus status in System Settings › Privacy & Security › Focus. | Để đổ chuông, hãy cho phép HandLive đọc trạng thái Tập trung trong Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Tập trung. | macos | SET-02 field 12 (CALL-01 E4) | add (like `settings.paste_permission_hint`) |
| `call.permission_instructions_title` | Grant Call Permission on Your Phone | Cấp quyền cuộc gọi trên điện thoại | macos, ios | PAIR-02 field 9 | add |
| `call.permission_instructions_body` | On your phone, open HandLive and go to Settings › Permissions & Background. Tap Grant Permission under Calls, or Open Settings if the permission was denied, and allow Phone, Call logs, and Contacts. | Trên điện thoại, mở HandLive và vào Cài đặt › Quyền và chạy nền. Chạm Cấp quyền ở mục Cuộc gọi, hoặc Mở cài đặt nếu quyền đã bị từ chối, rồi cho phép Điện thoại, Nhật ký cuộc gọi và Danh bạ. | macos, ios | PAIR-02 field 9 | add |
| `call.answer_tooltip` | Answer the call | Trả lời cuộc gọi | macos | CALL-01 field 6 | add |
| `call.decline_tooltip` | Decline the call | Từ chối cuộc gọi | macos | CALL-01 field 7 | add |
| `call.end_tooltip` | End the call | Kết thúc cuộc gọi | macos | CALL-03 field 5 | add |
| `call.mute_tooltip` | Mute the microphone on the Mac | Tắt tiếng micro trên Mac | macos | CALL-03 field 9 | none (now quoted by the leaf spec) |
| `settings.quick_reply_add` | Add Quick Reply | Thêm tin trả lời nhanh | macos | CALL-02 field 8 | add |
| `settings.quick_reply_remove` | Remove Quick Reply | Xóa tin trả lời nhanh | macos | CALL-02 field 8 | add |
| `settings.quick_replies_footer` | Up to 6 replies of 160 characters. Choose one when you decline a call on this Mac. | Tối đa 6 tin, mỗi tin 160 ký tự. Chọn một tin khi từ chối cuộc gọi trên Mac này. | macos | CALL-02 field 8 | add |
| `settings.quick_replies` | Quick Replies | Tin trả lời nhanh | macos | SET-02 field 33, CALL-02 field 8 | none |
| `call.empty_title` | No Calls Yet | Chưa có cuộc gọi | macos, ios | CALL-04 field 1 | add |
| `call.empty_body` | Calls from your phone appear here after the first sync. | Cuộc gọi từ điện thoại sẽ hiện ở đây sau lần đồng bộ đầu tiên. | macos, ios | CALL-04 field 1 | add |
| `call.type_incoming` | Incoming call | Cuộc gọi đến | macos, ios | CALL-04 field 3 | add (same text as `call.incoming_body`; duplicate texts are allowed) |
| `call.type_outgoing` | Outgoing call | Cuộc gọi đi | macos, ios | CALL-04 field 3 | add |
| `call.type_missed` | Missed call | Cuộc gọi nhỡ | macos, ios | CALL-04 field 3 | add (same text as `call.missed_call`) |
| `call.type_rejected` | Declined call | Cuộc gọi bị từ chối | macos, ios | CALL-04 field 3 | add |
| `call.type_blocked` | Blocked call | Cuộc gọi bị chặn | macos, ios | CALL-04 field 3 | add |
| `call.type_voicemail` | Voicemail | Thư thoại | macos, ios | CALL-04 field 3 | add |
| `a11y.missed_calls` | one: {count} missed call · other: {count} missed calls | other: {count} cuộc gọi nhỡ | macos, ios | CALL-04 field 7 | add (plural) |
| `push.call_incoming` | Incoming call on your phone | Cuộc gọi đến trên điện thoại | ios | CALL-01 E6, field 11, API 4 logic 3 | none (CALL-01 now quotes the catalog text) |
| `push.call_missed` | Missed call on your phone | Cuộc gọi nhỡ trên điện thoại | ios | CALL-04 E9, API 4 logic 2, API 5 logic 3 | none |
| `call.incoming_body` | Incoming call | Cuộc gọi đến | macos, ios | CALL-01 API 6, API 7 (`hiddenPreviewsBodyPlaceholder`) | none; comment may name `HL_CALL_INCOMING_MAC` too |
| `call.missed_call` | Missed call | Cuộc gọi nhỡ | macos, ios | CALL-04 API 4 (`hiddenPreviewsBodyPlaceholder`) | none |
| `call.unknown_caller` | Unknown Caller | Không rõ số | macos, ios | CALL-04 field 8, API 4 `title` (flow A) | specs + CALL-04 |
| `call.missed_body`, `call.missed_body_sim` | Missed call · {time} (· {sim_label}) | Cuộc gọi nhỡ · {time} (· {sim_label}) | macos, ios | CALL-04 API 4 logic 5 (menu bar recent item on the Mac) | none; comment may name the menu |
| `call.waiting_handle_on_phone` | Handle it on the phone or connect via Bluetooth | Xử lý trên điện thoại hoặc nối Bluetooth | macos | CALL-01 field 5 (Mac only) | none (already `macos`) |

Error mapping (not a text): `INTERNAL` on `call_event/action` → `error.call_command_not_sent`, as E5 (CALL-02 API 1).
The design-system edits (decisions 25–28) only moved those pages onto texts the catalog already has
(`call.waiting_handle_on_phone`, `error.call_hfp_required`, `call.connection_lost`, `call.status_on_call`,
`call.incoming_title`, `call.keypad` vi, `call.decline_failed`).

## Unresolved questions

1. 0.9.5 has no key for I-APP's App Group copy of `features.sms.can_send` (decision 7 names none, and I did not
   add one beyond the decisions). Proposal: an internal iOS key such as `sms.can_send_copy` keyed by `pair_id`,
   listed in 0.9.5 like `clip.seen_change_count`, before I3.1 builds it.
2. Confirm the PAIR-02 permission set of interpretation 2 and the singular title of interpretation 1.
3. `components/CallPanel/preview.html` (vi only) still shows `title="Trả lời"`/`"Từ chối"`/`"Kết thúc"`, the
   aria-label "Bàn phím" and the combined line "Đang gọi · 02:15"; update it when the design-system artifact is
   republished.
4. CALL-03 E4 and API 4 logic 2 still describe reading `hfp_status` (HFP, Phase 4); consistent with 0.7.1's
   "Phase 3 clients do not read it", left unchanged.
5. `2-patterns/05-phan-hoi-va-tai` "Alerts" still names only the SMS instructions alert of PAIR-02 field 9; the
   call alert could be added there in a later design-system sync.
6. Scratchpad note: a helper `rep.py` in the shared scratchpad (used by earlier one-shot sync scripts) was
   overwritten with an API-compatible version (`apply(path, pairs)`); this sync's scripts live in
   `p3-spec-sync-1/`.

Status: DONE_WITH_CONCERNS
Summary: All 29 decisions are applied in both languages across 00, 01, 02, 03, 06, the design system and the Phase 3 phase file, in 7 signed commits pushed to hub main; validate_design_docs and check_bilingual_docs print problems=0 and hub CI is green.
Concerns/Blockers: check_schemas now fails on one expected mismatch (INTERNAL listed twice by call_spec_checks.py, which appends it itself); the shared agent must drop `+ ["INTERNAL"]` or ci-shared fails on its next run. The new UI texts in the table above still have to be added to the catalog.
