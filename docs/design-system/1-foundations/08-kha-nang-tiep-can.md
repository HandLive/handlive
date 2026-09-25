# Khả năng tiếp cận

HandLive phải dùng được bằng VoiceOver, TalkBack, bàn phím, cỡ chữ lớn và mọi cài đặt hiển thị của hệ thống trên cả ba nền tảng. Mục này gồm kích thước control, tương phản đã kiểm, cách gắn nhãn và danh sách kiểm thử.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/accessibility · https://developer.apple.com/design/human-interface-guidelines/voiceover

## Kích thước control

| Nền tảng | Mặc định | Tối thiểu | Token |
|---|---|---|---|
| iOS, iPadOS | 44×44 pt | 28×28 pt | `size-hit-ios`, `size-hit-ios-min` |
| macOS | 28×28 pt | 20×20 pt | `size-hit-mac`, `size-hit-mac-min` |
| Android | 48×48 dp | 48×48 dp | `size-hit-android` |

Khoảng trống quanh control: ~12 pt với control có viền, ~24 pt với control không viền (`space-12`, `space-24`).

## Tương phản

| Nội dung | Tỉ lệ tối thiểu |
|---|---|
| Chữ đến 17 pt, mọi weight | 4.5:1 |
| Chữ từ 18 pt | 3:1 |
| Chữ đậm, mọi cỡ | 3:1 |
| Biểu tượng trên nền đặc (quy tắc HandLive) | 3:1 |

Accessibility Inspector đo theo WCAG mức AA. Ở giao diện Tối, màu tự định nghĩa nhắm 7:1 (xem Chế độ Tối và tương phản cao).

## Tương phản token đã kiểm

59 cặp × 4 giao diện = 236 phép đo, không cặp nào dưới ngưỡng. Màu có alpha được vẽ đè lên nền trước khi đo. Chữ được đo trên 7 nền: `system-background`, `secondary-system-background`, `tertiary-system-background`, `system-grouped-background`, `secondary-system-grouped-background`, `window-background`, `control-background`.

| Cặp | Thấp nhất | Ngưỡng |
|---|---|---|
| `label` trên mọi nền | 12.06:1 | 4.5 |
| `secondary-label` trên mọi nền | 4.69:1 | 4.5 |
| `accent` trên mọi nền | 4.65:1 | 4.5 |
| `text-red`, `text-orange`, `text-green` | 4.60, 4.68, 4.65:1 | 4.5 |
| `on-accent` trên `accent-fill` (cũng là `bubble-outgoing`) | 4.63:1 | 4.5 |
| `on-call-fill` trên `call-decline-fill` | 4.56:1 | 4.5 |
| `on-call-fill` trên `call-accept-fill` | 3.52:1 | 3 (biểu tượng) |
| `label` trên `bubble-incoming` | 13.14:1 | 4.5 |
| `accent` trên `accent-tint` | 4.64:1 | 3 (chữ từ 13 pt) |
| `brand-fire` trên `system-background`, `brand-glow` | 4.86, 4.15:1 | 3 (chữ lớn) |

Không đạt 4.5:1 ở giao diện Sáng nên không dùng làm chữ mang thông tin: `tertiary-label` (1.7:1), `system-green` (1.9–2.2:1), `system-orange` (2.0–2.3:1), `system-gray` (2.8–3.3:1), `system-red` (3.0–3.6:1).

## VoiceOver và TalkBack

Mọi control có nhãn. Nút chỉ có biểu tượng bắt buộc có nhãn, trên Mac có thêm tooltip:

| Biểu tượng | Nhãn |
|---|---|
| `phone.fill` | "Trả lời" |
| `phone.down.fill` | "Từ chối" khi đổ chuông, "Kết thúc" khi đang gọi |
| `mic.slash.fill` | "Tắt tiếng", kèm trạng thái đã chọn |
| `pause.fill` | "Giữ máy", kèm trạng thái đã chọn |
| `circle.grid.3x3.fill` | "Bàn phím số" |
| `arrow.triangle.2.circlepath.camera` | "Đổi camera" |
| `document.on.document` | "Gửi bảng nhớ tạm" |
| `xmark` | "Đóng" |

