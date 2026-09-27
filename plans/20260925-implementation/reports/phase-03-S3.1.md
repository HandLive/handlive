# Phase 3 — S3.1 [shared]: UI strings for Phase 3

Card S3.1 of `phase-03-cuoc-goi.md`: every user-facing string of CALL-01…04, SET-01 part B (call permissions),
SET-02 fields 10–12 and the Mac Calls pane in `shared/strings/ui-strings.json`, `en` and `vi`. Branch
`feat/phase-03-calls` of handlive-shared, pushed; CI `ci-shared` green (run 36294680710 on c5f0a21).
**The Android and Apple agents can build their Phase 3 UI now: regenerate the resources from the catalog**
(Android: the `buildSrc` task; Apple: `python3 apple/Packages/HLLocalization/Scripts/generate-strings.py`, which I
ran in memory against the new catalog without writing — it renders all 11 files, `L10n.Call` has 44 accessors).

## What was done

- **Catalog: 313 → 373 strings** (60 new keys, 6 existing entries widened or re-commented; no existing text
  changed). Every new `en` text was checked, before writing, to be quoted verbatim in the English docs and every
  `vi` text in the Vietnamese docs (`docs/detailed-design` + `docs/design-system`), so `--docs` stays at
  **0 warnings**. Field order, sorting, inline arrays and formatting are unchanged (the file is written by a
  serializer that round-trips the old file byte for byte).
- Texts the specs do not spell out were **not** added (they would be `--docs` warnings); they are listed with
  proposed wording under "Spec deviations and proposals", item 10, for a spec sync. The one exception is
  `permission.calls_primer`, which only the design system quotes (marked "Proposed" there, comment says so).
- Conventions: `call.*` group for the call UI, `error.call_*` for the error texts, `a11y.*` for VoiceOver-only
  texts; `*_ellipsis` for the two Mac-only labels ending in "…"; one key per text with and without the SIM label
  (no string concatenation in code); dates, times and durations are `string` args formatted by the system; SIM
  labels (`sim_label`, `features.sms.sims[].label`) and quick replies saved by the user are user content, never
  keys. HFP-only texts of CALL-03 (Hold, Resume, Keypad, Mute, the three call-waiting buttons, "On hold", the HFP
  error) and the call-audio texts of CALL-01/02 ("Answer on Phone"/"Answer on Mac", the audio switch error) are in
  the catalog already because CALL-01…03 quote them; the UI shows them only when `controls.*`/`hfp_connected`/call
  audio allow it.

### New keys (60)

Mac call panel — ringing (CALL-01, CALL-02):

| Key | en | vi | Platforms |
|-----|----|----|-----------|
| `call.incoming_title` | Incoming Call | Cuộc gọi đến | macos, ios |
| `call.waiting_title` | Call Waiting | Cuộc gọi chờ | macos, ios |
| `call.no_caller_id` | No Caller ID | Số ẩn | macos, ios |
| `call.unknown_caller` | Unknown Caller | Không rõ số | macos, ios |
| `call.caller_id_permission_hint` | Allow HandLive to read the call log on the phone to show caller numbers | Cho phép HandLive đọc nhật ký cuộc gọi trên điện thoại để hiện số gọi đến | macos, ios |
| `call.waiting_handle_on_phone` | Handle it on the phone or connect via Bluetooth | Xử lý trên điện thoại hoặc nối Bluetooth | macos |
| `call.decline` | Decline | Từ chối | macos, ios |
| `call.answer` | Answer | Trả lời | macos |
| `call.answer_on_phone` | Answer on Phone | Nghe trên điện thoại | macos |
| `call.answer_on_mac` | Answer on Mac | Nghe trên Mac | macos |
| `call.decline_with_message_ellipsis` | Decline with Message… | Từ chối kèm tin nhắn… | macos |
| `call.custom_message_ellipsis` | Custom Message… | Tin khác… | macos |
| `call.ignore` | Ignore | Bỏ qua | macos |
| `call.answering` | Answering… | Đang trả lời… | macos |
| `call.declining` | Declining… | Đang từ chối… | macos, ios |
| `call.quick_reply_call_back` | I'll call you back later | Tôi sẽ gọi lại sau | macos |
| `call.quick_reply_in_meeting` | I'm in a meeting | Tôi đang họp | macos |
| `a11y.call_incoming_from` | Incoming call from {caller} | Cuộc gọi đến từ {caller} | macos, ios |

