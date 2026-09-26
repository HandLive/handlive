[English](01-thiet-lap-ban-dau.md) | Tiếng Việt

# Thiết lập ban đầu

Mục này quy định lần mở đầu tiên trên từng nền tảng: chào ngắn, xin đúng quyền cần để app chạy, ghép
nối bằng mã QR rồi vào app. Quyền của từng tính năng để tới lúc dùng tính năng đó.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/onboarding ·
https://developer.apple.com/design/human-interface-guidelines/launching ·
https://developer.apple.com/design/human-interface-guidelines/privacy#Requesting-permission

## Nguyên tắc

- Ngắn và dạy bằng việc thật: bước ghép nối chính là phần hướng dẫn. Mac và iPhone tối đa 6 màn
  (SET-03), Android tối đa 5 màn trước ghép nối (SET-01); xong trong 60 s.
- Chỉ nói về HandLive, không dạy cách dùng máy. Mẹo theo ngữ cảnh (TipKit, iOS 17 và macOS 14 trở
  lên) thay cho chuỗi màn hướng dẫn.
- Xin ở đây chỉ quyền cần để chạy: thông báo, mạng cục bộ (Mac, iPhone); thông báo, chạy nền
  (Android). Bluetooth và micro của Mac xin khi bật "Nghe gọi trên Mac"; quyền camera và Camera
  Extension khi bật "Dùng điện thoại làm webcam"; quyền SMS, cuộc gọi của Android ở thẻ tính năng
  sau lần ghép đầu. Chi tiết ở mục Xin quyền.
- Màn giải thích quyền không có "Bỏ qua"; người dùng từ chối trong hộp thoại của hệ thống. "Bỏ qua"
  chỉ có ở bước không mở hộp thoại hệ thống, ví dụ hướng dẫn tự khởi chạy theo hãng.
