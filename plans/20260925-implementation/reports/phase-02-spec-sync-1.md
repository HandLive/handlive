# Phase 2 — spec sync 1: decisions from the S2.1, S2.2, S2.3, T2.1 (batch 1), R2.1, R2.2 (batch 2) reports and the coordinator's answers (batch 3)

Hub `main`, both languages in every commit, pushed (`0d88586..340e1fe` batches 1–2, `340e1fe..32af250` batch 3).
Nested repos (`android/`, `apple/`, `relay/`, `shared/`) untouched; shared tools run read-only.

## Batch 1 — decisions applied

| # | Where (file · section) | Change |
|---|---|---|
| 1 | 00 · 0.4.3 | New bullet "Relay handling of `to`/`from` wrappers and `HR` frames": checks only wrapper / 20-byte `HR` header, never the envelope; malformed → op `error` `BAD_REQUEST`; non-peer `to` → `NOT_PAIRED`; device `from` ignored; `env` re-emitted byte for byte `{"from":"<device_id>","env":<raw env>}` |
| 2 | 00 · 0.4.4; 03 · CONN-04 API 2 | `hl` / `env_b64` = standard base64 with padding of the UTF-8 envelope JSON, ≤ 3,000 characters of base64 (not bytes) |
| 3 | 00 · 0.7.1 | `sms/send` Ack = "Yes (with data)" |
| 4 | 00 · 0.7.3 | `error` row lists `code` ∈ {`NOT_PAIRED`, `NOT_CONNECTED`, `PAYLOAD_TOO_LARGE`, `RATE_LIMITED`, `BAD_REQUEST`} (CONN-03 API 5) |
| 5 | 00 · 0.12.1 | `count` passed as integer → printed without digit grouping; plural texts must read well that way. `args` row: `count` is the exception to "numbers formatted before" |
| 6 | 01 · SET-02 field 28; design system 04-cai-dat | Buttons "Remove from Server" (field 26) / "Delete All" (field 27) next to "Cancel"; "Still to sync" note removed (en, vi) |
| 7 | 01 · SET-02 E5 (vi) | Final period |
| 8 | 01 · SET-03 E3, E4, step 9 | iPhone/iPad texts for E3, E4; local network primer body in step 9 — exactly as proposed |
| 9 | 01 · SET-01 fields 10, 12 | Card names = SET-02 switch labels; status texts for the 5 states; auto-send card uses field 15 ("Auto-send isn't on yet"); SMS primer title |
| 10 | 02 · PAIR-01 field 5, step 5 (en) | "Pair with \<…>?" |
| 11 | 02 · PAIR-01 API 7 | `rv_msg` example now carries `hello_envelope` of vector "QR cặp 1" (`shared/test-vectors/pair-handshake.json`); decoded payload validated against `pair-hello` (OK) |
| 12 | 02 · PAIR-01 API 6 | `attempts_left`: required with `PIN_INVALID`, absent otherwise, 0–3 |
| 13 | 03 · CONN-03 E6, E7 | Texts in field 4 (`{duration}` = remaining `Retry-After`) |
| 14 | 03 · CONN-03 API 6 | Rules of item 1 as logic 1–3 (old rules renumbered 4–6) |
| 15 | 03 · CONN-04 API 1 | `topic` only with APNs; APNs token lowercase hex (refined by batch 2 B3) |
| 16 | 03 · CONN-04 API 2 | `ttl_s` default 30 for `call_incoming` (CALL-01 API 4); item 2 wording |
| 17 | 03 · CONN-04 step 5b, API 2 example, API 4 table; 05 · SMS-02 API 2 | SMS `collapse_key` = the `message_key` (`sms:12847`); call `call:<call_id>`. Example `sms:118` / `sms:sms:12847` → `sms:12847` |
| 18 | 03 · CONN-04 step 5b; 05 · SMS-02 API 2 logic 3 | Cut `message.body` to ≤ 1,000 characters at a code-point boundary (ending "…"); while `env_b64` > 3,000, shorten `message.body` then `thread.snippet`; full text via SMS-01. "by UTF-8 bytes" removed |
| 19 | 04 · CLIP-01 API 5 | `width`, `height`: required when `kind = image`, absent for text |
| 20 | 04 · CLIP-04 field 3, API 2 logic 2 | Banner device word `{device_type}` = "iPhone"/"iPad" from `UIDevice.current.model`, never translated |
| 21 | 04 · CLIP-04 E9, field 5 (vi) | Final periods |
| 22 | 04 · CLIP-04 fields 1, 10 | PasteCard README has no concrete texts → written in CLIP-04: hint under Paste button; empty-state sentence (with "Nothing Received Yet") |
| 23 | 05 · SMS-01 API 1 | `unread` entries have `unread_count ≥ 1` |
| 24 | 05 · SMS-01 E7 | "Couldn't save messages on this device" (see deviation 1: E7 only) |
| 25 | 05 · SMS-02 special requirements | Latency from first `ContentObserver.onChange` of the batch; targets judged at p95 |
| 26 | 05 · SMS-02 API 2 | Items 17, 18 (+ `env_b64` "≤ 3,000 characters", deviation 5) |
| 27 | 05 · SMS-02 API 4 | Group category `HL_SMS_GROUP` (only `HL_SMS_MARK_READ`); quick-reply placeholder "SMS Message" |
| 28 | 05 · SMS-03 E1, E4, special requirements | E1 body, E4 text, bubble VoiceOver label format (label = sender, time, status; message text = accessibility value) |
| 29 | 05 · SMS-04 fields 1, 3, 4, 8, 11, E3, E8 | Recipient label, SIM picker title, counter format (`sms.char_counter`/`sms.part_count`/`sms.char_count` texts), E3 reason = "Missing SMS permission on the phone", vi final periods (E8, field 8 limit, field 11) |
| 30 | 05 · SMS-05 field 2 | Unread count = accessibility label of the row; `ThreadRow` shows only the dot |
| 31 | DS · components/MessageBubble README (en, vi) | "Waiting for phone"; reasons = SMS-04 field 8; counter = SMS-04 field 3 |
| 32 | DS · 2-patterns/05-phan-hoi-va-tai (en) | "Not sent · The phone is in airplane mode"; "Delete from this device anyway?" (vi already matched) |
| 33 | DS · 2-patterns/03-thong-bao (en, vi) | "Not sent yet. Open HandLive to try again." / vi with final period |
| 34 | DS · 2-patterns/04-cai-dat (en; vi) | Resync text = SMS-01 field 6; caption = SMS-05 field 6 (vi already matched); item 6 note removed (en, vi) |
| 35 | Phase file · S2.1 row | Android `sms` notification channel dropped |
| 36 | Phase file · Requirements | Latency from `ContentObserver.onChange`, judged at p95; "Sent" includes carrier radio time |
| 37 | Phase file · Risks | Rule of item 18 |