Button order per the `CallPanel` README: Decline (`call.decline`, `call-decline-fill`, left, ⌘⌫) · Answer
(`call.answer`, `call-accept-fill`, right, Return; with call audio in effect it becomes `call.answer_on_phone` +
`call.answer_on_mac`); text buttons `call.decline_with_message_ellipsis`, `call.ignore` (Esc). The round buttons'
accessibility labels are the same keys. The same `call.answer`/`call.decline` serve the ringing call in the menu
bar menu (also after Ignore, and while a Focus hides the panel). `{caller}` of `a11y.call_incoming_from` = name,
else number (national format), else `call.no_caller_id`/`call.unknown_caller`.

Mac call panel — in call (CALL-03):

| Key | en | vi | Platforms |
|-----|----|----|-----------|
| `call.status_on_call` | On call | Đang gọi | macos |
| `call.status_on_hold` | On hold | Đang giữ máy | macos |
| `call.status_waiting` | Call waiting | Có cuộc gọi chờ | macos |
| `call.status_ended` | Call ended · {duration} | Đã kết thúc · {duration} | macos |
| `call.audio_on_phone` | Audio: Phone | Âm thanh: Điện thoại | macos |
| `call.audio_on_mac` | Audio: Mac | Âm thanh: Mac | macos |
| `call.end` | End | Kết thúc | macos |
| `call.hold` / `call.resume` | Hold / Resume | Giữ máy / Tiếp tục | macos |
| `call.keypad` | Keypad | Bàn phím số | macos |
| `call.mute` | Mute | Tắt tiếng | macos |
| `call.mute_tooltip` | Mute the microphone on the Mac | Tắt tiếng micro trên Mac | macos |
| `call.reject_waiting` | Decline Waiting Call | Từ chối cuộc gọi chờ | macos |
| `call.end_and_answer` | End & Answer | Kết thúc và nghe | macos |
| `call.hold_and_answer` | Hold & Answer | Giữ và nghe | macos |
| `call.outgoing_call` | Outgoing Call | Cuộc gọi đi | macos |
| `call.connection_lost` | Lost connection to the phone | Mất kết nối với điện thoại | macos |
| `a11y.call_ended` | Call ended | Cuộc gọi đã kết thúc | macos |

The timer ("02:15") and `{duration}` are formatted by the system (`DateComponentsFormatter`); the switch-audio
button belongs to AUDIO-03 (Phase 4, not in the catalog yet).

Notifications (CALL-01 API 6/7, CALL-02 E8, CALL-04 API 4):

| Key | en | vi | Platforms |
|-----|----|----|-----------|
| `call.incoming_body` | Incoming call | Cuộc gọi đến | macos, ios |
| `call.incoming_body_sim` | Incoming call · {sim_label} | Cuộc gọi đến · {sim_label} | macos, ios |
| `call.incoming_late` | Incoming call at {time} | Cuộc gọi đến lúc {time} | ios |
| `call.decline_failed` | Couldn't decline the call. It's still ringing on the phone. | Không gửi được lệnh từ chối. Cuộc gọi vẫn đổ chuông trên điện thoại. | ios |
| `call.missed_body` | Missed call · {time} | Cuộc gọi nhỡ · {time} | macos, ios |
| `call.missed_body_sim` | Missed call · {time} · {sim_label} | Cuộc gọi nhỡ · {time} · {sim_label} | macos, ios |
| `call.missed_call` | Missed call | Cuộc gọi nhỡ | macos, ios |
| `call.message` | Message | Nhắn tin | macos, ios |

- Incoming call, Mac (`HL_CALL_INCOMING_MAC`) and iPhone/iPad (`HL_CALL_INCOMING`): title = name, number,
  `call.no_caller_id` or `call.unknown_caller`; body `call.incoming_body` or `call.incoming_body_sim`; actions
  `call.answer` (Mac, `HL_CALL_ANSWER`) and `call.decline` (`HL_CALL_REJECT`); `hiddenPreviewsBodyPlaceholder` =
  `call.incoming_body`. Late push (E7): body `call.incoming_late`, no category. Locked iPhone (E6): the APNs
  `loc-key` `push.call_incoming` stays.
