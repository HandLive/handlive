# Phase 2 — spec sync 1: decisions from the S2.1, S2.2, S2.3, T2.1 (batch 1), R2.1, R2.2 (batch 2) reports, the coordinator's answers (batch 3), the shared sync (batch 4) and the A2.1, A2.2 reports (batch 5)

Hub `main`, both languages in every commit, pushed (`0d88586..340e1fe` batches 1–2, `340e1fe..32af250` batch 3,
`7bf7f25..0978671` and `0978671..8868120` batch 4, `f67d57d..d7ed548` batch 5).
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

## Batch 4 — decisions applied

Source: `phase-02-shared-sync-1.md` (spec points 2, 3 and 5); addendum from the "Notes" of the R2.2 follow-up.

| # | Where | Change |
|---|---|---|
| D1 | 03 · CONN-04 API 2, `collapse_key` row (the only place that said "printable ASCII"; API 4 only names the header) | "1–64 visible ASCII characters (0x21–0x7E, no spaces), because it becomes the `apns-collapse-id` HTTP/2 header" |
| D2 | 03 · CONN-04 step 5b; 05 · SMS-02 API 2 logic 3; 05 · SMS-01 `thread` object, `snippet` row | The cut rule of Android `PushEnvelopeBuilder` and `shared/tools/vectors/push_sms_truncation.py` (both read): a body over 1,000 code points keeps its first 999 + "…"; while `env_b64` is over 3,000 characters the body becomes the longest shorter cut that fits (fewer code points each step, ending "…"), down to "…" alone; only then `thread.snippet` is cut the same way; if nothing fits, no alert push is sent and SMS-01 catches up. `snippet` itself = the newest body's first 160 code points without "…" (as Android `SmsObjects` builds it). Same wording in both languages (deviation 15) |
| D3 | 00 · 0.11 status paragraph; 02 · PAIR-01 field 6; 01 · SET-03 E1, E5, step 5 | The six texts quoted exactly as the catalog has them, en in `X.md`, vi in `X.vi.md`: `status.connected_internet_to` and `status.connected_usb_to` (with `status.connected_wifi_to` for the set) in 0.11; `pairing.pin_instructions` under the six digits on Mac/iOS (PAIR-01 field 6); `setup.keys_failed` with "Try Again" (SET-03 E1), `setup.login_item_approval_mac` with "Open System Settings" (E5), `setup.applications_drag_hint` (step 5, E2). `check_strings.py --docs` → 0 warnings |
| D4 (addendum) | 02 · PAIR-01 API 7, response table `error` row + logic 5 | An `rv_msg` for a rendezvous the sender is not in (never joined, or expired) → `error BAD_REQUEST`; `NOT_CONNECTED` stays for "no other member" |
| D5 (addendum) | 03 · CONN-04 API 4, Response + logic 1 | 403 `ExpiredProviderToken` / `InvalidProviderToken` → the relay signs a new provider token and tries once more, then 502; other 403 reasons and 400 stay configuration errors (502) |
| APNs not configured (addendum) | 03 · CONN-04 API 1 logic, API 4 logic 1 | Without an APNs configuration no topic matches (`PUT` → 400), no APNs token is stored, and a later push to that device answers 409 `PUSH_TOKEN_MISSING` — checked in `relay/crates/relay-server/src/routes/devices.rs` (read-only) |

No catalog text looked wrong against the spec: the Android names it cites ("Add Device" / "Thêm thiết bị", "Enter PIN"
/ "Nhập mã PIN") and the System Settings paths match PAIR-01, PAIR-02 and SET-03. No catalog change, no new UI text.
Note for the gate G1 real-device checks (not a change): macOS 15 shows the login items pane as "Login Items &
Extensions"; the spec and `setup.login_item_approval_mac` say "Login Items" (the macOS 13–14 name).

## Batch 5 — decisions applied

