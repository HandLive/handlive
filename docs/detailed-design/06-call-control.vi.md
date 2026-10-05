[English](06-call-control.md) | Tiếng Việt

# 6. Nhóm chức năng: Thông tin và điều khiển cuộc gọi

> Tham chiếu chung: [`00-common-specs.md`](00-common-specs.vi.md) — thành phần A-CALL, A-AUD, M-APP,
> M-HFP, I-APP, I-NSE (0.1), định danh `call_id`, `entry_id` (0.2), kiểu dữ liệu (0.3), envelope và
> `ack` (0.5.1), nguyên tắc bảo mật (0.6.5), loại tin `call_event` (0.7.1), capability
> `features.call`, `features.call.app_calls`, `features.call_audio.hfp_connected` (0.7.2), mã lỗi
> `CALL_*`, `PERMISSION_MISSING` (0.8.1), nguồn dữ liệu `CallLog.Calls`, `PhoneLookup` (0.9.2), bảng
> `call_log_entry`, `sync_cursor` (0.9.3), khóa `feature.call`, `call.notify`, `call.app_calls`
> (0.9.5), hằng số `CALLLOG_SYNC_WINDOW`, `APP_CALL_LINK_WINDOW`, `APP_CALL_TAP_NOTIFICATION_TTL`
> (0.10). Push: CONN-04. Âm thanh cuộc gọi: nhóm 7 (AUDIO-01…04). Cuộc gọi từ ứng dụng khác: CALL-05
> (README §5 C22).
>
> Quy tắc chung của nhóm:
> - **Không dùng `InCallService`** (README §5 C12). A-CALL chỉ thấy trạng thái tổng hợp của máy
>   (`IDLE`, `RINGING`, `OFFHOOK`) qua API công khai: không có chi tiết từng cuộc gọi, không biết
>   chắc tình huống nhiều cuộc gọi, số của cuộc gọi đi chưa biết cho tới khi nhật ký ghi xong.
>   Cuộc gọi từ ứng dụng khác (Telegram…, CALL-05) được đọc từ chính thông báo cuộc gọi của ứng
>   dụng gọi điện qua một `NotificationListenerService` và điều khiển bằng PendingIntent của chúng —
>   vẫn không dùng `InCallService` (C22).
> - Cuộc gọi **hiệu lực** với một cặp khi `feature.call = true` ở cả hai phía và Android có
>   `READ_PHONE_STATE`. Số gọi đến cần thêm `READ_CALL_LOG` (`features.call.caller_id`); trả lời, từ
>   chối, kết thúc cần `ANSWER_PHONE_CALLS` (`features.call.can_answer`, `can_end`); tên liên hệ cần
>   `READ_CONTACTS`.
> - Cuộc gọi ứng dụng **hiệu lực** với một phiên khi cả hai bên báo `features.call.app_calls =
>   true` (Android: `call.app_calls`, `feature.call` và quyền truy cập thông báo; Mac:
>   `call.app_calls`; iPhone/iPad không bao giờ); không cần quyền điện thoại nào và không làm đổi
>   CALL-01…04.
> - Qua WebSocket chỉ có `answer`, `reject`, `end`. Giữ máy, DTMF, tắt tiếng và xử lý cuộc gọi chờ
>   chỉ làm được bằng lệnh HFP do Mac gửi khi đang nối Bluetooth HFP tới điện thoại (P4, M-HFP).
> - iOS không dùng PushKit/CallKit (C7): cuộc gọi đến trên iPhone/iPad là thông báo `time-sensitive`
>   hoặc banner trong ứng dụng; iPhone/iPad chỉ từ chối được, không trả lời được.
> - Không ghi log số điện thoại, tên liên hệ, phím DTMF, người gọi của cuộc gọi ứng dụng hay nội
>   dung của bất kỳ thông báo nào; log chỉ gồm `type`, `op`, `call_id`, mã lỗi. Lỗi của nhóm được cô lập: không làm dừng A-SVC, không đóng phiên `/v1/ctl`.
> - Android kiểm cuộc gọi theo từng phiên: `call_event/action` và `call_event/log_sync` được trả
>   `FEATURE_DISABLED` khi cuộc gọi không hiệu lực với phiên đã gửi chúng (tắt ở một trong hai phía,
>   theo `capability` mới nhất của client đó, hoặc thiếu `READ_PHONE_STATE`), bất kể các phiên khác
>   cho phép gì; thao tác với cuộc gọi ứng dụng nhận `FEATURE_DISABLED` khi cuộc gọi ứng dụng không
>   hiệu lực với phiên đó (CALL-05 API 2).

## 6.1 CALL-01 — Thông báo cuộc gọi đến trên Mac/iOS

### 6.1.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | CALL-01 — Thông báo cuộc gọi đến trên Mac/iOS |
| Mô tả | Khi điện thoại đổ chuông, A-CALL phát hiện trạng thái `RINGING`, tạo ngữ cảnh cuộc gọi (`call_id`), lấy số gọi đến và tên liên hệ, rồi gửi `call_event/state` tới mọi client đang kết nối có cuộc gọi hiệu lực.<br>Mac hiện panel nổi (`NSPanel`) trên mọi Space với tên, số hoặc "Số ẩn", nhãn SIM nếu biết, các nút theo `controls` và chuông tùy chọn, kèm một thông báo liên lạc (`INStartCallIntent`); khi chế độ Tập trung đang bật thì chỉ có thông báo. iPhone/iPad đang mở ứng dụng hiện banner trong ứng dụng; iPhone/iPad đang treo nền nhận thông báo APNs `time-sensitive` qua CONN-04, I-NSE giải mã và gắn nút "Từ chối".<br>Mỗi lần trạng thái đổi (có số hoặc tên, nghe máy, kết thúc, có cuộc gọi chờ, đổi trạng thái HFP hoặc nơi phát âm thanh), A-CALL gửi `state` mới để client cập nhật hoặc đóng giao diện. `call_event/state` định nghĩa ở đây và dùng chung cho CALL-02, CALL-03, CALL-04. |
| Tác nhân | Chính: Người dùng (thấy cuộc gọi, chọn thao tác), Người gọi (tạo cuộc gọi). Hệ thống: A-CALL, A-SVC, A-AUD (trạng thái HFP, nơi phát âm thanh), OS (Telephony, Contacts provider), M-APP, I-APP, I-NSE, R-API, PUSH (APNs). |
| Điều kiện trước | 1.<br>Cặp hiệu lực (PAIR-01).<br>2.<br>Cuộc gọi hiệu lực với cặp; A-SVC đang chạy và A-CALL đã đăng ký listener (SET-01 đã xin `READ_PHONE_STATE`, `READ_CALL_LOG`, `READ_CONTACTS`, `ANSWER_PHONE_CALLS`).<br>3.<br>Để nhận ngay: client có phiên `/v1/ctl` (CONN-01 hoặc CONN-03); iPhone/iPad không có phiên nhận qua push khi đã đăng ký push (CONN-04), `relay.enabled = true` và `features.call.notify = true`.<br>4. iOS: người dùng đã cho phép thông báo, gồm thông báo nhạy cảm thời gian (SET-03). |
| Điều kiện sau | Client đang kết nối hiển thị cuộc gọi theo `call.notify` trong ≤ 300 ms (LAN); iPhone/iPad treo nền có thông báo (nội dung đầy đủ khi máy đang mở khóa).<br>Giao diện luôn khớp `state` mới nhất: `offhook` → Mac chuyển sang panel đang gọi (CALL-03), iOS đóng banner; `idle` → đóng panel, dừng chuông, gỡ thông báo cuộc gọi đến (cuộc gọi nhỡ do CALL-04 thông báo).<br>Ngữ cảnh cuộc gọi trên Android tồn tại tới `IDLE`, sau đó nằm thêm 60 s trong danh sách "vừa kết thúc" để ghép với nhật ký (CALL-04).<br>Không ghi dữ liệu bền nào. |
| Ngoại lệ | E1 — Cuộc gọi không hiệu lực (tắt ở một phía, thiếu `READ_PHONE_STATE`): không gửi gì; PAIR-02 hiển thị lý do.<br>E2 — Thiếu `READ_CALL_LOG`: `number = null`, `presentation = unknown` → hiển thị "Không rõ số" kèm gợi ý cấp quyền; thiếu `READ_CONTACTS`: `display_name = null` → hiển thị số.<br>E3 — `call.notify = false` trên client: Mac không mở panel, không đổ chuông, chỉ hiện cuộc gọi trong menu của biểu tượng menu bar; iOS không hiện banner; Android không push cho iPhone/iPad đó.<br>E4 — Mac đang bật chế độ Tập trung (`isFocused = true`): không hiện panel, không đổ chuông; thông báo liên lạc mức time-sensitive (API 7) để hệ thống quyết định theo người gọi và cài đặt Tập trung; cuộc gọi vẫn nằm trong menu của biểu tượng thanh menu. Cuộc gọi được trả lời từ thông báo đó thì mở panel đang gọi; các panel đang gọi khác vẫn ẩn khi Tập trung bật.<br>Chưa được phép đọc trạng thái Tập trung → hiện panel, không đổ chuông.<br>E5 — Không push được (relay tắt, chưa có token, APNs lỗi): xử lý theo CONN-04 (`push_outbox` hạn 30 s); push `call_incoming` đang xếp hàng bị bỏ khi cuộc gọi hết đổ chuông, để lần gửi lại muộn không thay được thông báo cuộc gọi nhỡ dùng chung collapse key (API 4 logic 5); cuộc gọi nhỡ sẽ đến qua CALL-04.<br>E6 — iPhone đang khóa khi push tới: I-NSE không đọc được khóa (C3) → nội dung chung "Cuộc gọi đến trên điện thoại", không có nút "Từ chối".<br>E7 — Push tới trễ (quá 60 s sau `started_at`): I-NSE hiển thị "Cuộc gọi đến lúc <giờ>", không gắn nút, ở mức `interruptionLevel = .active` thay cho time-sensitive.<br>E8 — A-SVC khởi động khi đang có cuộc gọi, hoặc client kết nối giữa chừng: A-CALL dựng ngữ cảnh từ trạng thái hiện tại (`direction = unknown` nếu đang `OFFHOOK`) và gửi `state` ngay sau khi phiên trao đổi capability.<br>E9 — Cuộc gọi chờ (`RINGING` khi đang `OFFHOOK`): `waiting = true`, chỉ hiển thị thông tin; xử lý cần HFP (CALL-03).<br>E10 — Số đến sau lượt `RINGING` đầu (broadcast đến hai lần, thứ tự không cố định): A-CALL gửi lại `state` cùng `call_id` khi có số và tên. |
| Yêu cầu đặc biệt | **Hiệu năng:** `state` tới client < 200 ms trong LAN kể từ callback của hệ điều hành (tra tên ≤ 30 ms nhờ cache LRU); panel Mac hiện ≤ 300 ms sau `RINGING`; qua relay ≤ 1 s khi phiên sẵn có, ≤ 3 s khi điện thoại phải mở relay; push iOS phụ thuộc APNs.<br>**Nền tảng:** panel Mac không lấy focus của ứng dụng đang dùng (non-activating), hiện trên mọi Space kể cả ứng dụng toàn màn hình — lệch có chủ đích so với HIG (panel thường ẩn khi ứng dụng không active), bù lại luôn đi kèm thông báo liên lạc; Mac cần capability Communication Notifications (`com.apple.developer.usernotifications.communication`, capability này cũng cho M-APP đọc trạng thái Tập trung bằng `INFocusStatusCenter`, kèm quyền của người dùng và `NSFocusStatusUsageDescription`), `NSUserActivityTypes` chứa `INStartCallIntent`, và entitlement Time Sensitive Notifications (`com.apple.developer.usernotifications.time-sensitive`): thiếu entitlement này, thông báo `.timeSensitive` trên macOS đến ở mức active và không vượt qua chế độ Tập trung; I-APP cần cùng entitlement Time Sensitive Notifications; không PushKit/CallKit (C7).<br>**Riêng tư:** relay và APNs chỉ thấy `reason = call_incoming` và nội dung chung; số, tên nằm trong envelope mã hóa bằng `K_push`; không log số, tên.<br>**Tuân thủ:** `READ_CALL_LOG` thuộc ngoại lệ "Cross-device synchronization or transfer of SMS or calls" của Google Play, cần Permissions Declaration Form (`docs/deployment-guide.md`); `READ_PHONE_STATE`, `READ_CONTACTS`, `ANSWER_PHONE_CALLS` là quyền runtime (SET-01).<br>**Truy cập:** VoiceOver đọc "Cuộc gọi đến từ <tên hoặc số>" khi panel hoặc banner xuất hiện. |

### 6.1.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 6.1.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Tiêu đề | string | Output | "Cuộc gọi đến" | "Cuộc gọi chờ" khi `waiting = true` (banner iPhone/iPad); Mac hiện cuộc gọi chờ ngay trong panel đang gọi: trạng thái "Có cuộc gọi chờ", người gọi đang chờ và trường 5 (CALL-03 trường 3, E7) |
| 2 | Tên người gọi | string | Output | `display_name` | `null` → dòng này hiển thị số (trường 3) |
| 3 | Số người gọi | e164 | Output | `number` | Định dạng quốc gia; `presentation = restricted` → "Số ẩn"; `unknown` hoặc `null` → "Không rõ số" |
| 4 | Nhãn SIM | string | Output | Ẩn | `sim_label`, chỉ khi điện thoại có > 1 SIM và biết SIM đổ chuông |
| 5 | Người gọi chờ | string | Output | Ẩn | Chỉ khi `waiting = true`: `waiting_display_name` hoặc `waiting_number` ("Không rõ số" khi cả hai `null`); trên Mac kèm "Xử lý trên điện thoại hoặc nối Bluetooth" khi `hfp_connected = false`; iPhone/iPad chỉ hiện người gọi chờ (không có HFP) |
| 6 | Nút "Trả lời" | action | Input | Ẩn | Chỉ Mac, khi `controls.answer = true`; tooltip "Trả lời cuộc gọi"; khi âm thanh cuộc gọi hiệu lực (AUDIO-01) tách thành "Nghe trên điện thoại" và "Nghe trên Mac" → CALL-02 |
| 7 | Nút "Từ chối" | action | Input | Ẩn | Panel Mac (tooltip "Từ chối cuộc gọi"), banner iOS, hành động của thông báo iOS; khi `controls.reject = true` → CALL-02 |
| 8 | Nút "Từ chối kèm tin nhắn…" | action | Input | Ẩn | Chỉ Mac; khi `controls.reject = true`, `number` khác `null`, SMS hiệu lực và `features.sms.can_send = true` → CALL-02 |
| 9 | Nút "Bỏ qua" | action | Input | — | Chỉ Mac: đóng panel và tắt chuông trên Mac; cuộc gọi vẫn đổ chuông trên điện thoại, vẫn nằm trong menu của biểu tượng menu bar |
| 10 | Chuông trên Mac | âm thanh | Output | Tắt | Phát lặp khi panel hiện, `call.notify = true`, `call.ringtone = true` và Focus không bật; dừng khi `state` đổi, khi bấm trường 6, 7, 8, 9, hoặc sau 60 s |
| 11 | Thông báo iOS | string | Output | Không đặt tiêu đề (hệ thống hiện tên app), nội dung "Cuộc gọi đến trên điện thoại" | I-NSE thay tiêu đề bằng trường 2 (hoặc 3), nội dung "Cuộc gọi đến" kèm nhãn SIM; gắn nút "Từ chối" khi `controls.reject = true` |
| 12 | Gợi ý cấp quyền | string | Output | Ẩn | "Cho phép HandLive đọc nhật ký cuộc gọi trên điện thoại để hiện số gọi đến" khi `permissions_missing` có `READ_CALL_LOG` (E2) |
| 13 | Tùy chọn "Thông báo cuộc gọi" | bool | Input/Output | `call.notify` = `true` | Cài đặt → Cuộc gọi (SET-02), Mac và iOS |
| 14 | Tùy chọn "Đổ chuông trên Mac" | bool | Input/Output | `call.ringtone` = `true` | Cài đặt → Cuộc gọi, chỉ Mac; khóa ở 0.9.5 |
| 15 | Thông báo liên lạc trên Mac | string | Output | Tiêu đề: trường 2 (hoặc 3); nội dung "Cuộc gọi đến" kèm nhãn SIM | `INStartCallIntent` (API 7): mức passive khi panel đang hiện (chỉ vào Trung tâm thông báo, không banner, không âm), time-sensitive khi Tập trung bật; chưa đọc được trạng thái Tập trung → panel hiện, không đổ chuông, thông báo ở mức passive như khi Tập trung tắt (E4); nút "Trả lời", "Từ chối" chỉ khi `controls.answer` và `controls.reject` đều `true` (API 7); gỡ khi `state` khác `ringing` |

### 6.1.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U10["(10) Thấy người gọi, chọn thao tác CALL-02 hoặc Bỏ qua"]
  end
  subgraph HT["Hệ thống"]
    S1["(1) Người gọi gọi tới, hệ thống báo RINGING"]
    D2{"(2) Cuộc gọi hiệu lực?"}
    S3["(3) A-CALL tạo ngữ cảnh call_id, lấy số, tra tên, tính controls"]
    S4["(4) Gửi call_event/state tới từng phiên"]
    S5["(5) Cặp iOS không có phiên: POST /v1/push call_incoming"]
    D6{"(6) call.notify bật trên client?"}
    S7["(7) Mac: panel nổi và thông báo liên lạc, Tập trung bật thì chỉ thông báo"]
    S8["(8) iOS đang mở ứng dụng: banner trong ứng dụng"]
    S9["(9) I-NSE giải mã, hiện thông báo kèm nút Từ chối"]
    S11["(11) Trạng thái đổi: gửi state mới cùng call_id"]
    S12["(12) Client cập nhật hoặc đóng panel, banner, thông báo"]
    X1(["Không hiển thị"])
    X2(["Chỉ hiện trong menu bar"])
  end
  S1 --> D2
  D2 -- "Không (E1)" --> X1
  D2 -- "Có" --> S3
  S3 -- "Client có phiên" --> S4 --> D6
  S3 -- "iOS không có phiên" --> S5 --> S9 --> U10
  D6 -- "Có, Mac" --> S7 --> U10
  D6 -- "Có, iOS" --> S8 --> U10
  D6 -- "Không (E3)" --> X2
  U10 -- "Nghe, từ chối, kết thúc hoặc người gọi dập máy" --> S11 --> S12
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Hệ thống | OS, A-CALL | Người gọi gọi tới. Listener trạng thái (API 2) báo `RINGING`; broadcast `PHONE_STATE` (API 3) mang `EXTRA_INCOMING_NUMBER`. | Đang `OFFHOOK` → cuộc gọi chờ (E9). |
| 2 | Hệ thống | A-CALL, A-SVC | Kiểm `feature.call` và `READ_PHONE_STATE` trên Android; với từng phiên, kiểm capability của client (`features.call.enabled`). | Không → E1. |
| 3 | Hệ thống | A-CALL, OS | Tạo ngữ cảnh: `call_id` (UUIDv7), `direction = incoming`, `state = ringing`, `started_at`.<br>Gán `sub_id`, `sim_label` từ listener theo SIM (nếu xác định được).<br>Lấy số từ broadcast kèm số, chuẩn hóa E.164; tra tên bằng `PhoneLookup` (Query); tính `presentation` và `controls` theo API 1. | Số đến sau → E10. Thiếu quyền → E2. |
| 4 | Hệ thống | A-SVC | Dựng `call_event/state` riêng cho từng phiên (các trường `controls`, `hfp_connected`, `audio_on` tính theo client nhận) và gửi. Client không ở LAN mà đang chờ trên relay: A-SVC mở relay (CONN-03); client bắt tay lại và nhận `state` ngay sau khi trao đổi capability. | E8. |
| 5 | Hệ thống | A-SVC, R-API, PUSH | Với mỗi cặp iOS/iPadOS không có phiên, `relay_registered = 1`, capability gần nhất có `features.call.enabled = true` và `features.call.notify = true`: chờ có số (tối đa 300 ms sau `RINGING`; không chờ khi thiếu `READ_CALL_LOG`), dựng envelope `call_event/state` mã hóa bằng `K_push`, gọi `POST /v1/push` (API 4).<br>Từ lúc `RINGING`, khi một cặp đã đăng ký relay chưa có phiên, A-SVC mở relay nếu chưa có và giữ suốt lúc cuộc gọi đổ chuông (CONN-03 bước 2), để lệnh "Từ chối" từ iOS tới nhanh (CALL-02 B2) và Mac đang chờ trên relay nhận được cuộc gọi (bước 4). | Lỗi → E5. Không push cho cuộc gọi chờ. |
| 6 | Hệ thống | M-APP / I-APP | Kiểm `call.notify`. | Không → E3 (X2). |
| 7 | Hệ thống | M-APP | Đọc trạng thái Tập trung (API 5). Không bật: hiện panel với trường 1–9, gửi thông báo liên lạc mức passive (trường 15, API 7), phát chuông (trường 10) nếu `call.ringtone = true`. Đang bật: không panel, không chuông, thông báo liên lạc mức time-sensitive. | E4. |
| 8 | Hệ thống | I-APP | Ứng dụng ở foreground: banner trong ứng dụng với trường 1–5, 7 (API 6); không đổ chuông vì điện thoại đang đổ chuông. |  |
| 9 | Hệ thống | I-NSE, OS | Nhận push (API 6). Máy đang mở khóa: giải mã, đặt tiêu đề và nội dung (trường 11), danh mục `HL_CALL_INCOMING` có nút "Từ chối" khi `controls.reject = true`, `userInfo`. Máy đang khóa hoặc giải mã lỗi: giữ nội dung chung. | E6, E7. |
| 10 | Người dùng | M-APP / I-APP | Thấy người gọi; chọn "Trả lời", "Từ chối", "Từ chối kèm tin nhắn…" (CALL-02), "Bỏ qua", hoặc không làm gì. |  |
| 11 | Hệ thống | A-CALL, A-SVC | Mọi thay đổi (có số hoặc tên, `OFFHOOK`, `IDLE`, `waiting`, `hfp_connected`, `audio_on`) → gửi `state` mới cùng `call_id` tới các phiên. `IDLE`: đặt `ended_at`, `end_reason`, chuyển ngữ cảnh vào danh sách "vừa kết thúc" (giữ 60 s). |  |
| 12 | Hệ thống | M-APP / I-APP | `ringing` → cập nhật các trường; `offhook` → Mac chuyển panel sang chế độ đang gọi (CALL-03) và gỡ thông báo liên lạc, iOS đóng banner và gỡ thông báo cuộc gọi đến; `idle` → đóng panel, dừng chuông, gỡ thông báo cuộc gọi đến. | Cuộc gọi nhỡ: CALL-04. |

### 6.1.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | `WS call_event/state` | `/v1/ctl` (LAN hoặc relay) | S→C | 4, 11, 12 |
| 2 | Listener trạng thái cuộc gọi: `TelephonyCallback.CallStateListener` (API 31+) / `PhoneStateListener` `LISTEN_CALL_STATE` (API 29–30) | Cục bộ Android | OS → A-CALL | 1, 3, 11 |
| 3 | Broadcast `TelephonyManager.ACTION_PHONE_STATE_CHANGED` (receiver đăng ký lúc chạy) | Cục bộ Android | OS → A-CALL | 1, 3 |
| 4 | `POST /v1/push` với `reason = call_incoming` (đặc tả đầy đủ ở CONN-04) | REST relay → APNs | A-SVC → R-API → PUSH | 5 |
| 5 | Panel cuộc gọi `NSPanel`, chuông `NSSound`, trạng thái Focus `INFocusStatusCenter` | Cục bộ Mac | — | 7, 12 |
| 6 | Banner trong ứng dụng và thông báo `HL_CALL_INCOMING` (`UNNotificationServiceExtension`, `UNUserNotificationCenter`) | Cục bộ iOS, I-NSE | — | 8, 9, 12 |
| 7 | Thông báo liên lạc trên Mac: `INStartCallIntent`, `UNNotificationContent.updating(from:)`, `UNUserNotificationCenter` | Cục bộ Mac | — | 7, 12 |

#### API 1 — `WS call_event/state`

- **URL:** `wss://{android_host}:{port}/v1/ctl` (LAN) hoặc qua relay `wss://{RELAY_HOST}/v1/relay`
  với lớp bọc `to` /`from`