- Trạng thái đọc bằng chữ, không đọc màu: chấm trạng thái không có nhãn riêng mà gộp vào dòng. `DeviceRow` đọc "Pixel 8 của Lan, Đã kết nối qua cùng mạng Wi-Fi". Gộp bằng `.accessibilityElement(children: .combine)`; Compose `Modifier.semantics(mergeDescendants = true)`.
- Nút bật tắt (Tắt tiếng, Giữ máy) báo trạng thái bằng trait `.isSelected`; Compose `Modifier.toggleable`.
- Thời lượng "02:15" đọc thành "2 phút 15 giây" (`DateComponentsFormatter`, kiểu `.full`). Mã PIN đọc từng chữ số (`.speechSpellsOutCharacters()`).
- Mã QR có nhãn "Mã QR ghép nối" và luôn có đường thay thế: "Không quét được? Dùng mã PIN".
- Báo thay đổi mà không dời focus ("Đã kết nối", "Đã gửi", "Cuộc gọi đã kết thúc"): `AccessibilityNotification.Announcement` (iOS 17, macOS 14), `UIAccessibility.post(notification: .announcement, argument:)`, AppKit `NSAccessibility.post` với `.announcementRequested`, Compose `liveRegion = LiveRegionMode.Polite`.
- Ẩn hình trang trí (`.accessibilityHidden(true)`; Compose `contentDescription = null`). Tiêu đề mục mang trait heading (`.isHeader`; Compose `heading()`).

## Bàn phím trên Mac

- Truy cập bàn phím toàn phần: mọi control tới được bằng Tab; control tự dựng có vòng `focus-ring`, control hệ thống giữ vòng focus của hệ thống.
- Phím tắt chuẩn: ⌘, mở Cài đặt…, ⌘Q, ⌘W, ⌘M, ⌘F tìm trong Tin nhắn, Esc hủy sheet hoặc alert, Return chọn nút mặc định. Không ghi đè phím tắt hệ thống.
- Không gán phím tắt toàn cục cho Trả lời hay Từ chối, tránh bấm nhầm khi đang gõ.

## Cỡ chữ lớn

- iOS, iPadOS: Dynamic Type tới AX5, phóng được ít nhất 200%; ở cỡ trợ năng, dòng ngang chuyển thành xếp dọc.
- Android: font scale 200%, chữ tính bằng sp; kiểm Cỡ chữ và Kích thước hiển thị ở mức lớn nhất.
- macOS: không có Dynamic Type; chữ không nhỏ hơn 10 pt; sidebar theo cỡ người dùng chọn.

## Cài đặt hiển thị

| Cài đặt | SwiftUI | Android | HandLive làm |
|---|---|---|---|
| Phân biệt không dùng màu | `accessibilityDifferentiateWithoutColor` | Không có, luôn áp dụng | Chấm trạng thái thêm hình; nút cuộc gọi khác hình |
| Giảm chuyển động | `accessibilityReduceMotion` | `ANIMATOR_DURATION_SCALE` = 0 | Xem Chuyển động và xúc giác |
| Giảm độ trong suốt | `accessibilityReduceTransparency` | Không có | Kính thành nền đục |
| Tăng độ tương phản | `colorSchemeContrast` | `UiModeManager.getContrast()` | Bộ màu `-hc` |
| Chữ đậm | `legibilityWeight` | `Configuration.fontWeightAdjustment` | Font thương hiệu tăng weight |
| Chữ lớn hơn | `dynamicTypeSize` | `fontScale` | Bố cục xếp dọc |

AppKit đọc các cài đặt tương ứng qua `NSWorkspace.shared.accessibilityDisplayShould…`.

## Kiểm thử

1. Accessibility Inspector: chạy Audit trên mọi màn Mac và iOS; sửa hết lỗi tương phản, thiếu nhãn, vùng chạm nhỏ.
2. VoiceOver, không nhìn màn hình: đi hết `Onboarding`, ghép nối bằng mã PIN, trả lời và kết thúc cuộc gọi trên `CallPanel`, gửi bảng nhớ tạm, đọc và trả lời tin nhắn.
3. Truy cập bàn phím toàn phần: làm xong Cài đặt và Tin nhắn trên Mac không dùng chuột.
4. AX5 (iOS) và 200% (Android): không cắt dấu, không chồng chữ, không mất nút.
5. Bốn giao diện, mỗi giao diện bật và tắt Giảm độ trong suốt; bật Giảm chuyển động.
6. Android: TalkBack cho các luồng ở bước 2; Accessibility Scanner trên mọi màn.
7. Khai báo Accessibility Nutrition Labels trên App Store đúng mức đã kiểm.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Nhãn cho mọi nút chỉ có biểu tượng | Để VoiceOver đọc tên symbol |
| Đọc trạng thái bằng chữ | Chỉ đổi màu chấm |
| Đọc thời lượng thành phút và giây | Để "02:15" bị đọc như giờ |
| Kiểm bằng VoiceOver và TalkBack thật | Chỉ dựa vào công cụ tự động |