## Batch 2 — decisions applied

| # | Where | Change |
|---|---|---|
| A1 | 03 · CONN-04 field 4, step 9b, API 4 (table, example `"thread-id":"sms"`, new logic 3); 05 · SMS-02 step 11, API 4 (`threadIdentifier` row, logic 3) | APNs `thread-id` generic: `sms` for SMS, `calls` for calls (relay sends exactly this, checked in `relay/crates/relay-push/src/payload.rs`); I-NSE sets `threadIdentifier` after decrypting; locked device keeps the generic group. 0.4.4 and the API 2 example do not mention thread-id (no change) |
| A2 | 00 · 0.4.3; 03 · CONN-03 API 6 logic 1; 02 · PAIR-01 API 7 logic 4 | Explicit exception: on the rendezvous the relay reads `env.type` and decodes the unencrypted `pair` payload to block a PIN-mode `pair/hello` |
| B1 | Phase file · R2.2, A2.2 rows | R2.2: no relay queue, one retry inside the request (500/503/network), then 502; A2.2: phone `push_outbox` retries until its deadline (30 s calls, 24 h SMS) |
| B2 | 03 · CONN-04 E3, API 2 errors, API 3/API 4 responses | Dead token (FCM `UNREGISTERED`, APNs 410) → token deleted, 409 `PUSH_TOKEN_MISSING`; APNs 400 `BadDeviceToken`/`DeviceTokenNotForTopic` and 403 → configuration error, 502; 500/503/network → one retry after 500 ms, then 502 |
| B3 | 00 · 0.4.4; 03 · CONN-04 API 1, API 2 (`ttl_s`, `collapse_key`, errors, logic 2), API 3 logic, API 4 logic 1 | `ttl_s` 0–86,400; FCM `collapse_key` always `wake`, TTL capped at 60 s; `sound: "default"`; push to a Mac → 400; `collapse_key` printable ASCII; FCM `topic` ignored by the relay (senders never send it); APNs tokens stored lowercase (400 only for non-hex) |
| B4 | 03 · CONN-03 API 6 logic 1, 5; Redis block | Non-UUIDv8 destination → `BAD_REQUEST` without `to`; `NOT_CONNECTED` from PUBLISH receiver count 0 or a failed publish; `EXISTS presence:<to>` line removed; presence only feeds `presence` op and `GET /v1/pairs` |
| B5 | 00 · 0.10; 03 · CONN-03 special requirements, API 6 logic 4; Redis block | "2 MiB/s per pair and direction"; `INCR rl:<device_id>:relay:<minute>` line removed |
| B6 | 03 · CONN-03 API 4 logic 6 | Upgrade counts against the REST limit; frame > 1 MiB → close 4400; ping every 15 s, 4411 after 45 s silence (pongs count); receiver with 32 MiB queued or write stuck 10 s → 4500. All three codes already in 0.8.3 → 0.8.3 unchanged |
| B7 | 00 · 0.9.4 Redis table | `usage_salt:<YYYY-MM>` (40 days), `maintenance:<day>` (25 h lock), `wake:<device_id>:<reason>` (300 s, released on send failure) |
| B8 | 00 · 0.6.5 | `device_hash` = SHA-256(16-byte `device_id` ‖ salt); salt 32 random bytes only in Redis; unlinkable after expiry; Redis restart mid-month → new salt |
| B9 | 02 · PAIR-01 API 8 (response table + logic 2) | New 400 row: `device_a` not Android or `device_b` not Mac/iPhone/iPad; locked-out device = not registered (404) |
| B10 | 02 · PAIR-01 API 7 (response table + logic 5) | `rv_msg` without another member → `error NOT_CONNECTED`; expired `rv_id` recreated by `rv_join` (`peer_present = false`), device times out per E3; "or has expired" removed from the `BAD_REQUEST` row |
| B11 | 01 · SET-02 API 2 logic 5 + Redis block | Presence and challenge deleted first, then connection closed → peers get no `presence` offline; with `revoke_pairs=false` their connections just drop the pair |
| B12 | 00 · 0.7.4 (description column; path cells unchanged for the table checker) | `?include_revoked=` other than `true`/`false` → 400; `DELETE /v1/devices/me` without `revoke_pairs` → 400 (0.8.2 format) |