- Missed call (`HL_CALL_MISSED`): title as above (`call.no_caller_id` when `number = null`); body
  `call.missed_body` / `call.missed_body_sim`; action `call.message` (text input, button `sms.send`, placeholder
  `sms.compose_placeholder`); `hiddenPreviewsBodyPlaceholder` = `call.missed_call`; locked iPhone: `push.call_missed`.
  A quick reply from it that gets no ack on iOS reuses `sms.quick_reply_not_sent`.
- CALL-02 E8 local notification: body `call.decline_failed`, no title (like `sms.quick_reply_not_sent`).

Call list, errors, settings, permissions:

| Key | en | vi | Platforms |
|-----|----|----|-----------|
| `call.title` | Calls | Cuộc gọi | macos, ios |
| `call.call_log_permission_hint` | Allow HandLive to read the call log on the phone to see call history | Cho phép HandLive đọc nhật ký cuộc gọi trên điện thoại để xem lịch sử cuộc gọi | macos, ios |
| `settings.call_log_last_sync` | Last synced: {time} | Lần đồng bộ cuối: {time} | macos, ios |
| `error.call_not_found` | The call has ended | Cuộc gọi đã kết thúc | macos, ios |
| `error.call_action_not_allowed` | The call was answered on the phone | Cuộc gọi đã được nghe trên điện thoại | macos, ios |
| `error.call_answer_permission` | The phone hasn't allowed HandLive to answer calls | Điện thoại chưa cho phép HandLive trả lời cuộc gọi | macos, ios |
| `error.call_command_not_sent` | Couldn't send the command to the phone | Không gửi được lệnh tới điện thoại | macos, ios |
| `error.call_audio_switch_failed` | Couldn't switch the audio to the Mac | Không chuyển được âm thanh sang Mac | macos |
| `error.call_message_not_sent` | The call was answered, so the message wasn't sent | Cuộc gọi đã được nghe, tin nhắn không được gửi | macos |
| `error.call_end_on_phone` | End this call on the phone | Hãy kết thúc cuộc gọi này trên điện thoại | macos |
| `error.call_hfp_required` | Connect to the phone via Bluetooth to hold, use the keypad, or mute | Nối Bluetooth với điện thoại để giữ máy, bấm số, tắt tiếng | macos |
| `error.call_hfp_command_failed` | The phone couldn't perform this action | Điện thoại không thực hiện được thao tác này | macos |
| `settings.call_notify` | Call Notifications | Thông báo cuộc gọi | macos, ios |
| `settings.call_ringtone` | Ring on Mac | Đổ chuông trên Mac | macos |
| `settings.quick_replies` | Quick Replies | Tin trả lời nhanh | macos |
| `permission.calls_primer` | To announce incoming calls and let you answer or decline them on your Mac, HandLive needs to read the phone state, the call log, and your contacts. | Để báo cuộc gọi đến và cho bạn trả lời, từ chối trên Mac, HandLive cần đọc trạng thái điện thoại, nhật ký cuộc gọi và danh bạ. | android |

Error mapping (`ack.error.code` → key): `CALL_NOT_FOUND` → `error.call_not_found`; `CALL_ACTION_NOT_ALLOWED` →
`error.call_action_not_allowed`, except `reason = system` on End → `error.call_end_on_phone`; `CALL_HFP_REQUIRED`
→ `error.call_hfp_required`; `PERMISSION_MISSING` (`ANSWER_PHONE_CALLS`) → `error.call_answer_permission`;
`TIMEOUT`/lost session → `error.call_command_not_sent`; `FEATURE_DISABLED` → the existing `error.feature_disabled`;
AUDIO-03 codes after Answer on Mac → `error.call_audio_switch_failed`; HFP `ERROR`/timeout →
`error.call_hfp_command_failed`; CALL-02 E9 → `error.call_message_not_sent`.

Default quick replies (0.12.4): on first use the Mac writes `call.quick_reply_call_back` and
`call.quick_reply_in_meeting`, in the active language, into `call.quick_replies`; after that they are user data.

### Existing keys changed (metadata only, no text change)

