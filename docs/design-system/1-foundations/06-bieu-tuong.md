# Biểu tượng

HandLive dùng SF Symbols trên Mac, iPhone, iPad và Material Symbols Rounded trên Android. Mục này gồm cách dùng SF Symbols, bảng đối chiếu hai bộ biểu tượng, biểu tượng trên thanh menu Mac và quy cách biểu tượng app.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/icons · https://developer.apple.com/design/human-interface-guidelines/sf-symbols · https://developer.apple.com/design/human-interface-guidelines/app-icons

## SF Symbols

| Khía cạnh | HandLive |
|---|---|
| Rendering mode | Monochrome mặc định. Hierarchical cho biểu tượng lớn ở trạng thái trống. Palette, Multicolor chỉ khi màu mang nghĩa. Tô bằng màu ngữ nghĩa (`label`, `secondary-label`, `accent`) để tự theo giao diện |
| Weight, scale | Weight theo chữ bên cạnh (symbol lấy weight từ `.font`); scale `small`, `medium` (mặc định), `large` qua `imageScale(_:)` hoặc `NSImage.SymbolConfiguration` |
| Outline hay fill | Toolbar, danh sách, menu: outline. Thanh tab iOS: fill (hệ thống tự chọn). Nút tròn cuộc gọi, nút nổi: fill. Không khả dụng: biến thể slash |
| Cỡ | Đặt cùng text style để symbol phóng theo Dynamic Type; không đặt cỡ point cố định |
| Chuyển động | Hiếm và có mục đích (xem Chuyển động và xúc giác). Symbol effect cần macOS 14, iOS 17; Magic Replace cần macOS 15, iOS 18 |

- Hành động quen thuộc dùng biểu tượng chuẩn của HIG: sao chép `document.on.document`, dán `document.on.clipboard`, xóa `trash`, đóng `xmark`, xong `checkmark`, soạn `square.and.pencil`, tìm `magnifyingglass`, thêm `ellipsis`, tài khoản `person.crop.circle`, chia sẻ `square.and.arrow.up`. Tên `document.*` chỉ có ở bản SF Symbols mới; bản hệ điều hành cũ dùng `doc.on.doc`, `doc.on.clipboard` (kiểm cột availability trong app SF Symbols).
- Menu: dùng lệnh chuẩn (Sao chép, Dán…) để hệ thống tự gắn biểu tượng. Trong một nhóm, hoặc mọi mục có biểu tượng, hoặc không mục nào có.
- Không vẽ lại phần cứng Apple; dùng symbol sản phẩm (`laptopcomputer`, `iphone`, `ipad`) và không sửa chúng.
- Biểu tượng tự vẽ: vector (SVG, PDF), căn giữa theo thị giác, có accessibility label.

## Bảng đối chiếu

Material Symbols Rounded: weight 400, grade 0, optical size 24, FILL 0 trừ khi ghi khác ở mục Android.

| Khái niệm | SF Symbol | Material Symbols Rounded |
|---|---|---|
| Điện thoại Android | `candybarphone` | `smartphone` |
| Mac | `laptopcomputer` | `laptop_mac` |
| iPhone | `iphone` | `phone_iphone` |
| iPad | `ipad` | `tablet_mac` |
| Cùng mạng Wi-Fi | `wifi` | `wifi` |
| Kết nối qua Internet | `globe` | `public` |
| USB | `cable.connector` | `usb` |
| Sao chép, gửi bảng nhớ tạm | `document.on.document` | `content_copy` |
| Dán | `document.on.clipboard` | `content_paste` |
| Tin nhắn | `message` | `chat_bubble` |
| Gọi, Trả lời | `phone.fill` | `call` |
| Từ chối, Kết thúc | `phone.down.fill` | `call_end` |
| Cuộc gọi nhỡ | `phone.arrow.down.left` | `phone_missed` |
| Tắt tiếng | `mic.slash.fill` | `mic_off` |
| Giữ máy | `pause.fill` | `pause` |
| Bàn phím số | `circle.grid.3x3.fill` | `dialpad` |
| Camera | `video.fill` | `videocam` |
| Đổi camera | `arrow.triangle.2.circlepath.camera` | `cameraswitch` |
| Máy nóng | `thermometer.medium` | `thermostat` |
| Mã QR | `qrcode` | `qr_code_2` |
| Quét mã | `qrcode.viewfinder` | `qr_code_scanner` |
| Mã hóa, khóa | `lock.fill` | `lock` |
| Cảnh báo | `exclamationmark.triangle.fill` | `warning` |
| Thông tin | `info.circle` | `info` |
| Cài đặt | `gearshape` | `settings` |
| Xong, đã chọn | `checkmark` | `check` |
| Đóng, hủy | `xmark` | `close` |
| Xóa | `trash` | `delete` |
| Soạn tin | `square.and.pencil` | `edit_square` |
| Tìm | `magnifyingglass` | `search` |
| Thêm lệnh | `ellipsis` | `more_horiz` |
| Người, liên hệ | `person.crop.circle` | `account_circle` |
| Trạng thái kết nối | `antenna.radiowaves.left.and.right`, `antenna.radiowaves.left.and.right.slash` | `sensors`, `sensors_off` |

