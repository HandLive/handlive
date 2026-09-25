[English](README.md) | Tiếng Việt

# ConsentSheet

Tấm công bố cần người dùng đồng ý trước khi bật một tính năng có hệ quả pháp lý hay riêng tư. Là
ngoại lệ duy nhất được có hai lựa chọn trước hộp thoại hệ thống (HIG cho phép khi cần chấp thuận
pháp lý). Lựa chọn và phiên bản văn bản được ghi lại.

| Chỗ dùng | Nền tảng | Ghi lại |
|----------|---------|---------|
| Nghe gọi trên Mac (AUDIO-01, văn bản `call-audio-v1`) | macOS — sheet gắn cửa sổ Cài đặt | `consent_record` |
| Tự gửi khi sao chép bằng Hỗ trợ tiếp cận (CLIP-01) | Android — toàn màn hình (công bố nổi bật theo chính sách Google Play; SET-01 trường 13) | `clip.a11y_consent_at` |

## Nội dung

- Tiêu đề là tên tính năng ("Nghe gọi trên Mac"), không phải "Cảnh báo".
- Ba đến năm dòng tính năng, mỗi dòng một SF Symbol màu `accent` và một câu: điều HandLive làm, điều
  HandLive không làm, trách nhiệm của người dùng.
- Với nghe gọi trên Mac, phải có: âm thanh chỉ đi giữa các thiết bị của bạn; không ghi âm; bạn báo
  cho người bên kia ở nơi luật đòi hai bên đồng ý (California, Florida, Illinois…); qua Bluetooth
  chỉ có mã hóa của Bluetooth, qua Wi-Fi được mã hóa đầu-cuối.
- Hai nút: Mac (nghe gọi) "Hủy" và "Đồng ý" — "Đồng ý" mặc định, bên phải; Android (Hỗ trợ tiếp cận)
  "Gửi thủ công" và "Đồng ý" — "Đồng ý" rộng hết lề ở dưới cùng. Đã đồng bộ với tài liệu chi tiết
  (25/09/2026): CLIP-01 trường 3 ghi "Gửi thủ công". Đồng ý xong mới tới hộp thoại quyền của hệ
  thống (Bluetooth, micro; Cài đặt Hỗ trợ tiếp cận trên Android).

## Theo nền tảng

- **macOS:** `.sheet` trên cửa sổ Cài đặt, rộng ~460 pt, cửa sổ cha mờ đi; Esc = Hủy, Return = Đồng
  ý.
- **Android:** toàn màn hình (công bố nổi bật theo chính sách Google Play; SET-01 trường 13), nền
  `system-background`; nút Quay lại = Hủy. Bản
  cài ngoài Google Play trên Android 13+ thêm bước "Cho phép cài đặt bị hạn chế".
- **iOS:** không có (iPhone không nghe gọi, không có Hỗ trợ tiếp cận kiểu Android).

## Nên và không nên

- Nên viết câu thường, ngắn; không in đậm cả đoạn, không chữ nhỏ giấu điều kiện.
- Không chọn sẵn đồng ý, không có ô "Tôi đã đọc".
- Đổi nội dung công bố thì tăng phiên bản (`call-audio-v2`) và hỏi lại.