- `push.call_incoming`: specs + CALL-01, comment names CALL-01 E6. `push.call_missed`: specs + CALL-04, comment
  names CALL-04 E9. Both texts follow CONN-04 API 4 and the design system (see deviation 1, 2); platforms stay
  `ios` (the Mac never receives pushes).
- `settings.calls`: platforms + `ios` (the switch for `feature.call` and the Calls group header on iPhone/iPad, as
  on the Android Settings tab and in the Mac pane) — widened instead of a duplicate "Calls" key.
- `sms.send`, `sms.compose_placeholder`: specs + CALL-02, CALL-04 (Custom Message… field, `HL_CALL_SMS` action).
  `sms.quick_reply_not_sent`: specs + CALL-04.
- `infoplist.focus_status_usage`: checked, unchanged — en and vi match CALL-01 API 5 logic 3, SET-03 and the design
  system word for word; `macos` only is right (iOS never reads the Focus status). No other purpose string is needed
  in Phase 3: communication notifications and `INStartCallIntent` need a capability and `NSUserActivityTypes`, not
  a usage description; iOS asks for no new permission.

## Commits (handlive-shared, branch `feat/phase-03-calls`)

| Hash | Subject |
|------|---------|
| 091ac37 | feat(shared): add the incoming call panel, banner and notification strings |
| 7214f40 | feat(shared): add the answer, decline and quick reply strings |
| eabdb51 | feat(shared): add the in-call panel strings |
| 77407f2 | feat(shared): add the call log and missed call strings |
| c5f0a21 | feat(shared): add the Calls settings and the Android call permission explanation |

All signed off; `.githooks/check-commits.sh origin/main..HEAD` → "commit sạch: đã kiểm 5 commit".

## Files

Changed: `shared/strings/ui-strings.json` only. **Shared change for the other platforms:** new catalog keys (no
schema or vector change yet) — Android and Apple regenerate their string resources.

## Tests (real output, from `shared/`)

```text
$ tools/.venv/bin/python tools/strings/check_strings.py
== strings/ui-strings.json: 373 strings, languages en, vi
== 373 strings, 0 errors, 0 warnings
OK

$ tools/.venv/bin/python tools/strings/check_strings.py --docs | tail -4
  en: 373 of 373 texts found in 50 English docs
  vi: 373 of 373 texts found in 50 Vietnamese docs
== 373 strings, 0 errors, 0 warnings
OK

$ tools/.venv/bin/python tools/strings/check_strings.py --self-test
self-test: 96 passed, 0 failed

$ tools/.venv/bin/python tools/schemas/check_schemas.py | tail -1
  XANH: mọi kiểm tra đạt

$ gh run list -R HandLive/handlive-shared --branch feat/phase-03-calls --limit 1
completed  success  feat(shared): add the Calls settings and the Android call permission …  ci-shared  push  36294680710  1m8s
```

Apple generator (in memory, apple repo untouched): `11 files rendered from the committed catalog`, `Call enum
members: 44`.

## Spec deviations and proposals (hub not edited)

1. **`push.call_incoming` (en).** CONN-04 API 4 (`03-connectivity.md`) and the design system (`2-patterns/03-thong-bao.md`)
   say "Incoming call on your phone"; CALL-01 E6, field 11 and API 4 logic 3 (`06-call-control.md`) say "Incoming
   call on the phone". vi is the same everywhere ("Cuộc gọi đến trên điện thoại"). The catalog keeps the CONN-04
   text. Proposal: CALL-01 E6, field 11, API 4 logic 3 → "Incoming call on your phone".
2. **`push.call_missed`.** CONN-04 API 4 and 03-thong-bao: "Missed call on your phone" / "Cuộc gọi nhỡ trên điện
   thoại"; CALL-04 E9, API 4 logic 2 and API 5 logic 3 (`06-call-control.md` + `.vi.md`) call the generic content
   "Missed call" / "Cuộc gọi nhỡ". The catalog keeps CONN-04's text for the loc-key; "Missed call" is
   `call.missed_call` (the `HL_CALL_MISSED` hidden-preview placeholder of 03-thong-bao). Proposal: CALL-04 E9, API 4
   logic 2, API 5 logic 3 → "Missed call on your phone" / "Cuộc gọi nhỡ trên điện thoại".