- **Method:** `WS call_event/state` (S→C), envelope mã hóa, không ack (0.7.1). Cũng là plaintext của
  envelope trong push `call_incoming` (mã hóa bằng `K_push`, API 4).
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `call_id` | uuid | Có | UUIDv7 của ngữ cảnh; tạo khi `RINGING` từ `IDLE` (cuộc gọi đến) hoặc `OFFHOOK` từ `IDLE` (cuộc gọi đi bắt đầu trên điện thoại) |
| `direction` | enum{incoming\| outgoing\| unknown} | Có | `unknown` khi ngữ cảnh dựng lúc máy đã `OFFHOOK` (E8) |
| `state` | enum{ringing\| offhook\| idle} | Có | Trạng thái tổng hợp của máy |
| `waiting` | bool | Có | `true` khi `RINGING` xuất hiện lúc đang `OFFHOOK` (cuộc gọi chờ); chỉ `true` khi `state = ringing` (trạng thái tổng hợp lúc có cuộc gọi chờ) |
| `number` | e164 \| null | Có | Số của cuộc gọi chính; `null` khi thiếu `READ_CALL_LOG`, số ẩn, hoặc cuộc gọi đi |
| `display_name` | string \| null | Có | Tên từ `PhoneLookup`; `null` khi thiếu `READ_CONTACTS` hoặc số không có trong danh bạ |
| `presentation` | enum{allowed\| restricted\| unknown} | Có | `allowed`: có số; `restricted`: có `READ_CALL_LOG` nhưng bản broadcast kèm số cho số rỗng (người gọi ẩn số); `unknown`: các trường hợp còn lại |
| `sub_id` | int32 \| null | Có | SIM của cuộc gọi (API 2, listener theo SIM); không xác định → `null` |
| `sim_label` | string \| null | Có | Tên SIM (`SubscriptionInfo.getDisplayName()`) của `sub_id`; chỉ khi máy có > 1 SIM hoạt động |
| `waiting_number` | e164 \| null | Có | Số của cuộc gọi chờ; `null` khi `waiting = false` hoặc không biết |
| `waiting_display_name` | string \| null | Có | Tên của cuộc gọi chờ |
| `started_at` | timestamp | Có | Lúc tạo ngữ cảnh (đồng hồ Android) |
| `answered_at` | timestamp \| null | Có | Lúc `RINGING` → `OFFHOOK` của cuộc gọi đến; cuộc gọi đi và `unknown` luôn `null` (không biết lúc bên kia nhấc máy) |
| `ended_at` | timestamp \| null | Có | Chỉ khi `state = idle` |
| `end_reason` | enum{missed\| rejected\| ended\| answered_elsewhere} \| null | Có | Chỉ khi `state = idle`; quy tắc ở logic 5 |
| `controls` | object | Có | Thao tác client được phép làm (bảng dưới) |
| `hfp_connected` | bool | Có | Mac nhận tin đang nối hồ sơ HFP tới điện thoại (A-AUD, AUDIO-02); luôn `false` với iPhone/iPad |
| `audio_on` | enum{phone\| mac} | Có | `mac`: âm thanh cuộc gọi đang ở chính Mac nhận tin (SCO tới Mac đó, hoặc đường Opus/WS của phiên đó — nhóm 7); còn lại `phone` |

Đối tượng `controls`:

| Trường | Kiểu | Giá trị |
|--------|------|---------|
| `answer` | bool | `true` khi `state = ringing`, `waiting = false`, có `ANSWER_PHONE_CALLS` và client nhận là Mac |
| `reject` | bool | `true` khi `state = ringing`, `waiting = false`, có `ANSWER_PHONE_CALLS` |
| `end` | bool | `true` khi `state = offhook`, `waiting = false`, có `ANSWER_PHONE_CALLS` |
| `hold` | enum{hfp\| unavailable} | `hfp` khi `state = offhook` và `hfp_connected = true` |
| `dtmf` | enum{hfp\| unavailable} | Như `hold` |
| `mute` | enum{hfp\| unavailable} | `hfp` khi `state = offhook`, `hfp_connected = true` và `audio_on = mac` |

- **Response:** N/A (không ack; client lỡ tin do mất kết nối nhận bản hiện tại khi phiên mới trao
  đổi capability — logic 3).
- **Ví dụ:** cuộc gọi đến đang đổ chuông, sau đó bị nhỡ.

```json
{"op":"state","data":{"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","direction":"incoming","state":"ringing","waiting":false,"number":"+84900000123","display_name":"Nguyễn Văn A","presentation":"allowed","sub_id":1,"sim_label":"SIM 1","waiting_number":null,"waiting_display_name":null,"started_at":1727150400123,"answered_at":null,"ended_at":null,"end_reason":null,"controls":{"answer":true,"reject":true,"end":false,"hold":"unavailable","dtmf":"unavailable","mute":"unavailable"},"hfp_connected":false,"audio_on":"phone"}}
```

```json
{"op":"state","data":{"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","direction":"incoming","state":"idle","waiting":false,"number":"+84900000123","display_name":"Nguyễn Văn A","presentation":"allowed","sub_id":1,"sim_label":"SIM 1","waiting_number":null,"waiting_display_name":null,"started_at":1727150400123,"answered_at":null,"ended_at":1727150425456,"end_reason":"missed","controls":{"answer":false,"reject":false,"end":false,"hold":"unavailable","dtmf":"unavailable","mute":"unavailable"},"hfp_connected":false,"audio_on":"phone"}}
```

- **Logic nghiệp vụ:**
  1. **Nguồn dữ liệu:** trạng thái lấy từ listener mặc định (API 2); số lấy từ broadcast (API 3);
     `sub_id` từ listener theo SIM. A-CALL xử lý mọi sự kiện tuần tự trên một luồng.
  2. **Máy trạng thái ngữ cảnh:** `IDLE → RINGING` tạo ngữ cảnh `incoming`; `IDLE → OFFHOOK` tạo ngữ
     cảnh `outgoing` (`number = null`, `presentation = unknown`); `RINGING → OFFHOOK` (không chờ)
     đặt `answered_at`; `OFFHOOK → RINGING` đặt `waiting = true` và `waiting_*` theo broadcast;
     `RINGING → OFFHOOK` khi đang chờ đặt `waiting = false`, xóa `waiting_*`, giữ nguyên `call_id`
     và số của cuộc gọi đầu — A-CALL không biết cuộc gọi chờ đã được nhận hay bị bỏ qua (giới hạn
     C12); `→ IDLE` kết thúc ngữ cảnh. Máy đã ở `RINGING` hoặc `OFFHOOK` lúc đăng ký listener → dựng
     ngữ cảnh theo E8.
  3. **Khi nào gửi:** mỗi khi một trường của `data` đổi so với bản đã gửi cho phiên đó; khi phiên
     mới trao đổi xong `capability/hello` mà ngữ cảnh khác `idle`. Không gửi lại bản giống hệt.
  4. **Theo từng client:** mỗi phiên nhận một envelope riêng; `controls.answer` chỉ `true` với Mac
     (`peer_platform = macos`); `hfp_connected`, `controls.hold` /`dtmf`/`mute`, `audio_on` tính
     theo `bt_address` và phiên của client nhận.
  5. **`end_reason`:** A-CALL đã gọi `endCall()` cho cuộc gọi đang đổ chuông trong vòng 3 s trước đó
     (CALL-02) → `rejected`; `RINGING → IDLE` không qua `OFFHOOK` → `missed`; có `OFFHOOK` →
     `ended`. **Hiệu chỉnh** (chỉ khi có `READ_CALL_LOG`): khi mục nhật ký của ngữ cảnh vừa kết thúc
     xuất hiện (CALL-04 API 3) với loại `REJECTED_TYPE`, `BLOCKED_TYPE` (người dùng từ chối hoặc
     chặn trên điện thoại) hoặc `ANSWERED_EXTERNALLY_TYPE` (nghe trên thiết bị khác dùng chung số)
     trong khi đã báo `missed`, A-CALL gửi thêm đúng một `state` cùng `call_id`, `state = idle`,
     `end_reason` = `rejected` hoặc `answered_elsewhere`. Client lấy bản sau cùng.
  6. **Phía client:** giữ ngữ cảnh mới nhất theo `ts` của envelope; bản của `call_id` đã `idle` chỉ
     được nhận khi cũng là `idle` (bản hiệu chỉnh); `call_id` mới ở `ringing` thay ngữ cảnh cũ
     (phòng mất bản `idle`).
  7. Số chuẩn hóa bằng libphonenumber theo quốc gia của SIM (như SMS-04 API 1); không chuẩn hóa được
     → giữ chuỗi gốc. Không log `number`, `display_name`, `waiting_*`.
  8. **Quy tắc nhất quán** (suy từ logic 2 và 5; schema `call_event-state` trong `shared/schemas/`
     kiểm mọi `state` theo các quy tắc này):
     - `ended_at` và `end_reason` có giá trị khi và chỉ khi `state = idle`.
     - `number` có giá trị khi và chỉ khi `presentation = allowed`; `number` là `null` thì
       `display_name` là `null`, `waiting_number` là `null` thì `waiting_display_name` là `null`
       (tên được tra theo số).
     - `waiting = true` chỉ khi `state = ringing`; `waiting = false` thì `waiting_number` và
       `waiting_display_name` là `null`.
     - `sim_label` chỉ có khi có `sub_id`.
     - `direction = outgoing` → `presentation = unknown`.
     - `direction` là `outgoing` hoặc `unknown` → `answered_at = null`, và `end_reason` chỉ có thể
       là `ended`.
     - `direction = incoming` kèm `state = offhook`, `waiting = true` hoặc `end_reason = ended` →
       có `answered_at`.
     - `state = ringing` với `waiting = false`, hoặc `end_reason` là `missed`, `rejected` hay
       `answered_elsewhere` → `answered_at = null`.
     - `controls.answer` hoặc `controls.reject` chỉ `true` khi `state = ringing` và
       `waiting = false`; `controls.answer = true` kéo theo `controls.reject = true`.
     - `controls.end = true` chỉ khi `state = offhook`.
     - `controls.hold` và `controls.dtmf` là `hfp` khi và chỉ khi `state = offhook` và
       `hfp_connected = true`; `controls.mute` là `hfp` khi và chỉ khi có thêm `audio_on = mac`.

#### API 2 — Listener trạng thái cuộc gọi

- **URL:** N/A
- **Method:** API 31+: `TelephonyManager.registerTelephonyCallback(executor, callback)` với
  `callback` cài `TelephonyCallback.CallStateListener.onCallStateChanged(state)`; gỡ bằng
  `unregisterTelephonyCallback(callback)`. API 29–30:
  `TelephonyManager.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)`, callback
  `PhoneStateListener.onCallStateChanged(state, phoneNumber)`; gỡ bằng
  `listen(listener, PhoneStateListener.LISTEN_NONE)`.
- **Request:** một listener trên `TelephonyManager` mặc định (trạng thái tổng hợp) và một listener
  cho mỗi SIM hoạt động trên `TelephonyManager.createForSubscriptionId(subId)` (chỉ để gán
  `sub_id`). Đăng ký khi A-SVC khởi động, `feature.call = true` và có `READ_PHONE_STATE`; đăng ký
  lại listener theo SIM khi danh sách SIM đổi (`SubscriptionManager.OnSubscriptionsChangedListener`,
  danh sách từ `getActiveSubscriptionInfoList()`).
- **Response:** `state` ∈ `TelephonyManager.CALL_STATE_IDLE` (0), `CALL_STATE_RINGING` (1),
  `CALL_STATE_OFFHOOK` (2). Callback API 31+ không có số; `phoneNumber` của API 29–30 không được
  dùng (lấy số thống nhất từ API 3).
- **Ví dụ:** listener mặc định báo `onCallStateChanged(1)` lúc `t0`; listener của `subId = 1` cũng
  báo `1` tại `t0 + 12 ms`, listener của `subId = 2` không báo → ngữ cảnh mới có `sub_id = 1`,
  `sim_label = "SIM 1"`.
- **Logic nghiệp vụ:**
  1. Callback chạy trên executor một luồng của A-CALL; xử lý tuần tự.
  2. Khi đăng ký, hệ thống báo ngay trạng thái hiện tại → dựng ngữ cảnh cho E8.
  3. `sub_id` lấy từ SIM có lượt chuyển trạng thái tạo ra ngữ cảnh (`IDLE → RINGING` hoặc
     `IDLE → OFFHOOK`): chỉ được gán khi đúng một listener theo SIM báo trạng thái đó trong vòng
     500 ms quanh callback mặc định; nhiều SIM cùng báo hoặc máy không báo theo SIM → `null`. Không
     theo dõi SIM của cuộc gọi chờ.
  4. Mất `READ_PHONE_STATE` (`SecurityException` hoặc người dùng thu hồi quyền) → gỡ listener, gửi
     `capability/update` với `permissions_missing`; cuộc gọi hết hiệu lực (E1). `feature.call`
     chuyển `false` → gỡ mọi listener, receiver và observer của nhóm.

#### API 3 — Broadcast `ACTION_PHONE_STATE_CHANGED`

- **URL:** N/A
- **Method:**
  `Context.registerReceiver(receiver, IntentFilter(TelephonyManager.ACTION_PHONE_STATE_CHANGED))`
  trong A-SVC (receiver đăng ký lúc chạy, không khai trong manifest); gỡ bằng
  `unregisterReceiver(receiver)`.
- **Request:** N/A (hệ thống phát khi trạng thái tổng hợp đổi).
- **Response:** extra `TelephonyManager.EXTRA_STATE` ∈ {`EXTRA_STATE_IDLE`, `EXTRA_STATE_RINGING`,
  `EXTRA_STATE_OFFHOOK` }; `TelephonyManager.EXTRA_INCOMING_NUMBER` (deprecated từ API 29, vẫn được
  gửi) chỉ có trong bản phát cho ứng dụng có cả `READ_PHONE_STATE` và `READ_CALL_LOG`.
- **Ví dụ:** hai intent cho cùng lượt đổ chuông: `{state: "RINGING"}` và
  `{state: "RINGING", incoming_number: "0900000123"}` → `number = "+84900000123"`,
  `presentation = allowed`.
- **Logic nghiệp vụ:**
  1. Ứng dụng có đủ hai quyền nhận broadcast **hai lần** cho mỗi lần đổi trạng thái (một bản có
     `EXTRA_INCOMING_NUMBER`, một bản không), thứ tự không cố định. A-CALL chỉ lấy số từ bản có khóa
     `EXTRA_INCOMING_NUMBER` (`intent.hasExtra(...)`) và ghép với ngữ cảnh theo `EXTRA_STATE`.
  2. Bản `RINGING` khi ngữ cảnh đang `OFFHOOK` → gán `waiting_number`; ngược lại gán `number`. Số
     của bản `OFFHOOK` chỉ được dùng cho ngữ cảnh `incoming` chưa nhận được bản đổ chuông nào. Ngữ
     cảnh `outgoing` và `unknown` giữ `number = null`, kể cả khi bản đó mang số đã gọi (số của cuộc
     gọi đi tới Mac qua nhật ký cuộc gọi, CALL-04). Tên tra theo số vừa có (Query).
  3. Có khóa nhưng giá trị rỗng → `presentation = restricted`. AOSP chỉ thêm `EXTRA_INCOMING_NUMBER`
     khi số không rỗng. Vì vậy người gọi ẩn số cũng được nhận ra khi hai bản `RINGING` đều không có
     khóa trong lúc có `READ_CALL_LOG` → `presentation = restricted`, và push `call_incoming` đi ngay
     lúc đó (API 4 logic 2); cần kiểm trên máy thật. Thiếu `READ_CALL_LOG` → chỉ nhận bản không số →
     `number = null`, `presentation = unknown` (E2).
  4. Broadcast không đổi trạng thái ngữ cảnh (nguồn trạng thái là API 2). Bản có số tới trước
     callback của API 2 được giữ tạm tối đa 2 s để gán khi ngữ cảnh được tạo.

#### API 4 — `POST /v1/push` (`call_incoming`)

- **URL:** `https://{RELAY_HOST}/v1/push`
- **Method:** `POST`, header `Authorization: Bearer <jwt>` (JWT của Android, 0.6.4).
- **Request:** cấu trúc đầy đủ ở CONN-04 API 2. Giá trị dùng cho cuộc gọi đến:

| Trường | Giá trị |
|--------|---------|
| `pair_id` | Cặp của iPhone/iPad đích |
| `to` | `device_id` của iPhone/iPad |
| `kind` | `alert` |
| `reason` | `call_incoming` |
| `env_b64` | Envelope `call_event/state` (API 1, `state = ringing`) mã hóa bằng `K_push` |
| `collapse_key` | `call:<call_id>` — push cuộc gọi nhỡ của cùng cuộc gọi (CALL-04) thay thế thông báo này |
| `ttl_s` | 30 |

- **Response:** theo CONN-04: 202 → xong; 409 `PUSH_TOKEN_MISSING` → bỏ qua; 403 `NOT_PAIRED` → cặp
  đã thu hồi (PAIR-03); 429 `RATE_LIMITED`, 502 `PUSH_PROVIDER_ERROR` → ghi `push_outbox`, hạn 30 s
  (E5).
- **Ví dụ (minh họa):**

```http
POST /v1/push HTTP/1.1
Host: relay.example.com
Authorization: Bearer <jwt>
Content-Type: application/json

{"pair_id":"7a6b5c4d-3e2f-4a1b-9c8d-7e6f5a4b3c2d","to":"2c3d4e5f-6a7b-8c9d-8e0f-1a2b3c4d5e6f","kind":"alert","reason":"call_incoming","env_b64":"<b64: envelope call_event/state mã hóa bằng K_push>","collapse_key":"call:0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","ttl_s":30}
```

- **Logic nghiệp vụ:**
  1. Chỉ push khi đủ điều kiện ở bước 5; mỗi `call_id` tối đa một push `call_incoming`; cuộc gọi chờ
     không push.
  2. Chờ có số tối đa 300 ms sau `RINGING` để push mang đủ số và tên (push không sửa được sau khi
     gửi); quá hạn thì gửi với `number = null`. Push đi ngay khi số đã rõ: bản mang số đã tới, hoặc
     đã biết người gọi ẩn số (API 3 logic 3). Thiếu `READ_CALL_LOG` thì không thể có số (E2), nên push
     đi ngay, không chờ 300 ms. Mục tiêu push (< 300 ms) tính từ thời điểm đó (broadcast làm rõ số,
     `RINGING` khi thiếu `READ_CALL_LOG`, hoặc `RINGING` + 300 ms khi không có số) tới khi relay trả
     202; khoảng này gồm cả lượt gọi REST tới relay.
  3. Relay đặt `interruption-level = time-sensitive`, `thread-id = calls` và nội dung mặc định:
     không đặt tiêu đề (hệ thống hiện tên app), nội dung "Cuộc gọi đến trên điện thoại" (CONN-04 API
     4); nội dung thật chỉ nằm trong envelope.
  4. Từ lúc `RINGING`, không chỉ sau khi push, khi một cặp đã đăng ký relay chưa có phiên, A-SVC mở
     kết nối relay nếu chưa có và giữ suốt lúc cuộc gọi đổ chuông (CONN-03 bước 2), sau đó theo
     `RELAY_IDLE_DISCONNECT`. Nhờ vậy I-APP từ chối từ thông báo thường không cần wake push, và Mac
     đang chờ trên relay cũng nhận được cuộc gọi (bước 4).
  5. **Gửi lại** (E5): push `call_incoming` gửi lại vẫn giữ `ttl_s = 30`, kể cả khi hạn 30 s của
     hàng đợi chỉ còn ít hơn. Khi cuộc gọi hết đổ chuông, A-SVC xóa push `call_incoming` đang xếp
     hàng của cuộc gọi đó khỏi `push_outbox` (Query), để lần gửi lại muộn không thay được thông báo
     cuộc gọi nhỡ dùng chung `collapse_key`. Thông báo cuộc gọi đến còn lại sau khi hết đổ chuông do
     iOS tự gỡ (API 6 logic 4).

#### API 5 — Panel cuộc gọi trên Mac

- **URL:** N/A
- **Method:** `NSPanel` (AppKit) với `styleMask` có `.nonactivatingPanel`, `level = .floating`,
  `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `hidesOnDeactivate = false`,
  hiển thị bằng `orderFrontRegardless()`. Chuông: `NSSound` phát lặp một âm tự tổng hợp hoặc âm của chính dự án (HandLive tự tổng hợp một tiếng chuông nhẹ hai nốt, nên không kèm âm thanh của bên thứ ba). Focus:
  `INFocusStatusCenter.default.focusStatus.isFocused`. Trợ năng:
  `NSAccessibility.post(element:notification:userInfo:)` với `.announcementRequested`.
- **Request (dữ liệu hiển thị):** trường 1–10 lấy từ `state` mới nhất.
- **Response:** thao tác của người dùng → CALL-02 ("Trả lời", "Từ chối", "Từ chối kèm tin nhắn…")
  hoặc "Bỏ qua" (chỉ cục bộ).
- **Ví dụ:** `state` `ringing` ở ví dụ API 1 → panel góc trên bên phải: "Cuộc gọi đến", "Nguyễn Văn
  A", số ở định dạng quốc gia, "SIM 1", nút "Trả lời", "Từ chối", "Từ chối kèm tin nhắn…", "Bỏ qua";
  chuông phát nếu Focus không bật.
- **Logic nghiệp vụ:**
  1. Một panel cho một cuộc gọi, đặt ở góc trên bên phải của màn hình đang có con trỏ chuột. Panel
     không lấy focus: người dùng đang gõ trong ứng dụng khác không bị gián đoạn.
  2. Chuông chỉ phát khi `call.notify = true`, `call.ringtone = true` và `isFocused = false`; dừng
     khi `state` khác `ringing`, khi bấm nút, hoặc sau 60 s; âm lượng theo âm lượng hệ thống.
  3. Đọc trạng thái Focus cần capability Communication Notifications
     (`com.apple.developer.usernotifications.communication`; Apple không có entitlement riêng cho
     trạng thái Tập trung) và người dùng cho phép; M-APP xin quyền này khi người dùng
     bật "Đổ chuông trên Mac" (trường 14); Info.plist có `NSFocusStatusUsageDescription` ("HandLive
     đọc trạng thái Tập trung để không đổ chuông và không hiện cuộc gọi khi bạn đang tập trung.").
     Chưa được phép (`INFocusStatusCenter.default.authorizationStatus` khác `.authorized`) →
     **không** phát chuông riêng (an toàn cho chế độ Tập trung); panel vẫn hiện. Bản build ký không
     có capability này (ví dụ ký bằng team cá nhân) không xin được quyền, nên HandLive không bao giờ
     có trong Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Tập trung: trạng thái Tập trung là
     `unavailable`, M-APP báo như khi Tập trung tắt (panel, chuông khi `call.ringtone = true`, thông
     báo passive) và ẩn dòng gợi ý cấp quyền Tập trung dưới "Đổ chuông trên Mac".
  4. `call.notify = false` → không tạo panel; menu của biểu tượng menu bar hiện cuộc gọi kèm các nút
     theo `controls` (E3).
  5. Khi panel xuất hiện, VoiceOver đọc "Cuộc gọi đến từ <tên hoặc số>".
  6. `isFocused = true` → không tạo panel (E4); thông báo liên lạc mức time-sensitive (API 7) thay
     thế. Panel nổi khi ứng dụng không active là lệch có chủ đích so với HIG (design system, mục
     Trình bày).
  7. Panel chỉ đóng khi `state` đổi, người dùng bấm nút hoặc "Bỏ qua"; không tự đóng theo thời gian
     (chuông dừng sau 60 s nhưng panel vẫn giữ).

#### API 6 — Banner iOS và thông báo `HL_CALL_INCOMING`

- **URL:** N/A
- **Method:** I-NSE: `UNNotificationServiceExtension.didReceive(_:withContentHandler:)` thay
  `title`, `body`, đặt `categoryIdentifier`, `userInfo`; máy đang mở khóa còn dựng
  `INStartCallIntent` (`INPerson` từ tên hoặc số đã giải mã) và gọi `content.updating(from:)` để
  thành thông báo liên lạc — hệ thống hiện avatar và lọc theo người gọi trong chế độ Tập trung (cần
  capability Communication Notifications cho I-NSE). I-APP đăng ký danh mục lúc khởi động bằng
  `UNUserNotificationCenter.setNotificationCategories(_:)`: `UNNotificationCategory`
  `HL_CALL_INCOMING` gồm `UNNotificationAction` `HL_CALL_REJECT` (tiêu đề "Từ chối", tùy chọn
  `.destructive` và `.authenticationRequired`, không có `.foreground`) và `hiddenPreviewsBodyPlaceholder`
  "Cuộc gọi đến" (nội dung hệ thống hiện khi bản xem trước bị tắt). Ứng dụng ở foreground nhận
  `userNotificationCenter(_:willPresent:withCompletionHandler:)`; banner trong ứng dụng là view
  SwiftUI phủ trên cùng.
- **Request (nội dung thông báo do I-NSE đặt):**

| Thuộc tính | Giá trị |
|------------|---------|
| `title` | Trường 2, hoặc trường 3 khi không có tên |
| `body` | "Cuộc gọi đến", thêm " · <nhãn SIM>" khi có |
| `threadIdentifier` | `calls` (relay đặt `thread-id`) |
| `categoryIdentifier` | `HL_CALL_INCOMING` chỉ khi `controls.reject = true` (trường 7); ngược lại không đặt |
| `interruptionLevel` | `.timeSensitive` (từ `interruption-level` của APNs); `.active` với push tới trễ (E7) |
| `userInfo` | `{pair_id, call_id, started_at}` — dùng cho hành động "Từ chối" (CALL-02 B2) |

- **Response:** chạm "Từ chối" → CALL-02 (B1–B3); chạm vào thông báo → mở I-APP (kết nối, hiện
  banner nếu cuộc gọi còn đổ chuông).
- **Ví dụ:**

```json
{"title":"Nguyễn Văn A","body":"Cuộc gọi đến · SIM 1","threadIdentifier":"calls","categoryIdentifier":"HL_CALL_INCOMING","userInfo":{"pair_id":"7a6b5c4d-3e2f-4a1b-9c8d-7e6f5a4b3c2d","call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","started_at":1727150400123}}
```

- **Logic nghiệp vụ:**
  1. I-NSE giải mã theo CONN-04 bước 9b; envelope `call_event/state` có `state = ringing` → nội dung
     cuộc gọi đến. Máy khóa hoặc giải mã lỗi → giữ nội dung chung, không đặt danh mục (E6).
  2. `now − started_at > 60 s` → nội dung "Cuộc gọi đến lúc <giờ>", không đặt danh mục,
     `interruptionLevel = .active` (E7).
  3. Foreground (`willPresent`): đã có banner cho cùng `call_id` → không trình bày thông báo hệ
     thống; chưa có phiên → hiện banner từ nội dung đã giải mã, đồng thời kết nối (CONN-01 hoặc
     CONN-03).
  4. Điện thoại không push khi cuộc gọi được nghe hoặc bị từ chối, nên I-APP tự gỡ thông báo
     (`removeDeliveredNotifications(withIdentifiers:)`): khi nhận `state` khác `ringing` của
     `call_id` đó, và mỗi lần vào foreground với mọi thông báo cuộc gọi đến có `started_at` cũ hơn
     60 s. Việc này gồm cả thông báo chung đăng khi máy đang khóa (E6). Các thông báo đó không có
     `started_at`: I-APP nhận ra chúng qua loại `call_event` của envelope, mở bằng `K_push` rồi dùng
     `started_at`; envelope bị từ chối vì cũ hơn 24 h thì xét theo `ts` của envelope. Push cuộc gọi nhỡ
     cùng `collapse_key` tự thay thế thông báo (CALL-04).

#### API 7 — Thông báo liên lạc trên Mac

- **URL:** N/A
- **Method:**
  `INStartCallIntent(callRecordFilter: nil, callRecordToCallBack: nil, audioRoute: .unknown, destinationType: .normal, contacts: [INPerson], callCapability: .audioCall)`;
  `INInteraction(intent:response:)` với `direction = .incoming`, `donate(completion:)`;
  `UNMutableNotificationContent.updating(from:)`; `UNUserNotificationCenter.add(_:)`; gỡ bằng
  `removeDeliveredNotifications(withIdentifiers:)`. Cần capability Communication Notifications và
  `NSUserActivityTypes` có `INStartCallIntent`.
- **Request (nội dung thông báo):**

| Thuộc tính | Giá trị |
|------------|---------|
| `INPerson` | `displayName` = trường 2, hoặc trường 3 khi không có tên; `personHandle` = số E.164 (`.phoneNumber`) để hệ thống lọc theo người gọi trong chế độ Tập trung |
| `body` | "Cuộc gọi đến", thêm " · <nhãn SIM>" khi có |
| `threadIdentifier` | `calls` |
| `categoryIdentifier` | `HL_CALL_INCOMING_MAC` chỉ khi `controls.answer` và `controls.reject` đều `true`: hành động "Trả lời" (`HL_CALL_ANSWER`), "Từ chối" (`HL_CALL_REJECT`, `.destructive`); `hiddenPreviewsBodyPlaceholder` "Cuộc gọi đến". Ngược lại không đặt danh mục; panel đưa ra các thao tác mà `controls` cho phép |
| `interruptionLevel` | `.passive` khi panel đang hiện; `.timeSensitive` khi chế độ Tập trung bật và không có panel |
| `sound` | `.default` với bản `.timeSensitive` (Tập trung bật); không có âm với `.passive` |
| `identifier` | `call_id` — một thông báo cho một cuộc gọi; gửi lại cùng `identifier` để cập nhật |
| `userInfo` | `{pair_id, call_id, started_at}` |

- **Response:** "Trả lời" → CALL-02 (`answer`) và mở panel ở chế độ đang gọi, kể cả khi Tập trung bật
  (các panel đang gọi khác vẫn ẩn khi Tập trung bật, E4); "Từ chối" → CALL-02
  (`reject`); bấm vào thông báo → đưa panel ra trước (mở panel nếu Tập trung đã tắt).
- **Ví dụ:** cuộc gọi ở ví dụ API 1 khi panel đang hiện → thông báo
  `identifier = "0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90"`, `interruptionLevel = .passive`: nằm trong
  Trung tâm thông báo, không banner, không âm.
- **Logic nghiệp vụ:**
  1. Một cuộc gọi chỉ có một lớp báo hiện lên: panel (Tập trung tắt) hoặc banner thông báo (Tập
     trung bật). Khi có panel, thông báo ở mức passive để lịch sử vẫn nằm trong Trung tâm thông báo.
  2. Gỡ thông báo khi `state` khác `ringing` (bước 12); cuộc gọi nhỡ dùng thông báo riêng của
     CALL-04.
  3. `call.notify = false` → không gửi thông báo, không panel (E3).
  4. Hành động của thông báo chạy trong tiến trình M-APP (luôn chạy) qua
     `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)`;
     không cần mở cửa sổ.

#### Query

```text
// [Thiết kế] Android, bước 3 và API 3: tên liên hệ của số gọi đến (chỉ đọc dòng đầu;
// cache LRU 200 số trong bộ nhớ A-CALL, không ghi đĩa)
ContentResolver.query(
    Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number)),
    arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME), null, null, null)
