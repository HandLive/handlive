[English](05-phan-hoi-va-tai.md) | Tiếng Việt

# Phản hồi, tải và lỗi

Mục này quy định cách HandLive báo kết quả, trạng thái chờ, tiến trình và lỗi: mức ngắt quãng khớp
với tầm quan trọng, đặt ngay chỗ người dùng đang nhìn, luôn nói bước tiếp theo.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/feedback ·
https://developer.apple.com/design/human-interface-guidelines/loading ·
https://developer.apple.com/design/human-interface-guidelines/progress-indicators ·
https://developer.apple.com/design/human-interface-guidelines/alerts

## Chọn cách báo

| Tình huống | Cách báo | Ví dụ |
|---|---|---|
| Thao tác chủ động xong | `Feedback`. Mac: biểu tượng thanh menu đổi sang `checkmark` ~1 giây rồi trở lại. iPhone, Android: HUD kính ~1,5 giây kèm rung | "Đã gửi tới Pixel 8 của Lan" |
| Việc tự động thành công | Im lặng, trạng thái cập nhật tại chỗ. Riêng lần đầu chép từ điện thoại sang Mac có dấu `checkmark` như trên (khoảnh khắc Niềm vui) | — |
| Đang chờ, xếp hàng | Chữ trạng thái ngay trên đối tượng | "Đang chờ điện thoại", "2 tin đang chờ điện thoại", "Chạm Bật trên điện thoại" |
| Lỗi có cách sửa | Ngay chỗ gây lỗi, kèm nút sửa | "Gửi lỗi · Không có sóng" và "Thử lại" dưới bong bóng |
| Mất kết nối | Chỉ `StatusIndicator` | "Mất kết nối" và "Kết nối lại ngay" |
| Hành động không hoàn tác | `Alert` xác nhận | "Hủy ghép nối với Pixel 8 của Lan?" |
| Lỗi app không tự phục hồi | `Alert` có nút dẫn tới cách sửa | Tạo khóa thất bại lúc thiết lập (SET-03 E1), nút "Thử lại" |

- Mac, macOS 14+: `.contentTransition(.symbolEffect(.replace))`, từ macOS 15 hệ thống tự dùng Magic
  Replace; macOS 13 đổi biểu tượng không hiệu ứng.
- Rung: iOS `UINotificationFeedbackGenerator` `.success` / `.error` (iOS 17+ `.sensoryFeedback`);
  Android `HapticFeedbackConstants.CONFIRM` / `REJECT` (API 30+), API 29 `CONTEXT_CLICK`.
- Android khi HandLive không hiện trên màn (ô Cài đặt nhanh, nút trong thông báo, bảng chia sẻ):
  toast của hệ thống thay cho HUD.
- Giảm chuyển động: HUD chỉ hiện và ẩn mờ, biểu tượng thanh menu đổi thẳng. VoiceOver và TalkBack
  đọc cùng câu.
- HUD không có nút. Việc cần làm ("Vẫn gửi", "Gửi lại") đi bằng `Notification` hoặc nằm trong màn
  đang mở.

## Lỗi

Viết như nói chuyện: điều gì xảy ra, vì sao, làm gì tiếp. Không "Lỗi", không mã lỗi, không đổ lỗi
cho người dùng.

| Lỗi | Chỗ hiện | Chữ | Hành động |
|---|---|---|---|
| Gửi SMS thất bại (SMS-04 E7) | Dưới bong bóng | "Gửi lỗi · Điện thoại đang ở chế độ máy bay" | "Thử lại" |
| Tải tin cũ khi không có phiên (SMS-03 E2) | Dải đầu hội thoại | "Kết nối điện thoại để tải tin cũ hơn" | Tự tải khi kết nối lại |
| Lệnh cuộc gọi không tới (CALL-02 E5) | Trong `CallPanel` | "Không gửi được lệnh tới điện thoại" | Panel về trạng thái trước |
| Thao tác chỉ có qua Bluetooth (CALL-03 E2) | Trong `CallPanel`, thay ba nút bị ẩn | "Nối Bluetooth với điện thoại để giữ máy, bấm số, tắt tiếng" | — |
| Nội dung sao chép quá lớn (CLIP-01 E5) | Mac: dòng trạng thái `MenuBarMenu`; Android: toast | "Nội dung quá lớn để gửi (tối đa 1 MB văn bản)" | — |
| Điện thoại không ghi được (CLIP-02 E8) | Mac: dòng trạng thái `MenuBarMenu` | "Không ghi được bảng nhớ tạm trên điện thoại" | — |
| Camera khi đang qua Internet (CAM-02 E1) | Xem trước camera, `MenuBarMenu` | "Cần cùng mạng Wi-Fi hoặc cắm cáp USB" | — |
| Ghép nối sai xác thực (PAIR-01 E4) | Trong sheet ghép nối | "Ghép nối không an toàn, thử lại" | Mã QR mới |
| Máy chủ không phản hồi (SET-02 E5) | Dưới nút vừa dùng | "Không kết nối được máy chủ, hãy thử lại sau" | — |

## Alert: chỉ hai việc