3. **SET-02 field 12** (`01-setup-settings.md` + `.vi.md`): "key proposed by CALL-01, pending addition to 0.9.5" is
   stale — 0.9.5 has `call.ringtone`. Proposal: drop the parenthetical.
4. **CONN-04 field 2** (`03-connectivity.md` + `.vi.md`): "I-NSE replaces it with the sender's name or "Incoming
   Call"" — CALL-01 API 6 sets the title to the caller's name or number ("No Caller ID"/"Unknown Caller" otherwise),
   never "Incoming Call". Proposal: "the sender's or caller's name or number".
5. **iOS banner and CALL-01 field 5.** Step 8 shows fields 1–5 and 7 on iPhone/iPad, but field 5's line "Handle it
   on the phone or connect via Bluetooth" applies when `hfp_connected = false`, which is always true on iPhone/iPad
   (no HFP). The catalog targets `call.waiting_handle_on_phone` at the Mac only. Proposal: field 5 — the line is Mac
   only; iPhone/iPad show only the waiting caller.
6. **Flow A missed-call title.** CALL-04 field 8/API 4 use "No Caller ID" whenever `number = null`; in flow A (no
   `READ_CALL_LOG`) the number is null because of the permission and the panel said "Unknown Caller" (CALL-01 field
   3). Proposal: in flow A with `presentation = unknown`, the title is "Unknown Caller" (`call.unknown_caller`).
7. **Hidden-preview placeholders** "Incoming call" / "Missed call" are quoted only by the design system
   (03-thong-bao). Proposal: name `hiddenPreviewsBodyPlaceholder` in CALL-01 API 6/7 and CALL-04 API 4.
8. **Design system vs leaf spec** — the catalog follows the leaf spec; proposal: align the design system pages:
   - `CallPanel` README: "Handle it on the phone or connect Bluetooth" vs CALL-01 field 5 "… connect via
     Bluetooth"; "Connect to the phone over Bluetooth to hold, use the keypad, or mute" (also
     `2-patterns/05-phan-hoi-va-tai.md`) vs CALL-03 E2 "… via Bluetooth …"; "Disconnected from the phone" (also
     05-phan-hoi-va-tai, `StatusIndicator`) vs CALL-03 E6 "Lost connection to the phone"; in-call "In call · 02:15"
     vs CALL-03 fields 2–3 "On call" + timer; ringing subtitle "Incoming call · SIM 1" vs CALL-01 field 1 "Incoming
     Call" + field 4 SIM label (the catalog has both `call.incoming_title` and `call.incoming_body_sim`). The vi
     texts of the first three pairs are identical.
   - 03-thong-bao "Deviations": "Couldn't send the decline command. The call is still ringing on the phone." vs
     CALL-02 field 11 "Couldn't decline the call. It's still ringing on the phone." (vi identical).
   - Keypad label vi: `1-foundations/08-kha-nang-tiep-can.vi.md` "Bàn phím số" vs `CallPanel/README.vi.md` "Bàn
     phím"; the catalog uses "Bàn phím số" (the accessibility-label table).
   - `CallPanel` README "Behavior": "This deviates from CALL-01 E4" is stale — CALL-01 E4 now says the same (panel
     without ringing when the Focus status can't be read).
9. **Android primer for calls** is only in the design system (`2-patterns/02-xin-quyen.md`, "Proposed"); SET-01
   field 12 has no call primer and no title. `permission.calls_primer` carries the design system text with a
   "Proposed text" comment. Proposal: add body and title to SET-01 field 12 (see item 10).
10. **Texts the Phase 3 UI needs but the specs don't spell out** — not in the catalog (they would be `--docs`
    warnings); proposed wording to add to the specs first, then the keys (by me, or by the platform agent under
    the lock):