```

```sql
-- [Thiết kế] Android, bước 4: nền tảng và địa chỉ Bluetooth của client nhận (tính controls, hfp_connected)
SELECT peer_platform, peer_bt_address
FROM paired_device
WHERE pair_id = :pair_id AND revoked_at IS NULL;

-- [Thiết kế] Android, bước 5: cặp iOS/iPadOS có thể cần push (lọc tiếp theo phiên đang mở và features_json trong bộ nhớ)
SELECT pair_id, peer_device_id, features_json
FROM paired_device
WHERE revoked_at IS NULL AND relay_registered = 1 AND peer_platform IN ('ios', 'ipados');

-- [Thiết kế] Android, API 4 logic 5: cuộc gọi hết đổ chuông → bỏ push call_incoming đang xếp hàng
DELETE FROM push_outbox
WHERE collapse_key = :collapse_key AND reason = 'call_incoming';   -- :collapse_key = 'call:<call_id>'

-- [Thiết kế] Mac/iOS, bước 6: capability gần nhất của điện thoại (features.call, permissions_missing)
SELECT features_json
FROM paired_device
WHERE pair_id = :pair_id AND revoked_at IS NULL;
```

Ghi `push_outbox` khi push lỗi: xem CONN-04.

---

## 6.2 CALL-02 — Trả lời hoặc từ chối cuộc gọi đến

### 6.2.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | CALL-02 — Trả lời hoặc từ chối cuộc gọi đến |
| Mô tả | Từ panel cuộc gọi đến (CALL-01), người dùng Mac trả lời, từ chối, hoặc từ chối kèm một tin nhắn trả lời nhanh; người dùng iPhone/iPad từ chối từ banner trong ứng dụng hoặc từ nút "Từ chối" của thông báo.<br>Client gửi `call_event/action` (`answer` hoặc `reject`); Android kiểm tra rồi gọi `TelecomManager.acceptRingingCall()` hoặc `TelecomManager.endCall()` (quyền `ANSWER_PHONE_CALLS`; hai hàm deprecated từ API 29 nhưng vẫn hoạt động — C12).<br>Kết quả thấy qua `call_event/state`: `offhook` (đã nghe) hoặc `idle` với `end_reason = rejected`.<br>**Nghe trên Mac** (P4, cần âm thanh cuộc gọi hiệu lực): Mac đang nối HFP → M-HFP trả lời bằng lệnh HFP `ATA` để âm thanh đi thẳng tới Mac; không nối HFP → trả lời qua WebSocket rồi chuyển âm thanh theo AUDIO-03 (qua HFP — AUDIO-02, hoặc Opus/WS — AUDIO-04).<br>**Từ chối kèm tin nhắn** (chỉ Mac) = từ chối rồi gửi SMS trả lời nhanh tới người gọi qua SMS-04; mẫu tin lưu cục bộ trên Mac. |
| Tác nhân | Chính: Người dùng. Hệ thống: M-APP, M-HFP, I-APP, A-SVC, A-CALL, A-SMS (tin trả lời nhanh), OS (Telecom, `UNUserNotificationCenter`), R-API (chuyển tiếp khi qua relay, wake push). |
| Điều kiện trước | 1.<br>Có ngữ cảnh `state = ringing`, `waiting = false` (CALL-01) và client đang hiển thị nó.<br>2. `controls.answer` (chỉ Mac) hoặc `controls.reject` bằng `true` (Android có `ANSWER_PHONE_CALLS`).<br>3.<br>Có phiên `/v1/ctl`; iOS từ thông báo: I-APP tự kết nối trong tác vụ nền.<br>4.<br>Nghe trên Mac: âm thanh cuộc gọi hiệu lực (AUDIO-01 đã chấp thuận, `feature.call_audio = true` ở hai phía).<br>5.<br>Từ chối kèm tin nhắn: `number` khác `null`, SMS hiệu lực và `features.sms.can_send = true`. |
| Điều kiện sau | **Trả lời:** điện thoại ở `OFFHOOK`; mọi client nhận `state = offhook` có `answered_at`; Mac chuyển sang panel đang gọi (CALL-03); âm thanh ở điện thoại hoặc ở Mac theo lựa chọn (`audio_on`).<br>**Từ chối:** cuộc gọi kết thúc, `state = idle` với `end_reason = rejected`; nhật ký điện thoại ghi loại `rejected`, không có thông báo cuộc gọi nhỡ.<br>**Kèm tin nhắn:** thêm một dòng `sms_outbox` và một tin SMS tới người gọi theo SMS-04.<br>**Thất bại:** cuộc gọi giữ nguyên; client làm mới giao diện theo `state` mới nhất. |
| Ngoại lệ | E1 — `CALL_NOT_FOUND`: ngữ cảnh đã kết thúc hoặc `call_id` cũ.<br>E2 — `CALL_ACTION_NOT_ALLOWED`: trạng thái không còn cho phép (đã nghe trên điện thoại, client khác nhanh hơn, đang là cuộc gọi chờ, iPhone/iPad gửi `answer`).<br>E3 — `PERMISSION_MISSING` (`details.permission = "android.permission.ANSWER_PHONE_CALLS"`): ẩn nút, hiện hướng dẫn SET-01.<br>E4 — `FEATURE_DISABLED`.<br>E5 — Không có `ack` trong `REQUEST_TIMEOUT` hoặc mất phiên: panel trở lại trạng thái trước kèm "Không gửi được lệnh tới điện thoại"; không tự gửi lại bằng `id` mới (cuộc gọi có thể đã đổi).<br>E6 — Lệnh HFP `ATA` trả `ERROR` hoặc không phản hồi trong 2 s: gửi `call_event/action answer` (`audio = mac`) qua WebSocket như nhánh không HFP.<br>E7 — Chuyển âm thanh sang Mac thất bại sau khi đã trả lời: cuộc gọi vẫn được nghe, âm thanh ở điện thoại (`audio_on = phone`), lỗi báo theo AUDIO-03 (`CALL_ROUTE_FAILED`, `CALL_BT_NOT_CONNECTED`, `SHIZUKU_NOT_RUNNING`, `CALL_AUDIO_CAPTURE_UNSUPPORTED`).<br>E8 — iOS từ thông báo: không kết nối được hoặc không có `ack` trong 15 s → thông báo cục bộ "Không gửi được lệnh từ chối".<br>E9 — Từ chối kèm tin nhắn khi cuộc gọi đã được nghe: không gửi tin, báo "Cuộc gọi đã được nghe, tin nhắn không được gửi"; gửi SMS lỗi → xử lý theo SMS-04.<br>E10 — Thông báo iOS không có nút "Từ chối" (máy khóa khi nhận push, CALL-01 E6): người dùng mở I-APP để từ chối từ banner. |
| Yêu cầu đặc biệt | **Hiệu năng:** trả lời < 500 ms ở phân vị 95, từ lúc bấm trên Mac tới khi Mac nhận `state = offhook` (LAN, cả nhánh WebSocket và nhánh `ATA`); bench cũng báo khoảng từ lúc bấm tới `OFFHOOK` trên điện thoại; từ chối < 500 ms tới `state = idle`; từ chối từ thông báo iPhone < 2 s qua relay khi điện thoại đã mở relay sau push (CALL-01 API 4 logic 4); `CALL_REJECT_BG_TIMEOUT` (15 s, tính cả kết nối trong nền) vẫn là hạn cứng.<br>**Không thao tác trùng:** nút bị khóa sau lần bấm đầu tới khi có `ack` hoặc `state` mới; gửi lại do mạng dùng cùng `id` envelope (Android chống trùng theo 0.5.1); Android chỉ nhận một lệnh cho mỗi `call_id` trong 3 s (client khác bấm cùng lúc nhận `CALL_ACTION_NOT_ALLOWED`).<br>**An toàn:** chỉ phiên đã xác thực của cặp hợp lệ gửi được lệnh; `answer` chỉ nhận từ Mac.<br>**Riêng tư:** không log tin trả lời nhanh; mẫu tin nằm trong `UserDefaults` của Mac, không đồng bộ sang thiết bị khác. |

### 6.2.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 6.2.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Nút "Trả lời" | action | Input | — | Mac; khi âm thanh cuộc gọi chưa hiệu lực: nghe trên điện thoại (`audio = phone`) |
| 2 | Nơi nghe | enum{phone\| mac} | Input | `phone` | "Nghe trên điện thoại" / "Nghe trên Mac"; chỉ hiện khi âm thanh cuộc gọi hiệu lực (AUDIO-01) |
| 3 | Nút "Từ chối" | action | Input | — | Panel Mac, banner iOS |
| 4 | Hành động "Từ chối" trên thông báo | action | Input | — | iOS (`HL_CALL_REJECT`); hệ thống yêu cầu mở khóa máy trước khi chạy |
| 5 | Nút "Từ chối kèm tin nhắn…" | action | Input | — | Mac; mở danh sách mẫu tin (trường 6, 7) |
| 6 | Mẫu tin trả lời nhanh | string(160) | Input | "Tôi sẽ gọi lại sau", "Tôi đang họp" | Chọn một mẫu trong `call.quick_replies` → từ chối và gửi ngay |
| 7 | Tin tự soạn | string(160) | Input | Rỗng | Mục "Tin khác…": ô nhập một dòng, bấm "Gửi"; không gửi khi rỗng sau khi bỏ khoảng trắng |
| 8 | Danh sách mẫu tin | array<string(160)> | Input/Output | `call.quick_replies` | Cài đặt → Cuộc gọi (Mac), danh sách "Tin trả lời nhanh" (SET-02 trường 33): thêm ("Thêm tin trả lời nhanh"), sửa, xóa ("Xóa tin trả lời nhanh"), sắp xếp; tối đa 6 mẫu; chú thích dưới danh sách "Tối đa 6 tin, mỗi tin 160 ký tự. Chọn một tin khi từ chối cuộc gọi trên Mac này."; khóa ở 0.9.5 |
| 9 | Trạng thái đang xử lý | enum{idle\| answering\| rejecting} | Output | `idle` | "Đang trả lời…", "Đang từ chối…"; các nút bị khóa |
| 10 | Thông báo lỗi | string | Output | Ẩn | Theo E1–E9: "Cuộc gọi đã kết thúc", "Cuộc gọi đã được nghe trên điện thoại", "Điện thoại chưa cho phép HandLive trả lời cuộc gọi", "Không gửi được lệnh tới điện thoại", "Không chuyển được âm thanh sang Mac" |
| 11 | Thông báo iOS "Không gửi được lệnh từ chối" | string | Output | — | E8: "Không gửi được lệnh từ chối. Cuộc gọi vẫn đổ chuông trên điện thoại." |

### 6.2.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U1["(1) Chọn Trả lời, Từ chối hoặc Từ chối kèm tin nhắn"]
    UB1["(B1) iOS: chạm Từ chối trên thông báo, mở khóa máy"]
    U10["(10) Thấy panel đang gọi hoặc panel đóng"]
  end
  subgraph HT["Hệ thống"]
    D2{"(2) Nghe trên Mac và đang nối HFP?"}
    S3["(3) M-HFP gửi lệnh HFP ATA"]
    S4["(4) Gửi call_event/action answer hoặc reject"]
    D5{"(5) Android: tính năng, call_id, quyền, trạng thái hợp lệ?"}
    S6["(6) acceptRingingCall hoặc endCall, trả ack"]
    S7["(7) A-CALL thấy OFFHOOK hoặc IDLE, gửi state"]
    S8["(8) Kèm tin nhắn: sms_outbox và sms/send theo SMS-04"]
    S9["(9) Nghe trên Mac qua WebSocket: chuyển âm thanh theo AUDIO-03"]
    SB2["(B2) I-APP chạy nền, kết nối LAN hoặc relay"]
    X1(["Báo lỗi, làm mới theo state mới nhất"])
  end
  U1 --> D2
  D2 -- "Có" --> S3 --> S7
  S3 -- "Lỗi hoặc quá 2 s (E6)" --> S4
  D2 -- "Không" --> S4 --> D5
  UB1 --> SB2 --> S4
  D5 -- "Hợp lệ" --> S6 --> S7
  D5 -- "Lỗi (E1 đến E4)" --> X1
  S4 -- "Không có ack (E5, E8)" --> X1
  S7 -- "Từ chối kèm tin" --> S8 --> U10
  S7 -- "Nghe trên Mac qua WebSocket" --> S9 --> U10
  S7 -- "Còn lại" --> U10
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Người dùng | M-APP / I-APP | Mac: bấm "Trả lời" (hoặc "Nghe trên điện thoại" / "Nghe trên Mac"), "Từ chối", hoặc "Từ chối kèm tin nhắn…" rồi chọn mẫu tin hoặc nhập tin. iOS: bấm "Từ chối" trên banner. Client khóa nút, hiện trường 9. | Nút chỉ có khi `controls` cho phép. |
| 2 | Hệ thống | M-APP | "Nghe trên Mac" và M-HFP đang có kết nối HFP (`hfp_connected = true`) → bước 3; mọi trường hợp khác → bước 4. |  |
| 3 | Hệ thống | M-HFP | Gửi lệnh HFP `ATA` (API 4); điện thoại nghe máy và mở kết nối âm thanh SCO tới Mac. Không gửi `call_event/action`. | `ERROR` hoặc quá 2 s → E6, sang bước 4 với `audio = mac`. |
| 4 | Hệ thống | M-APP / I-APP | Gửi `call_event/action` (API 1) `{call_id, action, audio}`; chờ `ack` tối đa `REQUEST_TIMEOUT`; mất phiên trong lúc chờ → gửi lại cùng `id` nếu phiên nối lại trước hạn. | Hết hạn → E5. |
| 5 | Hệ thống | A-SVC, A-CALL | Kiểm theo thứ tự: `feature.call`, `action`, `call_id` khớp ngữ cảnh hiện tại, quyền `ANSWER_PHONE_CALLS`, trạng thái (`ringing`, không chờ, chưa có lệnh khác trong 3 s), nền tảng client với `answer`. | `ack` lỗi → E1–E4 (X1). |
| 6 | Hệ thống | A-CALL, OS | `answer` → `acceptRingingCall()` (API 2), ghi `audio` vào ngữ cảnh. `reject` → đánh dấu ngữ cảnh "HandLive từ chối" rồi `endCall()` (API 3). Trả `ack` `{}`. | `endCall()` trả `false` → `CALL_NOT_FOUND`; `SecurityException` → `PERMISSION_MISSING`. |
| 7 | Hệ thống | A-CALL, A-SVC | Listener báo `OFFHOOK` (đặt `answered_at`) hoặc `IDLE` (`end_reason = rejected`); gửi `state` tới mọi phiên (CALL-01 API 1). Client khác đang hiện cuộc gọi cũng cập nhật. | Không có `state` mới trong 3 s sau `ack` → client mở khóa nút, hiển thị theo `state` gần nhất. |
| 8 | Hệ thống | M-APP, A-SMS | Từ chối kèm tin nhắn: khi `ack` thành công hoặc `state = idle`, M-APP tạo `sms_outbox` và gửi `sms/send` (API 5) tới `number`, qua `sub_id` của cuộc gọi. | `state = offhook` → không gửi (E9). |
| 9 | Hệ thống | M-APP, A-AUD | "Nghe trên Mac" đi qua bước 4: sau `ack` thành công, M-APP chạy AUDIO-03 để chuyển âm thanh sang Mac (nối HFP theo AUDIO-02 rồi mở SCO, hoặc Opus/WS theo AUDIO-04). | Lỗi → E7. |
| 10 | Người dùng | M-APP / I-APP | Mac: thấy panel đang gọi (CALL-03) với `audio_on`, hoặc panel đóng sau khi từ chối; tin trả lời nằm trong hội thoại (SMS-04). iOS: banner đóng. |  |
| B1 | Người dùng | I-APP (thông báo) | iOS: chạm "Từ chối" trên thông báo cuộc gọi đến (CALL-01 API 6); hệ thống yêu cầu mở khóa (`.authenticationRequired`). | Thông báo không có nút → E10. |
| B2 | Hệ thống | I-APP | Hệ thống đánh thức I-APP ở nền (API 6).<br>I-APP xin thời gian chạy nền, đọc `pair_id`, `call_id` trong `userInfo`, dùng phiên nếu còn đang được giữ (CONN-02 E3), không thì kết nối CONN-01 (LAN) hoặc CONN-03 (relay — điện thoại thường đã mở relay sau push, CALL-01 API 4; chưa online thì gửi wake `call_action` theo CONN-04), rồi làm bước 4 với `reject`. |  |
| B3 | Hệ thống | I-APP | `ack` thành công, `CALL_NOT_FOUND` hoặc `CALL_ACTION_NOT_ALLOWED` (mọi `reason`, kể cả `system`: điện thoại không còn cho từ chối cuộc gọi) → gỡ thông báo, kết thúc tác vụ nền. Lỗi khác (`PERMISSION_MISSING`, `FEATURE_DISABLED`, `INTERNAL`), không kết nối được hoặc quá 15 s → đăng trường 11, kết thúc tác vụ nền. | E8. |

### 6.2.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | `WS call_event/action` (`answer`, `reject`) | `/v1/ctl` (LAN hoặc relay) | C→S, có ack | 4, 5, 6, B2 |
| 2 | `TelecomManager.acceptRingingCall()` | Cục bộ Android | A-CALL → OS | 6 |
| 3 | `TelecomManager.endCall()` | Cục bộ Android | A-CALL → OS | 6 |
| 4 | Lệnh HFP `ATA` qua M-HFP | Bluetooth HFP (Mac vai trò HF, điện thoại vai trò AG) | M-HFP → điện thoại | 3 |
| 5 | `WS sms/send` (đặc tả chính ở SMS-04 API 1) | `/v1/ctl` (LAN hoặc relay) | C→S, có ack | 8 |
| 6 | Hành động thông báo `HL_CALL_REJECT` và tác vụ nền iOS | Cục bộ iOS | OS → I-APP | B1–B3 |

Kết quả của bước 7 đi qua `call_event/state` (CALL-01 API 1); wake push `call_action` ở B2 theo
CONN-04 API 2 — không phát sinh lời gọi mới.

#### API 1 — `WS call_event/action`

- **URL:** `wss://{android_host}:{port}/v1/ctl` (LAN) hoặc qua relay `wss://{RELAY_HOST}/v1/relay`
  với lớp bọc `to` /`from`
- **Method:** `WS call_event/action` (C→S), envelope mã hóa, có ack. Dùng chung cho CALL-03 (`end`).
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `call_id` | uuid | Có | Của ngữ cảnh client đang hiển thị: ngữ cảnh cuộc gọi điện thoại, hoặc một cuộc gọi ứng dụng còn sống (CALL-05) |
| `action` | enum{answer\| reject\| end\| hold\| unhold\| dtmf\| mute} | Có | Qua WebSocket chỉ thực hiện `answer`, `reject`, `end`; các giá trị còn lại luôn nhận `CALL_HFP_REQUIRED` (0.7.1) |
| `audio` | enum{phone\| mac} | Không | Chỉ với `answer`: nơi người dùng muốn nghe; vắng → `phone`; cuộc gọi ứng dụng chỉ nhận `phone` (CALL-05 API 2) |

- **Response (`ack.data`):** `{}` khi `ok = true` — Android đã gọi API Telecom; kết quả thật đi qua
  `state`.

Lỗi (`ack.error.code`), theo thứ tự kiểm:

| Mã | Khi nào |
|----|---------|
| `FEATURE_DISABLED` | Cuộc gọi không hiệu lực với phiên gửi yêu cầu (`feature.call = false` trên Android hoặc trên client đó, hoặc thiếu `READ_PHONE_STATE`); với `call_id` của cuộc gọi ứng dụng: cuộc gọi ứng dụng không hiệu lực với phiên đó (CALL-05) |
| `BAD_REQUEST` | Thiếu trường, `action` hoặc `audio` ngoài danh sách |
| `CALL_HFP_REQUIRED` | `action` ∈ {`hold`, `unhold`, `dtmf`, `mute`}; `details.action` = giá trị đã gửi |
| `CALL_NOT_FOUND` | Không có ngữ cảnh, `call_id` khác ngữ cảnh hiện tại, hoặc `endCall()` trả `false` khi máy đã `IDLE` |
| `PERMISSION_MISSING` | Thiếu `ANSWER_PHONE_CALLS`; `details.permission = "android.permission.ANSWER_PHONE_CALLS"` |
| `CALL_ACTION_NOT_ALLOWED` | `details.state` = trạng thái hiện tại; `details.reason` = `state` (`answer`/`reject` khi không `ringing`, `end` khi không `offhook`, hoặc đã có lệnh khác cho `call_id` trong 3 s), `waiting` (đang có cuộc gọi chờ), `platform` (`answer` từ iPhone/iPad), `system` (Telecom từ chối, ví dụ cuộc gọi khẩn cấp — CALL-03) |
| `CALL_ROUTE_FAILED` | Chỉ với `call_id` của cuộc gọi ứng dụng: `answer` với `audio = mac` (âm thanh cuộc gọi ứng dụng ở lại điện thoại, CALL-05 API 2) |
| `CALL_APP_ACTION_UNAVAILABLE` | Chỉ với `call_id` của cuộc gọi ứng dụng: thông báo của ứng dụng không còn thao tác đó, hoặc đã mất (CALL-05 API 2) |
| `INTERNAL` | Lỗi không mong đợi trên Android (0.8.1), ví dụ hàm Telecom ném ngoại lệ khác `SecurityException`; client xử lý như E5, không tự gửi lại |

- **Ví dụ:**

```json
{"op":"action","data":{"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","action":"answer","audio":"phone"}}
{"re":"0192f3f1-0b2c-7d3e-8f4a-5b6c7d8e9f01","ok":true,"data":{}}
```

```json
{"op":"action","data":{"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","action":"reject"}}
{"re":"0192f3f1-2c3d-7e4f-9a5b-6c7d8e9f0a12","ok":false,"error":{"code":"CALL_ACTION_NOT_ALLOWED","message":"Call is no longer ringing","details":{"state":"offhook","reason":"state"}}}
```

- **Logic nghiệp vụ:**
  1. Kiểm theo thứ tự trong bảng lỗi; `call_id` chỉ so với ngữ cảnh hiện tại (không nhận `call_id`
     trong danh sách "vừa kết thúc").
  2. `ack` gửi ngay sau khi hàm Telecom trả về, không chờ `OFFHOOK` /`IDLE`; client coi `state` là
     kết quả cuối.
  3. Lệnh hợp lệ đầu tiên cho một `call_id` giữ "khóa thao tác" 3 s; lệnh khác (cùng hoặc khác
     client, `id` khác) trong thời gian này → `CALL_ACTION_NOT_ALLOWED` (`state`). Gửi lại cùng `id`
     → nhận lại `ack` cũ (0.5.1).
  4. `reject`: đặt cờ "HandLive từ chối" trước khi gọi `endCall()`; cờ hết hạn sau 3 s, dùng để tính
     `end_reason = rejected` (CALL-01 API 1, logic 5).
  5. `answer` với `audio = mac`: cách trả lời không đổi; `audio` được ghi vào ngữ cảnh để A-AUD biết
     âm thanh sắp chuyển sang Mac (AUDIO-03). Việc chuyển do M-APP khởi xướng; M-APP chỉ hiện "Nghe
     trên Mac" khi âm thanh cuộc gọi hiệu lực ở cả hai phía.
  6. Client: `ok = false` → hiện trường 10 theo mã, mở khóa nút, áp dụng `state` mới nhất;
     `ok = true` → chờ `state` tối đa 3 s.
  7. **Cuộc gọi ứng dụng (CALL-05):** A-CALL tìm `call_id` trong các ngữ cảnh cuộc gọi ứng dụng còn
     sống trước; khớp thì CALL-05 API 2 xử lý, chỉ trả `FEATURE_DISABLED`, `BAD_REQUEST`,
     `CALL_HFP_REQUIRED`, `CALL_ROUTE_FAILED`, `CALL_APP_ACTION_UNAVAILABLE` hoặc `INTERNAL`, theo thứ
     tự này. Mọi `call_id` khác đi qua các bước kiểm ở trên không đổi, trừ việc phiên có cuộc gọi ứng
     dụng hiệu lực nhưng cuộc gọi điện thoại không hiệu lực nhận `CALL_NOT_FOUND` thay cho
     `FEATURE_DISABLED`.

#### API 2 — `TelecomManager.acceptRingingCall()`

- **URL:** N/A
- **Method:** `context.getSystemService(TelecomManager::class.java).acceptRingingCall()`; quyền
  runtime `ANSWER_PHONE_CALLS`. Deprecated từ API 29, vẫn hoạt động (C12).
- **Request:** không tham số (bản không có `videoState` — cuộc gọi thoại).
- **Response:** không trả giá trị; kết quả thấy qua listener (`OFFHOOK`). Thiếu quyền →
  `SecurityException`.
- **Ví dụ:** ngữ cảnh `0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90` đang `ringing` → `acceptRingingCall()`
  → khoảng 150 ms sau listener báo `CALL_STATE_OFFHOOK` → `state = offhook`,
  `answered_at = 1727150405321`.
- **Logic nghiệp vụ:**
  1. Gọi trên luồng A-CALL; `SecurityException` → `PERMISSION_MISSING`, gửi `capability/update`
     (`can_answer = false`, `permissions_missing`).
  2. Chỉ gọi khi trạng thái tổng hợp là `RINGING` và không có cuộc gọi chờ; với cuộc gọi chờ, hệ
     thống sẽ giữ hoặc ngắt cuộc gọi đang nói — đó là xử lý cuộc gọi chờ, chỉ làm qua HFP (CALL-03).
  3. Điện thoại đang khóa màn hình vẫn nghe máy được. Âm thanh theo tuyến mặc định của điện thoại
     (loa trong, tai nghe có dây, hoặc thiết bị Bluetooth đang nối).

#### API 3 — `TelecomManager.endCall()`

- **URL:** N/A
- **Method:** `telecomManager.endCall()` → `Boolean`; quyền `ANSWER_PHONE_CALLS`. Deprecated từ API
  29, vẫn hoạt động (C12). Dùng chung cho CALL-03.
- **Request:** không tham số.
- **Response:** `true` khi Telecom đã từ chối cuộc gọi đang đổ chuông hoặc kết thúc cuộc gọi đang
  nói; `false` khi không có cuộc gọi hoặc Telecom không cho kết thúc (ví dụ cuộc gọi khẩn cấp).
- **Ví dụ:** ngữ cảnh đang `ringing`, cờ "HandLive từ chối" đã đặt → `endCall()` = `true` → listener
  báo `CALL_STATE_IDLE` → `state = idle`, `end_reason = rejected`; nhật ký ghi `REJECTED_TYPE`.
- **Logic nghiệp vụ:**
  1. Cuộc gọi tiền cảnh đang đổ chuông → Telecom từ chối nó; đang nói → kết thúc (CALL-03).
  2. `false` khi máy đã `IDLE` → `CALL_NOT_FOUND`; `false` khi máy vẫn `RINGING` hoặc `OFFHOOK` →
     `CALL_ACTION_NOT_ALLOWED` (`reason = system`).
  3. Không gọi khi `waiting = true` (API 1): khi có hai cuộc gọi, trạng thái tổng hợp không cho biết
     cuộc gọi nào sẽ bị tác động.

#### API 4 — Lệnh HFP `ATA` qua M-HFP

- **URL:** N/A (kết nối HFP mức dịch vụ giữa Mac — vai trò HF — và điện thoại — vai trò AG; thiết
  lập ở AUDIO-02)
- **Method:** M-HFP gửi lệnh HFP qua protocol abstraction (tầng cài đặt
  `IOBluetoothHandsFreeDevice`, lệnh AT thô bằng `sendATCommand`).
- **Request:** `ATA`
- **Response:** `OK`, sau đó chỉ báo `+CIEV` (cuộc gọi chuyển sang đang nói); hoặc `ERROR`.
- **Ví dụ:** Mac gửi `ATA` → điện thoại trả `OK`, `+CIEV` báo có cuộc gọi đang nói, mở SCO tới Mac →
  A-CALL thấy `OFFHOOK`, A-AUD thấy SCO tới Mac → `state = offhook`, `audio_on = mac`.
- **Logic nghiệp vụ:**
  1. Chỉ dùng khi người dùng chọn "Nghe trên Mac", âm thanh cuộc gọi hiệu lực và M-HFP đang có kết
     nối HFP tới điện thoại; M-HFP không nhận lệnh khi chưa chấp thuận AUDIO-01.
  2. Chờ `OK` tối đa 2 s; `ERROR` hoặc quá hạn → E6 (gửi `answer` qua WebSocket với `audio = mac`).
  3. Không có `call_event/action`, nên ngữ cảnh trên Android không có `audio`; A-AUD tự nhận ra SCO
     tới Mac và `state` báo `audio_on = mac`.
  4. Từ chối không đi bằng HFP: luôn dùng `call_event/action reject`, để Mac và iPhone/iPad dùng
     chung một đường và A-CALL đặt được `end_reason = rejected`.

#### API 5 — `WS sms/send` cho "Từ chối kèm tin nhắn…"

- **URL:** như API 1
- **Method:** `WS sms/send` (C→S), envelope mã hóa, có ack — đặc tả chính ở SMS-04 API 1.
- **Request (`data`), giá trị dùng ở đây:**

| Trường | Giá trị |
|--------|---------|
| `local_id` | UUIDv7 mới |
| `thread_id` | Hội thoại sẵn có với số người gọi (Query); không có → vắng |
| `addresses` | `[number]` của `state` |
| `body` | Mẫu tin đã chọn (trường 6) hoặc tin tự soạn (trường 7) |
| `sub_id` | `sub_id` của `state`; `null` → vắng (SIM gửi SMS mặc định) |

- **Response:** theo SMS-04 API 1 (`{accepted, parts}`); trạng thái tiếp theo qua `sms/status`.
- **Ví dụ:**

```json
{"op":"send","data":{"local_id":"0192f3f1-4d5e-7f60-8a7b-9c0d1e2f3a4b","thread_id":42,"addresses":["+84900000123"],"body":"Tôi đang họp","sub_id":1}}
```

- **Logic nghiệp vụ:**
  1. Gửi khi `ack` của `reject` thành công hoặc khi đã nhận `state = idle` của cuộc gọi;
     `state = offhook` → không gửi (E9).
  2. Đi qua `sms_outbox` như SMS-04 (bong bóng tạm, thử lại, trạng thái); tin hiện trong hội thoại
     với người gọi.
  3. `call.quick_replies` nằm trong `UserDefaults` của Mac, mỗi mẫu ≤ 160 ký tự, tối đa 6 mẫu; cài
     mới có hai mẫu mặc định (trường 6).

#### API 6 — Hành động `HL_CALL_REJECT` trên iOS

- **URL:** N/A
- **Method:**
  `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)`
  nhận `UNNotificationResponse` có `actionIdentifier = "HL_CALL_REJECT"` (danh mục ở CALL-01 API 6).
  Việc kết nối và gửi nằm trong `UIApplication.beginBackgroundTask(withName:expirationHandler:)` …
  `endBackgroundTask(_:)`.
- **Request:**

| Thuộc tính | Giá trị |
|------------|---------|
| `actionIdentifier` | `HL_CALL_REJECT` |
| `notification.request.content.userInfo` | `{pair_id, call_id, started_at}` do I-NSE đặt |

- **Response:** gọi `completionHandler()` khi có kết quả (B3) hoặc hết 15 s.
- **Ví dụ:**
  `userInfo = {"pair_id":"7a6b5c4d-3e2f-4a1b-9c8d-7e6f5a4b3c2d","call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","started_at":1727150400123}`
  → kết nối qua relay → `call_event/action` `{call_id, action: "reject"}` → `ack` thành công → gỡ
  thông báo.
- **Logic nghiệp vụ:**
  1. Tùy chọn `.authenticationRequired` bảo đảm máy đã mở khóa, nên I-APP đọc được `PRK` trong
     Keychain (C3) kể cả khi tiến trình phải khởi động lại.
  2. `now − started_at > 90 s` → không gửi (cuộc gọi chắc chắn đã kết thúc), chỉ gỡ thông báo.
  3. Thứ tự đường kết nối: LAN (CONN-01) → relay (CONN-03). Điện thoại chưa online trên relay →
     `POST /v1/push` `kind = wake`, `reason = call_action` (CONN-04) rồi chờ presence trong thời
     gian còn lại.
  4. Kết quả theo B3; lỗi không làm I-APP mở ra foreground.

#### Query

```sql
-- [Thiết kế] Android, bước 5: nền tảng của client gửi lệnh (answer chỉ nhận từ Mac)
SELECT peer_platform
FROM paired_device
WHERE pair_id = :pair_id AND revoked_at IS NULL;

-- [Thiết kế] Mac, bước 8: hội thoại sẵn có với số người gọi, gắn thread_id cho tin trả lời nhanh
SELECT thread_id
FROM sms_thread
WHERE pair_id = :pair_id AND addresses_json = :addresses_json   -- '["+84900000123"]'
LIMIT 1;

-- [Thiết kế] Mac, bước 8: tạo mục hàng đợi tin trả lời nhanh (như SMS-04, Query bước 3)
INSERT INTO sms_outbox (local_id, pair_id, thread_id, addresses_json, body, sub_id,
                        state, attempts, created_at, updated_at)
VALUES (:local_id, :pair_id, :thread_id, :addresses_json, :body, :sub_id,
        'pending', 0, :now, :now);
```

Ngữ cảnh cuộc gọi, khóa thao tác và cờ "HandLive từ chối" nằm trong bộ nhớ A-CALL, không có bảng.

---

## 6.3 CALL-03 — Điều khiển cuộc gọi đang diễn ra

### 6.3.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | CALL-03 — Điều khiển cuộc gọi đang diễn ra |
| Mô tả | Khi điện thoại đang trong cuộc gọi (`state = offhook`: cuộc gọi đến đã nghe, hoặc cuộc gọi đi bấm trên điện thoại), Mac hiện panel đang gọi với tên hoặc số, đồng hồ tính từ `answered_at`, trạng thái và nơi đang phát âm thanh (`audio_on`).<br>"Kết thúc" đi bằng lệnh HFP `AT+CHUP` khi Mac đang nối HFP, ngược lại qua WebSocket `call_event/action end` → `TelecomManager.endCall()`.<br>Giữ máy/tiếp tục (`AT+CHLD=2`), bàn phím DTMF (`AT+VTS`) và tắt tiếng (tắt micro Mac khi âm thanh đang ở Mac) **chỉ** làm được qua HFP khi `hfp_connected = true` (P4); gửi qua WebSocket nhận `CALL_HFP_REQUIRED`, và giao diện ẩn các nút này khi không nối HFP.<br>Cuộc gọi chờ: qua WebSocket chỉ có thông tin; xử lý (`AT+CHLD=0` từ chối cuộc gọi chờ, `AT+CHLD=1` kết thúc cuộc gọi đang nói và nghe cuộc gọi chờ, `AT+CHLD=2` giữ cuộc gọi đang nói và nghe cuộc gọi chờ) cần HFP.<br>Chuyển âm thanh giữa Mac và điện thoại thuộc AUDIO-03. |
| Tác nhân | Chính: Người dùng (Mac). Hệ thống: M-APP, M-HFP, A-SVC, A-CALL, A-AUD, OS (Telecom; stack Bluetooth của Android ở vai trò AG). |
| Điều kiện trước | 1.<br>Có ngữ cảnh `state = offhook` (CALL-01, CALL-02) và Mac có phiên `/v1/ctl` hoặc đang nối HFP tới điện thoại.<br>2.<br>"Kết thúc" qua WebSocket: `controls.end = true` (có `ANSWER_PHONE_CALLS`).<br>3.<br>Giữ máy, DTMF, tắt tiếng, xử lý cuộc gọi chờ: M-HFP đang có kết nối HFP tới điện thoại (AUDIO-02, P4, đã chấp thuận AUDIO-01); tắt tiếng cần thêm `audio_on = mac`. |
| Điều kiện sau | Thao tác được áp dụng trên điện thoại; khi trạng thái tổng hợp đổi, mọi client nhận `state` mới (kết thúc → `idle`, `end_reason = ended`; cuộc gọi chờ đã xử lý → `waiting = false`).<br>Trạng thái giữ máy, micro tắt và dãy số DTMF chỉ nằm ở M-HFP (WebSocket không có thông tin này).<br>Kết thúc: panel hiện "Đã kết thúc · mm:ss" 2 s rồi đóng. |
| Ngoại lệ | E1 — `CALL_NOT_FOUND` hoặc `CALL_ACTION_NOT_ALLOWED` (`state`): cuộc gọi đã kết thúc hoặc đổi trạng thái → làm mới theo `state`.<br>E2 — `CALL_HFP_REQUIRED` (client gửi `hold`, `unhold`, `dtmf`, `mute` qua WebSocket): ẩn nút, hiện "Nối Bluetooth với điện thoại để giữ máy, bấm số, tắt tiếng" (AUDIO-02).<br>E3 — Điện thoại trả `ERROR` hoặc không phản hồi lệnh HFP trong 2 s (ví dụ AG không hỗ trợ gọi ba bên nên không có `AT+CHLD`): báo "Điện thoại không thực hiện được thao tác này", giữ nguyên trạng thái.<br>E4 — HFP ngắt giữa cuộc gọi: `hfp_connected = false` (qua `state` và `call_event/hfp_status`), nút chỉ-HFP ẩn, tắt tiếng bị hủy, "Kết thúc" chuyển sang WebSocket.<br>E5 — `PERMISSION_MISSING` (`ANSWER_PHONE_CALLS`) và không nối HFP: nút "Kết thúc" ẩn, hướng dẫn SET-01.<br>E6 — Mất phiên WebSocket giữa cuộc gọi: panel hiện "Mất kết nối với điện thoại" khi phiên đã mất được 3 s (nối lại nhanh, như sau rekey hoặc khi đổi mạng, thì không hiện gì), và ẩn ngay khi phiên trở lại; thao tác HFP vẫn dùng được nếu đang nối; khi phiên nối lại, A-CALL gửi `state` hiện tại (CALL-01 E8).<br>E7 — Cuộc gọi chờ: trong lúc `waiting = true`, `controls.end = false` và panel ẩn "Kết thúc"; nối HFP → hiện ba nút xử lý cuộc gọi chờ; không nối HFP → chỉ hiện thông tin.<br>E8 — Cuộc gọi đi bắt đầu trên điện thoại: chưa biết số (`number = null`) → "Cuộc gọi đi"; đồng hồ tính từ `started_at` (gồm cả thời gian đổ chuông); số có trong nhật ký sau khi kết thúc (CALL-04).<br>E9 — Telecom không cho kết thúc (ví dụ cuộc gọi khẩn cấp: `endCall()` trả `false` khi máy vẫn `OFFHOOK`) → `CALL_ACTION_NOT_ALLOWED` (`reason = system`), báo "Hãy kết thúc cuộc gọi này trên điện thoại". |
| Yêu cầu đặc biệt | **Hiệu năng:** "Kết thúc" < 500 ms tới `state = idle` (LAN hoặc HFP); DTMF: mỗi phím gửi ngay, hàng đợi tuần tự chờ `OK` của từng lệnh (≤ 300 ms mỗi phím).<br>**Đồng hồ:** không phụ thuộc lệch giờ giữa hai máy: thời lượng = (`ts` của envelope − `answered_at`) + thời gian trôi trên Mac kể từ lúc nhận envelope.<br>**Giới hạn nền tảng (C12):** WebSocket chỉ có trạng thái tổng hợp; khi nối HFP, M-HFP có thêm chỉ báo của AG (`+CIEV`, `+CCWA`, `+CLCC`) nên biết cuộc gọi đang giữ và số của cuộc gọi chờ chính xác hơn — giao diện ưu tiên thông tin HFP khi có.<br>**Riêng tư:** không log phím DTMF (có thể là mã PIN, OTP); dãy số đã bấm không lưu.<br>**Phạm vi:** iPhone/iPad không có chức năng này (chỉ đóng banner khi `state = offhook`, CALL-01). |

### 6.3.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 6.3.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Tên hoặc số | string | Output | `display_name` / `number` | Như CALL-01 trường 2–3; "Cuộc gọi đi" khi cuộc gọi đi chưa biết số (E8) |
| 2 | Đồng hồ | string (mm:ss) | Output | "00:00" | Tính từ `answered_at`; `answered_at = null` → tính từ `started_at` |
| 3 | Trạng thái | enum{active\| held\| waiting\| ended} | Output | `active` | "Đang gọi", "Đang giữ máy" (chỉ khi nối HFP), "Có cuộc gọi chờ", "Đã kết thúc · mm:ss" |
| 4 | Nơi phát âm thanh | enum{phone\| mac} | Output | `audio_on` | "Âm thanh: Điện thoại" / "Âm thanh: Mac"; nút chuyển → AUDIO-03 |
| 5 | Nút "Kết thúc" | action | Input | — | Hiện khi `waiting = false` và (`controls.end = true` hoặc M-HFP đang nối); tooltip "Kết thúc cuộc gọi" |
| 6 | Nút "Giữ máy" / "Tiếp tục" | action | Input | Ẩn | Chỉ khi `controls.hold = hfp` và `waiting = false` |
| 7 | Bàn phím DTMF | string(1) | Input | Ẩn | Chỉ khi `controls.dtmf = hfp`; một trong `0`–`9`, `*`, `#`; nhận cả phím trên bàn phím Mac khi panel có focus |
| 8 | Dãy số đã bấm | string | Output | Rỗng | Dưới bàn phím; xóa khi đóng bàn phím; không lưu, không log |
| 9 | Nút "Tắt tiếng" | bool | Input/Output | `false` | Chỉ khi `controls.mute = hfp`; `true` = micro Mac đang tắt; tooltip "Tắt tiếng micro trên Mac" |
| 10 | Người gọi chờ | string | Output | Ẩn | `waiting_display_name` / `waiting_number`, hoặc số từ `+CCWA` khi nối HFP |
| 11 | Nút xử lý cuộc gọi chờ | enum{reject_waiting\| end_and_accept\| hold_and_accept} | Input | Ẩn | Chỉ khi `waiting = true` và M-HFP đang nối: "Từ chối cuộc gọi chờ" (`AT+CHLD=0`), "Kết thúc và nghe" (`AT+CHLD=1`), "Giữ và nghe" (`AT+CHLD=2`) |
| 12 | Thông báo lỗi, hướng dẫn | string | Output | Ẩn | Theo E1–E9 |

### 6.3.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U2["(2) Chọn Kết thúc, Giữ máy, bấm số, Tắt tiếng hoặc xử lý cuộc gọi chờ"]
    U10["(10) Thấy kết quả trên panel"]
  end
  subgraph HT["Hệ thống"]
    S1["(1) state offhook: hiện panel đang gọi, đồng hồ, nơi phát âm thanh"]
    D3{"(3) M-HFP đang nối HFP?"}
    S4["(4) M-HFP gửi lệnh HFP hoặc tắt micro Mac"]
    D5{"(5) Thao tác là Kết thúc?"}
    S6["(6) Gửi call_event/action end"]
    D7{"(7) Android: call_id, quyền, trạng thái hợp lệ?"}
    S8["(8) endCall, trả ack"]
    S9["(9) A-CALL gửi state mới, M-HFP cập nhật chỉ báo"]
    X1(["Ẩn nút, hướng dẫn nối Bluetooth"])
    X2(["Báo lỗi, làm mới theo state"])
  end
  S1 --> U2 --> D3
  D3 -- "Có" --> S4 --> S9
  S4 -- "ERROR hoặc quá 2 s (E3)" --> X2
  D3 -- "Không" --> D5
  D5 -- "Có" --> S6 --> D7
  D5 -- "Không (E2)" --> X1
  D7 -- "Hợp lệ" --> S8 --> S9
  D7 -- "Lỗi (E1, E5, E9)" --> X2
  S9 --> U10
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Hệ thống | M-APP | Nhận `state = offhook` (sau CALL-02, hoặc cuộc gọi bắt đầu trên điện thoại khi `call.notify = true`): panel chuyển sang chế độ đang gọi (trường 1–4), bật đồng hồ; nút theo `controls` và kết nối HFP của M-HFP. | E8. Khi Tập trung bật, panel vẫn ẩn trừ khi cuộc gọi được trả lời từ thông báo trên Mac (CALL-01 E4). |
| 2 | Người dùng | M-APP | Chọn thao tác: "Kết thúc", "Giữ máy"/"Tiếp tục", bấm phím DTMF, "Tắt tiếng", hoặc một nút xử lý cuộc gọi chờ. | Cuộc gọi chờ → E7. |
| 3 | Hệ thống | M-APP | M-HFP đang có kết nối HFP mức dịch vụ tới điện thoại → bước 4; ngược lại → bước 5. |  |
| 4 | Hệ thống | M-HFP | Gửi lệnh HFP (API 3) và chờ `OK` tối đa 2 s: Kết thúc → `AT+CHUP`; Giữ máy/Tiếp tục → `AT+CHLD=2`; phím DTMF → `AT+VTS=<phím>`; cuộc gọi chờ → `AT+CHLD=0`, `1` hoặc `2`. Tắt tiếng không có lệnh AT: M-HFP ngừng đưa micro Mac vào kênh SCO (gửi khung im lặng). | `ERROR` hoặc quá hạn → E3 (X2). |
| 5 | Hệ thống | M-APP | Không nối HFP: chỉ "Kết thúc" đi được qua WebSocket; các nút khác đã bị ẩn. | Client gửi thao tác khác qua WebSocket → `CALL_HFP_REQUIRED` (E2, X1). |
| 6 | Hệ thống | M-APP | Gửi `call_event/action` `{call_id, action: "end"}` (API 1), chờ `ack` tối đa `REQUEST_TIMEOUT`. | Hết hạn → như CALL-02 E5. |
| 7 | Hệ thống | A-SVC, A-CALL | Kiểm như CALL-02 bước 5 với `end`: `state = offhook`, `waiting = false`, có `ANSWER_PHONE_CALLS`. | E1, E5, E7. |
| 8 | Hệ thống | A-CALL, OS | Gọi `endCall()` (API 2), trả `ack` `{}`. | `false` → `CALL_NOT_FOUND` (máy đã `IDLE`) hoặc `CALL_ACTION_NOT_ALLOWED` (`system`, E9). |
| 9 | Hệ thống | A-CALL, A-SVC, M-HFP | Trạng thái tổng hợp đổi → `state` mới (API 4): `idle` với `end_reason = ended`, hoặc `waiting = false` sau khi xử lý cuộc gọi chờ. Giữ máy, tắt tiếng, DTMF không đổi trạng thái tổng hợp: panel cập nhật theo phản hồi `OK` và chỉ báo HFP (`+CIEV` của `callheld`). | E4 khi HFP ngắt. |
| 10 | Người dùng | M-APP | Thấy "Đang giữ máy", micro tắt, dãy số đã bấm, hoặc "Đã kết thúc · mm:ss" (panel đóng sau 2 s). |  |

