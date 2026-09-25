# Thương hiệu

Thương hiệu HandLive nằm ở lớp nội dung: màn chào, màn ghép nối, trạng thái trống, biểu tượng app và
chữ HandLive. Control, trạng thái và thanh điều hướng giữ diện mạo của hệ thống. Mục này gồm câu
chuyện, bảng màu, chữ và các giới hạn.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/branding

## Câu chuyện

Bảng màu chọn theo phong thủy mệnh Sơn Đầu Hỏa, lửa trên đỉnh núi. Người xưa đốt lửa hiệu trên đỉnh
núi để truyền tin từ trạm này sang trạm khác; HandLive làm việc tương tự giữa điện thoại và máy
tính. Tính cách: đáng tin, kín đáo, ấm. Theo HIG, thương hiệu nhường chỗ cho nội dung: không rải
logo, không trang trí thừa.

## Bảng màu

| Vai trò | Token | Sáng / Tối | Ngũ hành | Dùng cho |
|---|---|---|---|---|
| Nhận diện | `brand-fire` (đỏ son) | #d2381f / #ff6b4a | Hỏa, màu bản mệnh | Chữ HandLive, biểu tượng app, màn chào |
| Mảng sâu | `brand-ember` (đỏ than) | #8a2210 / #b43a20 | Hỏa | Khối lớn ở bìa, lớp nền biểu tượng app, thay cho đen |
| Điểm sáng | `brand-flame` (cam lửa) | #f07a1a / #ff9a3d | Hỏa | Gradient thương hiệu, minh họa; không làm màu chữ |
| Nền thương hiệu | `brand-glow` (hồng đào) | #fde9e2 / #3b1a12 | Hỏa | Nền màn chào, màn ghép nối |
| Thao tác | `accent`, `accent-fill` (xanh lá) | #197934 / #3ddc6c | Mộc sinh Hỏa, tương sinh | AccentColor |
| Trung tính | Xám hệ thống | Theo hệ thống | Kim; Hỏa khắc Kim, dùng được | Nền, chữ, viền |
| Nhấn phụ | `system-pink`, `system-purple`; ít dùng `system-yellow`, `system-brown` | Theo hệ thống | Hỏa; Thổ | Ảnh đại diện chữ cái, minh họa |
| Không dùng | Đen, `systemBlue`, `systemCyan`, `systemTeal`, `systemMint`, `systemIndigo` | — | Thủy khắc Hỏa | Không cho thương hiệu hay mảng màu lớn |

Nền tối của hệ thống (đen trên iPhone, xám trên Mac) là của Apple; HandLive không thêm mảng đen hay
xanh dương nào của riêng mình. Mỗi màu thương hiệu có đủ 4 biến thể, kể cả hai bản tương phản cao
(xem Màu sắc).

## Màu thương hiệu ở đâu

| Có | Không |
|---|---|
| `Onboarding`: màn chào nền `brand-glow`, tiêu đề `brand-large-title` | Nút, công tắc, `SegmentedControl`, liên kết |
| `PairingCard`: nền `brand-glow` quanh khung mã QR trắng | Chấm trạng thái, huy hiệu, chữ lỗi |
| Trạng thái trống: minh họa lửa hiệu | `MenuBarMenu`, `CallPanel`, thanh tab, `Notification` |
| Biểu tượng app, chữ HandLive (`wordmark`) | Cài đặt, danh sách tin nhắn |

- HIG: muốn thể hiện thương hiệu bằng màu thì đưa màu vào lớp nội dung, nơi nó cuộn bên dưới control
  kính và được kính "bắt" màu; không tô màu thương hiệu lên control.
- Đỏ son không dùng cho nút hay trạng thái, để không lẫn với màu hủy, xóa, lỗi (systemRed).
- Mỗi màn tối đa một khoảnh khắc thương hiệu.

## Màu nhấn trên control

Theo HIG, màu nhấn dùng tiết chế trên control:

- Nút chính: một nút tô `accent-fill` mỗi màn, tối đa hai.
- Chỉ báo trạng thái: dấu chưa đọc `unread`, biểu tượng tab đang chọn, bong bóng tin mình gửi
  `bubble-outgoing`, liên kết.
- Trên kính: tô nền của một hành động chính, không tô chữ hay symbol.
- Công tắc iOS giữ xanh lá mặc định của hệ thống.
- Mac: người dùng chọn màu nhấn khác Nhiều màu thì control theo màu đó; nhận diện thương hiệu không
  phụ thuộc màu nhấn.

## Chữ thương hiệu

- Be Vietnam Pro (OFL), thiết kế cho tiếng Việt, dấu rõ ở cỡ lớn; đóng gói trong app trên cả Apple
  và Android.
- Chỉ cho `brand-large-title`, `brand-title`, `wordmark`; phóng theo Dynamic Type và hỗ trợ Chữ đậm
  (xem Kiểu chữ). Chữ thân, nút và nhãn control dùng font hệ thống.

## Logo và chữ HandLive

- Chưa có logo. Cho tới khi có, dùng chữ "HandLive" kiểu `wordmark` (Be Vietnam Pro Bold 20/24), màu
  `brand-fire` hoặc `label`.
- Wordmark chỉ ở màn chào và cửa sổ Giới thiệu; không rải logo khắp app, không đặt trên thanh điều
  hướng.
- Không dùng SF Symbols, font San Francisco hay hình dễ lẫn với symbol trong logo và biểu tượng app:
  giấy phép của Apple không cho phép.

## Màn khởi động

- Không làm thương hiệu trên launch screen. iOS: launch screen giống màn đầu tiên của app, không
  chữ, không logo. macOS không có launch screen.
- Android 12+: màn khởi động của hệ thống (biểu tượng app trên nền), không thêm splash riêng.
- Khoảnh khắc thương hiệu đặt ở `Onboarding`: màn chào nền `brand-glow`, tiêu đề
  `brand-large-title`.

## Nhãn hiệu của Apple

- Tên app là "HandLive"; không ghép nhãn hiệu Apple vào tên app hay biểu tượng app. Mô tả trên store
  dùng "cho Mac", "cho iPhone và iPad". Tên nội bộ "HandLive for Mac", "HandLive for iOS/iPadOS"
  trong tài liệu chi tiết không dùng làm tên hiển thị.
- Viết đúng: iPhone, iPad, Mac, macOS, iOS, iPadOS, Liquid Glass; không "IPhone", "MacOS",
  "Macbook".
- Không vẽ phần cứng Apple trong minh họa; cần hình thiết bị thì dùng SF Symbol sản phẩm, chỉ trên
  nền tảng Apple.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Màu thương hiệu ở màn chào, màn ghép nối | Nút chính màu `brand-fire` |
| Chữ HandLive bằng `wordmark` | Logo ghép từ SF Symbol |
| Màn chào trong `Onboarding` | Logo trên launch screen |
| Đỏ than thay cho đen | Nền đen hay xanh dương tự vẽ |