| Where | Proposed key | en | vi |
|-------|--------------|----|----|
| SET-01 field 12 (Android call primer title) | `permission.calls_primer_title` | See Calls on Your Mac and iPhone | Xem cuộc gọi trên Mac và iPhone |
| SET-01 field 17 (suggestion when a client got `PERMISSION_MISSING` for a call permission) | `notification.permission_call` | {device_name} needs call permission on this phone — tap to allow | {device_name} cần quyền cuộc gọi trên điện thoại — chạm để cho phép |
| CALL-04 field 3 (VoiceOver label of the call type icon) | `call.type_incoming`, `_outgoing`, `_missed`, `_rejected`, `_blocked`, `_voicemail` | Incoming call · Outgoing call · Missed call · Declined call · Blocked call · Voicemail | Cuộc gọi đến · Cuộc gọi đi · Cuộc gọi nhỡ · Cuộc gọi bị từ chối · Cuộc gọi bị chặn · Thư thoại |
| CALL-04 field 1 empty state (like SMS-03 E1) | `call.empty_title`, `call.empty_body` | No Calls Yet · Calls from your phone appear here after the first sync. | Chưa có cuộc gọi · Cuộc gọi từ điện thoại sẽ hiện ở đây sau lần đồng bộ đầu tiên. |
| CALL-04 field 7 (VoiceOver of the missed-call badge, like SMS-02 field 6) | `a11y.missed_calls` (plural) | {count} missed call / {count} missed calls | {count} cuộc gọi nhỡ |
| CallPanel tooltips of the round Answer, Decline and End buttons (only Mute's is quoted) | `call.answer_tooltip`, `call.decline_tooltip`, `call.end_tooltip` | Pick up on the phone · Reject the call on the phone · Hang up on the phone | Nhấc máy trên điện thoại · Từ chối cuộc gọi trên điện thoại · Gác máy trên điện thoại |
| CALL-02 field 8 (editing Quick Replies in the Mac Calls pane) | `settings.quick_reply_add`, `settings.quick_reply_remove`, `settings.quick_replies_footer` | Add Quick Reply · Remove Quick Reply · Up to 6 replies of 160 characters. Choose one when you decline a call on this Mac. | Thêm tin trả lời nhanh · Xóa tin trả lời nhanh · Tối đa 6 tin, mỗi tin 160 ký tự. Chọn một tin khi từ chối cuộc gọi trên Mac này. |
| PAIR-02 field 9 (instructions for a missing call permission, like the SMS alert) | `call.permission_instructions_title`, `call.permission_instructions_body` | Grant Call Permissions on Your Phone · On your phone, open HandLive and go to Settings › Permissions & Background. Tap Grant Permission under Calls, or Open Settings if the permission was denied, and allow Phone, Call logs, and Contacts. | Cấp quyền cuộc gọi trên điện thoại · Trên điện thoại, mở HandLive và vào Cài đặt › Quyền và chạy nền. Chạm Cấp quyền ở mục Cuộc gọi, hoặc Mở cài đặt nếu quyền đã bị từ chối, rồi cho phép Điện thoại, Nhật ký cuộc gọi và Danh bạ. |

   Also unspecified, lower priority: a one-line description under the Android "Calls" switch (SET-02 usability
   rule), a hint under "Ring on Mac" while the Focus status permission is denied, the missed-call item of the menu
   bar menu's "Recent" group (`call.missed_body` can serve), and the Android system group names in the permission
   instructions ("Phone", "Call logs", "Contacts" — check on a device).

## Pending manual checks

- Both languages at the largest text size (AX5, 200 %) and in the 340 pt Mac panel: `call.decline_with_message_ellipsis`
  next to `call.ignore`, `error.call_hfp_required`, `call.caller_id_permission_hint`, `call.waiting_handle_on_phone`,
  `call.decline_failed`; Vietnamese is usually 20–30 % longer.
- On real devices: the iOS `hiddenPreviewsBodyPlaceholder` of `HL_CALL_INCOMING`/`HL_CALL_MISSED`, the
  communication notification title with `call.no_caller_id`/`call.unknown_caller`, and VoiceOver reading
  `a11y.call_incoming_from` once per call.

Status: DONE_WITH_CONCERNS
Summary: 60 new and 6 widened catalog strings (CALL-01…04, SET-01 part B, SET-02 fields 10–12, Mac Calls pane) are committed and pushed on feat/phase-03-calls; check_strings, --docs (0 warnings), self-test and CI are green.
Concerns/Blockers: several texts the Phase 3 UI needs are not in the specs yet (item 10: Android call primer title, call type labels, Calls empty state, quick reply editing, tooltips); the push texts of CALL-01/CALL-04 disagree with CONN-04 (items 1–2).
