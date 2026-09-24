# Báo cáo 05-sms

**Trạng thái:** Xong — `docs/detailed-design/05-sms.md` (5 chức năng lá, ~1 180 dòng).

## Cần bổ sung vào 00-common-specs

1. 0.8.1: `SMS_CURSOR_INVALID` (`details.reason` = `cursor` | `page_token`) → client bắt đầu lại hoặc đồng bộ lại toàn bộ.
2. 0.7.2: `features.sms.default_sub_id` (Android, int32 | null, cho bộ chọn SIM); `features.sms.notify` (iOS gửi, bằng `sms.notify`; Android chỉ push khi `true`).
3. 0.10 (đề xuất): `SMS_PAGE_MAX_BYTES` 180 KiB plaintext/ack; `SMS_BODY_MAX` 1 600 ký tự; `SMS_OUTBOX_EXPIRY` 24 h; `SMS_SEND_MATCH_WINDOW` 60 s; `SMS_QUICK_REPLY_TIMEOUT` 20 s; `SMS_OBSERVER_DEBOUNCE` 100 ms.
4. `sms/sync` ack thêm `unread` ở trang cuối (hòa giải trạng thái đọc khi client ngoại tuyến); JSON con trỏ thêm `"v":1`.

## Giả định

- v1 gửi đúng 1 người nhận; hội thoại nhiều người chỉ xem.
- `SendRegistry` trong bộ nhớ 24 h (mở rộng map `local_id`): chống trùng theo `local_id`, phát lại `sms/status` khi có phiên mới; mất khi A-SVC khởi động lại.
- Đồng bộ bù dùng `_id > id OR date > t` (phòng `_id` bị cấp lại); `page_token` không trạng thái.
- Dòng `outbox`/`queued` do điện thoại gửi được theo dõi bằng `pending_out`.
- Tin đến qua SMS-01 không tạo thông báo.
- Cờ "đã hết tin" (SMS-03) giữ trong bộ nhớ, không thêm cột.

## Chưa chắc / cần xác nhận

- Tên trường `POST /v1/push` phải khớp CONN-04 (ví dụ trong tài liệu chỉ minh họa).
- CONN-02: I-APP vào nền cần đóng phiên sớm; nếu không, Android gửi `sms/new` vào socket chết mà không push.
- Thiết kế dùng ContentObserver nên không cần `RECEIVE_SMS`; có giữ quyền này trong Declaration Form không?
- Liệt kê SIM cần `READ_PHONE_STATE`; SET-01 có xin quyền này không?
- Tài liệu dài hơn mục tiêu 600–900 dòng; độ dày mỗi chức năng tương đương 02-pairing.