### 6.3.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | `WS call_event/action` với `end` (đặc tả chính ở CALL-02 API 1) | `/v1/ctl` (LAN hoặc relay) | C→S, có ack | 5, 6, 7, 8 |
| 2 | `TelecomManager.endCall()` (đặc tả chính ở CALL-02 API 3) | Cục bộ Android | A-CALL → OS | 8 |
| 3 | Lệnh HFP qua M-HFP: `AT+CHUP`, `AT+CHLD`, `AT+VTS`; tắt micro Mac | Bluetooth HFP (Mac vai trò HF, điện thoại vai trò AG) | M-HFP ↔ điện thoại | 4, 9 |
| 4 | `WS call_event/state` (CALL-01 API 1) và `WS call_event/hfp_status` (AUDIO-02) | `/v1/ctl` (LAN hoặc relay) | S→C | 1, 9 |

#### API 1 — `WS call_event/action` với `end`

- **URL:** `wss://{android_host}:{port}/v1/ctl` (LAN) hoặc qua relay `wss://{RELAY_HOST}/v1/relay`
  với lớp bọc `to` /`from`
- **Method:** `WS call_event/action` (C→S), envelope mã hóa, có ack — cấu trúc, mã lỗi và thứ tự
  kiểm ở CALL-02 API 1.
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `call_id` | uuid | Có | Ngữ cảnh đang `offhook` |
| `action` | enum{end\| hold\| unhold\| dtmf\| mute} | Có | Trong CALL-03 chỉ `end` được thực hiện qua WebSocket |

- **Response (`ack.data`):** `{}` khi `ok = true`. Lỗi: `FEATURE_DISABLED` (cuộc gọi không hiệu lực
  với phiên gửi yêu cầu, như CALL-02 API 1), `BAD_REQUEST`,
  `CALL_HFP_REQUIRED` (`hold`, `unhold`, `dtmf`, `mute`), `CALL_NOT_FOUND`, `PERMISSION_MISSING`,
  `CALL_ACTION_NOT_ALLOWED` (`reason` ∈ {`state`, `waiting`, `system` }), `INTERNAL`.
- **Ví dụ:**

```json
{"op":"action","data":{"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","action":"end"}}
{"re":"0192f3f2-1a2b-7c3d-9e4f-5a6b7c8d9e0f","ok":true,"data":{}}
```

```json
{"op":"action","data":{"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","action":"hold"}}
{"re":"0192f3f2-3c4d-7e5f-8a6b-7c8d9e0f1a2b","ok":false,"error":{"code":"CALL_HFP_REQUIRED","message":"Hold requires Bluetooth HFP","details":{"action":"hold"}}}
```

- **Logic nghiệp vụ:**
  1. Android không bao giờ thực hiện `hold`, `unhold`, `dtmf`, `mute`: không có API công khai khi
     không dùng `InCallService` (C12). Luôn trả `CALL_HFP_REQUIRED`, kể cả khi Mac đang nối HFP (Mac
     phải dùng API 3).
  2. `end` khi `waiting = true` → `CALL_ACTION_NOT_ALLOWED` (`waiting`): khi có hai cuộc gọi, trạng
     thái tổng hợp không cho biết `endCall()` tác động vào cuộc gọi nào.
  3. Sau `ack` thành công, `state = idle` đến với `end_reason = ended`; không có `state` mới trong 3
     s → client mở khóa nút, hiển thị theo `state` gần nhất.

#### API 2 — `TelecomManager.endCall()` khi đang nói

- **URL:** N/A
- **Method:** `telecomManager.endCall()` → `Boolean`; quyền `ANSWER_PHONE_CALLS` — đặc tả chính ở
  CALL-02 API 3.
- **Request:** không tham số.
- **Response:** `true` → Telecom ngắt cuộc gọi tiền cảnh (đang nói); `false` → không có cuộc gọi,
  hoặc Telecom không cho kết thúc.
- **Ví dụ:** ngữ cảnh `offhook`, `answered_at = 1727150405321` → `endCall()` = `true` → listener báo
  `CALL_STATE_IDLE` lúc `1727150530456` → `state = idle`, `end_reason = ended`; panel hiện "Đã kết
  thúc · 02:05".
- **Logic nghiệp vụ:**
  1. Chỉ gọi khi `state = offhook` và `waiting = false`.
  2. `false` khi máy vẫn `OFFHOOK` (ví dụ cuộc gọi khẩn cấp) → `CALL_ACTION_NOT_ALLOWED` (`system`,
     E9); `false` khi máy đã `IDLE` → `CALL_NOT_FOUND`.

#### API 3 — Lệnh HFP qua M-HFP

- **URL:** N/A (kết nối HFP mức dịch vụ giữa Mac — vai trò HF — và điện thoại — vai trò AG; thiết
  lập ở AUDIO-02)
- **Method:** M-HFP gửi lệnh HFP qua protocol abstraction (tầng cài đặt
  `IOBluetoothHandsFreeDevice`, lệnh AT thô bằng `sendATCommand`); nhận phản hồi `OK` /`ERROR` và
  chỉ báo không yêu cầu (`+CIEV`, `+CCWA`) từ điện thoại.
- **Request:**

| Thao tác | Lệnh | Điều kiện |
|----------|------|-----------|
| Kết thúc | `AT+CHUP` | Đang có cuộc gọi, `waiting = false` |
| Giữ máy / tiếp tục | `AT+CHLD=2` | Đang nói (giữ máy) hoặc chỉ còn cuộc gọi đang giữ (tiếp tục); AG hỗ trợ gọi ba bên |
| Từ chối cuộc gọi chờ | `AT+CHLD=0` | Có cuộc gọi chờ |
| Kết thúc cuộc gọi đang nói và nghe cuộc gọi chờ | `AT+CHLD=1` | Có cuộc gọi chờ |
| Giữ cuộc gọi đang nói và nghe cuộc gọi chờ | `AT+CHLD=2` | Có cuộc gọi chờ |
| DTMF | `AT+VTS=<c>`, `<c>` ∈ `0`–`9`, `*`, `#` | Đang nói |
| Tắt tiếng / bật tiếng | Không có lệnh AT: M-HFP ngừng hoặc tiếp tục đưa micro Mac vào SCO | `audio_on = mac` |

- **Response:** `OK`, `ERROR` hoặc `+CME ERROR: <n>`. Sau lệnh giữ máy, chỉ báo `+CIEV` của
  `callheld` cho biết có cuộc gọi đang giữ; `+CCWA` mang số của cuộc gọi chờ (khi HF đã bật thông
  báo cuộc gọi chờ lúc thiết lập kết nối).
- **Ví dụ:** người dùng bấm "1" → `AT+VTS=1` → `OK`, trường 8 = "1". Người dùng bấm "Giữ máy" →
  `AT+CHLD=2` → `OK`, `+CIEV` (`callheld` = 2) → trường 3 = "Đang giữ máy"; bấm "Tiếp tục" →
  `AT+CHLD=2` → `OK`, `+CIEV` (`callheld` = 0) → "Đang gọi".
- **Logic nghiệp vụ:**
  1. Lệnh xếp hàng tuần tự: chỉ gửi lệnh kế tiếp khi lệnh trước đã có `OK` /`ERROR` hoặc quá 2 s
     (HFP chỉ cho một lệnh đang chờ).
  2. Nút dùng `AT+CHLD` chỉ hiện khi tính năng của AG (`+BRSF`) có gọi ba bên và `AT+CHLD=?` liệt kê
     giá trị tương ứng; không có → ẩn (E3).
  3. Tắt tiếng là thao tác cục bộ của M-HFP; tự hủy khi cuộc gọi kết thúc, khi âm thanh rời Mac
     (AUDIO-03) hoặc khi HFP ngắt (E4).
  4. Sau `AT+CHUP` hoặc `AT+CHLD`, A-CALL thấy trạng thái tổng hợp đổi và gửi `state`; nhãn "Đang
     giữ máy" lấy từ chỉ báo HFP vì `state` không có thông tin giữ máy.
  5. Không log phím DTMF; M-HFP chỉ nhận lệnh khi đã chấp thuận AUDIO-01.

#### API 4 — `WS call_event/state` và `WS call_event/hfp_status`

- **URL:** `wss://{android_host}:{port}/v1/ctl` (LAN) hoặc qua relay `wss://{RELAY_HOST}/v1/relay`
- **Method:** `WS call_event/state` (S→C, đặc tả ở CALL-01 API 1); `WS call_event/hfp_status` (S→C,
  đặc tả ở AUDIO-02). Không ack.
- **Request (`data`):** các trường CALL-03 dùng: `direction`, `state`, `waiting`, `waiting_number`,
  `waiting_display_name`, `number`, `display_name`, `started_at`, `answered_at`, `ended_at`,
  `end_reason`, `controls`, `hfp_connected`, `audio_on`.
- **Response:** N/A.
- **Ví dụ:** cuộc gọi đang nói, Mac nối HFP, âm thanh ở Mac:

```json
{"op":"state","data":{"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","direction":"incoming","state":"offhook","waiting":false,"number":"+84900000123","display_name":"Nguyễn Văn A","presentation":"allowed","sub_id":1,"sim_label":"SIM 1","waiting_number":null,"waiting_display_name":null,"started_at":1727150400123,"answered_at":1727150405321,"ended_at":null,"end_reason":null,"controls":{"answer":false,"reject":false,"end":true,"hold":"hfp","dtmf":"hfp","mute":"hfp"},"hfp_connected":true,"audio_on":"mac"}}
```

- **Logic nghiệp vụ:**
  1. Đồng hồ: `elapsed = (ts − answered_at) + (giờ Mac hiện tại − giờ Mac lúc nhận envelope)`;
     `answered_at = null` → dùng `started_at`.
  2. `hfp_connected` đổi (qua `state` hoặc `hfp_status`) → hiện hoặc ẩn trường 6, 7, 9, 11 ngay;
     việc có gửi được lệnh HFP hay không lấy theo trạng thái kết nối của chính M-HFP.
  3. `idle` → trường 3 = "Đã kết thúc · mm:ss" trong 2 s rồi đóng panel; bản `idle` hiệu chỉnh
     (CALL-01 API 1, logic 5) chỉ cập nhật `end_reason`.

#### Query

N/A — CALL-03 không đọc hoặc ghi cơ sở dữ liệu: ngữ cảnh cuộc gọi nằm trong bộ nhớ A-CALL; trạng
thái giữ máy, micro, dãy số DTMF nằm trong bộ nhớ M-HFP; kiểm nền tảng client dùng query bước 5 của
CALL-02.

---

## 6.4 CALL-04 — Đồng bộ nhật ký cuộc gọi và cuộc gọi nhỡ

### 6.4.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | CALL-04 — Đồng bộ nhật ký cuộc gọi và cuộc gọi nhỡ |
| Mô tả | Sao chép nhật ký cuộc gọi của điện thoại (`CallLog.Calls`) sang bảng `call_log_entry` mã hóa trên Mac/iOS và báo cuộc gọi nhỡ.<br>**Đồng bộ** chạy sau mỗi lần kết nối khi cuộc gọi hiệu lực: `call_event/log_sync` với con trỏ mờ; lần đầu lấy tối đa 500 mục trong 90 ngày gần nhất (`CALLLOG_SYNC_WINDOW`), các lần sau lấy mục có `_ID` lớn hơn con trỏ; mỗi `ack` là một trang `{entries, cursor, has_more}`.<br>**Mục mới** khi đang kết nối: `ContentObserver` trên `CallLog.Calls.CONTENT_URI` phát `call_event/log_new`.<br>**Cuộc gọi nhỡ:** Mac/iOS hiện thông báo `UNUserNotificationCenter` có nút "Nhắn tin" (SMS-04) và huy hiệu theo cờ `seen`; iPhone/iPad treo nền nhận push `call_missed` qua CONN-04.<br>Thiếu `READ_CALL_LOG`: không có nhật ký, nhưng cuộc gọi nhỡ vẫn được suy từ `call_event/state` (`ringing` → `idle`, `end_reason = missed`) và được thông báo (luồng A).<br>Mục bị xóa trên điện thoại không bị xóa theo. |
| Tác nhân | Chính: Hệ thống. Phụ: Người dùng (xem nhật ký, xử lý thông báo cuộc gọi nhỡ). Thành phần: M-APP / I-APP, I-NSE, A-SVC, A-CALL, OS (CallLog provider, Contacts provider, `UNUserNotificationCenter`), R-API, PUSH (APNs). |
| Điều kiện trước | 1.<br>Cặp hiệu lực; phiên `/v1/ctl` đã trao đổi capability (CONN-01 hoặc CONN-03).<br>2.<br>Cuộc gọi hiệu lực với cặp.<br>3.<br>Nhật ký: Android có `READ_CALL_LOG` (`features.call.caller_id = true`).<br>4.<br>Client không có lần đồng bộ nhật ký nào khác đang chạy cho cặp.<br>5.<br>Thông báo: người dùng cho phép thông báo trên Mac/iOS (SET-03) và `call.notify = true`. |
| Điều kiện sau | `call_log_entry` chứa các mục tới trang đã ghi cuối; `sync_cursor` (`stream = 'calllog'`) giữ con trỏ của trang đó; mỗi cuộc gọi nhỡ mới có đúng một thông báo trên mỗi client và `seen = 0` cho tới khi người dùng xem trên thiết bị đó. |
| Ngoại lệ | E1 — Cuộc gọi không hiệu lực: không đồng bộ; nếu Android vẫn nhận `log_sync` → `FEATURE_DISABLED`.<br>E2 — Thiếu `READ_CALL_LOG`: `log_sync` trả `PERMISSION_MISSING` (`details.permission = "android.permission.READ_CALL_LOG"`), không có `log_new`; client hiện hướng dẫn và dùng luồng A.<br>E3 — Thiếu `READ_CONTACTS`: `display_name` lấy `CACHED_NAME` của nhật ký, không có thì `null`.<br>E4 — Mất kết nối hoặc `TIMEOUT` giữa chừng: dừng; các trang đã ghi giữ nguyên cùng con trỏ của chúng; lần kết nối sau chạy tiếp.<br>E5 — Con trỏ không đọc được, khác phiên bản, hoặc lớn hơn `_ID` lớn nhất hiện có (nhật ký bị xóa phần mới nhất hoặc bị làm lại): Android xử lý như lần đầu và trả `reset = true`; client xóa nhật ký cũ của cặp trong cùng giao dịch của trang đầu.<br>E6 — Lỗi đọc provider (`INTERNAL`): thử lại 1 lần sau 5 s, sau đó chờ lần kết nối sau.<br>E7 — Lỗi ghi cơ sở dữ liệu trên client: hủy giao dịch của trang, dừng, báo lỗi không chặn.<br>E8 — `call.notify = false` hoặc không có quyền thông báo: vẫn đồng bộ và cập nhật huy hiệu, không thông báo.<br>E9 — iPhone đang khóa khi push cuộc gọi nhỡ tới: nội dung chung "Cuộc gọi nhỡ trên điện thoại", không có nút "Nhắn tin" (C3).<br>E10 — Số ẩn hoặc không rõ số, hoặc SMS không gửi được: thông báo không có nút "Nhắn tin".<br>E11 — Luồng A: cuộc gọi bị từ chối ngay trên điện thoại cũng hiện như cuộc gọi nhỡ (không có nhật ký để phân biệt — C12). |
| Yêu cầu đặc biệt | **Hiệu năng:** lần đầu (≤ 500 mục) ≤ 2 s trong LAN, ≤ 5 s qua relay; `log_new` tới client ≤ 1 s sau khi cuộc gọi kết thúc; thông báo cuộc gọi nhỡ trên Mac ≤ 1,5 s sau khi cuộc gọi kết thúc.<br>**Không dồn thông báo:** mục đến qua `log_sync` không tạo thông báo, chỉ cập nhật danh sách và huy hiệu; mỗi cuộc gọi nhỡ thông báo tối đa một lần trên mỗi client.<br>**Bảo mật:** dữ liệu chỉ nằm trong `handlive.sqlite` mã hóa SQLCipher (0.6.5); không log số, tên.<br>**Tuân thủ:** `READ_CALL_LOG` thuộc ngoại lệ "Cross-device synchronization or transfer of SMS or calls" của Google Play (đã kiểm chứng), cần Permissions Declaration Form (`docs/deployment-guide.md`).<br>**Giới hạn v1:** mục bị xóa trên điện thoại không được xóa theo (trừ khi E5 làm lại toàn bộ); client giữ mục trong 90 ngày. |

### 6.4.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 6.4.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Danh sách cuộc gọi | array\<object> | Output | Rỗng | Mac: mục "Cuộc gọi" ở thanh bên cửa sổ Tin nhắn; iOS: tab "Cuộc gọi". Mỗi dòng gồm trường 2–6, sắp theo `ts` giảm dần, tải thêm khi cuộn<br>Trạng thái trống (như SMS-03 E1): "Chưa có cuộc gọi" · "Cuộc gọi từ điện thoại sẽ hiện ở đây sau lần đồng bộ đầu tiên." |
| 2 | Tên hoặc số | string | Output | `display_name` / `number` | `number = null` → "Số ẩn" |
| 3 | Loại cuộc gọi | enum{incoming\| outgoing\| missed\| rejected\| blocked\| voicemail} | Output | `type` | Biểu tượng theo loại; `missed` màu cảnh báo, in đậm khi `seen = 0`; nhãn VoiceOver của biểu tượng: `incoming` "Cuộc gọi đến", `outgoing` "Cuộc gọi đi", `missed` "Cuộc gọi nhỡ", `rejected` "Cuộc gọi bị từ chối", `blocked` "Cuộc gọi bị chặn", `voicemail` "Thư thoại" |
| 4 | Thời điểm | timestamp | Output | `ts` | Giờ ("14:05") nếu trong ngày, ngày tháng nếu cũ hơn |
| 5 | Thời lượng | int32 (giây) | Output | `duration_s` | "2 phút 5 giây"; ẩn khi bằng 0 |
| 6 | Nhãn SIM | string | Output | Ẩn | `label` của SIM có `sub_id` tương ứng trong `features.sms.sims`; chỉ khi > 1 SIM |
| 7 | Huy hiệu cuộc gọi nhỡ | int32 | Output | 0 | Số mục `type = missed`, `seen = 0` của cặp; trên tab "Cuộc gọi" (iOS) và mục "Cuộc gọi" (Mac); VoiceOver đọc là "3 cuộc gọi nhỡ" (chuỗi số nhiều) |
| 8 | Thông báo cuộc gọi nhỡ | string | Output | — | Tiêu đề: tên, số, "Số ẩn" khi người gọi ẩn số (`entry.number = null`), hoặc "Không rõ số" ở luồng A, khi thiếu `READ_CALL_LOG` (`presentation = unknown`), như trên panel (CALL-01 trường 3); nội dung: "Cuộc gọi nhỡ · 14:05" (kèm nhãn SIM khi có) |
| 9 | Hành động "Nhắn tin" | string(1600) | Input | Rỗng | Ô nhập trong thông báo, nút "Gửi" → SMS-04; chỉ khi có số và SMS gửi được |
| 10 | Chạm vào thông báo | action | Input | — | Mở danh sách cuộc gọi (Mac: cửa sổ Tin nhắn › Cuộc gọi; iOS: tab Cuộc gọi) và đánh dấu đã xem |
| 11 | Lần đồng bộ cuối | timestamp | Output | `sync_cursor.updated_at` | Cài đặt → Cuộc gọi; hiển thị tương đối ("5 phút trước") |
| 12 | Hướng dẫn cấp quyền | string | Output | Ẩn | "Cho phép HandLive đọc nhật ký cuộc gọi trên điện thoại để xem lịch sử cuộc gọi" (E2) |

### 6.4.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U11["(11) Xem nhật ký hoặc thông báo, chọn Nhắn tin"]
  end
  subgraph HT["Hệ thống"]
    S1["(1) Phiên sẵn sàng, cuộc gọi hiệu lực"]
    D2{"(2) Android có READ_CALL_LOG?"}
    S3["(3) Đọc sync_cursor, gửi call_event/log_sync"]
    S4["(4) Android đọc CallLog theo con trỏ, trả entries, cursor, has_more"]
    S5["(5) Ghi trang và con trỏ trong một giao dịch"]
    D6{"(6) has_more?"}
    S7["(7) Cuộc gọi kết thúc, ContentObserver thấy mục mới"]
    S8["(8) Gửi call_event/log_new, iOS không có phiên thì push call_missed"]
    D9{"(9) Mục nhỡ và call.notify bật?"}
    S10["(10) Hiện thông báo cuộc gọi nhỡ kèm Nhắn tin"]
    S12["(12) Đánh dấu seen, gỡ thông báo"]
    SA1["(A1) Không có nhật ký: thông báo nhỡ suy từ state idle missed"]
    X1(["Chờ sự kiện tiếp theo"])
  end
  S1 --> D2
  D2 -- "Có" --> S3 --> S4 --> S5 --> D6
  D6 -- "Có" --> S3
  D6 -- "Không" --> X1
  D2 -- "Không (E2)" --> SA1 --> S10
  S7 --> S8 --> D9
  D9 -- "Có" --> S10 --> U11 --> S12
  D9 -- "Không (E8)" --> X1
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Hệ thống | M-APP / I-APP | Phiên `Connected` và đã nhận `capability/hello` của Android (CONN-01 bước 10, CONN-02 bước 10); cũng chạy khi `capability/update` làm cuộc gọi hoặc nhật ký chuyển sang hiệu lực. | Đang có lần đồng bộ khác của cặp → không chạy thêm. |
| 2 | Hệ thống | M-APP / I-APP | Kiểm `features.call.caller_id = true` và `permissions_missing` không có `READ_CALL_LOG`. | Không → E2, luồng A. |
| 3 | Hệ thống | M-APP / I-APP | Đọc `sync_cursor` (`stream = 'calllog'`); gửi `log_sync` (API 1) với `cursor` (nếu có) và `limit = 200`; chờ `ack` tối đa `REQUEST_TIMEOUT`. | Hết hạn hoặc mất kết nối → E4. |
| 4 | Hệ thống | A-SVC, A-CALL, OS | Kiểm `feature.call`, `READ_CALL_LOG`, `limit`, con trỏ.<br>Không có con trỏ (hoặc E5): lấy 500 mục mới nhất có `DATE` trong 90 ngày, trả theo `_ID` tăng dần; có con trỏ: các mục `_ID > id`.<br>Tên theo `PhoneLookup`, dự phòng `CACHED_NAME`.<br>Trả `ack` `{entries, cursor, has_more, reset}` (Query). | E1, E2, E3, E5, E6. |
| 5 | Hệ thống | M-APP / I-APP | Một giao dịch cho mỗi trang: `reset = true` → xóa `call_log_entry` của cặp; upsert mục, giữ `seen` đã có (mục mới: `seen = 1` khi là lần đầu, `reset`, hoặc loại khác `missed`; ngược lại `seen = 0`); lưu `cursor`. Không tạo thông báo. Cập nhật trường 1, 7, 11. | Lỗi ghi → E7. |
| 6 | Hệ thống | M-APP / I-APP | `has_more = true` → quay lại bước 3 với con trỏ vừa lưu. |  |
| 7 | Hệ thống | OS, A-CALL | Hệ thống ghi mục nhật ký khi cuộc gọi kết thúc. `ContentObserver` (API 3) báo; A-CALL gộp 100 ms, đọc các mục `_ID > last_calllog_id`, ghép với ngữ cảnh vừa kết thúc để gắn `call_id` và gửi `state` hiệu chỉnh khi cần (CALL-01 API 1, logic 5). |  |
| 8 | Hệ thống | A-SVC, R-API, PUSH | Gửi `log_new` (API 2) tới mọi phiên có cuộc gọi hiệu lực. Mục `missed`: với mỗi cặp iOS/iPadOS không có phiên và `features.call.notify = true` → push `call_missed` (API 5). | Relay lỗi → `push_outbox` hạn 24 h (CONN-04). |
| 9 | Hệ thống | M-APP / I-APP | Upsert mục như bước 5 (không đổi con trỏ). Thông báo khi `type = missed`, `call.notify = true` và có quyền thông báo. | Không → E8 (X1). |
| 10 | Hệ thống | M-APP / I-APP / I-NSE, OS | Tạo thông báo cuộc gọi nhỡ (API 4): tiêu đề và nội dung theo trường 8, nút "Nhắn tin" khi có số và `features.sms.can_send = true`. iPhone/iPad treo nền: I-NSE dựng thông báo từ push. | E9, E10. |
| 11 | Người dùng | M-APP / I-APP | Xem thông báo hoặc danh sách cuộc gọi (Mac: cửa sổ Tin nhắn › Cuộc gọi; iOS: tab "Cuộc gọi"); chọn "Nhắn tin" để gửi SMS (SMS-04, như trả lời nhanh ở SMS-04 API 5). |  |
| 12 | Hệ thống | M-APP / I-APP | Mở danh sách cuộc gọi → mọi mục `missed` của cặp có `seen = 1`, gỡ các thông báo cuộc gọi nhỡ đã hiển thị; chạm một thông báo → `seen = 1` cho mục đó. |  |
| A1 | Hệ thống | A-SVC, M-APP / I-APP | Luồng A (không có `READ_CALL_LOG`): client nhận `state` `idle` với `end_reason = missed` → thông báo cuộc gọi nhỡ như bước 10 (không lưu vào `call_log_entry` vì không có `entry_id`; `number` thường `null` nên không có "Nhắn tin"). iPhone/iPad không có phiên → Android push `call_missed` với envelope `call_event/state` (API 5). | E11. |

