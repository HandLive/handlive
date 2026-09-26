# Phase 2 — S2.1 [shared]: UI strings for Phase 2

Card S2.1 of `phase-02-sms-ios-relay.md`: every user-facing string of SMS-01…05, CONN-03, CONN-04, CLIP-04, PAIR-01
over the relay, PAIR-03 flow B, SET-01 part B, SET-02 fields 7–9, 21, 24–30 and SET-03 (iOS) in
`shared/strings/ui-strings.json`, `en` and `vi`. Branch `feat/phase-02-sms-ios-relay` of handlive-shared, pushed; CI
`ci-shared` green (run 36216177078 on 6421ad9). **The Android and Apple agents can build their Phase 2 UI now:
regenerate the resources from the catalog** (Android: the `buildSrc` task; Apple:
`python3 apple/Packages/HLLocalization/Scripts/generate-strings.py`, which I ran in memory against the new catalog
without writing — it renders all 8 files without error).

## What was done

- **Catalog: 207 → 284 strings** (77 new, 15 existing entries widened or re-commented). Every new `en` and `vi`
  text was checked, before writing, to be quoted verbatim in the English and Vietnamese docs (leaf specs first,
  then the design system components the leaf specs rely on without quoting: `MessageBubble`, `ThreadRow`,
  `PasteCard`, the Settings pattern and the iOS platform page), so `--docs` reports **no new warning** (the same 16
  as on `main`, all Phase 1 texts). Field order, sorting, inline arrays and formatting are unchanged (the file is
  written by a serializer that round-trips the old file byte for byte).
- **SMS (SMS-01…05), Mac and iPhone/iPad** — `sms.*` (37 keys) and `error.sms_*` (8):
  - SMS-01: `sms.syncing`, `sms.sync_failed`, `sms.sync_downloaded` (plural), resync alert
    `sms.resync_confirm_title` (`{device_name}` = this Mac/iPhone) + `sms.resync_confirm_message` + button
    `sms.resync`, `sms.contacts_permission_hint`, `common.view_instructions` (E2), `settings.sms_last_sync`.
  - SMS-02: `sms.notification_hidden_body` ("New SMS message" with `sms.preview` off, and the
    `hiddenPreviewsBodyPlaceholder` of `HL_SMS`), actions `sms.reply` ("Reply"), `sms.send` ("Send", also the compose
    send button), `sms.mark_as_read` ("Mark as Read", also the ThreadRow menu/swipe), settings
    `settings.sms_notify`, `settings.sms_preview`.
  - SMS-03: `sms.title` (Mac Messages window, iOS Messages tab), `sms.empty_title`, `sms.unread_count` (exactly the
    0.12.1 example: ThreadRow accessibility label), `sms.filter_all`/`sms.filter_unread` (iOS), `sms.copy_number`
    (Mac), `sms.loading_older`, `sms.beginning_of_conversation`, `sms.history_needs_connection`,
    `error.sms_thread_not_found`.
  - SMS-04: `sms.new_message`, `sms.compose_placeholder`, the counter `sms.char_count` "{used}/{limit}" (empty field,
    "0/160") and `sms.char_counter` "{used}/{limit} · {parts}" with `sms.part_count` (plural, "1 message"),
    statuses `sms.status_pending|sending|sent|delivered|failed` and `sms.status_failed_reason` "Not sent · {reason}",
    the failure reasons of field 8 as `error.sms_no_service`, `error.sms_radio_off`, `error.sms_invalid_address`,
    `error.sms_sim_unavailable`, `error.sms_limit_exceeded`, `error.sms_generic_failure` (also any other code),
    `error.sms_not_connected` (`last_error = NOT_CONNECTED` after 24 h), the iOS local notification
    `sms.quick_reply_not_sent` (E8), `sms.group_reply_on_phone` (E9); "Try Again" stays `common.retry`.
  - SMS-05: `sms.unread_divider`, `settings.sms_read_note`.
