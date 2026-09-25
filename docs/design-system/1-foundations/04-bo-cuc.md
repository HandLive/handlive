# Bố cục

Mục này quy định khoảng cách, lề, bố cục theo size class, góc bo, vùng chạm và quy tắc riêng của cửa
sổ Mac. Trên Apple, lề và vùng an toàn lấy từ hệ thống; token là giá trị cho view tự dựng, preview
và Android.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/layout

## Khoảng cách

Lưới 4 pt (dp trên Android).

| Token | Giá trị | Dùng cho |
|---|---|---|
| `space-4` | 4 | Khe giữa biểu tượng và chữ nhỏ |
| `space-8` | 8 | Khe giữa các phần tử trong một dòng |
| `space-12` | 12 | Đệm quanh control có viền (HIG: ~12 pt) |
| `space-16` | 16 | Đệm trong thẻ, khe giữa các dòng nội dung |
| `space-20` | 20 | Lề nội dung cửa sổ Mac, khe giữa các nhóm cài đặt |
| `space-24` | 24 | Đệm quanh control không viền (HIG: ~24 pt), khe giữa hai nút tròn cuộc gọi |
| `space-32` | 32 | Khe giữa các khối lớn trên màn chào |
| `space-40` | 40 | Lề trên của tiêu đề màn chào |
| `margin-compact` | 16 | Lề màn hình iPhone và điện thoại Android |
| `margin-regular` | 20 | Lề màn hình iPad, cửa sổ rộng |

## Lề hệ thống

HIG bản 9/9/2026 không còn bảng lề. Trên Apple, lề đọc từ hệ thống, không cộng số cố định:

- UIKit: `layoutMargins`, `directionalLayoutMargins`, `readableContentGuide` (giới hạn bề rộng đoạn
  văn trên iPad).
- SwiftUI: `.padding()` mặc định, `.scenePadding()`; `List` và `Form` tự lề; `.safeAreaInset(edge:)`
  cho thanh tự dựng.
- macOS: `Form` với `.formStyle(.grouped)` tự lề; view tự dựng cách mép cửa sổ `space-20`.
- Android: `margin-compact` khi bề rộng dưới 600 dp, `margin-regular` từ 600 dp, cộng thêm
  `WindowInsets.safeDrawing`.

## Size class

Bố cục theo size class, không theo loại thiết bị hay hướng xoay. Đổi size class chỉ đổi lượng nội
dung hiển thị, không bớt chức năng. Không đặt bề rộng cố định.

| Nơi hiển thị | Chiều ngang | HandLive |
|---|---|---|
| iPhone | Compact (máy lớn xoay ngang: Regular) | Thanh tab 4 tab; danh sách một cột; Tin nhắn đẩy sang màn hội thoại |
| iPad toàn màn hình, cửa sổ rộng | Regular | Tin nhắn dùng `NavigationSplitView` (danh sách + hội thoại) |
| iPad chia đôi, cửa sổ hẹp | Compact | Như iPhone |
| iPhone Duo, màn ngoài | Compact | Như iPhone; hệ thống đưa thanh tab, toolbar ra cạnh dọc |
| iPhone Duo, màn trong | Regular | Như iPad: Tin nhắn hai cột |
| Android dưới 600 dp / từ 600 dp | `WindowSizeClass` Compact / Medium, Expanded | Như iPhone / như iPad |

- iPhone Duo: component hệ thống tự tránh vùng camera và nếp gập (reserved regions); chỉ view tự
  dựng mới cần `ReservedRegion` (iOS 27.1). Mỗi mục toolbar có cả chữ và symbol. Xem trước bằng
  Device Hub trong Xcode.
- Ở cỡ chữ trợ năng, bố cục ngang chuyển sang xếp dọc và giảm số cột.

## Góc bo đồng tâm

Góc bên trong đồng tâm với góc bên ngoài: bán kính trong = bán kính ngoài − khoảng đệm. Ví dụ thẻ
trong sheet: `radius-sheet` 26 − `space-12` = 14 = `radius-card`.

- macOS 26, iOS 26 trở lên: control, sheet, popover, cửa sổ lấy góc đồng tâm của hệ thống. View tự
  dựng dùng `ConcentricRectangle`, `.containerShape(_:)`, `rect(corners:isUniform:)` (SwiftUI) hoặc
  `cornerConfiguration` (UIKit), không đặt bán kính bằng số.
- macOS 13–15, iOS 16–18 và Android dùng token:

| Token | Giá trị | Dùng cho |
|---|---|---|
| `radius-control-mac` | 6 | Nút push, ô nhập trên macOS 13–15 |
| `radius-row` | 10 | Nhóm danh sách inset (iOS 16–18), vùng chọn trong sidebar |
| `radius-card` | 14 | Thẻ ở lớp nội dung, alert iOS 16–18 |
| `radius-panel` | 18 | Menu, popover, thông báo, `CallPanel` |
| `radius-sheet` | 26 | Sheet; nhóm danh sách và cửa sổ Mac từ bản 26 |
| `radius-capsule` | 999 | Nút capsule, công tắc, huy hiệu, thanh tab nổi |

## Vùng chạm

| Nền tảng | Mặc định | Tối thiểu | Token |
|---|---|---|---|
| iOS, iPadOS | 44×44 pt | 28×28 pt | `size-hit-ios`, `size-hit-ios-min` |
| macOS | 28×28 pt | 20×20 pt | `size-hit-mac`, `size-hit-mac-min` |
| Android | 48×48 dp | 48×48 dp | `size-hit-android` |

- Biểu tượng nhỏ hơn vùng chạm thì nới vùng chạm, không phóng biểu tượng: SwiftUI
  `.frame(minWidth:minHeight:)` với `.contentShape(Rectangle())`; Compose
  `Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)`.
- Đệm quanh control, đo từ mép nhìn thấy: ~12 pt với control có viền (`space-12`), ~24 pt với
  control không viền (`space-24`).
- Nút tròn cuộc gọi `size-call-button` 48, cách nhau `space-24`.

## Cửa sổ macOS

- Không đặt control hay thông tin quan trọng ở đáy cửa sổ: người dùng hay kéo cửa sổ lệch khỏi mép
  dưới màn hình. Thanh dưới chỉ chứa thông tin phụ; nút soạn tin đặt trên toolbar, không ở đáy
  sidebar.
- Không tự vẽ khung cửa sổ, thanh tiêu đề hay nút điều khiển cửa sổ; không đặt nội dung dưới vùng
  camera (notch).
- Tiêu đề cửa sổ dưới 15 ký tự, không lấy tên app làm tiêu đề. Cửa sổ Settings đổi tiêu đề và kích
  thước theo pane.
- Thanh menu cao 24 pt (`size-menu-bar`). Biểu tượng HandLive có thể bị notch hoặc thanh menu chật
  che mất, nên luôn có đường vào khác: mở lại app thì hiện cửa sổ chính.
- Split view: đường chia mỏng 1 pt.

## Bề rộng HandLive dùng

Không phải số của HIG; là giá trị HandLive chọn để các nền tảng và preview khớp nhau.

| Thành phần | Bề rộng | Ghi chú |
|---|---|---|
| `MenuBarMenu` | Hệ thống tự tính (preview 280 pt) | Nhãn ngắn; tên thiết bị dài cắt ở giữa |
| `CallPanel`, `Notification` | 340 pt | Cao theo nội dung; không đổi bề rộng khi đổi trạng thái cuộc gọi |
| `Alert` trên macOS | Hệ thống tự tính (preview 260 pt) | — |
| Popover | Vừa nội dung | Chỉ thông tin ngắn, không dùng để cảnh báo |
| `PairingCard` | Mã QR `size-qr` 220 pt | Có vùng trắng quanh mã |
| `MessageBubble` | Tối đa 76% khung hội thoại | — |
| Ảnh đại diện | `size-avatar` 40 (Mac 32) | — |

## Vùng an toàn

- iOS và iPadOS: nền kéo dài dưới thanh tab và toolbar kính; nội dung để đọc và chạm nằm trong safe
  area. `ignoresSafeArea` chỉ dùng cho nền.
- Android: edge-to-edge (`enableEdgeToEdge()`), đệm theo `WindowInsets.safeDrawing`; không đặt
  control trong vùng cử chỉ quay lại ở hai mép (`WindowInsets.systemGestures`). Thanh trạng thái và
  thanh điều hướng do Android quản lý.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Đọc lề và safe area từ hệ thống | Cộng lề 16 pt cố định trên iOS |
| Bố cục theo size class | Rẽ nhánh theo tên thiết bị |
| Góc trong đồng tâm với góc ngoài | Cùng bán kính cho thẻ lồng trong sheet |
| Nút quan trọng trong thân cửa sổ | Nút quan trọng ở đáy cửa sổ Mac |
