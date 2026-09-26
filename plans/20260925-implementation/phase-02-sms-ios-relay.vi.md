[English](phase-02-sms-ios-relay.md) | Tiếng Việt

# Phase 2 — SMS, app iPhone/iPad, relay và push

**Mục tiêu:** đọc và trả lời SMS từ Mac và iPhone/iPad; kết nối qua Internet khi ngoài LAN; đánh
thức iPhone bằng push; app iOS có bảng nhớ tạm, tin nhắn, cài đặt.

## Ngữ cảnh

- Chức năng lá: `05-sms.md` SMS-01…05; `03-connectivity.md` CONN-03, CONN-04; `04-clipboard.md`
  CLIP-04; `02-pairing.md` PAIR-01 qua relay (`rv`), PAIR-03 luồng B; `01-setup-settings.md` SET-02
  (trường 7–9, 21, 24–30), SET-03 (iOS).
- Common specs: 0.9.4 lược đồ relay (PostgreSQL), 0.9.4 Redis (`presence`, `dev:<device_id>`,
  `revoked_notice`), REST relay, `DELETE /v1/devices/me?revoke_pairs=` (C16).
- Design system: `3-platforms/02-ios-ipados.md`; thành phần `ThreadRow`, `MessageBubble`,
  `PasteCard`, `Notification`, `GroupedList`; `2-patterns/03-thong-bao.md`.
- Quyết định: C3 (Keychain khi khóa), C7 (không PushKit/CallKit), C18 (`ContentObserver`, không
  `RECEIVE_SMS`), cổng G2 (Play Console).

## Yêu cầu và tiêu chí đo

- Thông báo SMS mới trên Mac < 500 ms từ lúc điện thoại nhận (LAN), đo từ `ContentObserver.onChange`
  đầu tiên của lượt gộp và xét ở phân vị 95; trả lời có xác nhận "Đã gửi" < 2 s, thời gian này tính
  cả thời gian nhà mạng gửi tin.
- Relay zero-knowledge: không giải mã, không log payload; dữ liệu phiên tự xóa sau 30 ngày.
- iPhone đang khóa: thông báo chỉ hiện nội dung chung (C3), gửi bằng `loc-key` để iPhone tự dịch
  (0.12.4).