No new UI text in batch 2.

## Batch 3 — decisions applied

| # | Where | Change |
|---|---|---|
| C1 | 01 · SET-02 E7 | The "Delete from this device anyway?" alert: "Delete" (destructive) and "Cancel" / "Xóa" (phá hủy) and "Hủy"; "Delete" → delete locally |
| C2 | 01 · SET-03 E3, E4 | Mac texts added before the iPhone/iPad ones. Pane names checked against SET-03 API 4 logic 1 and API 5 logic 4 (same paths): "System Settings › Notifications › HandLive" / "Cài đặt hệ thống › Thông báo › HandLive"; "System Settings › Privacy & Security › Local Network" / "Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Mạng cục bộ". E3 says **missed calls**, not incoming calls (deviation 13) |
| C3 | 05 · SMS-05 step 8 | No visible count: the row keeps only the unread dot, its accessibility label carries the count (field 2) |
| C4 | 03 · CONN-04 API 1 (`topic` row, errors, logic) | Only the APNs `topic` equal to `RELAY_APNS_TOPIC` (I-APP bundle id, relay environment) is accepted; any other → 400 in the relay error format (0.8.2) |
| C5 | design system (en + vi) | 1-foundations/09-viet-noi-dung: exception note after the Numbers table (plural counts have no grouping, 0.12.1), same sentence in the English section, sync row now "Đã tải 1500 tin" (Downloaded 1500 messages), airplane mode gloss in lowercase. 2-patterns/05-phan-hoi-va-tai: "Waiting for phone" (2 places, SMS status), "Delete All HandLive Data", "Downloaded 1500 messages" / "Đã tải 1500 tin", empty states with the SMS-03 E1 and CLIP-04 field 10 sentences, vi SET-02 E5 final period. components/Alert: the SET-02 field 28 buttons. components/PasteCard: hint under the Paste button, empty-state sentence, and the not-connected state of CLIP-04 E5 (disabled Paste button, "Not connected to the phone") instead of the CLIP-01 queued-send toast |