- **SET-02 (Android, Mac, iOS)** — `settings.sms_messages` (field 7), `settings.resync_sms` (iOS) and
  `settings.resync_sms_ellipsis` (Mac, "…" because it opens an alert, like `pairing.unpair_ellipsis`),
  `settings.remove_from_server` / `_ellipsis`, `settings.delete_all_data` / `_ellipsis`, warnings
  `settings.remove_from_server_warning` and `settings.delete_all_data_warning` (field 29, one line each),
  `common.delete` (field 28), `settings.removed_from_server` (field 30), `error.server_unreachable` (E5),
  `settings.delete_all_offline_confirm` (E7); iOS Settings groups from the design system: `settings.phone`,
  `settings.permissions`, `settings.local_network`, `settings.data` (also Android); `settings.messages` now also
  targets iOS (group header) and `settings.notifications` iOS (Permissions row). Field 21 ("Internet Connection" and
  its Android description) and field 24 (the three reasons `pairing.reason_*`) already existed.
- **CLIP-04 (iPhone/iPad)** — `clipboard.title` (tab), `clipboard.send_to_phone_title` "Send to {device_name}",
  banners `clipboard.new_content_banner` / `clipboard.new_image_banner` with `{device_type}` = "iPhone" or "iPad"
  (see deviation 7), `clipboard.not_connected_to_phone`, `error.clip_send_failed` (E9), `error.clip_unsupported_mime`
  (E3), `error.clip_content_too_large` (E4), and the `PasteCard` parts `clipboard.received_from`, `clipboard.copy`,
  `clipboard.sensitive_hidden`, `clipboard.nothing_received`. Widened to `ios`: `clipboard.conflict_title`,
  `clipboard.conflict_body`, `clipboard.send_again`, `clipboard.image_sending`, `clipboard.image_receiving`,
  `error.clip_image_send_failed`, `error.clip_image_no_space` (CLIP-04 fields 6, 8, 9 and E8 → CLIP-03).
- **CONN-03 / CONN-04 / PAIR** — `error.relay_device_revoked` (CONN-03 E3, all platforms). `status.connected_internet`,
  `status.peer_offline`, `status.channel_internet` now list CONN-03. `pairing.unpaired` and `pairing.unpaired_pending`
  (PAIR-03 field 4, flow B) now target Mac and iOS too; their "Proposed text" note is gone because PAIR-03 quotes them.
  The CONN-04 API 4 `loc-key` table matches the four existing `push.*` keys verbatim in both languages
  (`push.sms_new` "New SMS message", `push.call_incoming`, `push.call_missed`; `push.generic` is the E5/field 3
  fallback) — no change. PAIR-01 over the relay has no new text (E3 is the existing `pairing.phone_not_found`).
- **iOS purpose strings** — iOS asks only for notifications (no purpose string) and the local network: the design
  system (10-quyen-rieng-tu) says "Same purpose string as on macOS", and `infoplist.local_network_usage` already
  lists `ios`. No camera, Bluetooth or microphone on iOS. Nothing to add.
- Generators: plural strings keep exactly one `int` argument `count` (the Apple generator enforces it); new `args`
  are `string`, so numbers are formatted before they are passed in.