### 6.4.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | `WS call_event/log_sync` | `/v1/ctl` (LAN hoặc relay) | C→S, ack kèm dữ liệu | 3, 4, 5, 6 |
| 2 | `WS call_event/log_new` | `/v1/ctl` (LAN hoặc relay) | S→C | 8, 9 |
| 3 | `ContentResolver.registerContentObserver` trên `CallLog.Calls.CONTENT_URI` | Cục bộ Android | OS → A-CALL | 7 |
| 4 | Thông báo cuộc gọi nhỡ, danh mục `HL_CALL_MISSED` (`UNUserNotificationCenter`, I-NSE) | Cục bộ Mac/iOS | — | 9, 10, 11, 12, A1 |
| 5 | `POST /v1/push` với `reason = call_missed` (đặc tả đầy đủ ở CONN-04) | REST relay → APNs | A-SVC → R-API → PUSH | 8, A1 |

**Đối tượng dữ liệu dùng chung** — `entry`, dùng trong `log_sync` và `log_new`:

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `entry_id` | int64 | Có | `CallLog.Calls._ID` (0.2) |
| `number` | e164 \| null | Có | Cột `NUMBER`, chuẩn hóa như CALL-01; rỗng hoặc `NUMBER_PRESENTATION` khác `PRESENTATION_ALLOWED` → `null` |
| `display_name` | string \| null | Có | Tên từ `PhoneLookup` (có `READ_CONTACTS`); thiếu `READ_CONTACTS`, hoặc `PhoneLookup` không tìm thấy → cột `CACHED_NAME`; rỗng → `null` |
| `type` | enum{incoming\| outgoing\| missed\| rejected\| blocked\| voicemail} | Có | Cột `TYPE`: 1 → `incoming`, 2 → `outgoing`, 3 → `missed`, 4 → `voicemail`, 5 → `rejected`, 6 → `blocked`, 7 (`ANSWERED_EXTERNALLY_TYPE`) → `incoming`; giá trị khác → bỏ mục |
| `ts` | timestamp | Có | Cột `DATE` (lúc cuộc gọi bắt đầu) |
| `duration_s` | int32 | Có | Cột `DURATION` (giây) |
| `sub_id` | int32 \| null | Có | Từ `PHONE_ACCOUNT_COMPONENT_NAME` và `PHONE_ACCOUNT_ID` qua `TelephonyManager.getSubscriptionId(PhoneAccountHandle)` (API 30+); API 29 hoặc không ánh xạ được → `null` |

#### API 1 — `WS call_event/log_sync`

- **URL:** `wss://{android_host}:{port}/v1/ctl` (LAN) hoặc qua relay `wss://{RELAY_HOST}/v1/relay`
  với lớp bọc `to` /`from`
- **Method:** `WS call_event/log_sync` (C→S), envelope mã hóa, có ack kèm dữ liệu.
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `cursor` | string | Không | Con trỏ mờ nhận ở trang trước hoặc lần đồng bộ trước; vắng → đồng bộ lần đầu |
| `limit` | int32 | Có | Số mục tối đa của trang; client gửi 200; Android chấp nhận 1–500 |

- **Response (`ack.data`):**

| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `entries` | array\<entry> | Theo `_ID` tăng dần |
| `cursor` | string | Con trỏ sau trang này; client lưu trong cùng giao dịch với trang |
| `has_more` | bool | Còn mục sau trang này |
| `reset` | bool | `true` khi Android bỏ qua con trỏ gửi lên và trả trang đầu như đồng bộ lần đầu (E5) |

Lỗi (`ack.error.code`): `FEATURE_DISABLED` (cuộc gọi không hiệu lực với phiên gửi yêu cầu, E1),
`PERMISSION_MISSING` (`details.permission = "android.permission.READ_CALL_LOG"`), `BAD_REQUEST` (`limit` ngoài 1–500), `INTERNAL`.

- **Ví dụ:** đồng bộ lần đầu, một trang:

```json
{"op":"log_sync","data":{"limit":200}}
```

```json
{"re":"0192f3f3-5e6f-7a80-9b1c-2d3e4f5a6b7c","ok":true,"data":{"entries":[{"entry_id":5119,"number":"+84900000456","display_name":null,"type":"outgoing","ts":1727140000000,"duration_s":62,"sub_id":1},{"entry_id":5120,"number":"+84900000123","display_name":"Nguyễn Văn A","type":"missed","ts":1727150400123,"duration_s":0,"sub_id":1}],"cursor":"eyJ2IjoxLCJpZCI6NTEyMH0","has_more":false,"reset":false}}
```

Đồng bộ bù:

```json
{"op":"log_sync","data":{"cursor":"eyJ2IjoxLCJpZCI6NTEyMH0","limit":200}}
```

```json
{"re":"0192f3f3-7a8b-7c9d-8e0f-1a2b3c4d5e6f","ok":true,"data":{"entries":[{"entry_id":5123,"number":"+84900000123","display_name":"Nguyễn Văn A","type":"incoming","ts":1727160000000,"duration_s":125,"sub_id":1}],"cursor":"eyJ2IjoxLCJpZCI6NTEyM30","has_more":false,"reset":false}}
```

- **Logic nghiệp vụ:**
  1. Kiểm theo thứ tự: `feature.call` → `READ_CALL_LOG` → `limit` → con trỏ.
  2. **Con trỏ** = b64u của JSON `{"v":1,"id":<_ID lớn nhất đã phủ>}`; client coi là chuỗi mờ. `_ID`
     của nhật ký tăng dần khi thêm mục, nên đồng bộ bù chỉ cần `_ID > id`.
  3. **Lần đầu** (không có con trỏ, hoặc `reset`): `since = now − 90 ngày`; đọc `_ID` theo `_ID`
     giảm dần với `DATE >= since`, tối đa 500 dòng; `start` = `_ID` nhỏ nhất đọc được; trang đầu gồm
     các mục `_ID >= start` theo `_ID` tăng dần; các trang sau dùng con trỏ như đồng bộ bù. Nhật ký
     rỗng → `entries = []`, con trỏ `{"v":1,"id":0}`. Không có mục nào trong 90 ngày nhưng có mục cũ
     hơn → `entries = []`, con trỏ `{"v":1,"id":<_ID lớn nhất hiện có>}`, nên các lần đồng bộ sau chỉ
     trả mục mới.
  4. Mỗi trang đọc `limit + 1` dòng để biết `has_more`; con trỏ trả về = `_ID` của dòng cuối trong
     trang (kể cả dòng bị bỏ vì `TYPE` lạ); trang rỗng giữ nguyên con trỏ.
  5. **E5:** con trỏ sai định dạng, khác `v`, hoặc `id` lớn hơn `_ID` lớn nhất hiện có → xử lý như
     lần đầu, `reset = true`. Không cần mã lỗi riêng, và việc người dùng xóa các mục mới nhất cũng
     được phản ánh sang client.
  6. Kích thước: Android dừng trang khi plaintext đạt 180 KiB (như `SMS_PAGE_MAX_BYTES`) để envelope
     < 256 KiB (0.5.1 quy tắc 4).
  7. Tên tra theo từng số, cache LRU 200 mục trong phạm vi một trang (một `ack`); Android không lưu tên
     xuống đĩa. Mục thư thoại có thể bị provider ẩn với ứng dụng không có quyền thư thoại; khi đó
     không xuất hiện.
  8. Client: mỗi trang một giao dịch (mục và con trỏ), nên dừng giữa chừng không mất tiến độ;
     `log_new` đến trong lúc đồng bộ được upsert ngay; mỗi cặp chỉ chạy một lần đồng bộ tại một thời
     điểm.

#### API 2 — `WS call_event/log_new`

- **URL:** như API 1
- **Method:** `WS call_event/log_new` (S→C), envelope mã hóa, không ack (0.7.1). Cũng là plaintext
  của envelope push `call_missed` khi có `READ_CALL_LOG` (API 5).
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `entry` | entry | Có | Mục mới |
| `call_id` | uuid \| null | Có | Ngữ cảnh cuộc gọi (CALL-01) ghép được với mục; `null` khi không ghép được |

- **Response:** N/A (mục bị lỡ do mất kết nối đến ở `log_sync` kế tiếp vì `_ID` lớn hơn con trỏ đã
  lưu).
- **Ví dụ:**

```json
{"op":"log_new","data":{"entry":{"entry_id":5120,"number":"+84900000123","display_name":"Nguyễn Văn A","type":"missed","ts":1727150400123,"duration_s":0,"sub_id":1},"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90"}}
```

- **Logic nghiệp vụ:**
  1. Gửi tới mọi phiên có cuộc gọi hiệu lực, theo `_ID` tăng dần. Client không cập nhật con trỏ khi
     nhận `log_new` (tránh bỏ sót mục khi có `log_new` bị lỡ).
  2. **Ghép với ngữ cảnh:** chọn ngữ cảnh trong danh sách "vừa kết thúc" (60 s) chưa được ghép, có
     `|DATE − started_at| ≤ 5 s`, chiều khớp (`incoming`/`unknown` với loại 1, 3, 5, 6, 7;
     `outgoing` /`unknown` với loại 2) và cùng số khi cả hai đều có số.
  3. **Nguồn thông báo cuộc gọi nhỡ:** khi Android có `READ_CALL_LOG`, client chỉ thông báo từ
     `log_new` có `type = missed` (nhật ký đã phân biệt nhỡ, từ chối, nghe nơi khác); `state` có
     `end_reason = missed` không tạo thông báo. Không có `READ_CALL_LOG` → luồng A. Hai nguồn không
     bao giờ cùng dùng, nên không trùng.
  4. Upsert giữ `seen` đã có; mục `missed` mới có `seen = 0`.

#### API 3 — `ContentObserver` trên `CallLog.Calls.CONTENT_URI`

- **URL:** `CallLog.Calls.CONTENT_URI` (`content://call_log/calls`)
- **Method:** `ContentResolver.registerContentObserver(CallLog.Calls.CONTENT_URI, true, observer)`;
  callback `ContentObserver.onChange(selfChange, uri)`; gỡ bằng
  `ContentResolver.unregisterContentObserver(observer)`.
- **Request:** N/A. A-CALL đăng ký khi A-SVC khởi động, `feature.call = true` và có `READ_CALL_LOG`;
  gỡ khi tắt tính năng hoặc mất quyền (gửi `capability/update` với `permissions_missing`).
- **Response:** `onChange` không kèm dữ liệu; A-CALL luôn truy vấn lại provider (Query).
- **Ví dụ:** `last_calllog_id = 5119`; cuộc gọi nhỡ kết thúc lúc `1727150425456` → `onChange` → sau
  100 ms truy vấn `_ID > 5119` được mục `5120` (`TYPE = 3`) → ghép với ngữ cảnh
  `0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90` → gửi `log_new`, push `call_missed` cho iPhone không có
  phiên → `last_calllog_id = 5120`.
- **Logic nghiệp vụ:**
  1. `last_calllog_id` nằm trong bộ nhớ A-CALL, khởi tạo bằng `_ID` lớn nhất lúc đăng ký (không phát
     lại mục cũ; lịch sử đi qua `log_sync`). A-SVC khởi động lại thì mọi phiên cũng nối lại và chạy
     `log_sync`, nên không cần lưu bền; mục phát sinh trong lúc A-SVC dừng không có push.
  2. Gộp các `onChange` trong 100 ms; xử lý tuần tự trên luồng A-CALL, không chạy chồng.
  3. Không dựa vào `uri` của callback; luôn đọc `_ID > last_calllog_id`. `_ID` lớn nhất nhỏ hơn
     `last_calllog_id` (mục bị xóa) → hạ `last_calllog_id` xuống giá trị đó.
  4. Sau khi phát `log_new`, kiểm hiệu chỉnh `end_reason` cho ngữ cảnh đã ghép (CALL-01 API 1, logic
     5).
  5. Mọi ngoại lệ được bắt và ghi mã lỗi; observer không làm dừng A-SVC.

#### API 4 — Thông báo cuộc gọi nhỡ trên Mac/iOS

- **URL:** N/A
- **Method:** `UNUserNotificationCenter.add(_:withCompletionHandler:)` với `UNNotificationRequest`
  (M-APP; I-APP khi đang chạy); I-NSE thay nội dung push trong
  `UNNotificationServiceExtension.didReceive(_:withContentHandler:)`. Danh mục `HL_CALL_MISSED` đăng
  ký lúc khởi động bằng `setNotificationCategories(_:)`, gồm `UNTextInputNotificationAction`
  `HL_CALL_SMS` (tiêu đề "Nhắn tin", nút "Gửi", tùy chọn `.authenticationRequired`: máy đang khóa
  không đọc được `PRK`, C3) và `hiddenPreviewsBodyPlaceholder` "Cuộc gọi nhỡ" (nội dung hệ thống hiện
  khi bản xem trước bị tắt).
- **Request (nội dung thông báo):**

| Thuộc tính | Giá trị |
|------------|---------|
| `identifier` | `call-missed:<pair_id>:<entry_id>`; luồng A: `call-missed:<pair_id>:<call_id>` (thông báo do push tạo: định danh do hệ thống đặt) |
| `title` | Tên, số ở định dạng quốc gia, "Số ẩn" khi người gọi ẩn số, hoặc "Không rõ số" ở luồng A (`presentation = unknown`, CALL-01 trường 3) |
| `body` | "Cuộc gọi nhỡ · <giờ>", thêm " · <nhãn SIM>" khi có |
| `threadIdentifier` | `calls:<pair_id>` (push: `calls` do relay đặt) |
| `categoryIdentifier` | `HL_CALL_MISSED` khi có số, SMS hiệu lực và `features.sms.can_send = true` (I-NSE đọc bản sao của I-APP, logic 2); ngược lại không đặt (E10) |
| `userInfo` | `{pair_id, entry_id, call_id, number, sub_id}` — cho "Nhắn tin" và đánh dấu `seen`; luôn có đủ các khóa; `entry_id` là `null` ở luồng A, `call_id` là `null` khi không ghép được cuộc gọi (API 2 logic 2), `number` và `sub_id` có thể là `null`; ít nhất một trong `entry_id` và `call_id` khác `null` |
| `sound` | `UNNotificationSound.default` |

- **Response:** "Nhắn tin" → `UNTextInputNotificationResponse` → gửi SMS như SMS-04 API 5 (Mac xử lý
  ngay; iOS trong tác vụ nền khoảng 20 s, `SMS_QUICK_REPLY_TIMEOUT`); chạm thông báo → mở tab "Cuộc
  gọi", đặt `seen = 1` cho mục. Không có quyền thông báo → bỏ qua (E8).
- **Ví dụ:**

```json
{"identifier":"call-missed:3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d:5120","title":"Nguyễn Văn A","body":"Cuộc gọi nhỡ · 11:00 · SIM 1","threadIdentifier":"calls:3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","categoryIdentifier":"HL_CALL_MISSED","userInfo":{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","entry_id":5120,"call_id":"0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","number":"+84900000123","sub_id":1}}
```

- **Logic nghiệp vụ:**
  1. Nguồn thông báo theo API 2, logic 3; mỗi cuộc gọi nhỡ tối đa một thông báo trên mỗi client; mục
     đến qua `log_sync` không tạo thông báo. I-APP ở foreground vẫn đăng thông báo này, chỉ hiện trong
     Trung tâm thông báo (`willPresent` → `.list`), vì ứng dụng đang mở không hiện banner (design
     system, 02-ios-ipados).
  2. I-NSE: envelope `call_event/log_new` có `entry.type = missed`, hoặc `call_event/state` có
     `end_reason = missed` (luồng A) → dựng nội dung như bảng; máy khóa hoặc giải mã lỗi → nội dung
     chung "Cuộc gọi nhỡ trên điện thoại", không đặt danh mục (E9). I-NSE không ghi cơ sở dữ liệu
     (0.9.3); mục vào `call_log_entry` ở lần `log_sync` sau. I-NSE cũng không mở cơ sở dữ liệu, nên
     đọc một bản sao để đặt `categoryIdentifier`. I-APP giữ `features.sms.can_send` mới nhất của từng
     cặp, tính cả việc SMS hiệu lực ở hai đầu (chỉ `true` khi đó), trong `UserDefaults` của App Group
     (`sms.peer_can_send`, 0.9.5) và ghi lại mỗi khi capability này hoặc SMS ở một trong hai phía đổi
     (như `sms.preview` được giữ cho extension). I-NSE chỉ đặt `HL_CALL_MISSED` khi bản sao là `true` và biết số. Không
     có bản sao thì không có nút "Nhắn tin".
  3. Gỡ thông báo khi mục được xem (bước 12) bằng `removeDeliveredNotifications(withIdentifiers:)`;
     mở danh sách cuộc gọi gỡ mọi thông báo cuộc gọi nhỡ của cặp.
  4. "Nhắn tin" gửi tới `number` qua `sub_id` của cuộc gọi (vắng → SIM SMS mặc định); nội dung rỗng
     sau khi bỏ khoảng trắng → bỏ qua.
  5. Mac: cuộc gọi nhỡ cũng hiện trong các mục gần đây của menu biểu tượng thanh menu
     (`MenuBarMenu`), với người gọi như `title` và nội dung `body` "Cuộc gọi nhỡ · <giờ>" (thêm
     " · <nhãn SIM>" khi có). Menu giữ ba cuộc gọi nhỡ gần nhất và dọn chúng khi danh sách cuộc gọi
     được mở.

#### API 5 — `POST /v1/push` (`call_missed`)

- **URL:** `https://{RELAY_HOST}/v1/push`
- **Method:** `POST`, header `Authorization: Bearer <jwt>` (JWT của Android, 0.6.4).
- **Request:** cấu trúc đầy đủ ở CONN-04 API 2. Giá trị dùng cho cuộc gọi nhỡ:

| Trường | Giá trị |
|--------|---------|
| `pair_id` | Cặp của iPhone/iPad đích |
| `to` | `device_id` của iPhone/iPad |
| `kind` | `alert` |
| `reason` | `call_missed` |
| `env_b64` | Envelope `call_event/log_new` (API 2) khi có `READ_CALL_LOG`; luồng A: `call_event/state` có `end_reason = missed` (CALL-01 API 1); mã hóa bằng `K_push` |
| `collapse_key` | `call:<call_id>` khi biết `call_id` (thay thế thông báo cuộc gọi đến của cùng cuộc gọi); không biết → `calllog:<entry_id>` |
| `ttl_s` | 86 400 |

- **Response:** theo CONN-04: 409 `PUSH_TOKEN_MISSING` → bỏ qua (iOS thấy mục ở `log_sync` sau); 403
  `NOT_PAIRED` → cặp đã thu hồi; 429, 502 → ghi `push_outbox`, hạn 24 h.
- **Ví dụ (minh họa):**

```http
POST /v1/push HTTP/1.1
Host: relay.example.com
Authorization: Bearer <jwt>
Content-Type: application/json

{"pair_id":"7a6b5c4d-3e2f-4a1b-9c8d-7e6f5a4b3c2d","to":"2c3d4e5f-6a7b-8c9d-8e0f-1a2b3c4d5e6f","kind":"alert","reason":"call_missed","env_b64":"<b64: envelope call_event/log_new mã hóa bằng K_push>","collapse_key":"call:0192f3f0-6a1b-7c2d-8e3f-4a5b6c7d8e90","ttl_s":86400}
```

- **Logic nghiệp vụ:**
  1. Chỉ push khi: đối phương là iOS/iPadOS, không có phiên `/v1/ctl`, `relay_registered = 1`,
     capability gần nhất có `features.call.enabled = true` và `features.call.notify = true`, và là
     cuộc gọi nhỡ (`type = missed`, hoặc `end_reason = missed` ở luồng A).
  2. Mỗi cuộc gọi nhỡ một push; khi có `READ_CALL_LOG` thì không push từ `state` (API 2, logic 3).
  3. Relay đặt nội dung mặc định: không đặt tiêu đề, nội dung "Cuộc gọi nhỡ trên điện thoại", `thread-id = calls`,
     `interruption-level = active` (CONN-04 API 4).
  4. Mac không nhận push (0.4.4); Mac thấy cuộc gọi nhỡ qua `log_sync` khi kết nối lại (không thông
     báo, chỉ huy hiệu).

#### Query

```text
// [Thiết kế] Android, bước 4 (E5) và API 3: _ID lớn nhất hiện có (chỉ đọc dòng đầu)
ContentResolver.query(
    CallLog.Calls.CONTENT_URI.buildUpon()
        .appendQueryParameter(CallLog.Calls.LIMIT_PARAM_KEY, "1").build(),
    arrayOf(CallLog.Calls._ID), null, null, "_id DESC")

// [Thiết kế] Android, bước 4 (lần đầu): start = _ID nhỏ nhất trong 500 mục mới nhất của 90 ngày
ContentResolver.query(
    CallLog.Calls.CONTENT_URI.buildUpon()
        .appendQueryParameter(CallLog.Calls.LIMIT_PARAM_KEY, "500").build(),
    arrayOf(CallLog.Calls._ID),
    "date >= ?", arrayOf(since.toString()), "_id DESC")

// [Thiết kế] Android, bước 4: một trang — trang đầu của lần đồng bộ đầu dùng "_id >= ?" với start,
// các trang khác dùng "_id > ?" với id của con trỏ; đọc limit + 1 dòng để biết has_more
ContentResolver.query(
    CallLog.Calls.CONTENT_URI.buildUpon()
        .appendQueryParameter(CallLog.Calls.LIMIT_PARAM_KEY, (limit + 1).toString()).build(),
    arrayOf(CallLog.Calls._ID, CallLog.Calls.NUMBER, CallLog.Calls.NUMBER_PRESENTATION,
            CallLog.Calls.CACHED_NAME, CallLog.Calls.TYPE, CallLog.Calls.DATE, CallLog.Calls.DURATION,
            CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME, CallLog.Calls.PHONE_ACCOUNT_ID),
    "_id > ?", arrayOf(afterId.toString()), "_id ASC")

// [Thiết kế] Android, bước 7 (API 3): mục mới — cùng projection, "_id > ?" với last_calllog_id, "_id ASC"

// [Thiết kế] Android, bước 4 và 7: tên liên hệ — query PhoneLookup của CALL-01 (6.1.5)
```

```sql
-- [Thiết kế] Android, bước 8: cặp iOS/iPadOS có thể cần push — dùng lại query bước 5 của CALL-01 (6.1.5)

-- [Thiết kế] Mac/iOS, bước 3: con trỏ hiện tại
SELECT cursor FROM sync_cursor WHERE pair_id = :pair_id AND stream = 'calllog';

-- [Thiết kế] Mac/iOS, bước 5 (reset = true, cùng giao dịch với trang đầu): xóa nhật ký cũ của cặp
DELETE FROM call_log_entry WHERE pair_id = :pair_id;

-- [Thiết kế] Mac/iOS, bước 5 và 9: upsert mục, giữ seen đã có
INSERT INTO call_log_entry (pair_id, entry_id, number, display_name, type, ts, duration_s, sub_id, seen)
VALUES (:pair_id, :entry_id, :number, :display_name, :type, :ts, :duration_s, :sub_id, :seen)
ON CONFLICT (pair_id, entry_id) DO UPDATE SET
  number = excluded.number, display_name = excluded.display_name, type = excluded.type,
  ts = excluded.ts, duration_s = excluded.duration_s, sub_id = excluded.sub_id;

-- [Thiết kế] Mac/iOS, bước 5: lưu con trỏ của trang (cùng giao dịch)
INSERT INTO sync_cursor (pair_id, stream, cursor, updated_at)
VALUES (:pair_id, 'calllog', :cursor, :now)
ON CONFLICT (pair_id, stream) DO UPDATE SET cursor = excluded.cursor, updated_at = excluded.updated_at;

-- [Thiết kế] Mac/iOS, trường 1: một trang danh sách (tải thêm theo ts của dòng cuối)
SELECT entry_id, number, display_name, type, ts, duration_s, sub_id, seen
FROM call_log_entry
WHERE pair_id = :pair_id AND ts < :before_ts
ORDER BY ts DESC
LIMIT 100;

-- [Thiết kế] Mac/iOS, trường 7: huy hiệu cuộc gọi nhỡ chưa xem
SELECT COUNT(*) AS unseen_missed
FROM call_log_entry
WHERE pair_id = :pair_id AND type = 'missed' AND seen = 0;

-- [Thiết kế] Mac/iOS, bước 12: mở tab Cuộc gọi
UPDATE call_log_entry SET seen = 1
WHERE pair_id = :pair_id AND type = 'missed' AND seen = 0;

-- [Thiết kế] Mac/iOS, bước 12: chạm một thông báo
UPDATE call_log_entry SET seen = 1
WHERE pair_id = :pair_id AND entry_id = :entry_id;

-- [Thiết kế] Mac/iOS, hằng ngày: chỉ giữ 90 ngày (7 776 000 000 ms)
DELETE FROM call_log_entry WHERE ts < :now - 7776000000;
```