- Đóng giữa chừng vẫn vào được app: trạng thái trống mời "Thêm điện thoại…" (Android: "Thêm thiết
  bị"). Bước đã đạt thì tự bỏ qua; lần mở sau chạy tiếp từ bước còn thiếu.
- Launch screen không mang thương hiệu. iOS: nền `system-background` trơn, không chữ, không logo.
  macOS không có launch screen. Android 12+: giữ splash của hệ thống (biểu tượng app trên
  `system-background`), không thêm chữ. Thương hiệu (`wordmark`, `brand-large-title`, nền
  `brand-glow`) chỉ ở màn Chào mừng, ghép nối và Đã ghép nối.

## Các bước

### macOS

Lần chạy đầu, biểu tượng thanh menu hiện "Chưa ghép nối" và cửa sổ chào mở ra phía trước.

| # | Màn | Nội dung | Nút |
|---|-----|----------|-----|
| 1 | Chào mừng | "Chào mừng đến với HandLive", dòng tính năng kèm tóm tắt quyền riêng tư: mã hóa đầu-cuối, chỉ đi giữa các thiết bị của bạn, không cần tài khoản | "Bắt đầu" |
| 2 | Chuyển vào thư mục Ứng dụng (khi cần) | "Camera ảo chỉ hoạt động khi HandLive nằm trong thư mục Ứng dụng." | "Để sau", "Chuyển" |
| 3 | Thông báo | `PermissionPrimer` | "Tiếp tục" |
| 4 | Mạng cục bộ (macOS 15+) | `PermissionPrimer` | "Tiếp tục" |
| 5 | Thanh menu | Hộp chọn "Hiện HandLive trên thanh menu" và "Mở HandLive khi đăng nhập", bật sẵn; chú thích "Khi tắt, HandLive nằm trên Dock." | "Tiếp tục" |
| 6 | Dán từ ứng dụng khác (macOS 15.4+, khi cần) | Hướng dẫn chọn Luôn cho phép (C10) | "Mở Cài đặt hệ thống", "Tiếp tục" |
| 7 | Ghép nối | Sheet `PairingCard` trên cửa sổ chào | "Hủy" |
| 8 | Đã ghép nối | Tên điện thoại, ba việc làm được ngay (chép dán, tin nhắn, cuộc gọi), chỗ của HandLive trên thanh menu | "Xong" |

Bỏ chọn "Hiện HandLive trên thanh menu" thì app chuyển ngay sang có biểu tượng Dock (xem macOS).

### iOS và iPadOS

| # | Màn | Nội dung | Nút |
|---|-----|----------|-----|
| 1 | Chào mừng | Tiêu đề và tóm tắt quyền riêng tư như Mac | "Bắt đầu" |
| 2 | Thông báo | `PermissionPrimer`: khi HandLive đóng, SMS và cuộc gọi đến chỉ tới được bằng thông báo | "Tiếp tục" |
| 3 | Mạng cục bộ | `PermissionPrimer` | "Tiếp tục" |
| 4 | Ghép nối | Sheet `PairingCard`: iPhone, iPad hiện QR, không cần quyền camera | "Hủy" |
| 5 | Đã ghép nối | Tên điện thoại và giới hạn: bảng nhớ tạm đồng bộ khi HandLive đang mở; khi app đóng, SMS và cuộc gọi đến là thông báo; iPhone, iPad không nghe gọi được | "Xong" |

### Android

| # | Màn | Nội dung | Nút |
|---|-----|----------|-----|
| 1 | Chào mừng | Điện thoại đồng bộ với Mac, iPhone và iPad; tóm tắt quyền riêng tư (SET-01 trường 1) | "Bắt đầu" |
| 2 | Thông báo (Android 13+) | `PermissionPrimer` rồi hộp thoại hệ thống | "Tiếp tục" |
| 3 | Chạy nền | `PermissionPrimer` rồi hộp thoại miễn tối ưu pin; Android 11+ gợi ý tắt "Tạm dừng hoạt động nếu không dùng" | "Tiếp tục" |
| 4 | Tự khởi chạy (Xiaomi, OPPO, Samsung…) | Hướng dẫn theo hãng (SET-01 API 5) | "Mở cài đặt của hãng", "Đã xong", "Bỏ qua" |
| 5 | Ghép nối thiết bị | "Quét mã QR" (giải thích quyền camera ngay trước khung quét) hoặc "Nhập mã PIN" | — |
| 6 | Xác nhận | "Ghép nối với MacBook của Lan?" kèm Mã an toàn | "Hủy", "Ghép nối" |
| 7 | Đã ghép nối | Thẻ tính năng (SET-01 trường 10) với "Cấp quyền" cho SMS, cuộc gọi, tự gửi bảng nhớ tạm | "Xong" |

## Thành phần

| Thành phần | Vai trò |
|------------|---------|
| `Onboarding` | Màn chào: tiêu đề `brand-large-title`, dòng tính năng, liên kết "HandLive và quyền riêng tư của bạn", một nút chính |
| `PermissionPrimer` | Màn giải thích trước hộp thoại hệ thống, đúng một nút "Tiếp tục" |
| `PairingCard` | QR `qr-ink` trên `qr-paper`, cạnh `size-qr` trên Mac, đếm ngược "Mã đổi sau 1:42", "Không quét được? Dùng mã PIN" |
| `ConsentSheet` | Công bố Hỗ trợ tiếp cận trên Android, mở từ thẻ tự gửi bảng nhớ tạm |

## Ghép nối (PAIR-01)

- Mac và iPhone/iPad hiện QR, Android quét. Mã tự làm mới sau 120 s.
- PIN 6 số là đường dự phòng, chỉ dùng được khi cùng mạng Wi-Fi; hiện bằng `code-pin`, nhóm ba số
  "482 915"; sai quá 3 lần thì sinh mã mới.
- Lỗi hiện ngay trong sheet, không bằng alert: "Ghép nối không an toàn, thử lại" (E4). Hết hạn thì
  mã mới tự thay, không báo lỗi.
- Ghép xong: sheet tự đóng, hai máy cùng hiện "Đã ghép nối với <tên>". Đây là khoảnh khắc Niềm vui:
  minh họa trên `brand-glow`, rung `success` trên iPhone; bật Giảm chuyển động thì bỏ chuyển động,
  giữ nội dung. Trong thiết lập ban đầu, màn Đã ghép nối thay cho HUD `Feedback`; ghép lại từ Cài
  đặt thì chỉ có HUD.

## Điểm lệch

- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 trường 14 chỉ còn "Tiếp tục" (quyết định
  11).
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 đặt hai hộp chọn "Mở HandLive khi đăng nhập"
  (trường 3) và "Hiện HandLive trên thanh menu" (trường 16) trên màn chào; màn Thanh menu trong bảng
  bước ở trên là cách trình bày tương đương — khi dựng giao diện theo SET-03.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 trường 11 bỏ câu về quyền dán và nói rõ gửi
  bằng nút Dán (CLIP-04); giới hạn vẫn hiện ở bước 11 của SET-03.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-01 trường 6 dùng "Tiếp tục"; PAIR-01 trường 5
  dùng "Ghép nối" / "Hủy".

## Nên và không nên

| Nên | Không nên |
|-----|-----------|
| Cho người dùng tới bước ghép nối trong ≤ 3 lần chạm | Chuỗi màn giới thiệu tính năng |
| Hỏi quyền khi người dùng hiểu vì sao cần | Xin mọi quyền ngay lúc mở app |
| Cho vào app kể cả khi chưa ghép nối | Khóa app tới khi ghép xong |
| Nói thẳng giới hạn của iPhone, iPad | Hứa tính năng nền tảng không cho phép |
