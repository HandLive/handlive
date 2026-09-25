[English](phase-02-sms-ios-relay.md) | Tiếng Việt

# Phase 2 — SMS, app iPhone/iPad, relay và push

**Mục tiêu:** đọc và trả lời SMS từ Mac và iPhone/iPad; kết nối qua Internet khi ngoài LAN; đánh
thức iPhone bằng push; app iOS có bảng nhớ tạm, tin nhắn, cài đặt.

## Ngữ cảnh

- Chức năng lá: `05-sms.md` SMS-01…05; `03-connectivity.md` CONN-03, CONN-04; `04-clipboard.md`
  CLIP-04; `02-pairing.md` PAIR-01 qua relay (`rv`), PAIR-03 luồng B; `01-setup-settings.md` SET-02
  (trường 7–9, 21, 24–30), SET-03 (iOS).
- Common specs: 0.9.4 lược đồ relay (PostgreSQL), 0.9.5 Redis (`presence`, `dev:<device_id>`,
  `revoked_notice`), REST relay, `DELETE /v1/devices/me?revoke_pairs=` (C16).
- Design system: `3-platforms/02-ios-ipados.md`; thành phần `ThreadRow`, `MessageBubble`,
  `PasteCard`, `Notification`, `GroupedList`; `2-patterns/03-thong-bao.md`.
- Quyết định: C3 (Keychain khi khóa), C7 (không PushKit/CallKit), C18 (`ContentObserver`, không
  `RECEIVE_SMS`), cổng G2 (Play Console).

## Yêu cầu và tiêu chí đo

- Thông báo SMS mới trên Mac < 500 ms từ lúc điện thoại nhận (LAN); trả lời có xác nhận "Đã gửi" < 2
  s.
- Relay zero-knowledge: không giải mã, không log payload; dữ liệu phiên tự xóa sau 30 ngày.
- iPhone đang khóa: thông báo chỉ hiện nội dung chung (C3), gửi bằng `loc-key` để iPhone tự dịch
  (0.12.4).
- Chuỗi giao diện mới của Phase 2 (SMS, iOS, relay, push) vào catalog trước mã, đủ `en` và `vi`
  (C20).

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| R2.1 [relay] | REST: đăng ký thiết bị, cặp, thu hồi, `DELETE /v1/devices/me` (C16), push token; WS `/v1/relay` với lớp bọc `to`/`from`, presence Redis, chuyển tiếp giữa instance qua pub/sub (C5); rate limit; xóa dữ liệu 30 ngày | `relay/crates/relay-server` | Test tích hợp với hai client giả; `cargo clippy` sạch; không có payload trong log |
| R2.2 [relay] | Push proxy: APNs (token .p8, `apns-collapse-id`, `interruption-level`), FCM; `push_outbox` hạn 30 s; nội dung mặc định theo CONN-04 API 4: chỉ `loc-key`, relay không gửi câu chữ | `relay/crates/relay-push` | Push tới iPhone thật trong < 2 s; hết hạn đúng |
| A2.1 [android] | SMS: `ContentObserver` trên provider (SMS-02), đồng bộ lịch sử theo trang (SMS-01), gửi qua `SmsManager` với `SendRegistry` và trạng thái `sending → sent → delivered/failed` (SMS-04), đã đọc (SMS-05); quyền SMS theo SET-01 phần B | `android/feature/sms` | Mọi mã lỗi `SMS_*` (0.8) được trả đúng; test với hai SIM |
| A2.2 [android] | Relay: kết nối `/v1/relay` khi không có LAN (CONN-03), đăng ký, gửi push qua relay khi client iOS không có phiên (CONN-04), FCM nhận đánh thức | `android/core/transport`, `feature/…` | Chuyển LAN ↔ relay không mất tin; `relay.enabled = false` đóng phiên relay |
| M2.1 [macOS] | Cửa sổ Tin nhắn: `NavigationSplitView`, `ThreadRow`, `MessageBubble`, ô soạn tin với chọn SIM và số phần, thông báo liên lạc `INSendMessageIntent` với "Trả lời" và "Đánh dấu đã đọc" (SMS-02 API 4), lưu SQLCipher | `apple/macOS/HandLive` | Chuỗi trạng thái tin đúng SMS-04; thông báo hiện avatar người gửi; huy hiệu số chưa đọc trên thanh menu |
| M2.2 [macOS] | Kết nối qua Internet (CONN-03) trong `HLTransport`; cài đặt Tin nhắn và Kết nối qua Internet; "Xóa thiết bị khỏi máy chủ", "Xóa toàn bộ dữ liệu" với alert | app | Đổi Wi-Fi sang 4G trên điện thoại vẫn nhận tin qua relay |
| I2.1 [iOS] | App iOS: thiết lập SET-03, ghép nối hiện QR, tab Bảng nhớ tạm với `PasteButton` (CLIP-04), tab Tin nhắn (`ThreadRow`, `MessageBubble`), tab Cài đặt (`GroupedList`), `HLTransport` LAN và relay | `apple/iOS/HandLive` | Dán không bật hộp thoại quyền; iPad `NavigationSplitView`; Dynamic Type AX5 không cắt chữ |
| I2.2 [iOS] | Notification Service Extension: giải mã envelope bằng `K_push` khi máy mở khóa, thông báo liên lạc `INSendMessageIntent`, hành động trả lời (SMS-04 trong ~20 s nền), nội dung chung khi khóa (C3); đăng ký push (CONN-04) | `apple/iOS/NotificationService` | Test với máy khóa và mở khóa; extension < 30 MB bộ nhớ |
| T2.1 [test] | Bench: thời gian thông báo SMS và xác nhận trả lời; test tải relay 1 000 kết nối giả | `tools/bench/`, `reports/` | Đạt mục tiêu đo trên máy thật; relay ổn ở 1 000 kết nối |
| T2.2 [release] | Play Console: Permissions Declaration Form (SMS, nhật ký cuộc gọi), chính sách quyền riêng tư; App Store: mô tả quyền, App Group, capability Communication Notifications | `docs/deployment-guide.md` | Cổng G2 |

## Kiểm thử

- Đơn vị: phân trang `sms/history`, khớp `local_id` với hộp Sent (SMS-04 API 4), quy tắc trạng thái
  chỉ đi tiến.
- Tích hợp: kịch bản mất mạng giữa chừng (CONN-02 E), relay khởi động lại (presence Redis mất).

## Rủi ro và quay lui

- Play Store từ chối SMS → Plan B: Notification Listener đọc thông báo SMS (mất gửi), phân phối
  F-Droid/APK; ghi trong deployment-guide.
- APNs payload 4 KB → nội dung SMS cắt 1 000 ký tự trong push, đầy đủ sau SMS-01.