Ghi `push_outbox` khi push lỗi: xem CONN-04.

---

## 6.5 CALL-05 — Cuộc gọi từ ứng dụng khác trên Mac

### 6.5.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | CALL-05 — Cuộc gọi từ ứng dụng khác trên Mac |
| Mô tả | Khi một ứng dụng gọi điện trên điện thoại đổ chuông (Telegram trước tiên; mọi ứng dụng đăng thông báo cuộc gọi `CallStyle`), A-CALL đọc thông báo cuộc gọi của ứng dụng đó qua một `NotificationListenerService` (`AppCallListener`) — vẫn không dùng `InCallService` (C12, C22) —, tạo ngữ cảnh cuộc gọi ứng dụng (`call_id`) và gửi `call_event/app_call` tới mọi phiên Mac có cuộc gọi ứng dụng hiệu lực.<br>Mac hiện panel cuộc gọi với tên ứng dụng ("Cuộc gọi Telegram") và người gọi; "Trả lời", "Từ chối" và "Kết thúc" gửi `call_event/action`, Android thực hiện bằng cách gửi chính PendingIntent của ứng dụng: intent từ chối và intent trả lời của thông báo đổ chuông, intent gác máy (hoặc thao tác duy nhất) của thông báo đang gọi.<br>Trả lời là mở một activity của ứng dụng, Android chỉ cho làm từ nền khi HandLive có miễn trừ giới hạn mở activity từ nền (dịch vụ Hỗ trợ tiếp cận của HandLive đang được bind). HandLive chỉ cho mượn miễn trừ đó với cuộc gọi mà Android bảo đảm (logic 6): khi đó `answer_mode = direct`. Ngược lại (`answer_mode = tap`), "Trả lời" đăng một thông báo "chạm để nghe" trên điện thoại và Mac báo điều đó.<br>Ở v1 âm thanh luôn ở trên điện thoại (`audio = phone`; Mac từ chối HFP SCO, spike T3.2) và panel báo điều đó. iPhone/iPad không có chức năng này: chúng báo `features.call.app_calls = false`. |
| Tác nhân | Chính: Người dùng (ngồi ở Mac), Người gọi (gọi qua ứng dụng). Hệ thống: A-CALL (`AppCallListener`), A-SVC, A-CLIP (dịch vụ Hỗ trợ tiếp cận đang được bind cho miễn trừ), OS (`NotificationManager`, `PackageManager`, `ActivityOptions`), ứng dụng gọi điện, M-APP. |
| Điều kiện trước | 1.<br>Cặp hiệu lực; Mac có phiên `/v1/ctl` (CONN-01 hoặc CONN-03).<br>2.<br>Cuộc gọi ứng dụng hiệu lực với phiên: `feature.call` và `call.app_calls` bật ở cả hai phía, Android đã được cấp quyền truy cập thông báo (SET-01 N1–N2), nên cả hai bên báo `features.call.app_calls = true`.<br>3.<br>Ứng dụng gọi điện đăng thông báo `CallStyle` cho cuộc gọi đến (`android.callType = 1`). |
| Điều kiện sau | Mac hiện cuộc gọi ứng dụng và panel luôn khớp `app_call` mới nhất: `ringing` → panel cuộc gọi đến, `ongoing` → panel đang gọi, `ended` → panel đóng.<br>Ngữ cảnh nằm trong bộ nhớ A-CALL tới khi đã gửi `ended`, sau đó bị quên; không ghi gì xuống đĩa ở cả hai phía; thông báo chạm để nghe bị gỡ khi cuộc gọi rời `ringing` hoặc sau `APP_CALL_TAP_NOTIFICATION_TTL`.<br>Cuộc gọi di động (CALL-01…04) không đổi. |
| Ngoại lệ | E1 — Chưa cấp quyền truy cập thông báo (`permissions_missing` có `NOTIFICATION_LISTENER`): cuộc gọi ứng dụng tắt trên điện thoại và màn giải thích nói lý do (SET-01 E11); không gửi gì; CALL-01…04 vẫn chạy như cũ.<br>E2 — Thông báo của ứng dụng không còn thao tác đó, đã mất, hoặc PendingIntent đã bị hủy: `CALL_APP_ACTION_UNAVAILABLE`; Mac áp dụng `app_call` mới nhất.<br>E3 — Cuộc gọi đã mất (đã gửi `ended` và ngữ cảnh đã bị quên): thao tác nhận `CALL_NOT_FOUND`; Mac đóng panel.<br>E4 — Cuộc gọi ứng dụng không hiệu lực với phiên (`call.app_calls` hoặc `feature.call` tắt ở một phía, hoặc capability mới nhất của Mac báo `false`): không gửi gì; thao tác với `call_id` của cuộc gọi ứng dụng nhận `FEATURE_DISABLED`; Mac đóng các panel cuộc gọi ứng dụng.<br>E5 — Qua relay: cố gắng hết mức. `app_call` đi qua phiên relay đã có sẵn; A-SVC không mở relay cho cuộc gọi ứng dụng và không gửi push, nên Mac đang chờ trên relay có thể lỡ một cuộc gọi ngắn.<br>E6 — Thông báo chỉ có `category = call` và không dùng `CallStyle` (`android.callType` không đặt): không hỗ trợ, không tạo ngữ cảnh, không gửi gì; thông báo như vậy chỉ có thể thành thông báo đang gọi theo logic 3 nếu có ngữ cảnh `CallStyle`. Bộ chuyển đổi riêng theo ứng dụng có thể làm sau.<br>E7 — Không có miễn trừ mở activity từ nền, hoặc thông báo đang đổ chuông không được Android bảo đảm (`answer_mode = tap`, logic 6): "Trả lời" đăng thông báo chạm để nghe và Mac hiện trường 6; điện thoại không được đăng thông báo (từ chối `POST_NOTIFICATIONS` hoặc kênh `hl_app_call` bị chặn) → `CALL_APP_ACTION_UNAVAILABLE`.<br>E8 — Thông báo đang gọi không có intent gác máy và có nhiều hơn một thao tác: `controls.end = false`; kết thúc cuộc gọi trên điện thoại.<br>E9 — `answer` với `audio = mac`: `CALL_ROUTE_FAILED`; Mac không bao giờ đưa lựa chọn này cho cuộc gọi ứng dụng.<br>E10 — Listener thông báo bị ngắt hoặc quyền truy cập thông báo bị thu hồi giữa cuộc gọi: mọi ngữ cảnh còn sống kết thúc (`end_reason = unknown`, `answered_at = null` kể cả khi cuộc gọi đang diễn ra), `capability/update` báo `app_calls = false`.<br>E11 — Thông báo đang gọi bị gỡ không phải do chính ứng dụng (`reason` của `onNotificationRemoved` khác `REASON_APP_CANCEL` và `REASON_APP_CANCEL_ALL`): từ API 34 người dùng vuốt bỏ được thông báo đang diễn ra không dùng `CallStyle`, như của Telegram, trong khi cuộc gọi vẫn tiếp tục. Dưới API 31, hoặc khi `AudioManager.getMode()` lúc đó không phải `MODE_IN_COMMUNICATION`, cuộc gọi kết thúc ngay (`end_reason = unknown`); ngược lại cuộc gọi vẫn `ongoing`, ở trạng thái tách rời, với `controls.end = false`, và kết thúc `unknown` ngay khi chế độ âm thanh rời `MODE_IN_COMMUNICATION`. Trong lúc tách rời, đúng khóa đó được đăng lại thì lại thành thông báo đang gọi của nó, kèm thao tác kết thúc (logic 5); một khóa mới của cùng gói, chưa có lúc cuộc gọi bị tách, chỉ thành như vậy khi có dạng thông báo đang gọi (`CallStyle` loại 2 hoặc category `call`). Mọi thông báo đang diễn ra khác của gói đó (một lượt tải lên có nút Hủy) không bao giờ giữ cuộc gọi và không bao giờ cho `controls.end`: cuộc gọi vẫn tách rời, và thông báo đó bị gỡ cũng không làm cuộc gọi kết thúc. Chế độ âm thanh là của cả máy: cuộc gọi VoIP của ứng dụng khác giữ cuộc gọi tách rời sống cho tới khi nó cũng kết thúc. Mất listener → E10. |
| Yêu cầu đặc biệt | **Hiệu năng (LAN, phân vị 95):** panel Mac ≤ 400 ms sau khi ứng dụng đăng thông báo cuộc gọi (`postTime`; riêng Android đã mất 215–232 ms để chuyển thông báo, spike T3.2), có tên ứng dụng và người gọi; "Từ chối" hoặc "Kết thúc" có hiệu lực trên điện thoại ≤ 500 ms sau khi bấm; "Trả lời" nghe máy trên điện thoại ≤ 1 s với `answer_mode = direct` (miễn mục tiêu khi `tap`: người dùng chạm trên điện thoại).<br>**Riêng tư:** chỉ phân tích thông báo cuộc gọi: bộ lọc (API 3 logic 1) chạy trước khi đọc bất cứ gì khác; mọi thông báo khác bị bỏ mà không đọc tiêu đề hay nội dung, không lưu, không log, không rời khỏi điện thoại. `caller` chỉ đi trong envelope E2E, không log, không lưu; log gồm `type`, `op`, `call_id`, mã lỗi và thời gian đo. Không push nào mang cuộc gọi ứng dụng.<br>**Nền tảng:** không dùng `InCallService` (C12); listener khai báo với `BIND_NOTIFICATION_LISTENER_SERVICE` và người dùng tự bật quyền truy cập thông báo (SET-01); PendingIntent được gửi kèm tùy chọn cho mở activity từ nền (API 4); spike T3.2: không có miễn trừ, Android chặn activity trả lời (`BAL_BLOCK`).<br>**Tuân thủ:** quyền truy cập thông báo rất rộng: bộ lọc chặt, màn giải thích (SET-01 trường 19), công tắc `call.app_calls` để tắt, khai báo với Google Play về việc dùng listener.<br>**Truy cập:** VoiceOver đọc tiêu đề panel và người gọi khi panel xuất hiện.<br>**Phạm vi:** chỉ Mac. Ngoài phạm vi: iPhone/iPad, gọi đi bằng ứng dụng từ Mac, nhật ký cuộc gọi ứng dụng, cuộc gọi video, âm thanh trên Mac (`audio = mac` để dành). |

### 6.5.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 6.5.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Tiêu đề | string | Output | "Cuộc gọi \<ứng dụng>" | `app.label` trong tiêu đề, ví dụ "Cuộc gọi Telegram"; panel cuộc gọi đến và panel đang gọi |
| 2 | Người gọi | string | Output | `caller` | `null` → "Không rõ số" |
| 3 | Nút "Trả lời" | action | Input | Ẩn | Mac, khi `controls.answer = true`; thay bằng "Nghe trên điện thoại" khi âm thanh cuộc gọi đang hiệu lực trên Mac (AUDIO-01), vì âm thanh cuộc gọi ứng dụng ở lại điện thoại; không bao giờ có "Nghe trên Mac" → API 2 `answer` |
| 4 | Nút "Từ chối" | action | Input | Ẩn | Khi `controls.decline = true` → API 2 `reject` |
| 5 | Nút "Bỏ qua" | action | Input | — | Chỉ panel cuộc gọi đến, như CALL-01 trường 9: đóng panel và tắt chuông trên Mac; cuộc gọi vẫn đổ chuông trên điện thoại |
| 6 | Gợi ý chạm để nghe | string | Output | Ẩn | Sau khi "Trả lời" thành công với `answer_mode = tap`: "Chạm vào thông báo trên điện thoại để nghe." thay trường 3 cho tới khi `state` đổi; trường 4 vẫn còn |
| 7 | Đồng hồ | string (mm:ss) | Output | "00:00" | Panel đang gọi: tính từ `answered_at`, không có thì từ `started_at` (như CALL-03 trường 2) |
| 8 | Nơi phát âm thanh | string | Output | "Âm thanh: Điện thoại" | Panel đang gọi, luôn hiện (`audio = phone`); không có nút chuyển âm thanh |
| 9 | Nút "Kết thúc" | action | Input | Ẩn | Panel đang gọi, khi `controls.end = true` → API 2 `end` |
| 10 | Trạng thái đang xử lý, thông báo lỗi | string | Output | Ẩn | "Đang trả lời…", "Đang từ chối…" như CALL-02 trường 9; lỗi như CALL-02 trường 10 ("Không gửi được lệnh tới điện thoại" khi hết hạn chờ); `CALL_APP_ACTION_UNAVAILABLE` không hiện thông báo (E2) |
| 11 | Chuông trên Mac | âm thanh | Output | Tắt | Như CALL-01 trường 10 (`call.notify`, `call.ringtone`, Tập trung) |
| 12 | Thông báo chạm để nghe | string | Output | Ẩn | Android (API 5): tiêu đề "Nghe cuộc gọi \<ứng dụng>", ví dụ "Nghe cuộc gọi Telegram"; nội dung: `caller` khi biết; kênh `hl_app_call` ("Cuộc gọi từ ứng dụng khác"); chạm vào thì chạy intent trả lời của ứng dụng |
| 13 | Tùy chọn "Cuộc gọi từ ứng dụng khác" | bool | Input/Output | `call.app_calls` = `true` | Cài đặt → Cuộc gọi (SET-02 trường 38), Android và Mac; chú thích "Hiện cuộc gọi từ các ứng dụng như Telegram trên Mac. Âm thanh vẫn ở trên điện thoại." |
| 14 | Màn giải thích quyền truy cập thông báo | string | Output | — | Android (SET-01 trường 19): "Cho phép truy cập thông báo", rồi "HandLive chỉ đọc thông báo cuộc gọi của các ứng dụng gọi điện để hiện trên Mac. Các thông báo khác bị bỏ qua và không bao giờ rời khỏi điện thoại." |

### 6.5.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U9["(9) Thấy ứng dụng và người gọi, chọn Trả lời, Từ chối, Bỏ qua hoặc Kết thúc"]
    U12["(12) Chế độ chạm: chạm thông báo HandLive trên điện thoại"]
  end
  subgraph HT["Hệ thống"]
    S1["(1) Ứng dụng gọi điện đăng thông báo, AppCallListener nhận được"]
    D2{"(2) Là thông báo cuộc gọi CallStyle?"}
    S3["(3) Tạo hoặc cập nhật ngữ cảnh cuộc gọi ứng dụng, tính controls và answer_mode"]
    D4{"(4) Cuộc gọi ứng dụng hiệu lực với phiên?"}
    S5["(5) Gửi call_event/app_call tới phiên"]
    S6["(6) Thông báo đổ chuông bị gỡ: ongoing nếu ứng dụng đăng thông báo đang diễn ra trong APP_CALL_LINK_WINDOW, ngược lại ended"]
    S7["(7) Ứng dụng gỡ thông báo đang gọi: ended, rồi quên ngữ cảnh, gỡ theo cách khác: E11"]
    S8["(8) Mac hiện, cập nhật hoặc đóng panel"]
    S10["(10) Gửi call_event/action"]
    D11{"(11) Android: hiệu lực, thao tác còn có?"}
    S13["(13) Gửi PendingIntent của ứng dụng hoặc đăng thông báo chạm, trả ack"]
    X1(["Bỏ qua: không đọc, không gửi gì"])
    X2(["ack lỗi, làm mới theo app_call mới nhất"])
  end
  S1 --> D2
  D2 -- "Không (E6)" --> X1
  D2 -- "Có" --> S3 --> D4
  D4 -- "Không (E1, E4)" --> X1
  D4 -- "Có" --> S5 --> S8 --> U9
  U9 -- "Trả lời, Từ chối hoặc Kết thúc" --> S10 --> D11
  D11 -- "Không (E2, E3, E4, E9)" --> X2
  D11 -- "Có" --> S13
  S13 -- "Chế độ chạm (E7)" --> U12 --> S6
  S13 -- "Từ chối hoặc Trả lời" --> S6 --> S5
  S13 -- "Kết thúc" --> S7 --> S5
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Hệ thống | OS, A-CALL | Ứng dụng gọi điện đăng hoặc cập nhật một thông báo; hệ thống gọi `AppCallListener.onNotificationPosted` (API 3). | Listener chưa kết nối (chưa có quyền truy cập thông báo) → E1. |
| 2 | Hệ thống | A-CALL | Lọc trước khi đọc bất cứ gì khác (API 3 logic 1): bỏ gói của chính HandLive; là thông báo cuộc gọi khi `extras` có `android.callType` (`CallStyle`) hoặc category là `call`; trong khoảng ghép (bước 6) lấy thêm thông báo đang diễn ra của cùng gói, chỉ đọc cờ và các thao tác. Mọi thứ khác bị bỏ mà không đọc tiêu đề hay nội dung. | `callType = 3` (sàng lọc) → bỏ qua. Không có `CallStyle` → E6. |
| 3 | Hệ thống | A-CALL, OS | `callType = 1` → ngữ cảnh `ringing` mới (`call_id` UUIDv7, `started_at`) theo khóa thông báo, hoặc cập nhật ngữ cảnh đã có; `callType = 2` với khóa chưa có ngữ cảnh → ngữ cảnh `ongoing` mới (`answered_at = null`).<br>Đọc `app.package`, `app.label` (`PackageManager`), `caller` (`android.callPerson`, không có thì `android.title`) và các intent; tính `controls` và `answer_mode` (API 1 logic 5–6). | Dữ liệu cá nhân chỉ nằm trong bộ nhớ. |
| 4 | Hệ thống | A-SVC | Với từng phiên: cuộc gọi ứng dụng hiệu lực (`features.call.app_calls = true` ở cả hai phía). | Không → E1, E4 (X1). |
| 5 | Hệ thống | A-SVC | Gửi `call_event/app_call` (API 1) khi có trường khác bản đã gửi gần nhất cho phiên đó; phiên vừa có cuộc gọi ứng dụng hiệu lực nhận mọi ngữ cảnh còn sống sau khi trao đổi capability. Qua relay chỉ khi đã có sẵn phiên relay. | E5. |
| 6 | Hệ thống | A-CALL | Thông báo đổ chuông bị gỡ: cùng gói đăng thông báo đang diễn ra (`FLAG_ONGOING_EVENT`, `CallStyle` loại 2 hay không) trong `APP_CALL_LINK_WINDOW` → `state = ongoing`, `answered_at` = lúc nó được đăng, và nó thành thông báo đang gọi; ngược lại `state = ended` với `end_reason` theo API 1 logic 4. Thông báo chạm để nghe bị gỡ khi cuộc gọi rời `ringing` (API 5). |  |
| 7 | Hệ thống | A-CALL | Ứng dụng gỡ thông báo đang gọi (`REASON_APP_CANCEL`, `REASON_APP_CANCEL_ALL`) → `state = ended`, `end_reason = ended`, `ended_at`; sau khi đã gửi `ended`, ngữ cảnh bị quên. | Listener bị ngắt → E10. Người dùng hoặc hệ thống gỡ → E11. |
| 8 | Hệ thống | M-APP | `ringing` → panel cuộc gọi đến (trường 1–5, 11, API 6); `ongoing` → panel đang gọi (trường 1, 2, 7–9); `ended` → đóng panel, dừng chuông. | Cuộc gọi điện thoại đang giữ panel → cuộc gọi ứng dụng chờ (API 6 logic 2). `call.notify = false` hoặc chế độ Tập trung → không có panel (CALL-01 E3, E4). |
| 9 | Người dùng | M-APP | Thấy "Cuộc gọi Telegram" và người gọi; chọn "Trả lời", "Từ chối", "Bỏ qua" (chỉ cục bộ, trường 5) hoặc, ở panel đang gọi, "Kết thúc". | Nút chỉ có khi `controls` cho phép. |
| 10 | Hệ thống | M-APP | Gửi `call_event/action` (API 2) `{call_id, action}`: `answer` (không có `audio`), `reject` hoặc `end`; khóa nút tới khi có `ack` hoặc `app_call` mới; chờ tối đa `REQUEST_TIMEOUT`. | Hết hạn → như CALL-02 E5. |
| 11 | Hệ thống | A-SVC, A-CALL | Định tuyến theo `call_id` (CALL-02 API 1 logic 7), rồi kiểm theo API 2: cuộc gọi ứng dụng hiệu lực, `action`, `audio`, thao tác còn có trong thông báo hiện tại của ngữ cảnh. | `ack` lỗi → E2, E3, E4, E9 (X2). |
| 12 | Người dùng | OS | `answer_mode = tap`: chạm "Nghe cuộc gọi \<ứng dụng>" trên điện thoại; intent trả lời của ứng dụng mở màn hình cuộc gọi của ứng dụng. | Không chạm → cuộc gọi vẫn đổ chuông; thông báo tự gỡ sau `APP_CALL_TAP_NOTIFICATION_TTL`. |
| 13 | Hệ thống | A-CALL, OS | `reject` → đánh dấu ngữ cảnh "HandLive từ chối", gửi `android.declineIntent`; `end` → gửi thao tác kết thúc; `answer` → đánh dấu ngữ cảnh "HandLive trả lời", rồi `direct`: gửi `android.answerIntent`, `tap`: đăng thông báo chạm để nghe (API 5). PendingIntent được gửi kèm tùy chọn cho mở activity từ nền (API 4). Trả `ack` `{}`; kết quả thấy được khi ứng dụng đổi thông báo của nó (bước 6, 7). | `CanceledException` → E2. Không được đăng thông báo → E7. |

### 6.5.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | `WS call_event/app_call` | `/v1/ctl` (LAN hoặc relay) | S→C | 5, 8 |
| 2 | `WS call_event/action` với `call_id` của cuộc gọi ứng dụng (đặc tả chính ở CALL-02 API 1) | `/v1/ctl` (LAN hoặc relay) | C→S, có ack | 10, 11, 13 |
| 3 | `NotificationListenerService` `AppCallListener`: `onNotificationPosted`, `onNotificationRemoved`, `onListenerConnected`, `onListenerDisconnected` | Cục bộ Android | OS → A-CALL | 1, 2, 3, 6, 7 |
| 4 | `PendingIntent.send` với `ActivityOptions.setPendingIntentBackgroundActivityStartMode` | Cục bộ Android | A-CALL → ứng dụng gọi điện | 13 |
| 5 | Thông báo chạm để nghe: `NotificationManagerCompat.notify` trên kênh `hl_app_call` | Cục bộ Android | A-CALL → OS | 6, 12, 13 |
| 6 | Panel cuộc gọi cho cuộc gọi ứng dụng (`NSPanel` của CALL-01 API 5) | Cục bộ Mac | — | 8, 9 |

#### API 1 — `WS call_event/app_call`

- **URL:** `wss://{android_host}:{port}/v1/ctl` (LAN) hoặc qua relay `wss://{RELAY_HOST}/v1/relay`
  với lớp bọc `to` /`from`
- **Method:** `WS call_event/app_call` (S→C), envelope mã hóa, không ack (0.7.1); không bao giờ đi
  trong push.
- **Request (`data`):** mọi trường luôn có mặt (`null` ở chỗ cho phép).

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `call_id` | uuid | Có | UUIDv7, một cho mỗi cuộc gọi ứng dụng; giữ nguyên từ `ringing` tới `ongoing` tới `ended` |
| `app` | object | Có | Ứng dụng gọi điện (bảng dưới) |
| `caller` | string(128) \| null | Có | Tên trong `android.callPerson`, không có thì tiêu đề thông báo; `null` khi không có. Dữ liệu cá nhân: chỉ đi trong E2E, không log, không lưu |
| `state` | enum{ringing\| ongoing\| ended} | Có | Logic 2–4 |
| `controls` | object | Có | Thao tác Mac được gửi (bảng dưới) |
| `answer_mode` | enum{direct\| tap} | Có | `direct` khi HandLive có miễn trừ giới hạn mở activity từ nền (dịch vụ Hỗ trợ tiếp cận của nó đang được bind) và Android bảo đảm cho thông báo đang đổ chuông; ngược lại `tap` (logic 6) |
| `audio` | enum{phone} | Có | Hằng ở v1; `mac` để dành cho sau |
| `started_at` | timestamp | Có | Lúc tạo ngữ cảnh (đồng hồ Android) |
| `answered_at` | timestamp \| null | Có | Lúc ngữ cảnh `ringing` chuyển sang `ongoing`; `null` khi đang đổ chuông, với ngữ cảnh tạo ra ở `ongoing`, và với cuộc gọi kết thúc là `declined`, `missed` hoặc `unknown` |
| `ended_at` | timestamp \| null | Có | Chỉ khi `state = ended` |
| `end_reason` | enum{declined\| ended\| missed\| unknown} \| null | Có | Chỉ khi `state = ended`; logic 4 |

