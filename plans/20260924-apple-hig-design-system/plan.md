# Design system HandLive theo Apple HIG

**Trạng thái:** Hoàn tất (artifact phiên bản 5; tài liệu chi tiết đã đồng bộ 25/09/2026) · **Ngày:** 24/09/2026 · **Kết quả:** artifact Design System https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT (thay bản Material 3 + HIG trước đó)

## Quyết định của chủ dự án

| # | Quyết định | Hệ quả |
|---|-----------|--------|
| DS1 | Theo chuẩn Apple (https://developer.apple.com/design/) cho **mọi nền tảng**, kể cả Android | Android dùng ngôn ngữ thiết kế Apple như Apple Music/Apple TV cho Android; phần do Android quản lý (thông báo, hộp thoại quyền, ô Cài đặt nhanh, cử chỉ quay lại) giữ nguyên của hệ thống. SF Pro và SF Symbols chỉ được dùng trên nền tảng Apple → Android dùng font và bộ biểu tượng thay thế |
| DS2 | Thêm iOS/iPadOS | Bao phủ CLIP-04, SMS, thông báo cuộc gọi, ghép nối bằng QR trên iPhone/iPad |
| DS3 | Màu thương hiệu hợp mệnh **Sơn Đầu Hỏa** | Màu bản mệnh (đỏ, cam, hồng, tím) và màu tương sinh (xanh lá — Mộc sinh Hỏa); không dùng đen, xanh dương, xanh nước biển (Thủy khắc Hỏa) cho thương hiệu |

## Giai đoạn

| # | Việc | Trạng thái |
|---|------|-----------|
| 1 | Nghiên cứu HIG: nền tảng (màu, chữ, bố cục, vật liệu, khả năng tiếp cận, biểu tượng, viết) và thành phần/mẫu tương tác — `reports/research-01-*.md`, `reports/research-02-*.md` | Xong |
| 2 | Bảng màu thương hiệu theo DS3 + token 4 giao diện (Sáng, Tối, hai bản tương phản cao) theo màu hệ thống Apple — 68 màu, 38 kiểu chữ; 236 cặp tương phản đạt ngưỡng | Xong |
| 3 | Tài liệu nền tảng, mẫu tương tác, từng nền tảng (macOS, iOS/iPadOS, Android) — 19 mục | Xong |
| 4 | Thành phần kiểu Apple kèm preview cho ba nền tảng — 19 thành phần | Xong |
| 5 | Bìa, kiểm tra hiển thị hai giao diện, kiểm tương phản, xuất bản lên artifact | Xong |
| 6 | Đồng bộ `docs/detailed-design/` theo `reports/03-diem-can-dong-bo.md` (chủ dự án duyệt 25/09/2026): hành vi, câu chữ, dấu kiểu Apple, quyền micro và Tập trung trên Mac; `CLAUDE.md` bỏ PushKit | Xong |

## Tiêu chí hoàn thành

- Cấu trúc tài liệu theo HIG: nền tảng → mẫu tương tác → thành phần → từng nền tảng.
- Mọi cặp chữ–nền đạt 4.5:1 ở cả bốn giao diện; control đạt kích thước tối thiểu của từng nền tảng.
- Câu chữ và trạng thái khớp `docs/detailed-design/`; chỗ lệch được ghi lại.
- Không dùng SF Pro, SF Symbols trên Android; có bảng đối chiếu biểu tượng.
- Mỗi preview hiển thị đúng ở Sáng và Tối.

## Rủi ro

- Liquid Glass chỉ có từ macOS 26/iOS 26; app hỗ trợ macOS 13+, iOS 16+ → thành phần tuỳ biến cần phương án vật liệu cũ.
- Giao diện kiểu Apple trên Android lệch quy ước Material; cần giữ nguyên các phần hệ thống và vùng chạm 48dp.