## Deviations and interpretations (closest correct change)

1. **24 (SMS-01 E6/E7):** text applied to E7 only. E6 is a provider read error on the phone; "…on this device" would be false.
   E6 already shows field 1 "Couldn't sync — will try again when connected" (catalog `sms.sync_failed` lists E4, E6, E7).
2. **29 (SMS-04 fields):** the decision's mapping was swapped — field 1 is Recipient, field 4 is Sending SIM. Recipient
   label → field 1, SIM picker title → field 4.
3. **5 → SMS-01 field 2:** example "Downloaded 1,500 messages" / "Đã tải 1.500 tin" would contradict 0.12.1 → now
   "Downloaded 1500 messages" / "Đã tải 1500 tin".
4. **17/18 → rest of CONN-04:** also fixed lines that contradicted them: special requirements "Limits" (→ step 5b) and
   "Anti-spam" (`apns-collapse-id` per SMS message or call); API 4 `call_missed` row aligned with CALL-04 API 5
   (`call:<call_id>` when known, else `calllog:<entry_id>`; the old row had the opposite priority).
5. **2 → SMS-02 API 2:** its `env_b64` row also said "≤ 3,000 bytes" → characters.
6. **A1 format:** I-NSE sets `threadIdentifier` = `sms:<pair_id>:<thread_id>` (the SMS-02 API 4 format of local
   notifications), not `sms:<thread_id>`, so push-built and app-built notifications of one conversation share a group.
7. **A2 wording:** the brief said "to enforce the PIN attempt limit"; PAIR-01 API 7 logic 4 and R2.1 describe blocking a
   PIN-mode `pair/hello` (PIN pairing is LAN-only). Written that way.
8. **B1 → CONN-04:** the relay's one retry is also written in CONN-04 API 3/4 responses (with B2), so the phase file
   does not state behaviour the leaf spec lacks.
9. **B3 changes batch-1 item 15:** FCM `topic` is ignored by the relay (no 400); APNs tokens accepted in any hex case and
   stored lowercase (400 only for non-hex). Senders still send lowercase hex and no topic with FCM (sender-strict).
10. **B5:** CONN-03 special requirements and API 6 logic 4 also say "per pair and direction".
11. **9:** card states "On"/"Off" reuse `common.on`/`common.off`; names reuse SET-02 labels ("Take Calls on Mac",
    "Use Phone as Webcam" are Phase 4/5, no catalog key yet).
12. **22:** texts written in CLIP-04 only; `PasteCard` README still described them without wording (fixed in batch
    3, C5).
