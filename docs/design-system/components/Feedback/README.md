# Feedback

Phản hồi nhẹ sau một thao tác — đã gửi, đang chờ, bị chặn — đặt ngay chỗ người dùng đang nhìn, không bằng alert hay thông báo. Dùng nhiều kênh cùng lúc: biểu tượng, chữ, rung (iPhone, Android).

## Theo nền tảng

| Nền tảng | Hình thức | Ví dụ |
|---------|-----------|-------|
| macOS | Biểu tượng thanh menu đổi sang `checkmark` trong ~1 giây (SF Symbols Magic Replace), rồi trở lại; dòng trạng thái trong menu ở lần mở tiếp | Gửi bảng nhớ tạm từ menu: không cửa sổ, không thông báo |
| macOS | Dòng trạng thái nhỏ trong cửa sổ đang mở | "Bảng nhớ tạm đang chờ gửi · còn 1:45" |
| iOS/iPadOS | HUD dạng viên kính ở đỉnh màn hình ~1,5 giây + rung `success` | "Đã gửi tới Pixel 8 của Lan" |
| Android (app mở) | Như iOS, HUD kính + rung `CONFIRM` | "Đã gửi tới MacBook của Lan" |
| Android (app ở nền: ô Cài đặt nhanh, nút trong thông báo) | Toast của hệ thống | "Đã gửi tới MacBook của Lan" |

HUD không có nút và không chứa việc cần làm. Việc cần làm (ví dụ "Vẫn gửi", "Gửi lại") đi bằng `Notification` hoặc nằm trong màn đang mở.

## Câu chữ (CLIP-01)

| Kết quả | Chữ | Biểu tượng |
|---------|-----|-----------|
| Thành công | "Đã gửi tới <tên thiết bị>" | `checkmark.circle.fill` ↔ `check_circle` (`status-connected`) |
| Chưa kết nối | "Chưa kết nối — sẽ gửi nếu kết nối lại trong 2 phút" | `clock` ↔ `schedule` (`status-connecting`) |
| Không đọc được | "Bảng nhớ tạm trống hoặc không phải văn bản" | `exclamationmark.circle` ↔ `error` (`status-offline`) |

Đã đồng bộ với tài liệu chi tiết (25/09/2026): CLIP-01 trường 11 viết "Bảng nhớ tạm trống…".

## Nên và không nên

- Nên tắt chuyển động trượt của HUD khi bật Giảm chuyển động (chỉ hiện/ẩn mờ).
- Không đưa nội dung vừa sao chép vào HUD hay thông báo.
- Không xác nhận những việc hiển nhiên (tự đồng bộ khi mọi thứ bình thường là im lặng).
