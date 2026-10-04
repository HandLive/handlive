[English](11-thuong-hieu.md) | Tiếng Việt

# Thương hiệu

Thương hiệu HandLive nằm ở lớp nội dung: màn chào, màn ghép nối, trạng thái trống, biểu tượng app và
logo HandLive. Control, trạng thái và thanh điều hướng giữ diện mạo của hệ thống. Mục này nói thương
hiệu xuất hiện thế nào trong app: bảng màu, chữ và các giới hạn. Câu chuyện, giọng văn, thông điệp, file
logo và ảnh quảng bá nằm trong [hướng dẫn thương hiệu](../../brand-guidelines.vi.md).

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/branding

## Câu chuyện

Điều xảy ra trên điện thoại hiện lên màn hình trước mặt bạn. Logo vẽ điều đó thành ngọn lửa hiệu trên
đỉnh núi, trong màu bình minh: đỏ lửa, cam và hổ phách trên ngọn núi tím than và bầu trời màu kem. Tính cách: đáng tin, kín đáo, ấm. Theo HIG, thương hiệu nhường chỗ cho nội dung: không rải
logo, không trang trí thừa.

## Bảng màu

| Vai trò | Token | Sáng / Tối | Dùng cho |
|---|---|---|---|
| Nhận diện | `brand-fire` (đỏ lửa) | #e63d1a / #ff7448 | Tiêu đề thương hiệu cỡ lớn, biểu tượng app, màn chào |
| Mảng sâu | `brand-ember` (tím than) | #33232d / #6e5463 | Ngọn núi trong logo, khối lớn ở bìa, thay cho đen |
| Điểm sáng | `brand-flame` (cam lửa) | #ff861f / #ffa04a | Ngọn lửa và vòng sóng, gradient thương hiệu, minh họa; không làm màu chữ |
| Nền thương hiệu | `brand-glow` (kem bình minh) | #fff0e3 / #2b1e26 | Nền màn chào, màn ghép nối |
| Thao tác | `accent`, `accent-fill` (xanh lá) | #197934 / #3ddc6c | AccentColor: đèn xanh của tín hiệu đã nhận |
| Trung tính | Xám hệ thống | Theo hệ thống | Nền, chữ, viền |
| Nhấn phụ | `system-pink`, `system-purple`; ít dùng `system-yellow`, `system-brown` | Theo hệ thống | Ảnh đại diện chữ cái, minh họa |
| Không cho thương hiệu | Đen, `systemBlue`, `systemCyan`, `systemTeal`, `systemMint`, `systemIndigo` | — | Xanh dương là của hệ thống; mảng sâu dùng `brand-ember` thay cho đen |

Nền tối của hệ thống (đen trên iPhone, xám trên Mac) là của Apple; HandLive không thêm mảng đen hay
xanh dương nào của riêng mình, nên không bị nhìn như một tiện ích hệ thống. Mỗi màu thương hiệu có đủ 4
biến thể, kể cả hai bản tương phản cao (xem Màu sắc).

## Màu thương hiệu ở đâu

| Có | Không |
|---|---|
| `Onboarding`: màn chào nền `brand-glow`, tiêu đề `brand-large-title` | Nút, công tắc, `SegmentedControl`, liên kết |
| `PairingCard`: nền `brand-glow` quanh khung mã QR trắng | Chấm trạng thái, huy hiệu, chữ lỗi |
| Trạng thái trống: minh họa lửa hiệu | `MenuBarMenu`, `CallPanel`, thanh tab, `Notification` |
| Biểu tượng app, chữ HandLive (`wordmark`) | Cài đặt, danh sách tin nhắn |

- HIG: muốn thể hiện thương hiệu bằng màu thì đưa màu vào lớp nội dung, nơi nó cuộn bên dưới control
  kính và được kính "bắt" màu; không tô màu thương hiệu lên control.
- Đỏ lửa không dùng cho nút hay trạng thái, để không lẫn với màu hủy, xóa, lỗi (systemRed).
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

- Logo là ngọn lửa hiệu trên đỉnh núi; các file (biểu tượng, chữ HandLive, bộ ghép, biểu tượng app)
  nằm ở `docs/brand/assets/`, quy tắc dùng ở [hướng dẫn thương hiệu](../../brand-guidelines.vi.md).
- Trong app, logo chỉ có ở màn chào và cửa sổ Giới thiệu. Màn chào đặt logo phía trên tiêu đề có tên app
  (`HLBrandMark`, xem Onboarding); cửa sổ Giới thiệu trên Mac là bảng chuẩn, có biểu tượng app. Ở chỗ khác, tên
  app là chữ "HandLive" kiểu `wordmark` (Be Vietnam Pro Bold 20/24) màu `brand-fire` hoặc `label`. Không rải logo
  khắp app, không đặt logo trên thanh điều hướng.
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
| Tím than `brand-ember` thay cho đen | Nền đen hay xanh dương tự vẽ |