Keys added (77): `clipboard.copy`, `clipboard.new_content_banner`, `clipboard.new_image_banner`,
`clipboard.not_connected_to_phone`, `clipboard.nothing_received`, `clipboard.received_from`,
`clipboard.send_to_phone_title`, `clipboard.sensitive_hidden`, `clipboard.title`, `common.delete`,
`common.view_instructions`, `error.clip_content_too_large`, `error.clip_send_failed`, `error.clip_unsupported_mime`,
`error.relay_device_revoked`, `error.server_unreachable`, `error.sms_generic_failure`, `error.sms_invalid_address`,
`error.sms_limit_exceeded`, `error.sms_no_service`, `error.sms_not_connected`, `error.sms_radio_off`,
`error.sms_sim_unavailable`, `error.sms_thread_not_found`, `settings.data`, `settings.delete_all_data`,
`settings.delete_all_data_ellipsis`, `settings.delete_all_data_warning`, `settings.delete_all_offline_confirm`,
`settings.local_network`, `settings.permissions`, `settings.phone`, `settings.remove_from_server`,
`settings.remove_from_server_ellipsis`, `settings.remove_from_server_warning`, `settings.removed_from_server`,
`settings.resync_sms`, `settings.resync_sms_ellipsis`, `settings.sms_last_sync`, `settings.sms_messages`,
`settings.sms_notify`, `settings.sms_preview`, `settings.sms_read_note`, `sms.beginning_of_conversation`,
`sms.char_count`, `sms.char_counter`, `sms.compose_placeholder`, `sms.contacts_permission_hint`, `sms.copy_number`,
`sms.empty_title`, `sms.filter_all`, `sms.filter_unread`, `sms.group_reply_on_phone`, `sms.history_needs_connection`,
`sms.loading_older`, `sms.mark_as_read`, `sms.new_message`, `sms.notification_hidden_body`, `sms.part_count`,
`sms.quick_reply_not_sent`, `sms.reply`, `sms.resync`, `sms.resync_confirm_message`, `sms.resync_confirm_title`,
`sms.send`, `sms.status_delivered`, `sms.status_failed`, `sms.status_failed_reason`, `sms.status_pending`,
`sms.status_sending`, `sms.status_sent`, `sms.sync_downloaded`, `sms.sync_failed`, `sms.syncing`, `sms.title`,
`sms.unread_count`, `sms.unread_divider`.

Changed (platforms, specs or comment only; no text changed): `clipboard.conflict_body`, `clipboard.conflict_title`,
`clipboard.image_receiving`, `clipboard.image_sending`, `clipboard.send_again`, `common.retry`,
`error.clip_image_no_space`, `error.clip_image_send_failed`, `pairing.unpaired`, `pairing.unpaired_pending`,
`settings.messages`, `settings.notifications`, `status.channel_internet`, `status.connected_internet`,
`status.peer_offline`.

## Commits (handlive-shared, branch `feat/phase-02-sms-ios-relay`)

| Hash | Subject |
|------|---------|
| 8fb344e | feat(shared): add the SMS conversation, notification and sending strings |
| 736b978 | feat(shared): add the Messages settings and server data actions of SET-02 |
| 59a351b | feat(shared): add the iPhone and iPad clipboard strings of CLIP-04 |
| 6421ad9 | feat(shared): add the relay removal error and unpair results for Mac and iPhone |

All signed off; `.githooks/check-commits.sh origin/main..HEAD` → "commit sạch: đã kiểm 4 commit".

## Files

Changed: `shared/strings/ui-strings.json` only. **Shared change for the other platforms:** new catalog keys (no
schema or vector change) — Android and Apple regenerate their string resources.

## Tests (real output, from `shared/`)

```text
$ tools/.venv/bin/python tools/strings/check_strings.py
== strings/ui-strings.json: 284 strings, languages en, vi
== 284 strings, 0 errors, 0 warnings
OK

$ tools/.venv/bin/python tools/strings/check_strings.py --docs | tail -4
  WARN status.connected_internet_to [vi]: not quoted in the Vietnamese specs
  WARN status.connected_usb_to [vi]: not quoted in the Vietnamese specs
== 284 strings, 0 errors, 16 warnings          # en 276/284, vi 276/284; the same 16 warnings as main (Phase 1 texts)
OK

$ tools/.venv/bin/python tools/strings/check_strings.py --self-test
self-test: 96 passed, 0 failed

$ tools/.venv/bin/python tools/schemas/check_schemas.py | tail -1
  XANH: mọi kiểm tra đạt

$ gh run list -R HandLive/handlive-shared --branch feat/phase-02-sms-ios-relay --limit 1
completed  success  feat(shared): add the relay removal error and unpair results for Mac …  ci-shared  push  36216177078
```

## Spec deviations and proposals (hub not edited)

