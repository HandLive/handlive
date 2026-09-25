# Điểm cần đồng bộ giữa design system (Apple HIG) và tài liệu thiết kế chi tiết

Ngày: 24/09/2026. Nguồn: design system https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT (bản theo
Apple HIG), `docs/detailed-design/`, hai báo cáo nghiên cứu `research-01-*`, `research-02-*`.

**Trạng thái 25/09/2026: chủ dự án đã duyệt cả bốn câu hỏi; toàn bộ các mục dưới đây đã được áp dụng vào `docs/detailed-design/` (xem README §3.5 và C19), `CLAUDE.md`, `docs/system-architecture.md`. Cách bỏ dấu kiểu Apple đã áp cho `docs/`, `README.md`, `CLAUDE.md` và `plans/` (trừ thư mục này, vì các bảng ở đây trích dạng cũ để so sánh).**

## Thay đổi hành vi (theo HIG)

| # | Chỗ trong tài liệu chi tiết | Hiện tại | Design system đề xuất | Lý do (HIG) |
|---|---|---|---|---|
| 1 | SET-03 trường 14 | Màn giải thích quyền có "Tiếp tục" + "Bỏ qua" | Chỉ một nút "Tiếp tục"; người dùng từ chối trong hộp thoại hệ thống. Ngoại lệ: công bố cần đồng ý pháp lý (AUDIO-01, Hỗ trợ tiếp cận) | Privacy › pre-alert screens |
| 2 | CALL-01 E4 | Tập trung bật: panel vẫn hiện, chỉ tắt chuông | Tập trung đang lọc người gọi → không hiện panel, không đổ chuông; cuộc gọi vẫn ở menu thanh menu; thêm thông báo liên lạc `INStartCallIntent` | Managing notifications, Notifications (communication) |
| 3 | SET-03 bước 6 (Mac) | Chỉ biểu tượng thanh menu, không Dock | Cài đặt "Hiện HandLive trên thanh menu" (mặc định bật); app `.accessory` khi chỉ có biểu tượng, chuyển `.regular` (Dock, thanh menu Sửa/Xem/Cửa sổ/Trợ giúp, Dock menu) khi mở cửa sổ Tin nhắn, Xem trước camera hoặc khi ẩn biểu tượng; thanh menu có HandLive, Tệp, Sửa, Xem, Cửa sổ, Trợ giúp | The menu bar › menu bar extras; Designing for macOS |
| 4 | CONN-01, menu thanh menu | Chưa nói kiểu hiển thị | Menu bar extra mở **menu** (`.menuBarExtraStyle(.menu)`), không popover | The menu bar |
| 5 | CALL-01 (panel) | `NSPanel` nổi | Giữ, ghi là lệch HIG có chủ đích (HIG muốn panel ẩn khi app không active); panel đóng khi cuộc gọi kết thúc, không tự đóng theo giờ | Panels, Accessibility › cognitive |
| 6 | PAIR-03 | Chưa nói kiểu xác nhận | Mac: alert, "Hủy ghép nối" là nút mặc định (không đỏ vì người dùng chủ động chọn); iPhone/Android: hộp chọn hành động, "Hủy ghép nối" đỏ ở trên | Alerts, Action sheets |
| 7a | CALL-01 API 6 | Thông báo cuộc gọi time-sensitive | Thông báo liên lạc `INStartCallIntent`; passive khi `CallPanel` đang hiện (không hiện chồng banner), time-sensitive khi Tập trung bật và không có panel | Notifications (communication), Managing notifications |
| 7b | CALL-04 trường 1, CAM-03 | Nhật ký cuộc gọi ở "cửa sổ menu bar → tab Cuộc gọi"; camera ở "bảng menu bar" | Nhật ký ở thanh bên cửa sổ Tin nhắn (mục "Cuộc gọi"); điều khiển camera là menu con trong menu thanh menu và cửa sổ Xem trước camera | Menu bar extra là menu |
| 7c | CLIP-01, CLIP-02, CLIP-03 (lỗi gửi) | Báo lỗi bằng thông báo | Dòng trạng thái trong menu thanh menu (Mac), toast của hệ thống (Android); thông báo chỉ cho việc cần hành động ("Vẫn gửi", "Gửi lại") | Notifications: lỗi không đi bằng thông báo |
| 7d | CAM-05 | "Đang thích ứng với mạng" tô vàng | Màu `status-connecting` (cam); vàng không phải màu trạng thái của HandLive | Color: mỗi màu một nghĩa |
| 7 | SMS-03 trường 5 | Dòng hội thoại có chấm, chữ đậm và số `unread_count` | Chỉ chấm và chữ đậm (như Tin nhắn của Apple); số chưa đọc ở thanh menu Mac và huy hiệu tab | Theo ứng dụng Tin nhắn; Tab bars › badge |

