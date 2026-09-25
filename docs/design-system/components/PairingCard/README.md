# PairingCard

Ghép nối hai máy bằng mã QR (PAIR-01): **Mac và iPhone/iPad hiện mã, Android quét.** Khi không quét
được thì dùng mã PIN 6 số (chỉ trong cùng mạng Wi-Fi). Là một khoảnh khắc thương hiệu: nền
`brand-glow` ở lớp nội dung.

## Phía hiện mã (Mac, iPhone, iPad)

| Phần | Quy cách |
|------|---------|
| Tiêu đề | "Ghép nối điện thoại" — `brand-title` (Mac: sheet trên cửa sổ chào hoặc Cài đặt; iPhone: sheet cỡ lớn có "Hủy" ở góc trái) |
| Hướng dẫn | "Mở HandLive trên điện thoại Android, chạm Thêm thiết bị rồi quét mã này." |
| Mã QR | Luôn `qr-ink` trên `qr-paper` ở mọi giao diện, cạnh `size-qr` (220 pt), trong thẻ bo `radius-card` |
| Tên máy | Tên máy này, để người dùng chọn đúng trên điện thoại |
| Đếm ngược | "Mã đổi sau 1:42" — số dùng `timer` (monospacedDigit) |
| Dự phòng | Nút chữ "Không quét được? Dùng mã PIN" → hiện 6 số kiểu `code-pin` ("482 915") |

Ghép xong: sheet tự đóng, `Feedback` "Đã ghép nối với Pixel 8 của Lan" và rung `success` (iPhone).

## Phía quét (Android)

Màn camera toàn màn hình: khung ngắm bốn góc màu `on-video`, lớp tối ngoài khung, câu "Hướng camera
vào mã QR trên Mac hoặc iPhone", nút kính tròn đóng (`xmark` ↔ `close`) ở góc trên trái, nút kính
"Nhập mã PIN" ở dưới. Quét được: rung `CONFIRM`, hiện tên máy và **Mã an toàn** để đối chiếu.

## Nên và không nên

- Nên giữ độ sáng tối đa của mã: không phủ kính, không đổi màu mã theo giao diện Tối.
- Không đặt đếm ngược đỏ nhấp nháy; hết giờ thì tự tạo mã mới.
- Không yêu cầu nhập tay thông tin mạng; mã QR đã đủ.