1. **Android `sms` notification channel.** No leaf spec defines one: A-SMS posts no SMS notification (the phone's
   default SMS app does), FCM wake-ups run under `hl_service`, and permission suggestions use `permission`. Not
   added. Proposal: drop it from the S2.1 card, or define in SMS-02/SET-01 what it would carry, with its name and
   description in both languages.
2. **SMS-04 field 3 counter.** 0.12.1 allows only one argument (`count`) in a plural string, and the Apple generator
   enforces it, so "120/160 · 1 message" is composed: `sms.char_counter` "{used}/{limit} · {parts}" with
   `{parts}` = `sms.part_count`; the empty field shows `sms.char_count` ("0/160"). Proposal: describe this in SMS-04
   field 3.
3. **Grouping in plural counts.** `sms.sync_downloaded` must read "Downloaded 1,500 messages" / "Đã tải 1.500 tin",
   but an `int` `count` becomes `%1$d` / `%lld`, which prints "1500". Proposal (0.12.1/0.12.2): let a plural carry a
   formatted string for display besides `count` (generators would then allow a second argument), or accept counts
   without grouping.
4. **Design system vs leaf spec** — the catalog follows the leaf spec; proposal: align the design system pages.
   - `MessageBubble` pending "Waiting for the phone" vs SMS-03/04 "Waiting for phone" (vi identical).
   - `MessageBubble` failure reasons ("The phone is in Airplane Mode", "Too many messages sent, try again later",
     "Invalid recipient number", "This SIM isn't working, choose another SIM", "Couldn't reach the phone within 24
     hours", "Couldn't send"; vi "Đã gửi quá nhiều tin, thử lại sau", "Số nhận không hợp lệ", "SIM này không hoạt
     động, hãy chọn SIM khác", "Không kết nối được điện thoại trong 24 giờ", "Không gửi được") vs SMS-04 field 8.
     Also 05-phan-hoi-va-tai "Not sent · The phone is in Airplane Mode".
   - `MessageBubble` "2 SMS messages" vs SMS-04 field 3 "1 message" / "1 tin".
   - 04-cai-dat resync text "Delete the messages stored on … and load them again…" vs SMS-01 field 6; caption
     "Marking messages as read on this device doesn't change their status on the phone." vs SMS-05 field 6.
   - 03-thong-bao "Couldn't send. Open HandLive to try again." vs SMS-04 E8 "Not sent yet. Open HandLive to try
     again."; 05-phan-hoi-va-tai "Remove from this device anyway?" vs SET-02 E7 "Delete from this device anyway?".
   - 04-cai-dat plans to replace the field 28 button "Delete" with "Remove from Server" / "Delete All"; the catalog
     has `common.delete` per SET-02 — a change needs two new keys.
5. **SMS-05 field 2** shows the unread count "next to the conversation", which contradicts SMS-03 field 5 and
   `ThreadRow` (dot only). The catalog has `sms.unread_count` only as the ThreadRow accessibility label (0.12.1).
   Proposal: SMS-05 field 2 → "accessibility label of the row".
6. **Vietnamese final periods.** The `vi` texts of SMS-04 E8/field 11, SMS-04 field 8 (limit), SET-02 E5 and
   CLIP-04 E9/field 5 lack the final period their English texts have; the catalog adds it in `vi` (the checker warns
   on different endings; `--docs` treats a final period as optional). The `<br>` inside SET-02 field 29 and E7 is
   written as a space. Proposal: add the periods in `01-setup-settings.vi.md`, `04-clipboard.vi.md`, `05-sms.vi.md`.
7. **CLIP-04 banner on iPad.** The spec only has "The iPhone clipboard has new content…"; the catalog takes
   `{device_type}` = "iPhone" or "iPad" (`UIDevice.current.model`, never translated). Proposal: say so in CLIP-04
   field 3 and API 2.
8. **Spec-side slip:** PAIR-01 field 5 (English) writes "Pair With \<client device name>?"; Apple title-style keeps
   "with" lowercase, as the catalog does.
9. **Texts the Phase 2 UI needs but the specs don't spell out** — not in the catalog (they would add `--docs`
   warnings); proposed wording to add to the specs first, then the keys:

