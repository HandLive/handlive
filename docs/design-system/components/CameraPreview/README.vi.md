[English](README.md) | Tiếng Việt

# CameraPreview

Cửa sổ "Xem trước camera" trên Mac khi điện thoại làm webcam (CAM-02…05): hình từ điện thoại, trạng
thái phiên, kênh truyền và các điều khiển. Điều khiển nhanh cũng có trong `MenuBarMenu`.

## Cấu tạo

| Phần | Quy cách |
|------|---------|
| Khung hình | `video-background`, 16:9, bo `radius-card`; khi chờ: "Đang chờ điện thoại…"; tạm dừng hình: "Đã tạm dừng hình" |
| Trạng thái (góc trên trái) | Viên kính: chấm nhấp nháy + "Đang phát" · "Qua Wi-Fi" hoặc "Qua USB"; các trạng thái khác: "Đang yêu cầu…", "Chạm Bật trên điện thoại", "Đang khởi động…", "Đang dừng…", "Lỗi" |
| Thanh điều khiển (dưới, nổi trên hình) | Kính **clear** với lớp tối 35% (`glass-dim`) vì nằm trên video: `SegmentedControl` "Trước / Sau" (ẩn khi máy có một camera), nút bật tắt micro, nút tạm dừng hình, pop-up "Chất lượng" (Tự động, 480p, 720p, 1080p; mục vượt khả năng thì mờ kèm lý do), nút "Dừng" |
| Thông số | "Camera trước · 1280×720 · 24 fps · 1,9 Mbps", `mac-caption-2`, số dạng bảng |
| Hạ chất lượng | Dòng `text-orange` có biểu tượng: "Đang hạ chất lượng · Điện thoại nóng" (lý do khác: "Mạng Wi-Fi chậm", "Pin điện thoại yếu (18 %)", "Theo ứng dụng họp", "Theo lựa chọn của bạn") |
| Dùng bởi | "Có ứng dụng đang dùng HandLive Camera và HandLive Microphone" |

"Dừng" là nút thường, không phải phá hủy: dừng camera không mất dữ liệu. Không có tùy chọn lật
gương.

## Theo nền tảng

- **macOS:** cửa sổ thường, co giãn giữ tỉ lệ; ⌘W đóng (không dừng camera nếu ứng dụng họp đang
  dùng); từ macOS 26 thanh điều khiển là `GlassEffectContainer` với `.clear`, trước đó `.hudWindow`.
- **Android:** không có cửa sổ này; trong lúc phát, thông báo kênh `camera_live` có "Đổi camera",
  "Tắt micro" / "Bật micro", "Dừng", cùng chỉ báo quyền riêng tư của Android.

## Nên và không nên

- Nên để chữ nói trạng thái; khung tối không đủ để biết đang phát hay đang chờ.
- Không tự chuyển Wi-Fi ↔ USB mà không đổi nhãn kênh truyền.