13. **C2 (batch 3), Mac E3:** "…new SMS messages and **missed calls** don't appear…" / "…SMS mới và **cuộc gọi nhỡ**…"
    instead of "incoming calls" / "cuộc gọi đến". SET-03 E3 itself says the Mac still shows the call panel for
    incoming calls while notifications are off; only SMS and missed-call notifications are lost. This is also the
    existing catalog text of `setup.notifications_denied_mac`, so no catalog change is needed. E4 is exactly as given.
14. **C5 extras:** besides the listed leftovers I aligned three more design-system statements that contradicted the
    leaf specs: the SMS status "Waiting for phone" in 05-phan-hoi-va-tai (CONN-02's "2 messages waiting for the phone"
    is kept), the PasteCard not-connected state (CLIP-04 E5, API 4 logic 1: no queued resend on iPhone), and the
    SMS-03 E1 empty-state sentence. MessageBubble `preview.html` is left as is: it is an HTML preview, and showing a
    two-part counter needs the multi-part `{limit}` rule (question 1).

## Commits (hub `main`)

| Hash | Subject |
|---|---|
| e4cc38a | docs(spec): pin relay wrapper handling, push encoding and plural counts in 0.x |
| 6ad78a4 | docs(spec): write the Phase 2 setup and settings texts in SET-01, SET-02 and SET-03 |
| 69be89d | docs(spec): fix the pairing confirmation title, pair/error attempts and the rv_msg example |
| b8785e4 | docs(spec): settle relay forwarding, push token, TTL, collapse key and SMS cut in CONN-03/04 |
| 8e83e92 | docs(spec): require image sizes and write the iPhone and iPad clipboard texts |
| 495c0db | docs(spec): write the Phase 2 SMS texts and settle push and latency rules in SMS-01…05 |
| db40a53 | docs(design-system): align SMS statuses, reasons, counter and settings texts with the leaf specs |
| 6f7066d | docs(plans): align the Phase 2 criteria and risks with the SMS push and latency rules |
| bd599e0 | docs(spec): record the relay's rendezvous exception, salts, Redis keys and limits in 0.x |
| 16498e6 | docs(spec): state the rendezvous and pair registration rules the relay enforces in PAIR-01 |
| 304cf2c | docs(spec): align CONN-03 and CONN-04 with the relay's routing, limits and push behaviour |
| 5ffb87d | docs(spec): delete presence before closing the connection when a device leaves the relay |
| a824556 | docs(spec): let I-NSE group SMS pushes by conversation after decrypting |
| 340e1fe | docs(plans): move the push retry queue from the relay card to the phone card |
| 57ce979 | docs(spec): name the SET-02 E7 buttons and write the Mac texts of SET-03 E3 and E4 (batch 3) |
| 73deeae | docs(spec): accept only the relay's configured APNs topic in CONN-04 API 1 (batch 3) |
| 279b0e4 | docs(spec): show no unread count in SMS-05 step 8 (batch 3) |
| 32af250 | docs(design-system): align counts, empty states, delete wording and the PasteCard with the leaf specs (batch 3) |

All signed off (Hồ Xuân Dũng <me@hxd.vn>), no AI trailer; `.githooks/check-commits.sh origin/main..HEAD` → "commit sạch:
đã kiểm 14 commit" (batches 1–2) and "đã kiểm 4 commit" (batch 3); `git pull --rebase` (up to date both times),
`git push origin main` → `0d88586..340e1fe`, then `340e1fe..32af250`.

## Checks (final state, real output)

After batch 3 (hub at 32af250; the local `shared/` checkout is at 335018c, which added 4 catalog strings meanwhile):