| Where | Proposed key | en | vi |
|-------|--------------|----|----|
| SET-03 E3 (iPhone, iPad) | `setup.notifications_denied_ios` | Notifications are off, so new SMS messages and incoming calls don't appear while HandLive is closed. Turn them on in Settings › Notifications › HandLive. | Thông báo đang tắt nên không thấy SMS mới và cuộc gọi đến khi HandLive đóng. Bật lại trong Cài đặt › Thông báo › HandLive. |
| SET-03 E4 (iPhone, iPad) | `setup.local_network_denied_ios` | HandLive can't look for the phone on Wi-Fi. Turn on HandLive in Settings › Privacy & Security › Local Network. | HandLive không tìm được điện thoại trong mạng Wi-Fi. Bật HandLive trong Cài đặt › Quyền riêng tư & Bảo mật › Mạng cục bộ. |
| SET-03 step 9 primer body (Mac, iOS) | `permission.local_network_primer` | HandLive looks for your Android phone on your Wi-Fi network to connect to it directly. | HandLive tìm điện thoại Android trong mạng Wi-Fi để kết nối trực tiếp. |
| SMS-03 E4 | `error.sms_history_failed` | Couldn't load older messages | Không tải được tin cũ hơn |
| SMS-01 E6/E7 | `error.sms_sync_storage` | Couldn't save messages on this device | Không lưu được tin nhắn trên máy này |
| SMS-03 E1 body | `sms.empty_body` | Messages from your phone appear here after the first sync. | Tin nhắn từ điện thoại sẽ hiện ở đây sau lần đồng bộ đầu tiên. |
| CONN-03 E7 | `error.relay_pin_mismatch` | The server's certificate isn't trusted, so HandLive didn't connect over the internet. | Chứng chỉ máy chủ không đáng tin cậy nên HandLive không kết nối qua Internet. |
| CONN-03 E6 | `error.relay_rate_limited` | Too many requests. Trying again in {duration}. | Quá nhiều yêu cầu. Thử lại sau {duration}. |

   Also unspecified: the SIM picker title and the recipient field label of New Message (SMS-04 fields 1, 4), the
   quick-reply field placeholder (SMS-02 API 4), the bubble VoiceOver label (sender, time, status — SMS-03), the SMS
   primer title and the feature-card names/states on Android (SET-01 part B, already noted in S1.2), the
   `PasteCard` empty-state sentence and the one-line hint under the Paste button, and the SMS-04 E3 reason (the
   existing `pairing.reason_missing_sms_permission` fits). Phase 3 owns "Incoming Call" (CONN-04 field 2, CALL-01)
   and the iOS "Calls" tab.

## Pending manual checks

- Both languages at the largest text size (AX5, 200 %): the SET-02 warnings, `clipboard.new_content_banner`,
  `sms.resync_confirm_title`, `sms.contacts_permission_hint`, the Mac Messages pane and the iOS Settings tab.
- On real devices: Android's own wording "airplane mode" (SMS-04 field 8 follows the spec's lowercase form), and that
  the iOS `hiddenPreviewsBodyPlaceholder` shows `sms.notification_hidden_body` with previews hidden.

Status: DONE_WITH_CONCERNS
Summary: 77 new and 15 widened catalog strings (SMS-01…05, SET-02 messages and server actions, CLIP-04, CONN-03, PAIR-03 flow B) are committed and pushed on feat/phase-02-sms-ios-relay; the catalog checker, --docs (no new warning), self-test and CI are green.
Concerns/Blockers: the Android `sms` channel is not specified anywhere and was not added (deviation 1); several Phase 2 texts the UI needs are still unspecified (deviation 9) and the design system disagrees with SMS-04/SMS-01/SMS-05 wording in places (deviation 4).