Đối tượng `app`:

| Trường | Kiểu | Giá trị |
|--------|------|---------|
| `package` | string(255) | Tên gói Android của ứng dụng gọi điện |
| `label` | string(64) | Nhãn của ứng dụng lấy từ `PackageManager` (chỉ để hiển thị). Từ API 30, package visibility ẩn các ứng dụng khác, và notification listener không được miễn: `<queries>` trong manifest khai báo intent `MAIN`/`LAUNCHER` để mọi ứng dụng có activity launcher đều thấy được (không bao giờ dùng `QUERY_ALL_PACKAGES`); ứng dụng vẫn bị ẩn hoặc đã gỡ thì dùng tên gói thay thế |

Đối tượng `controls`:

| Trường | Kiểu | Giá trị |
|--------|------|---------|
| `answer` | bool | `true` khi `state = ringing` và thông báo có intent trả lời |
| `decline` | bool | `true` khi `state = ringing` và thông báo có intent từ chối |
| `end` | bool | `true` khi `state = ongoing` và có thao tác kết thúc (logic 5) |

- **Response:** N/A (không ack; Mac lỡ tin vì mất kết nối sẽ nhận các ngữ cảnh còn sống khi phiên mới
  trao đổi capability — logic 7).
- **Ví dụ:** một cuộc gọi Telegram đổ chuông, được nghe, rồi kết thúc.

```json
{"op":"app_call","data":{"call_id":"0192f3f6-2c3d-7e4f-8a5b-6c7d8e9f0a1b","app":{"package":"org.telegram.messenger","label":"Telegram"},"caller":"Nguyễn Văn A","state":"ringing","controls":{"answer":true,"decline":true,"end":false},"answer_mode":"direct","audio":"phone","started_at":1727150400123,"answered_at":null,"ended_at":null,"end_reason":null}}
{"op":"app_call","data":{"call_id":"0192f3f6-2c3d-7e4f-8a5b-6c7d8e9f0a1b","app":{"package":"org.telegram.messenger","label":"Telegram"},"caller":"Nguyễn Văn A","state":"ongoing","controls":{"answer":false,"decline":false,"end":true},"answer_mode":"direct","audio":"phone","started_at":1727150400123,"answered_at":1727150405321,"ended_at":null,"end_reason":null}}
{"op":"app_call","data":{"call_id":"0192f3f6-2c3d-7e4f-8a5b-6c7d8e9f0a1b","app":{"package":"org.telegram.messenger","label":"Telegram"},"caller":"Nguyễn Văn A","state":"ended","controls":{"answer":false,"decline":false,"end":false},"answer_mode":"direct","audio":"phone","started_at":1727150400123,"answered_at":1727150405321,"ended_at":1727150530456,"end_reason":"ended"}}
```

- **Logic nghiệp vụ:**
  1. **Bộ lọc (riêng tư):** `onNotificationPosted` bỏ gói của chính HandLive và thông báo từ điện thoại
     mặc định (`TelecomManager.getDefaultDialerPackage()`), điện thoại hệ thống, gói nào triển khai
     `android.telecom.InCallService`, `com.android.server.telecom` và `com.android.phone` (các cuộc gọi
     di động thuộc CALL-01…04; ngược lại tên người gọi sẽ vượt qua `READ_CALL_LOG` và lặp sự kiện).
     Rồi chỉ lấy thông báo có `extras` chứa `android.callType` hoặc có `category` là `call` (C22, E6).
     Từ API 31, `android.callType` chỉ được tính khi có template của nền tảng
     `android.template = android.app.Notification$CallStyle`, thứ Android chỉ đăng cho ứng dụng có foreground
     service hoặc user-initiated job, hoặc có xin full-screen intent (từ API 34, yêu cầu bị từ chối cũng được
     tính): ứng dụng nào cũng tự gắn được extra trần vào một thông báo thường, và khi đó intent trả lời của nó sẽ
     được gửi bằng quyền miễn trừ mở activity từ nền của HandLive. Dưới API 31 không có `CallStyle` của nền tảng
     để kiểm. Ứng dụng đăng thông báo `CallStyle` thật chỉ được gửi intent trả lời kèm quyền miễn trừ đó khi
     Android bảo đảm cho nó (logic 6) và người dùng trả lời trên Mac, nơi hiện tên ứng dụng;
     trong khoảng ghép (logic 3) lấy thêm thông báo đang diễn ra của cùng gói (không phải gói đang chờ
     — chỉ ứng dụng gọi điện), chỉ đọc `flags` và `actions`. Không đọc gì khác: không tiêu đề, nội
     dung hay extras của bất kỳ thông báo nào khác; chúng không được lưu, không log và không rời khỏi
     điện thoại.
  2. **Ngữ cảnh:** theo khóa thông báo (`StatusBarNotification.key`). `CallStyle` `callType = 1`
     tạo ngữ cảnh `ringing`; `callType = 2` với khóa chưa có ngữ cảnh tạo ngữ cảnh `ongoing` với
     `answered_at = null` (cuộc gọi đi bấm trong ứng dụng, hoặc listener kết nối giữa cuộc gọi);
     `callType = 3` (sàng lọc) bị bỏ qua. Thông báo `category = call` không có `CallStyle` không bao
     giờ tạo ngữ cảnh (E6); nó chỉ có thể thành thông báo đang gọi theo logic 3. Cập nhật của cùng
     khóa đọc lại `caller` và các intent.
  3. **Đổ chuông → đang gọi:** khi thông báo của ngữ cảnh `ringing` bị gỡ, thông báo đang gọi của nó là
     thông báo đang diễn ra (`FLAG_ONGOING_EVENT`, `CallStyle` loại 2 hay không) đầu tiên của cùng gói
     có khóa xuất hiện lần đầu sau khi ngữ cảnh được tạo và có `postTime` không muộn hơn thời điểm gỡ +
     `APP_CALL_LINK_WINDOW` (3 giây). Thời điểm gỡ là lúc listener nhận sự kiện gỡ. Thông báo như vậy
     đăng trước khi gỡ thì được ghép ngay lúc gỡ; nếu chưa có, A-CALL chờ hết khoảng ghép và quyết định
     theo `postTime`, nên một thông báo còn trong hàng đợi khi khoảng ghép đóng (`APP_CALL_LINK_GRACE`, muộn hơn 500 ms) vẫn được tính. Thông báo
     đang diễn ra có khóa đã tồn tại trước khi ngữ cảnh được tạo (trình phát nhạc, tải tệp, dịch vụ
     nền trước) và các bản cập nhật của nó không bao giờ được ghép. Khi ghép: `state = ongoing`,
     `answered_at` = `postTime` của nó, giữ `caller`. Telegram (spike T3.2): thông báo đang gọi không
     phải `CallStyle` — kênh `Other3`, đang diễn ra, một thao tác.
  4. **Kết thúc:** ứng dụng gỡ thông báo đang gọi → `end_reason = ended`; bị gỡ vì lý do khác
     (người dùng vuốt bỏ, tạm ẩn, kênh bị chặn) → tách rời (E11), không bao giờ `ended`. Không có
     thông báo đang diễn ra
     trong khoảng chờ → `end_reason = declined` khi HandLive đã gửi lệnh từ chối cho ngữ cảnh này,
     `unknown` khi HandLive đã gửi lệnh trả lời (trực tiếp hoặc qua thông báo chạm để nghe) nhưng
     không có thông báo đang gọi theo sau, khi cuộc gọi tách rời kết thúc (E11), hoặc khi listener bị
     mất (E10) — `answered_at` vẫn là `null`
     với `unknown`, kể cả cuộc gọi đã thành đang gọi —, ngược lại `missed` (không ai nghe; cuộc gọi bị từ chối
     ngay trên điện thoại cũng kết thúc là `missed`, như CALL-04 E11). `ended_at` = lúc A-CALL quyết
     định; `ended` gửi một lần tới mỗi phiên, rồi ngữ cảnh bị quên.
  5. **controls:** `answer` và `decline` theo `android.answerIntent` và `android.declineIntent` của
     thông báo đổ chuông; `end` theo thông báo đang gọi: `android.hangUpIntent` của nó, không có thì
     thao tác duy nhất khi nó có đúng một thao tác, ngược lại `false` (E8). Tiêu đề thao tác được bản
     địa hóa và không bao giờ được so như văn bản.
  6. **answer_mode:** theo từng cuộc gọi, `direct` khi một dịch vụ Hỗ trợ tiếp cận của HandLive đang được
     bind (CLIP-01 A3), giúp HandLive được miễn giới hạn mở activity từ nền, và Android bảo đảm cho thông
     báo đang đổ chuông; ngược lại `tap`. Từ API 34, Android bảo đảm khi ứng dụng đăng thông báo kèm một
     foreground service hoặc một user-initiated job (`FLAG_FOREGROUND_SERVICE`, `FLAG_USER_INITIATED_JOB`)
     hoặc kèm full-screen intent đã được cấp (Android gỡ cờ giả và full-screen intent bị từ chối); với API
     31–33 là mọi thông báo `CallStyle` (logic 1); dưới API 31 thì không bao giờ, vì không gì phân biệt
     được cuộc gọi thật với cuộc gọi giả. Tính lại khi dịch vụ kết nối hoặc ngắt và khi thông báo đang đổ
     chuông được đăng lại; thay đổi được gửi như mọi trường khác.
  7. **Khi nào gửi:** như CALL-01 API 1 logic 3: mỗi khi có trường khác bản đã gửi gần nhất cho phiên
     đó, và mọi ngữ cảnh còn sống cho phiên vừa có cuộc gọi ứng dụng hiệu lực (sau `capability/hello`
     hoặc `capability/update`); không gửi lại bản giống hệt; không bao giờ gửi tới iPhone/iPad (chúng
     báo `app_calls = false`). Mac giữ bản mới nhất theo `call_id` dựa trên `ts` của envelope; sau
     `ended`, Mac bỏ qua các bản sau của `call_id` đó.
  8. **Giới hạn:** `caller` cắt còn 128 ký tự và `app.label` còn 64; `caller` rỗng → `null`. Không
     log `caller`, nhãn ứng dụng hay nội dung thông báo nào; log gồm `type`, `op`, `call_id`, mã lỗi
     và thời gian đo.
  9. **Vòng đời listener:** `onListenerConnected` → đọc `getActiveNotifications()` một lần qua cùng
     bộ lọc để dựng lại các ngữ cảnh còn sống; `onListenerDisconnected` hoặc quyền truy cập thông báo
     bị thu hồi → mọi ngữ cảnh còn sống kết thúc với `end_reason = unknown` (E10) và
     `capability/update` báo `app_calls = false` kèm `NOTIFICATION_LISTENER` trong
     `permissions_missing`.

#### API 2 — `WS call_event/action` với `call_id` của cuộc gọi ứng dụng

- **URL:** như API 1
- **Method:** `WS call_event/action` (C→S), envelope mã hóa, có ack — đặc tả chính ở CALL-02 API 1;
  A-CALL định tuyến theo `call_id` (CALL-02 API 1 logic 7).
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `call_id` | uuid | Có | `call_id` của một cuộc gọi ứng dụng còn sống |
| `action` | enum{answer\| reject\| end} | Có | `answer`, `reject` khi `ringing`; `end` khi `ongoing` |
| `audio` | enum{phone} | Không | Chỉ với `answer`; vắng → `phone`; `mac` → `CALL_ROUTE_FAILED` (E9) |

- **Response (`ack.data`):** `{}` khi `ok = true` — Android đã gửi PendingIntent của ứng dụng, hoặc
  đã đăng thông báo chạm để nghe; kết quả đi qua `app_call`.

Lỗi (`ack.error.code`), theo thứ tự kiểm:

| Mã | Khi nào |
|----|---------|
| `FEATURE_DISABLED` | Cuộc gọi ứng dụng không hiệu lực với phiên gửi yêu cầu (E4) |
| `BAD_REQUEST` | Thiếu trường, `action` hoặc `audio` ngoài danh sách |
| `CALL_HFP_REQUIRED` | `action` ∈ {`hold`, `unhold`, `dtmf`, `mute`} (quy tắc của 0.7.1; panel cuộc gọi ứng dụng không bao giờ có các nút này); `details.action` = giá trị đã gửi |
| `CALL_ROUTE_FAILED` | `answer` với `audio = mac` (E9) |
| `CALL_APP_ACTION_UNAVAILABLE` | `answer` hoặc `reject` khi ngữ cảnh không ở `ringing` hoặc thông báo không có intent đó; `end` khi không ở `ongoing` hoặc không có thao tác kết thúc; thông báo đã mất hoặc PendingIntent đã bị hủy (`PendingIntent.CanceledException`); `answer` ở chế độ `tap` khi điện thoại không đăng được thông báo (E2, E7) |
| `INTERNAL` | Lỗi không mong đợi trên Android (0.8.1); client xử lý như CALL-02 E5 |

`call_id` không phải cuộc gọi ứng dụng còn sống đi theo CALL-02 API 1 (`CALL_NOT_FOUND` với cuộc gọi
ứng dụng đã kết thúc, E3).

- **Ví dụ:**

```json
{"op":"action","data":{"call_id":"0192f3f6-2c3d-7e4f-8a5b-6c7d8e9f0a1b","action":"answer"}}
{"re":"0192f3f7-3d4e-7f50-9b6c-7d8e9f0a1b2c","ok":true,"data":{}}
```

```json
{"op":"action","data":{"call_id":"0192f3f6-2c3d-7e4f-8a5b-6c7d8e9f0a1b","action":"end"}}
{"re":"0192f3f7-4e5f-7061-8c7d-8e9f0a1b2c3d","ok":false,"error":{"code":"CALL_APP_ACTION_UNAVAILABLE","message":"The app's notification offers no end action"}}
```

- **Logic nghiệp vụ:**
  1. Kiểm theo thứ tự trong bảng lỗi; cuộc gọi ứng dụng không bao giờ nhận `CALL_ACTION_NOT_ALLOWED`
     hay `PERMISSION_MISSING` (thiếu quyền truy cập thông báo nghĩa là cuộc gọi ứng dụng không hiệu
     lực).
  2. `ack` gửi ngay khi đã gửi PendingIntent hoặc đã đăng thông báo chạm để nghe, không chờ ứng
     dụng; Mac coi `app_call` kế tiếp là kết quả.
  3. Không có khóa thao tác: Mac khóa nút tới khi có `ack` hoặc `app_call` mới, gửi lại cùng `id`
     nhận lại `ack` cũ (0.5.1), và lệnh thứ hai sau khi ứng dụng đã đổi thông báo nhận
     `CALL_APP_ACTION_UNAVAILABLE`.
  4. `reject` và `answer` đánh dấu ngữ cảnh ("HandLive từ chối", "HandLive trả lời") trước khi gửi
     intent, để tính `end_reason` (API 1 logic 4).
  5. Mac: `ok = false` → hiện CALL-02 trường 10 theo mã (không hiện gì với
     `CALL_APP_ACTION_UNAVAILABLE`), mở khóa nút, áp dụng `app_call` mới nhất; `CALL_NOT_FOUND` →
     đóng panel; `ok = true` → với `answer_mode = tap` hiện trường 6, ngược lại chờ `app_call` kế tiếp
     tối đa 3 s.

#### API 3 — `NotificationListenerService` `AppCallListenerService`

- **URL:** N/A
- **Method:** khai báo trong manifest là
  `<service android:name=".appcall.AppCallListenerService" android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" android:exported="false">`
  với intent filter `android.service.notification.NotificationListenerService`; callback
  `onListenerConnected()`, `onListenerDisconnected()`, `onNotificationPosted(StatusBarNotification)`,
  `onNotificationRemoved(StatusBarNotification, RankingMap, int)`; `getActiveNotifications()`. Kiểm
  quyền: `NotificationManager.isNotificationListenerAccessGranted(ComponentName)` (truyền
  `ComponentName` của dịch vụ).
- **Request:** chỉ đọc từ thông báo cuộc gọi (logic 1 của API 1): `packageName`, `key`, `postTime`,
  `notification.flags`, `notification.category`, `notification.actions`, và các `extras`
  `android.callType`, `android.callPerson`, `android.title`, `android.answerIntent`,
  `android.declineIntent`, `android.hangUpIntent`; từ lần gỡ, `key` và `reason`.
- **Response:** N/A (callback).
- **Ví dụ:** Telegram đổ chuông: `packageName = "org.telegram.messenger"`, `category = "call"`,
  `android.callType = 1`, có `android.callPerson`, một intent từ chối (broadcast) và một intent trả
  lời (activity) → ngữ cảnh `ringing` với `controls.answer = controls.decline = true`. Sau "Trả lời",
  thông báo đổ chuông bị gỡ và 0,3–1,5 s sau Telegram đăng thông báo đang diễn ra trên kênh `Other3`
  với một thao tác → `ongoing`, `controls.end = true`.
- **Logic nghiệp vụ:**
  1. Callback chạy trên main thread; chúng chỉ áp bộ lọc và chuyển thông báo cuộc gọi sang luồng
     đơn của A-CALL, nơi xử lý tuần tự cùng các sự kiện điện thoại.
  2. Listener sống trong tiến trình HandLive và hoạt động khi A-SVC chạy; nó chỉ được bật khi
     `call.app_calls` và `feature.call` đều `true` (ngược lại `requestUnbind()`), nên tắt tính năng
     là dừng mọi việc đọc.
  3. Người dùng cấp quyền truy cập thông báo trong cài đặt hệ thống (SET-01 API 9); A-SVC tính lại
     `features.call.app_calls` và `permissions_missing` khi listener kết nối hoặc ngắt.
  4. Cuộc gọi tách rời (E11): A-CALL đọc `AudioManager.getMode()` khi thông báo đang gọi bị gỡ và, từ
     API 31, đăng ký `AudioManager.addOnModeChangedListener` chỉ khi còn cuộc gọi tách rời; không cần
     quyền. Callback của nó vào luồng của A-CALL như các callback thông báo.

#### API 4 — Gửi PendingIntent của ứng dụng

- **URL:** N/A
- **Method:** `pendingIntent.send(context, 0, null, null, null, null, options)` cho `answer`; bare
  `pendingIntent.send(...)` cho `reject` và `end`. Cho `answer`, `options` =
  `ActivityOptions.makeBasic().setPendingIntentBackgroundActivityStartMode(<chế độ>).toBundle()` với
  `<chế độ>` = `ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOW_ALWAYS` trên API 36+ (Android 16)
  và `ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED` (deprecated ở API 36) trên API 34–35;
  API 29–33: không có `options`, miễn trừ của bên gửi (dịch vụ Hỗ trợ tiếp cận được bind) tự áp dụng.
  Từ chối và kết thúc là broadcast hoặc service nên không cần miễn trừ.
- **Request:** `reject` → `android.declineIntent`; `answer` (`direct`) → `android.answerIntent`;
  `end` → `android.hangUpIntent` của thông báo đang gọi, không có thì `actionIntent` của thao tác
  duy nhất.
- **Response:** không có; `PendingIntent.CanceledException` → `CALL_APP_ACTION_UNAVAILABLE`.
- **Ví dụ:** spike T3.2 trên S25 với Telegram: thông báo đổ chuông bị gỡ 12–14 ms sau khi gửi intent
  từ chối; thông báo đang gọi bị gỡ 19–28 ms sau thao tác kết thúc; khi dịch vụ Hỗ trợ tiếp cận đang
  được bind, intent trả lời gỡ thông báo đổ chuông sau 160 ms – 1,5 s, không có thì Android chặn mở
  activity (`BAL_BLOCK`).
- **Logic nghiệp vụ:**
  1. Từ chối và kết thúc là broadcast hoặc service ở các ứng dụng đã gặp, không cần miễn trừ; trả
     lời mở một activity nên cần miễn trừ, điều mà `answer_mode` báo trước cho Mac.
  2. PendingIntent được dùng chỉ khi gói người tạo bằng gói đăng; ngược lại thao tác không khả dụng
     (control vắng mặt). Tùy chọn mở activity từ nền được gắn chỉ vào trả lời (từ chối/kết thúc
     không cần).
  3. Chỉ gửi intent của các thông báo hiện tại của ngữ cảnh; intent được giữ trong bộ nhớ cùng ngữ
     cảnh và bị bỏ cùng nó.

#### API 5 — Thông báo chạm để nghe

- **URL:** N/A
- **Method:** `NotificationManagerCompat.notify("app_call:<call_id>", 1, notification)` trên kênh
  `hl_app_call` (`IMPORTANCE_HIGH`, tên "Cuộc gọi từ ứng dụng khác", tạo cùng các kênh khác khi tiến
  trình khởi động); `setContentIntent(<intent trả lời của ứng dụng>)`, `setAutoCancel(true)`,
  `setTimeoutAfter(APP_CALL_TAP_NOTIFICATION_TTL)`, `VISIBILITY_PRIVATE` với bản công khai chỉ có
  tiêu đề; gỡ bằng `cancel("app_call:<call_id>", 1)`.
- **Request (nội dung thông báo):**

| Thuộc tính | Giá trị |
|------------|---------|
| Tiêu đề | Trường 12: "Nghe cuộc gọi \<ứng dụng>" với `app.label` |
| Nội dung | `caller` khi biết; không thì để trống |
| Category | Không phải `call`, không `CallStyle`: đây không phải thông báo cuộc gọi, và dù sao listener cũng bỏ qua thông báo của chính HandLive |

- **Response:** người dùng chạm → intent trả lời của ứng dụng chạy nhờ chính cú chạm của người dùng
  (không cần miễn trừ); ứng dụng mở màn hình cuộc gọi.
- **Ví dụ:** tiêu đề "Nghe cuộc gọi Telegram", nội dung "Nguyễn Văn A"; chạm sau 4 s → Telegram nghe
  máy, đăng thông báo đang gọi → `app_call` `ongoing`.
- **Logic nghiệp vụ:**
  1. Đăng khi `answer` với `answer_mode = tap`, một thông báo cho mỗi cuộc gọi; gỡ khi ngữ cảnh rời
     `ringing`, sau `APP_CALL_TAP_NOTIFICATION_TTL`, hoặc khi được chạm.
  2. Không được đăng thông báo (từ chối `POST_NOTIFICATIONS`, tắt thông báo của HandLive, hoặc kênh bị
     chặn) → không đăng gì, `ack` là `CALL_APP_ACTION_UNAVAILABLE` (E7).

#### API 6 — Panel cuộc gọi cho cuộc gọi ứng dụng trên Mac

- **URL:** N/A
- **Method:** `NSPanel` của CALL-01 API 5 (không lấy focus, trên mọi Space, góc trên bên phải), chuông
  `NSSound`, trạng thái Tập trung `INFocusStatusCenter`.
- **Request (dữ liệu hiển thị):** trường 1–11 lấy từ `app_call` mới nhất.
- **Response:** "Trả lời", "Từ chối", "Kết thúc" → API 2; "Bỏ qua" → chỉ cục bộ.
- **Ví dụ:** `app_call` `ringing` ở ví dụ API 1 → panel: "Cuộc gọi Telegram", "Nguyễn Văn A", nút "Trả
  lời", "Từ chối", "Bỏ qua"; sau "Trả lời" với `answer_mode = tap`: "Chạm vào thông báo trên điện thoại
  để nghe." và "Từ chối"; rồi `ongoing`: "Cuộc gọi Telegram", "Nguyễn Văn A", đồng hồ, "Âm thanh: Điện
  thoại", "Kết thúc".
- **Logic nghiệp vụ:**
  1. Vị trí, focus, VoiceOver, `call.notify`, chế độ Tập trung và chuông theo CALL-01 API 5 (logic
     1–4, 6, 7): không có panel khi đang bật Tập trung hoặc `call.notify = false`. Ở v1 cuộc gọi ứng
     dụng không có thông báo liên lạc và không có mục trong menu của biểu tượng menu bar.
  2. Một panel cuộc gọi: cuộc gọi điện thoại (CALL-01…03) giữ panel khi ngữ cảnh của nó chưa `idle`;
     cuộc gọi ứng dụng đổ chuông lúc đó được hiện khi panel kia đóng, nếu còn sống. Nhiều cuộc gọi ứng
     dụng còn sống: panel hiện cuộc `ringing` mới nhất, không có thì cuộc `ongoing` mới nhất.
  3. Đang gọi: không có giữ máy, bàn phím số, tắt tiếng hay chuyển âm thanh; đồng hồ theo CALL-03
     API 4 logic 1; `ended` đóng panel ngay.
  4. Mac báo `features.call.app_calls = call.app_calls`; khi cuộc gọi ứng dụng hết hiệu lực (E4), Mac
     đóng mọi panel cuộc gọi ứng dụng của điện thoại đó.

#### Query

N/A — CALL-05 không đọc hoặc ghi cơ sở dữ liệu: ngữ cảnh cuộc gọi ứng dụng và PendingIntent của
chúng nằm trong bộ nhớ A-CALL và bị quên sau `ended`; Mac chỉ giữ `app_call` mới nhất trong bộ nhớ.
