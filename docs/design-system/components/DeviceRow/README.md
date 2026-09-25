# DeviceRow

Một thiết bị đã ghép nối: loại máy, tên, trạng thái liên kết và lối vào chi tiết (PAIR-02). Android
thấy danh sách tối đa tám máy; Mac và iPhone/iPad chỉ thấy một điện thoại.

## Cấu tạo

| Phần | Nội dung | Nguồn |
|------|----------|-------|
| Biểu tượng | `laptopcomputer` ↔ `laptop_mac`, `iphone` ↔ `phone_iphone`, `ipad` ↔ `tablet_mac`, điện thoại Android `candybarphone` ↔ `smartphone`; ô tròn `tertiary-system-fill` | `peer_platform` |
| Tên | Đúng như người dùng đặt, một dòng, cắt cuối bằng "…" | `peer_name` |
| Trạng thái | `StatusIndicator` cỡ nhỏ: "Đã kết nối qua Wi-Fi", "Điện thoại ngoại tuyến · lần cuối 14:05" | máy trạng thái kết nối, `last_seen_at` |
| Cuối dòng | Mũi tên mở chi tiết (iOS/Android); trên Mac là nút "Chi tiết…" | — |

Màn chi tiết có: tính năng đang dùng và lý do tính năng chưa dùng được, quyền còn thiếu trên điện
thoại, **Mã an toàn** 8 ký tự hex (hiển thị hai nhóm "7F3A 9C21", kiểu `code-pin` cỡ nhỏ, chọn và
sao chép được), nút "Hủy ghép nối" ở nhóm cuối.

## Theo nền tảng

- **macOS:** Cài đặt › Thiết bị: một dòng trong `Form` nhóm, biểu tượng 32 pt, tên `mac-headline`,
  trạng thái `mac-subheadline`, nút "Chi tiết…" và "Hủy ghép nối…" bên phải.
- **iOS/iPadOS:** Cài đặt › Điện thoại, dòng 60 pt trong `GroupedList`.
- **Android:** màn Thiết bị (tab chính), dòng 72 dp; trạng thái trống có tiêu đề `brand-title` "Chưa
  có thiết bị nào" và nút "Thêm thiết bị".

## Nên và không nên

- Nên cập nhật trạng thái trong ≤ 1 giây khi kết nối đổi, không cần kéo để làm mới.
- Không hiển thị `pair_id`, khóa, địa chỉ IP trên dòng.
- Không đặt "Hủy ghép nối" trực tiếp trên dòng; luôn qua màn chi tiết và `Alert` xác nhận.
