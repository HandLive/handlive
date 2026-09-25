[English](README.md) | Tiếng Việt

# Onboarding

Màn chào lần đầu mở app — khoảnh khắc thương hiệu chính của HandLive. Ngắn, bỏ qua được, nói về
HandLive chứ không dạy cách dùng hệ thống (SET-03). HIG không cho dùng launch screen để làm thương
hiệu; màn này là chỗ đúng.

## Cấu tạo

| Phần | Quy cách |
|------|---------|
| Nền | `system-background` với quầng `brand-glow` phía trên (màu thương hiệu nằm ở lớp nội dung) |
| Tiêu đề | "Chào mừng đến với HandLive", `brand-large-title`; chữ "HandLive" màu `brand-fire` |
| Ba–bốn dòng tính năng | SF Symbol màu `brand-fire` + tiêu đề đậm + một câu. Mac: bảng nhớ tạm, tin nhắn và cuộc gọi, webcam, riêng tư. iPhone/iPad: bảng nhớ tạm, tin nhắn, thông báo cuộc gọi, riêng tư. Android: vai trò trung tâm, riêng tư |
| Liên kết | "HandLive và quyền riêng tư của bạn" (mở `docs/privacy.vi.md` hoặc `docs/privacy.md` theo ngôn ngữ đang hiển thị) |
| Nút | "Bắt đầu" — `Button` nổi bật, dưới cùng (iPhone, Android) hoặc góc phải dưới (Mac); các bước sau dùng "Tiếp tục", bước cuối "Xong" |

Luồng sau màn chào: `PermissionPrimer` cho quyền cần để chạy → (Mac) hỏi "Hiện HandLive trên thanh
menu" → `PairingCard` → xong. Mọi quyền khác hỏi khi dùng tính năng.

## Theo nền tảng

- **macOS:** cửa sổ chào 520×560 pt, không thay đổi cỡ, nút đóng hoạt động (đóng = để sau; mở lại từ
  menu "Thêm điện thoại…"). macOS không có launch screen.
- **iOS/iPadOS:** toàn màn hình (iPad: form sheet); dòng tính năng co giãn theo Dynamic Type, cuộn
  được ở cỡ AX.
- **Android:** toàn màn hình, edge-to-edge; Be Vietnam Pro cho tiêu đề, Inter cho nội dung.

## Nên và không nên

- Nên để người dùng tới được việc chính (ghép nối) trong ≤ 3 lần chạm.
- Không hiện lại màn chào sau khi đã xong; không nhồi điều khoản, không hỏi đánh giá app ở đây.