```text
$ python3 tools/docs/validate_design_docs.py | tail -1
files=16 leaves=66 problems=0
$ python3 tools/docs/check_bilingual_docs.py | tail -1
pairs=67 missing=0 problems=0 warnings=0
$ cd shared && tools/.venv/bin/python tools/schemas/check_schemas.py      (exit 1)
  FAIL 03-connectivity.md:880 [push#apns-payload]: aps/thread-id: 'sms' does not match '^sms:[0-9]+$'
  FAIL 03-connectivity.vi.md:867 [push#apns-payload]: aps/thread-id: 'sms' does not match '^sms:[0-9]+$'
  … enum khớp bảng spec: 16 · ví dụ 01–08: 189 · envelope trong env_b64/hl: 19 · tin trong test vector: 37
  THẤT BẠI: 2
$ tools/.venv/bin/python tools/strings/check_strings.py --docs | tail -1
== 288 strings, 0 errors, 12 warnings        (en/vi of pairing.pin_instructions, setup.applications_drag_hint,
   setup.keys_failed, setup.login_item_approval_mac, status.connected_internet_to, status.connected_usb_to) — OK
```

- `check_schemas.py` was green (XANH) after every batch-1 commit. The 2 FAILs come from batch 2 A1: the CONN-04 API 4
  example now has `"thread-id":"sms"`, and `shared/schemas/push.schema.json#/$defs/apns-payload` still requires
  `^(sms:[0-9]+|calls)$`. The shared agent has to widen the pattern (see Follow-ups). **Until it does, `ci-shared`
  fails on this example**, because CI checks out hub `main`. Expected, as agreed.
- `--docs`: 16 → 12 warnings. The Mac texts of SET-03 E3/E4 (batch 3) now quote `setup.notifications_denied_mac` and
  `setup.local_network_denied_mac`. No new warning in any batch; new spec texts not yet in the catalog do not warn.
- `tools/docs/apple_diacritics.py` dry run on every changed `.vi.md`: nothing to fix except the intentional "don't"
  example "Huỷ Ghép Nối" in 09-viet-noi-dung.vi.md (unchanged, already in `HEAD`).

## New or changed UI texts for the catalog

Already added by the shared agent (handlive-shared 335018c, texts identical to the spec — nothing to do):

| Key (as added) | en | vi | Spec · field |
|---|---|---|---|
| `permission.sms_primer_title` | Use SMS on Your Mac and iPhone | Dùng SMS trên Mac và iPhone | SET-01 field 12 |
| `permission.status_needs_permission` | Needs permission | Cần cấp quyền | SET-01 field 10 (state `needs_permission`) |
| `permission.status_denied` | Permission denied | Quyền bị từ chối | SET-01 field 10 (state `permanently_denied`) |
| `permission.status_unsupported` | Not supported on this phone | Điện thoại này không hỗ trợ | SET-01 field 10 (state `unsupported`) |

New texts (propose new keys):