Source: the "Spec deviations and proposals" of `phase-02-A2.1.md` (points 1, 2, 7) and `phase-02-A2.2.md` (points 1,
3, 5, 8). Where a decision says "as the code does", the Android code on `feat/phase-02-sms-ios-relay` was read
(read-only): `feature/relay` (`RelayFeature`, `RelayConnector`, `RelayConnection`, `RelayRegistrar`, `RelayConstants`),
`core/transport` (`RelayApi`, `ControlServer`, `ControlSession`), `feature/sms` (`SmsSendPipeline`, `SimSelection`,
`SendRegistry`, `SmsConstants`) and `app` (`SettingsScreen`).

| # | Where | Change |
|---|---|---|
| E1 | 03 · CONN-03 description, step 2 (component now also A-SVC); 00 · 0.10 `RELAY_IDLE_DISCONNECT` note | The phone cannot tell that a client waits on the relay, so it connects only on a demand, the list of `RelayFeature`: the service starts or the relay is switched on while a relay-registered pair has no session; a LAN session ends without `session/bye`; SMS-02 detects a new message while such a pair has no session; the phone joins a pairing rendezvous (QR with `rv`); an FCM wake-up. While the last demand is less than `RELAY_IDLE_DISCONNECT` (5 min) old, or a relayed session or a rendezvous is open, it reconnects per `RECONNECT_BACKOFF` and a network change retries at once; it leaves after 5 min without relayed sessions, rendezvous or traffic and comes back only on a new demand. Notes column: no demand and no wake-up push → the client stays in `WaitingPeer` (E5) |
| E2 | 02 · PAIR-01 API 8 (404 row, logic 1, new logic 6), E8; PAIR-02 API 1 logic 3 | One 404 `DEVICE_NOT_FOUND` for an unknown caller and an unknown peer. Either device of the pair may call (`sub` = `device_a` or `device_b`, else 403). Every device with `relay_registered = 0` retries when a network is available, so the device that registers with the relay last completes the pair and the other gets 200 on its next call. On 404 the device registers itself again once (`POST /v1/devices`) and repeats the call (`RelayApi.authorized`); a second 404 → the next call for that pair waits 24 h (`RelayRegistrar`, `PAIR_RETRY_AFTER_404_MILLIS`). No new error code |
| E3 | 03 · CONN-02 API 4 (new paragraph), E7, step 7; CONN-03 API 6 new logic 7; 02 · PAIR-03 API 2 response | A relayed session has no WebSocket close between the peers (the `/v1/relay` link stays open, no close code reaches the peer), so a device always sends `session/bye` before it ends one: `revoked`, `replaced`, `update` as defined, `shutdown` for every other end (quit, sleep, background, relay switched off, the ends that close an established LAN session with 4400, 4410, 4411 or 4500). The receiver ends the session on `session/bye`: `replaced` counts as 4409 (E7), any other reason as 1000. Step 7 no longer "closes" the relay session with 4409 |
| E4 | 03 · CONN-03 E7, field 4; 01 · SET-02 field 21 | E7 applies on any device, Android included. Android shows E3 and E7 in place of the description under "Internet Connection" (SET-02 field 21), which is what `SettingsScreen` already does for E3 |
| E5 | 05 · SMS-04 step 6, API 1 logic 2 | One order everywhere = the API 1 error table = `SmsSendPipeline.accept`: `feature.sms` → `SEND_SMS` → parameters (`BAD_REQUEST`) → text length (`PAYLOAD_TOO_LARGE`) → recipient (`SMS_INVALID_ADDRESS`) → SIM (`SMS_SIM_UNAVAILABLE`). Step 6 had the recipient before the text. The envelope `id` is de-duplicated before the checks and `local_id` right after the parameters (an accepted `local_id` skips the remaining checks). Logic 2: the SIM of logic 3 is chosen first for the normalization region (the network's or the phone's region when none, as `SimChoices.countryIso`), and the address refusal comes before the SIM refusal |
| E6 | 05 · SMS-04 API 4 logic 1, step 10; 00 · 0.10 `SMS_SEND_MATCH_WINDOW` note | The window of `SendRegistry.match`: an entry with the same address and text that is still waiting for its final result (`sent` = every part sent, or `failed`) or got it at most `SMS_SEND_MATCH_WINDOW` (60 s) ago |
| E7 | 01 · SET-01 field 17; DS · 2-patterns/03-thong-bao (en, vi) | "Lan's MacBook needs SMS permission on this phone — tap to allow" / "MacBook của Lan cần quyền SMS trên điện thoại — chạm để cho phép", plus "(the same text whichever SMS permission is missing)". Wording taken from the existing `pairing.reason_missing_sms_permission` ("Missing SMS permission on the phone" / "Thiếu quyền SMS trên điện thoại") and matching the A2.1 proposal |

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
15. **D2 (batch 4), snippet step:** the brief says "only then cut `thread.snippet` to 160 code points without '…'".
    That is how SMS-01 builds the snippet, and it is now written in the SMS-01 `snippet` row. In the push, though, the
    Android code (`fitSnippet`) and the vector "crowded group conversation" (snippet 160 → 89 = 88 + "…") shorten the
    snippet like the body: the longest cut that fits, ending with "…". Step 5b and SMS-02 API 2 logic 3 say "cut the
    same way", following the code and the vectors as D2 asks.
