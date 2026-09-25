[English](README.md) | Tiếng Việt

# ThreadRow

Một hội thoại SMS trong danh sách, theo cách ứng dụng Tin nhắn của Apple trình bày: chấm chưa đọc,
avatar chữ cái, tên, giờ, hai dòng trích (SMS-03).

Android không có thành phần này — người dùng đọc SMS trong ứng dụng tin nhắn của điện thoại.

## Cấu tạo

| Phần | Quy cách | Nguồn |
|------|---------|-------|
| Chấm chưa đọc | 10 pt, màu `unread`, ở lề trái; không có thì để trống cùng bề rộng | `unread_count > 0` và `local_read_ts < last_ts` |
| Avatar | Chữ cái đầu trên nền xám chuyển (kiểu Danh bạ); số lạ → `person.crop.circle.fill`; nhóm → `person.2.fill` | `display_name`, `addresses` |
| Tên | Tên liên hệ, hoặc số dạng "090 000 0123"; nhóm: các tên nối bằng ", " | `display_name` |
| Giờ | "14:05" hôm nay, "Hôm qua", "12/09"; kèm `chevron.forward` trên iPhone | `last_ts` |
| Trích | Tối đa hai dòng, `secondary-label`. Tin gửi lỗi gần nhất: `exclamationmark.circle.fill` + "Gửi lỗi" màu `destructive-text` | `snippet`, `sms_outbox.state` |

- Chưa đọc: tên đậm và chấm. Không hiện số tin trong dòng (theo cách của Apple); số hội thoại chưa
  đọc nằm trên thanh menu Mac và huy hiệu tab Tin nhắn. Đã đồng bộ với tài liệu chi tiết
  (25/09/2026): SMS-03 trường 5 không còn số `unread_count` trong dòng.
- Dòng đang chọn (Mac, iPad): nền màu nhấn của hệ thống, chữ trắng.

## Theo nền tảng

- **macOS:** sidebar của cửa sổ Tin nhắn (`NavigationSplitView`, `List(selection:)` kiểu
  `.sidebar`), avatar 32 pt, tên `mac-headline`, trích `mac-subheadline`. Tìm kiếm ở đầu sidebar;
  nút soạn tin mới (⌘N) trên toolbar, không ở đáy sidebar. Chuột phải: "Đánh dấu đã đọc", "Sao chép
  số".
- **iOS/iPadOS:** `List` thường, avatar 40 pt, tên `ios-headline`, trích `ios-subheadline`; vuốt
  trái để đánh dấu đã đọc; lọc "Tất cả / Chưa đọc" bằng `SegmentedControl`.

## Nên và không nên

- Nên giữ thứ tự theo tin cuối mới nhất; hội thoại có tin lỗi không nhảy lên đầu.
- Không cắt tên ở giữa; không in đậm cả đoạn trích.