## Câu chữ và thuật ngữ

| # | Chỗ | Hiện tại | Đề xuất |
|---|---|---|---|
| 8 | Toàn bộ tài liệu (khoảng 800 chỗ: khoá 253, xoá 238, hoá 155, huỷ 95, tuỳ 46, hoà 6, hoạ 4, thoả 2) | Bỏ dấu kiểu mới: hoá, xoá, huỷ, tuỳ, thuỷ, khoẻ | Kiểu của bản tiếng Việt Apple: hóa, xóa, hủy, tùy, thủy, khỏe — để chữ trong app khớp chữ của hệ thống. Danh sách chuỗi cụ thể: mục "Viết nội dung" của design system |
| 9 | SET-02 (trường 1, 6), SET-01 trường 5, CLIP-01 trường 11, CLIP-02 trường 4 | "Đồng bộ clipboard", "Tự xoá clipboard đã nhận", "Gửi clipboard", "Clipboard trống hoặc không phải văn bản", "Gửi clipboard sang điện thoại" | "Đồng bộ bảng nhớ tạm", "Tự xóa bảng nhớ tạm đã nhận", "Gửi bảng nhớ tạm", "Bảng nhớ tạm trống hoặc không phải văn bản", "Gửi bảng nhớ tạm sang điện thoại" |
| 10 | PAIR-02 trường 4, CONN-01 trường 2 | "Đã kết nối (LAN)", "Đã kết nối (qua Internet)" | "Đã kết nối qua Wi-Fi", "Đã kết nối qua Internet"; "LAN" chỉ trong nhãn ngắn |
| 11 | SET-02 trường 14 | "Cho phép đường Opus/WS" | Nhãn cho người dùng: "Dự phòng qua Wi-Fi (cần Shizuku)" (giữ khóa `call_audio.allow_opus_fallback`) |
| 11a | SET-01 trường 6 | Nút "Cho phép" trước hộp thoại pin | "Tiếp tục" (màn giải thích không dùng "Cho phép") |
| 11b | PAIR-01 trường 5 | Xác nhận "Đồng ý" / "Huỷ" | "Hủy" / "Ghép nối" (nút là động từ nói việc sẽ xảy ra) |
| 11c | CLIP-01 trường 3 | "Không, tôi sẽ gửi thủ công" | "Gửi thủ công" (nút bắt đầu bằng động từ) |
| 11d | SET-01, SET-03 trường 1 | "máy chủ relay không đọc được nội dung" | "máy chủ không đọc được nội dung" |

## Thiếu trong tài liệu chi tiết

| # | Chỗ | Thiếu |
|---|---|---|
| 12 | CLIP-01, CLIP-02, SET-01 trường 17 (Android) | Kênh thông báo cho "Đã chặn nội dung nhạy cảm", xung đột, tiến trình ảnh, và thông báo thiếu quyền; design system đề xuất `clipboard` và `permission` (mức thấp) |
| 13 | AUDIO-02, AUDIO-04 (Mac) | `NSMicrophoneUsageDescription` và bước xin quyền micro trên Mac; đề xuất purpose string: "HandLive dùng micro để bạn nói trong cuộc gọi chuyển từ điện thoại." |
| 14 | SET-02 (Mac) | Khóa cài đặt cho "Hiện HandLive trên thanh menu" (mục 3) |
| 14a | CALL-01 API 5 (Mac) | Đọc trạng thái Tập trung cần `NSFocusStatusUsageDescription` và entitlement `com.apple.developer.focus-status` |
| 15 | SET-03 trường 11 và CLIP-04 | SET-03 nói iOS hỏi quyền dán; CLIP-04 dùng `PasteButton` nên không bị hỏi — cần thống nhất (design system theo CLIP-04) |

## Ngoài tài liệu chi tiết

- `CLAUDE.md` còn ghi iOS dùng "APNs/PushKit"; tài liệu chi tiết đã chốt không dùng PushKit/CallKit
  (không dùng CallKit thì không được dùng PushKit).
- Biểu tượng app chưa thiết kế: cần làm bằng Icon Composer, nhiều lớp, 6 giao diện; không dùng SF
  Symbol, không dùng font San Francisco.

## Câu hỏi còn mở

Không còn. Cả hai câu hỏi ở bản trước (bỏ dấu kiểu Apple; thay đổi hành vi 1–7d) đã được duyệt và áp
dụng ngày 25/09/2026.
