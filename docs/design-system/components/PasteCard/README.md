# PasteCard

Tab Bảng nhớ tạm trên iPhone và iPad (CLIP-04): gửi nội dung vừa sao chép sang điện thoại, và xem,
sao chép lại nội dung vừa nhận. iOS không cho app đọc bảng nhớ tạm khi chạy nền, nên người dùng gửi
bằng một lần chạm vào nút **Dán** của hệ thống.

## Cấu tạo

| Phần | Quy cách |
|------|---------|
| Gửi | Thẻ "Gửi sang Pixel 8 của Lan" với `PasteButton` (SwiftUI) / `UIPasteControl` (UIKit) — nút dán của hệ thống, **không** bật hộp thoại "Cho phép dán"; tô `accent`, dạng capsule; câu giải thích một dòng dưới nút |
| Kết quả | `Feedback` HUD "Đã gửi tới Pixel 8 của Lan" + rung `success`; chưa kết nối: "Chưa kết nối — sẽ gửi nếu kết nối lại trong 2 phút" |
| Nhận gần nhất | Thẻ nội dung (văn bản rút gọn 3 dòng hoặc ảnh thu nhỏ), dòng "Từ Pixel 8 của Lan · 14:05", nút "Sao chép" (`document.on.document`) |
| Nội dung nhạy cảm | Không hiện nội dung, chỉ "Nội dung nhạy cảm đã được ẩn" |
| Trống | "Chưa nhận gì" và câu hướng dẫn sao chép trên điện thoại |

Thanh tab (iOS 26 trở lên là kính nổi): "Bảng nhớ tạm", "Tin nhắn" (huy hiệu số chưa đọc, màu
`badge`), "Cuộc gọi", "Cài đặt"; biểu tượng bản đặc, tab đang chọn màu `accent`.

## Android

Android là máy trung tâm nên không có tab này: gửi thủ công bằng ô Cài đặt nhanh "Gửi bảng nhớ tạm",
nút trong thông báo thường trực, hoặc bảng chia sẻ — đều là giao diện của Android. Tự gửi khi sao
chép bật trong Cài đặt (cần Hỗ trợ tiếp cận, xem `ConsentSheet`).

## Nên và không nên

- Nên để nút Dán là thao tác đầu tiên trong vùng dễ với; không đặt hai nút dán.
- Không đọc bảng nhớ tạm bằng code khi mở app (sẽ bật hộp thoại xin phép của iOS).
- Không giữ lịch sử dài; chỉ mục nhận gần nhất.