- Xác nhận hành động không hoàn tác: "Hủy ghép nối" (PAIR-03), "Xóa thiết bị khỏi máy chủ", "Xóa
  toàn bộ dữ liệu HandLive" (câu SET-02 trường 29), "Đồng bộ lại toàn bộ SMS" (SMS-01 trường 6), "Gỡ
  camera và micro ảo" (CAM-01 A1), tắt tính năng đang chạy (SET-02 E9).
- Lỗi không tự phục hồi: tạo khóa thất bại (SET-03 E1, SET-01 E9); "Không khởi động được dịch vụ kết
  nối" với "Thử lại" (SET-01 E2); "Không kết nối được máy chủ. Vẫn xóa trên thiết bị này?" (SET-02
  E7).
- Mac: "Hủy" bên trái, hành động bên phải là nút mặc định, không tô đỏ vì người dùng chủ động chọn
  (quyết định 12); Esc hoặc ⌘. là Hủy. iPhone, Android: action sheet, hành động phá hủy màu đỏ ở
  trên, "Hủy" dưới cùng.
- Không alert lúc vừa mở app; không hai alert chồng nhau.

## Mất kết nối

- Không alert, không thông báo, kể cả khi mất rồi có lại nhiều lần. Chỉ `StatusIndicator`: biểu
  tượng thanh menu thêm `.slash`, dòng "Mất kết nối", "Điện thoại ngoại tuyến · lần cuối 14:05" hoặc
  "Đang kết nối…"; khi đang chờ thử lại: "Thử lại sau 8 s" và "Kết nối lại ngay" (CONN-02 trường
  3–4).
- Dữ liệu đã đồng bộ vẫn xem được. Việc cần điện thoại thì xếp hàng ("Đang chờ điện thoại") hoặc mờ
  kèm lý do: nút Dán vô hiệu với "Chưa kết nối với điện thoại" (CLIP-04 trường 4).
- `CallPanel` mất phiên: "Mất kết nối với điện thoại" (CALL-03 E6).
- "Cần ghép nối lại" (cặp bị thu hồi) là `status-error` vì người dùng phải làm gì đó: kèm "Ghép điện
  thoại…".

## Tải và tiến trình

- Hiện dữ liệu cục bộ ngay, đồng bộ ở nền; không chặn cả màn. Lần đầu: dải "Đang đồng bộ tin nhắn…"
  và "Đã tải 1 500 tin" trên danh sách (SMS-01 trường 1–2); "Đang tải tin cũ hơn" ở đầu hội thoại
  (SMS-03 trường 10).
- Câu cụ thể thay cho "Đang tải…". Mac: spinner nhỏ không nhãn cạnh nội dung đang tải.
- Biết tổng thì dùng thanh xác định; không đổi spinner thành thanh giữa chừng. Ảnh trên 1 MiB: "Đang
  gửi ảnh tới Pixel 8 của Lan — 45 %", kích thước MB, nút "Hủy" (CLIP-03) — Mac trong `MenuBarMenu`,
  Android trong thông báo, iPhone trên thẻ gửi.
- Nút đang xử lý đổi nhãn và khóa tới khi có kết quả: "Đang ghép nối…", "Đang trả lời…", "Đang từ
  chối…" (CALL-02 trường 9).
- Tự làm mới; kéo để làm mới trên iPhone chỉ là cách phụ.

## Trạng thái trống

| Chỗ | Chữ | Bước tiếp |
|---|---|---|
| Mac, iPhone chưa ghép nối | "Chưa ghép nối" | "Ghép điện thoại…" |
| Android chưa có thiết bị | "Chưa có thiết bị nào" | "Thêm thiết bị" |
| Tin nhắn trống (SMS-03 E1) | "Chưa có tin nhắn" kèm trạng thái đồng bộ | Chờ đồng bộ, hoặc "Tin nhắn mới" |
| Tính năng tắt hoặc thiếu quyền trên điện thoại | Lý do như trong Cài đặt | "Xem hướng dẫn" |
| Bảng nhớ tạm trên iPhone | "Chưa nhận gì" | Câu hướng dẫn sao chép trên điện thoại |

Tab trên iPhone không bao giờ ẩn hay vô hiệu vì trống; tab nói lý do ngay trong nội dung.

## Điểm lệch

- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CLIP-01 E5, CLIP-02 E5 và E8, CLIP-03 E2 báo lỗi
  tại chỗ — dòng trạng thái của `MenuBarMenu` (Mac) hoặc toast (Android); thông báo chỉ còn cho việc
  cần hành động ("Vẫn gửi", "Gửi lại").
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CAM-05 trường 1 dùng cam (`status-connecting`) cho
  cả "Đang thích ứng với mạng" và "Giới hạn do nhiệt/pin", khác nhau bằng chữ và biểu tượng; "Tốt"
  dùng `status-connected`.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): "Không ghi được bảng nhớ tạm trên điện thoại"; dấu
  kiểu Apple.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Báo thành công khi người dùng vừa chủ động làm | Báo mỗi lần tự đồng bộ bình thường |
| Giữ dữ liệu cũ trên màn khi mất kết nối | Thay màn bằng vòng quay hay alert |
| Nói lý do và nút sửa cạnh chỗ lỗi | "Đã xảy ra lỗi" chung chung |