| Proposed key | en | vi | Spec · field | Notes |
|---|---|---|---|---|
| `settings.remove_from_server_confirm` | Remove from Server | Xóa khỏi máy chủ | SET-02 field 28 | all; confirm button of field 26 |
| `settings.delete_all_confirm` | Delete All | Xóa toàn bộ | SET-02 field 28 | all; confirm button of field 27 |
| `setup.notifications_denied_ios` | Notifications are off, so new SMS messages and incoming calls don't appear while HandLive is closed. Turn them on in Settings › Notifications › HandLive. | Thông báo đang tắt nên không thấy SMS mới và cuộc gọi đến khi HandLive đóng. Bật lại trong Cài đặt › Thông báo › HandLive. | SET-03 E3 | ios; with `common.open_settings` |
| `setup.local_network_denied_ios` | HandLive can't look for the phone on Wi-Fi. Turn on HandLive in Settings › Privacy & Security › Local Network. | HandLive không tìm được điện thoại trong mạng Wi-Fi. Bật HandLive trong Cài đặt › Quyền riêng tư & Bảo mật › Mạng cục bộ. | SET-03 E4 | ios |
| `permission.local_network_primer` | HandLive looks for your Android phone on your Wi-Fi network to connect to it directly. | HandLive tìm điện thoại Android trong mạng Wi-Fi để kết nối trực tiếp. | SET-03 step 9 | macos, ios; title `permission.local_network_primer_title` |
| `error.relay_rate_limited` | Too many requests. Trying again in {duration}. | Quá nhiều yêu cầu. Thử lại sau {duration}. | CONN-03 E6 · field 4 | macos, ios; arg `duration` string (like `status.retry_in`) |
| `error.relay_pin_mismatch` | The server's certificate isn't trusted, so HandLive didn't connect over the internet. | Chứng chỉ máy chủ không đáng tin cậy nên HandLive không kết nối qua Internet. | CONN-03 E7 · field 4 | macos, ios (android too if its relay client shows it) |
| `clipboard.paste_hint` | Tap Paste to send what you just copied. | Chạm Dán để gửi nội dung vừa sao chép. | CLIP-04 field 1 | ios; one line under the Paste button (PasteCard) |
| `clipboard.nothing_received_body` | Content copied on the phone or Mac appears here while HandLive is open. | Nội dung sao chép trên điện thoại hoặc Mac sẽ hiện ở đây khi HandLive đang mở. | CLIP-04 field 10 | ios; under `clipboard.nothing_received` |
| `error.sms_sync_storage` | Couldn't save messages on this device | Không lưu được tin nhắn trên máy này | SMS-01 E7 | macos, ios |
| `sms.empty_body` | Messages from your phone appear here after the first sync. | Tin nhắn từ điện thoại sẽ hiện ở đây sau lần đồng bộ đầu tiên. | SMS-03 E1 | macos, ios; under `sms.empty_title` |
| `error.sms_history_failed` | Couldn't load older messages | Không tải được tin cũ hơn | SMS-03 E4 | macos, ios; with `common.retry` |
| `a11y.sms_bubble_received` | {sender}, {time} | {sender}, {time} | SMS-03 special requirements | macos, ios; args `sender`, `time` string; message text is the accessibility value |
| `a11y.sms_bubble_sent` | You, {time}, {status} | Bạn, {time}, {status} | SMS-03 special requirements | macos, ios; args `time`, `status` string (`status` = `sms.status_*` text) |
| `sms.recipient_label` | To: | Đến: | SMS-04 field 1 | macos, ios; New Message |
| `sms.choose_sim` | Choose SIM | Chọn SIM | SMS-04 field 4 | macos, ios; SIM picker title (also opened by E6) |

Existing keys — spec now quotes them or changed around them (catalog text unchanged unless noted):

| Key | Spec · field | Catalog action |
|---|---|---|
| `common.on`, `common.off` | SET-01 field 10 (states `ready`, `off`) | add SET-01 to `specs`, comment "feature card state" |
| `settings.auto_send`, `settings.sms_messages` | SET-01 field 10 (card names) | add SET-01 to `specs` |
| `settings.calls` | SET-01 field 10 (card name) | widen `platforms` to android, add SET-01 |
| `settings.auto_send_not_on` | SET-01 field 10 (auto-send card) | none |
| `common.delete` ("Delete" / "Xóa") | SET-02 E7: destructive button of "Delete from this device anyway?", with `common.cancel` (batch 3, C1); no longer the field 28 button | update comment: E7 only |
| `setup.notifications_denied_mac` | SET-03 E3 (Mac), batch 3 C2 — text quoted exactly as in the catalog ("…missed calls…") | none (deviation 13) |
| `setup.local_network_denied_mac` | SET-03 E4 (Mac), batch 3 C2 — identical to the catalog | none |
| `pairing.confirm_title` | PAIR-01 field 5 now "Pair with …?" | none (catalog already right) |
| `clipboard.new_content_banner`, `clipboard.new_image_banner` | CLIP-04 field 3, API 2 | none (`{device_type}` now in spec) |
| `clipboard.nothing_received` | CLIP-04 field 10 | add nothing; now quoted in the leaf spec |
| `sms.compose_placeholder` ("SMS Message" / "Tin nhắn SMS") | SMS-02 API 4 quick-reply placeholder | add SMS-02 to `specs` (or a separate `sms.quick_reply_placeholder`, same text) |
| `sms.char_counter`, `sms.part_count`, `sms.char_count` | SMS-04 field 3 | none |
| `pairing.reason_missing_sms_permission` | SMS-04 E3 | add SMS-04 to `specs` |
| `sms.unread_count` | SMS-05 field 2 | add SMS-05 to `specs` |
| `sms.sync_downloaded` | SMS-01 field 2 example "Downloaded 1500 messages" | comment: count printed without grouping (0.12.1) |
| `error.server_unreachable`, `error.clip_send_failed`, `sms.quick_reply_not_sent`, `error.sms_limit_exceeded` | vi final periods added in SET-02 E5, CLIP-04 E9/field 5, SMS-04 E8/fields 8, 11 | none (catalog already has them) |
| `clipboard.not_connected_to_phone` | PasteCard not-connected state now points to CLIP-04 E5 (batch 3, C5) | none |
| `sms.sync_downloaded`, `sms.status_pending`, `sms.empty_title` | design system (batch 3, C5) now quotes "Downloaded 1500 messages", "Waiting for phone", "No Messages Yet" with the SMS-03 E1 body | none |

