# Tài liệu thiết kế chi tiết — Kế hoạch soạn

**Trạng thái:** Hoàn tất · **Ngày:** 2026-09-24 · **Đầu ra:** `docs/detailed-design/`

## Mục tiêu

Tài liệu thiết kế chi tiết đủ để triển khai: mỗi nhóm chức năng một mục; mỗi chức năng lá đúng 5 mục
(Thông tin chung, Màn hình, Thành phần, Luồng nghiệp vụ, Đặc tả API/service).

## Các phần

| Phần | File | Người viết | Trạng thái |
|------|------|-----------|------------|
| Mục lục, quy ước, điều chỉnh C1–C18 | `README.md` | Controller | Xong |
| 0. Đặc tả dùng chung | `00-common-specs.md` | Controller (hợp nhất bổ sung của các nhóm) | Xong |
| 1. Thiết lập và cài đặt | `01-setup-settings.md` | Agent + controller rà soát | Xong |
| 2. Ghép nối | `02-pairing.md` | Controller | Xong |
| 3. Kết nối | `03-connectivity.md` | Controller | Xong |
| 4. Clipboard | `04-clipboard.md` | Agent + controller rà soát (C17) | Xong |
| 5. SMS | `05-sms.md` | Agent + controller rà soát | Xong |
| 6. Điều khiển cuộc gọi | `06-call-control.md` | Agent + controller rà soát | Xong |
| 7. Âm thanh cuộc gọi | `07-call-audio.md` | Agent + controller rà soát | Xong |
| 8. Camera và micro | `08-camera-mic.md` | Agent (2 lượt) + controller rà soát | Xong |

## Kiểm chứng đã chạy

- Bộ kiểm cấu trúc (`validate_design_docs.py`): 8 nhóm, 33 chức năng lá, 0 lỗi — mỗi chức năng đúng
  5 mục theo thứ tự, bảng Thông tin chung đủ 7 dòng, Màn hình `N/A`, số bước lưu đồ có trong bảng
  bước, mọi `WS type/op` có trong danh mục 0.7, mọi mã lỗi có trong 0.8, SQL gắn nhãn `[Thiết kế]`
  và chỉ dùng bảng ở 0.9.
- Mermaid 11: 34 sơ đồ parse và render không lỗi (nhãn bước dạng `(n)` vì `n. ` bị hiểu là danh sách
  markdown).
- Bản HTML: không cuộn ngang ở 375 px, chế độ sáng/tối, mọi liên kết nội bộ trỏ đúng.
- Kiểm chứng nền tảng (Android A1–A6, macOS M1–M4) và quyết định của chủ dự án:
  `docs/detailed-design/README.md` §5, `plans/20260924-definitive-architecture/plan.md` §13.

## Rủi ro còn lại (đã có phương án, không phải câu hỏi mở)

- `IOBluetoothHandsFreeDevice` trên macOS 13+ chưa có báo cáo chạy được → spike D1 tuần đầu Phase 4
  quyết định.
- Đường Opus/WS qua Shizuku: thu âm phụ thuộc máy; chèn giọng (Android 13+) chưa kiểm chứng → ma
  trận thiết bị thật.
- Accessibility cho clipboard: rủi ro chính sách Google Play → dự phòng gửi thủ công.
- Phát hiện thao tác sao chép và mở Activity từ nền qua Accessibility cần thử trên Android 15+ và
  nhiều OEM.

## Báo cáo

`reports/` — báo cáo từng nhóm do agent viết.