Bluetooth: SF Symbols không có biểu tượng Bluetooth, nên HandLive viết chữ "Bluetooth" ở mọi nền tảng. Android không dùng `bluetooth` để hai bên giống nhau.

## Biểu tượng thanh menu (macOS)

| Trạng thái | Biểu tượng |
|---|---|
| Đã kết nối | `antenna.radiowaves.left.and.right` |
| Đang kết nối | `antenna.radiowaves.left.and.right` với hiệu ứng variable color lặp (macOS 14+); khi bật Giảm chuyển động hoặc trên macOS 13 thì giữ biểu tượng tĩnh, trạng thái ghi ở dòng đầu của menu ("Đang kết nối…") |
| Ngoại tuyến, mất kết nối, chưa ghép nối | `antenna.radiowaves.left.and.right.slash` |
| Có cuộc gọi đến | `phone.fill` |
| Có hội thoại chưa đọc | Biểu tượng trạng thái, ngay sau là số hội thoại bằng chữ ("3") |
| Vừa gửi bảng nhớ tạm | `checkmark` khoảng 1 giây rồi trở lại biểu tượng trạng thái |

- Luôn là ảnh template (đen và trong suốt); hệ thống tô theo thanh menu sáng, tối và khi đang chọn. Không tô màu, không đổi màu theo trạng thái.
- HIG không nêu cỡ glyph; dùng SF Symbol để hệ thống tự căn trong thanh menu cao 24 pt. API: `MenuBarExtra(_:systemImage:isInserted:content:)` (macOS 13); ảnh tự vẽ dùng `init(_:image:isInserted:content:)` (macOS 14).

## Biểu tượng app

| Mục | Quy cách |
|---|---|
| Công cụ | Icon Composer, xuất sang Xcode |
| Cỡ, cấu trúc | 1024×1024 px cho iOS, iPadOS, macOS; một lớp nền và ít nhất một lớp trước; lớp vuông chưa mask, vector SVG hoặc PDF |
| Appearance | Mặc định, tối, clear sáng, clear tối, tinted sáng, tinted tối; cả sáu giữ cùng đặc điểm nhận dạng |
| Màu lớp | Nền `brand-ember` (đỏ than, thay cho đen); lớp trước `brand-fire`, `brand-flame` (ngọn lửa hiệu) |
| Không dùng | SF Symbols hay hình dễ lẫn với symbol, font SF, hình phần cứng Apple, chữ; không tự thêm bóng, vệt sáng, viền nổi, glow vì hệ thống tự thêm |
| Hiện tại | Chưa có biểu tượng. Preview dùng khối gradient lửa `brand-flame` → `brand-fire` → `brand-ember` (145°) làm chỗ giữ |

Android: adaptive icon dùng cùng lớp nền và lớp trước (lớp 108 dp, vùng an toàn 66 dp), có lớp monochrome cho biểu tượng theo chủ đề (Android 13+); hình dạng do Android cắt.

## Android

- Material Symbols Rounded (Apache 2.0) đóng gói trong app; weight 400, grade 0, 24 dp; vùng chạm 48 dp.
- FILL 0 mặc định; FILL 1 cho tab đang chọn (như fill của iOS), nút tròn cuộc gọi và nút nổi.
- Màu lấy từ token (`label`, `secondary-label`, `accent`). Biểu tượng nhỏ của thông báo là hình đơn sắc, do Android tô màu.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Biểu tượng chuẩn cho sao chép, dán, xóa | Tự vẽ biểu tượng cho hành động đã có chuẩn |
| Symbol template trên thanh menu | Biểu tượng màu trên thanh menu |
| Viết chữ "Bluetooth" | Logo Bluetooth tự vẽ |
| Lửa hiệu trong biểu tượng app | SF Symbol trong biểu tượng app hay logo |