16. **E1, network change:** the decision lists "a network change" among the demands. In the code a network change
    creates no demand: `RelayConnector.networkChanged()` restarts a waiting reconnect at once (backoff back to 0) and
    runs only while a demand is open (it also re-runs the registrations). Step 2 therefore says "a network change retries
    at once". The SMS trigger is any new message SMS-02 detects (received or sent from the phone), not only an incoming
    one, so step 2 says "SMS-02 detects a new message".
17. **E3, reasons for the other ends:** `session/bye` defines only `revoked|shutdown|replaced|update`. Every end without
    a reason of its own uses `shutdown`, as the code already does for relay off (`ControlServer.closeSessions`);
    handshake-time closes (4401, 4408, 4426, 4429) have no session to say goodbye on. No new reason value.
18. **E4, where Android shows it:** the decision widens E7 only; I also wrote where the phone shows the text (under
    "Internet Connection", SET-02 field 21), as `SettingsScreen` does for E3 and as A2.2 proposed.
19. **E6, 0.10:** `SMS_SEND_MATCH_WINDOW` (60 s) already existed in 0.10, contrary to A2.1 ("the spec gives no
    window"); the leaf texts lacked the "still waiting for the final result" half. The 0.10 note now says the same.

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
| 83a2577 | docs(spec): pin the push collapse key characters and the exact SMS cut rule (batch 4: D1, D2) |
| 0978671 | docs(spec): quote the catalog texts that 0.11, PAIR-01 and SET-03 only described (batch 4: D3) |
| 8868120 | docs(spec): record the relay's rendezvous and APNs provider-token answers (batch 4 addendum: D4, D5, APNs not configured) |
| c406132 | docs(spec): let either device register the pair and retry after a 404 in PAIR-01 API 8 (batch 5: E2) |
| 8673dba | docs(spec): list when the phone connects to the relay in CONN-03 step 2 (batch 5: E1) |
| 9c69969 | docs(spec): send session/bye before ending a relayed session (batch 5: E3) |
| eee8c6b | docs(spec): apply the relay pin mismatch to every device, Android included (batch 5: E4) |
| 5d867af | docs(spec): keep one order of the SMS-04 refusal checks (batch 5: E5) |
| 9bc1a1f | docs(spec): state the SMS_SEND_MATCH_WINDOW rule of the Sent-box match (batch 5: E6) |
| d7ed548 | docs(spec): use one permission suggestion text for every SMS permission (batch 5: E7) |

All signed off (Hồ Xuân Dũng <me@hxd.vn>), no AI trailer; `.githooks/check-commits.sh origin/main..HEAD` → "commit sạch:
đã kiểm 14 commit" (batches 1–2), "đã kiểm 4 commit" (batch 3), "đã kiểm 2 commit" and "đã kiểm 1 commit" (batch 4);
`git push origin main` → `0d88586..340e1fe`, `340e1fe..32af250`, `7bf7f25..0978671`, then `0978671..8868120` (the
coordinator's and other agents' hub commits in between were already on `main`). For the last push `git pull --rebase`
refused to run because other agents had uncommitted files in the shared working tree; the push was a fast-forward, so
nothing was missing. Two later local commits of another agent (fd4bb81, dd852c7) were left for that agent to push.
Batch 5: `.githooks/check-commits.sh origin/main..HEAD` → "commit sạch: đã kiểm 7 commit"; `git push origin main` →
`f67d57d..d7ed548` (fast-forward, working tree clean).

## Checks (final state, real output)

After batch 5 (hub at d7ed548; `shared/` at b07271f):

```text
$ python3 tools/docs/validate_design_docs.py | tail -1
files=16 leaves=66 problems=0
$ python3 tools/docs/check_bilingual_docs.py | tail -1
pairs=67 missing=0 problems=0 warnings=0
$ cd shared && tools/.venv/bin/python tools/strings/check_strings.py --docs | tail -5
  en: 303 of 304 texts found in 50 English docs
  WARN notification.permission_sms_read [en]: not quoted in the English specs
  vi: 303 of 304 texts found in 50 Vietnamese docs
  WARN notification.permission_sms_read [vi]: not quoted in the Vietnamese specs
== 304 strings, 0 errors, 2 warnings
$ tools/.venv/bin/python tools/schemas/check_schemas.py      (exit 0)
  … enum khớp bảng spec: 16 · loc-key có trong catalog: 3 · ví dụ 01–08: 191 · envelope trong env_b64/hl: 31
  · mẫu dương: 69 · mẫu âm: 157 · ví dụ catalog chuỗi giao diện: 1 · tin trong test vector: 52
  XANH: mọi kiểm tra đạt
```

The 2 `--docs` warnings are expected: E7 changes the SET-01 field 17 text, and the catalog still has the old
`notification.permission_sms_read` texts. They go back to 0 once the shared catalog takes the texts below. Each of the 7
commits was checked with the two doc checkers before it was made (problems=0 every time); `apple_diacritics.py` dry run
on every changed `.vi.md`: nothing to fix.

After batch 4 and its addendum, history (hub at 8868120; `shared/` at b07271f, the head of `phase-02-shared-sync-1.md`; same
output after 0978671 and after 8868120):

```text
$ python3 tools/docs/validate_design_docs.py | tail -1
files=16 leaves=66 problems=0
$ python3 tools/docs/check_bilingual_docs.py | tail -1
pairs=67 missing=0 problems=0 warnings=0
$ cd shared && tools/.venv/bin/python tools/strings/check_strings.py --docs | tail -3
  en: 304 of 304 texts found in 50 English docs
  vi: 304 of 304 texts found in 50 Vietnamese docs
== 304 strings, 0 errors, 0 warnings
$ tools/.venv/bin/python tools/schemas/check_schemas.py      (exit 0)
  … enum khớp bảng spec: 16 · ví dụ 01–08: 191 · envelope trong env_b64/hl: 31 · mẫu dương: 69 · mẫu âm: 157
  · tin trong test vector: 52
  XANH: mọi kiểm tra đạt
```

The two batch-2 schema failures are gone (the shared agent's `push.schema.json` accepts `thread-id` `sms`), and
`--docs` is at 0 warnings after D3. History of the earlier states below.

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

Status after batch 4: the shared agent has added every proposed key below and the metadata changes on existing keys
(handlive-shared ac85789 and 2dd4a46, `phase-02-shared-sync-1.md` §1); the catalog has 304 strings and all of them are
quoted in the specs. Batch 4 adds no text and proposes no catalog change.

Batch 5 (E4, E7) — the shared catalog follows:

| Key | Change | en | vi | Spec · field |
|---|---|---|---|---|
| `notification.permission_sms_read` | new texts; comment: "posted for any missing SMS permission (reading, sending, contacts)"; key name kept (stable key, one Android resource reference) | {device_name} needs SMS permission on this phone — tap to allow | {device_name} cần quyền SMS trên điện thoại — chạm để cho phép | SET-01 field 17 (E7) |
| `error.relay_pin_mismatch` | `platforms` + `android`; comment: "on Android shown in place of the description under Internet Connection (SET-02 field 21)"; add SET-02 to `specs` | unchanged | unchanged | CONN-03 E7, field 4; SET-02 field 21 (E4) |
| `error.relay_device_revoked` | comment as above; add SET-02 to `specs` (already on android) | unchanged | unchanged | CONN-03 E3, field 4; SET-02 field 21 |

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

- **Shared:** done in `phase-02-shared-sync-1.md` (schemas, vectors with the SMS cut cases, catalog). Batch 4 writes
  its two proposals into the spec: `collapse_key` 0x21–0x7E (D1) and the cut rule (D2).
- **Relay:** `Reason::default_ttl_s` for `call_incoming` 60 → 30 (CONN-04 API 2 now 30); rest of batches 2–3 document
  the current relay behaviour (including the `RELAY_APNS_TOPIC` check, C4).
- **Android:** SMS push `collapse_key` = `message_key`; code-point cut loop of step 5b; `push_outbox` owned by A2.2.
- **Apple:** I-NSE sets `threadIdentifier` = `sms:<pair_id>:<thread_id>`; `HL_SMS_GROUP`; new texts once in the catalog.
- **Design system:** the leftovers listed after batch 2 are aligned in batch 3 (C5), except MessageBubble
  `preview.html` ("2 tin SMS"; question 1). The design-system artifact needs republishing after the batch 1 and 3 edits
  (CLAUDE.md: docs first, then the artifact).
- **Batch 5 — Shared:** the catalog rows above (then `--docs` is back to 0 warnings); no schema or vector change.
- **Batch 5 — Android:** send `session/bye` before ending a relayed session in every case (idle 4411, failed rekey
  4410, replacement 4409; A2.2 point 5) and read a received one as its close (E3); show `error.relay_pin_mismatch`
  under Internet Connection (E4); the field 17 text comes from the catalog (E7). E1, E2, E5 and E6 already match the
  code. Optional: `RelayRegistrar.checkPairs` could set `relay_registered = 1` for a pair the relay lists while the
  flag is 0 (question 1 below).
- **Batch 5 — Apple:** before ending a relayed session send `session/bye` (`shutdown` unless another reason applies);
  on a received one end the relayed session, `replaced` → CONN-02 E7 (E3). `POST /v1/pairs` with the 404 rule of
  PAIR-01 API 8 logic 6 (E2).

## Unresolved questions

1. **Batch 5, E2 gap (proposal, needs a decision):** after a second 404 a device waits 24 h. If the peer completes
   the pair in the meantime, the waiting device keeps `relay_registered = 0` until its next call, and the phone
   creates no relay demand for that pair (E1 counts relay-registered pairs only). Proposed line for PAIR-02 API 1
   logic 3: "a pair that `GET /v1/pairs` lists without `revoked_at` → `relay_registered = 1`". Not applied.

Earlier batches: none open. The four questions of batches 1–2 were answered by C1–C4; the multi-part `{limit}`
question of batch 3 was settled by the coordinator in hub 427d911 (`{limit}` = capacity of the current number of
parts) and the MessageBubble preview updated in 298544d; the two shared-sync questions (visible ASCII `collapse_key`,
the SMS cut reading) are D1 and D2.

Status: DONE
Summary: All decisions of batches 1–5 (37 + 15 + 5 + 3 + 7, plus the batch-4 addendum D4, D5 and the APNs note) are applied in both languages in 28 signed-off hub commits, pushed (0d88586..d7ed548); both doc checkers print problems=0 and check_schemas prints XANH; check_strings --docs has the 2 expected warnings of E7 until the catalog takes the new field 17 texts.
Concerns/Blockers: none; deviations 13 (Mac E3 "missed calls"), 15 (the push cuts the snippet like the body, per the code and vectors) and 16–17 (batch 5: network change, `shutdown` for the other ends) are worth a glance; question 1 (E2 gap) is a proposal.