- Chuỗi giao diện mới của Phase 2 (SMS, iOS, relay, push) vào catalog trước mã, đủ `en` và `vi`
  (C20).

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| S2.1 [shared] | Catalog chuỗi giao diện cho Phase 2 (0.12, C20): mọi chuỗi người dùng thấy của SMS-01…05, CONN-03, CONN-04 (bảng `loc-key` nhóm `push.*` ở API 4), CLIP-04, PAIR-01 qua relay, PAIR-03 luồng B, SET-02 trường 7–9, 21, 24–30, SET-03 (iOS); chuỗi mục đích xin quyền của iOS | `shared/strings/ui-strings.json` | `check_strings.py` và `--docs` sạch; `en` và `vi` khớp đặc tả lá; vào trước mọi mã giao diện Phase 2 |
| S2.2 [shared] | JSON Schema: các op `sms` `sync`, `history`, `new`, `send`, `status`, `read_changed` kèm dữ liệu ack; lớp bọc định tuyến và thông điệp điều khiển của relay (0.4.3, 0.7.3); thân REST relay và thân lỗi (0.7.4, 0.8.2); thân push (`POST /v1/push`, dữ liệu FCM, payload APNs; 0.4.4, CONN-04) | `shared/schemas/` | `check_schemas.py` xanh, gồm mọi ví dụ JSON của các đặc tả lá Phase 2 |
| S2.3 [shared] | Test vector: dẫn xuất `K_push` và một envelope mã hóa bằng `K_push` (CONN-04 API 4, I-NSE giải mã); khung nhị phân định tuyến `HR` (0.4.3) | `shared/test-vectors/` | `verify_vectors.py` 0 lỗi, `generate_vectors.py --check` 0 lệch; test của Android, Apple và relay nạp các file này |
| R2.1 [relay] | REST: đăng ký thiết bị, cặp, thu hồi, `DELETE /v1/devices/me` (C16), push token; WS `/v1/relay` với lớp bọc `to`/`from`, presence Redis, chuyển tiếp giữa instance qua pub/sub (C5); rate limit; xóa dữ liệu 30 ngày | `relay/crates/relay-server` | Test tích hợp với hai client giả; `cargo clippy` sạch; không có payload trong log |
| R2.2 [relay] | Push proxy: APNs (token .p8, `apns-collapse-id`, `interruption-level`), FCM; relay không có hàng đợi riêng: thử lại một lần ngay trong yêu cầu khi gặp 500/503 hoặc lỗi mạng, rồi trả 502 (`push_outbox` của điện thoại thử lại, A2.2); nội dung mặc định theo CONN-04 API 4: chỉ `loc-key`, relay không gửi câu chữ | `relay/crates/relay-push` | Push tới iPhone thật trong < 2 s; hết hạn đúng |
| A2.1 [android] | SMS: `ContentObserver` trên provider (SMS-02), đồng bộ lịch sử theo trang (SMS-01), gửi qua `SmsManager` với `SendRegistry` và trạng thái `sending → sent → delivered/failed` (SMS-04), đã đọc (SMS-05); quyền SMS theo SET-01 phần B | `android/feature/sms` | Mọi mã lỗi `SMS_*` (0.8) được trả đúng; test với hai SIM |
| A2.2 [android] | Relay: kết nối `/v1/relay` khi không có LAN (CONN-03), đăng ký, gửi push qua relay khi client iOS không có phiên (CONN-04), `push_outbox` của điện thoại (0.9.1) thử lại push lỗi tới hạn (30 s với cuộc gọi, 24 h với SMS; CONN-04 E2, bước 5b), FCM nhận đánh thức | `android/core/transport`, `feature/…` | Chuyển LAN ↔ relay không mất tin; `relay.enabled = false` đóng phiên relay |
| M2.1 [macOS] | Cửa sổ Tin nhắn: `NavigationSplitView`, `ThreadRow`, `MessageBubble`, ô soạn tin với chọn SIM và số phần, thông báo liên lạc `INSendMessageIntent` với "Trả lời" và "Đánh dấu đã đọc" (SMS-02 API 4), lưu SQLCipher | `apple/macOS/HandLive` | Chuỗi trạng thái tin đúng SMS-04; thông báo hiện avatar người gửi; huy hiệu số chưa đọc trên thanh menu |
| M2.2 [macOS] | Kết nối qua Internet (CONN-03) trong `HLTransport`; cài đặt Tin nhắn và Kết nối qua Internet; "Xóa thiết bị khỏi máy chủ", "Xóa toàn bộ dữ liệu" với alert | app | Đổi Wi-Fi sang 4G trên điện thoại vẫn nhận tin qua relay |
| I2.1 [iOS] | App iOS: thiết lập SET-03, ghép nối hiện QR, tab Bảng nhớ tạm với `PasteButton` (CLIP-04), tab Tin nhắn (`ThreadRow`, `MessageBubble`), tab Cài đặt (`GroupedList`), `HLTransport` LAN và relay | `apple/iOS/HandLive` | Dán không bật hộp thoại quyền; iPad `NavigationSplitView`; Dynamic Type AX5 không cắt chữ |
| I2.2 [iOS] | Notification Service Extension: giải mã envelope bằng `K_push` khi máy mở khóa, thông báo liên lạc `INSendMessageIntent`, hành động trả lời (SMS-04 trong ~20 s nền), nội dung chung khi khóa (C3); đăng ký push (CONN-04) | `apple/iOS/NotificationService` | Test với máy khóa và mở khóa; extension < 30 MB bộ nhớ |
| T2.1 [test] | Bench: thời gian thông báo SMS và xác nhận trả lời; test tải relay 1 000 kết nối giả | `tools/bench/`, `reports/` | Đạt mục tiêu đo trên máy thật; relay ổn ở 1 000 kết nối |
| T2.2 [release] | Play Console: Permissions Declaration Form (SMS, nhật ký cuộc gọi), chính sách quyền riêng tư; App Store: mô tả quyền, App Group, capability Communication Notifications | `docs/deployment-guide.md` | Cổng G2 |

## Nhánh và thứ tự làm

- Nhánh `feat/phase-02-sms-ios-relay` ở handlive-shared, handlive-relay, handlive-android và
  handlive-apple; hub và `HandLive/.github` vẫn làm trên `main`.
- Mỗi kho một agent, chạy song song: shared (S2.1 → S2.2 → S2.3 → T2.1), relay (R2.1 → R2.2),
  Android (A2.1 → A2.2), Apple (client relay trong `HLTransport` và kho SMS trong các package trước,
  rồi M2.1 → M2.2 → I2.1 → I2.2). S2.1 đi đầu vì mọi thẻ giao diện chờ chuỗi của nó; trong lúc chờ,
  agent nền tảng làm các phần không có giao diện.
- App iOS và Notification Service Extension chỉ build trên CI (máy macOS có Xcode); máy phát triển
  chỉ có Command Line Tools.
- T2.2 (tài liệu) làm trong hub; việc nộp Play Console và App Store là bước của chủ dự án (cổng G2).

## Kiểm thử

- Đơn vị: phân trang `sms/history`, khớp `local_id` với hộp Sent (SMS-04 API 4), quy tắc trạng thái
  chỉ đi tiến.
- Tích hợp: kịch bản mất mạng giữa chừng (CONN-02 E), relay khởi động lại (presence Redis mất).

## Rủi ro và quay lui

- Play Store từ chối SMS → Plan B: Notification Listener đọc thông báo SMS (mất gửi), phân phối
  F-Droid/APK; ghi trong deployment-guide.
- APNs payload 4 KB → trong push, `message.body` cắt còn tối đa 1 000 ký tự tại ranh giới code point.
  Nếu `env_b64` vẫn dài hơn 3 000 ký tự thì rút gọn tiếp `message.body`, rồi `thread.snippet`, mỗi
  lần kết thúc bằng "…" (CONN-04 bước 5b). Nội dung đầy đủ đến sau SMS-01.