Batch 3 adds no new key: C1 and C2 reuse existing catalog texts, C3 and C4 carry no UI text, and C5 only aligns the
design system with texts already listed above.

## Follow-ups for other agents

- **Shared:** `push.schema.json` `thread-id` → `^(sms|calls)$` (fixes the 2 FAILs); `push-envelope.json` vectors:
  `apns_payload.thread-id` → `sms`, `push_request.collapse_key` `sms:sms:12847` → `sms:12847` (+ build/verify scripts);
  `relay-rest#push-request`: `ttl_s` max 86,400, `collapse_key` printable ASCII; catalog per the table above.
- **Relay:** `Reason::default_ttl_s` for `call_incoming` 60 → 30 (CONN-04 API 2 now 30); rest of batches 2–3 document
  the current relay behaviour (including the `RELAY_APNS_TOPIC` check, C4).
- **Android:** SMS push `collapse_key` = `message_key`; code-point cut loop of step 5b; `push_outbox` owned by A2.2.
- **Apple:** I-NSE sets `threadIdentifier` = `sms:<pair_id>:<thread_id>`; `HL_SMS_GROUP`; new texts once in the catalog.
- **Design system:** the leftovers listed after batch 2 are aligned in batch 3 (C5), except MessageBubble
  `preview.html` ("2 tin SMS"; question 1). The design-system artifact needs republishing after the batch 1 and 3 edits
  (CLAUDE.md: docs first, then the artifact).

## Unresolved questions

The four questions of batches 1–2 were answered by C1–C4 and are applied.

1. SMS-04 field 3 defines `{limit}` only for one part ("0/160", "120/160 · 1 message"). What does `{limit}` show once
   the text needs several parts: the capacity of the current number of parts (for example "96/134 · 2 messages" for
   UCS-2, 2 × 67), or something else? M2.1 and I2.1 need it for the counter; MessageBubble `preview.html` waits for it.

Status: DONE_WITH_CONCERNS
Summary: All 37 batch-1, 15 batch-2 and 5 batch-3 decisions are applied in both languages in 18 signed-off hub commits, pushed (0d88586..32af250); both doc checkers print problems=0, --docs drops from 16 to 12 warnings with none new, and the catalog table lists 16 keys still to add, the 4 the shared agent has already added, and the changes needed on existing keys.
Concerns/Blockers: check_schemas.py (and ci-shared) fails on the CONN-04 API 4 example ("thread-id":"sms", decision A1) until the shared agent widens push.schema.json and the push vectors — expected; batch 3 deviation 13 (Mac E3 says "missed calls", matching SET-03 E3 and the existing catalog text) and the open multi-part {limit} question need a glance.
