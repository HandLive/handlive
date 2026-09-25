# Chế độ Tối và tương phản cao

HandLive chạy đúng ở bốn giao diện và luôn theo cài đặt của hệ thống. Mục này quy định nền, màu và
ảnh ở giao diện Tối, và cách kiểm cùng Tăng độ tương phản, Giảm độ trong suốt.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/dark-mode ·
https://developer.apple.com/design/human-interface-guidelines/accessibility

## Bốn giao diện

| Giao diện | Token | Bật khi | Apple | Android |
|---|---|---|---|---|
| Sáng | `light` | Mặc định | `colorScheme == .light` | `isSystemInDarkTheme()` = false |
| Tối | `dark` | Chế độ Tối hoặc Tự động | `colorScheme == .dark` | `isSystemInDarkTheme()` = true |
| Sáng · tương phản cao | `light-hc` | Tăng độ tương phản | `colorSchemeContrast == .increased` | `UiModeManager.getContrast()` ≥ 0.5 (Android 14+) |
| Tối · tương phản cao | `dark-hc` | Tối và Tăng độ tương phản | như trên | như trên |

- Không có công tắc giao diện riêng trong app, không có mục "Giao diện" trong Cài đặt của HandLive.
  Theo HIG, công tắc riêng bắt người dùng chỉnh nhiều nơi và dễ tưởng app bị lỗi.
- Chế độ Tự động đổi giao diện ngay khi app đang mở: không lưu màu đã quy đổi, luôn dùng màu động và
  token của giao diện hiện tại.
- AppKit đọc `NSApp.effectiveAppearance`; không đặt `NSApp.appearance`.

## Nền base và elevated

- iOS và iPadOS: nền Tối có hai bộ. Base tối hơn, lùi ra sau; elevated sáng hơn, nổi lên. Hệ thống
  tự đổi sang elevated cho sheet, popover và cửa sổ khi đa nhiệm nếu view dùng bộ
  `systemBackground`. HandLive không tự tô nền cho sheet.
- Android và preview không có elevated tự động: sheet và hộp thoại ở giao diện Tối lấy
  `secondary-system-background` làm nền nổi, phần tử bên trong dùng `tertiary-system-background`.
- macOS: nền cửa sổ `window-background` là xám, không đen; danh sách và bảng dùng
  `control-background`. Màu nhấn Graphite làm nền cửa sổ nhuốm màu hình nền.
- Giao diện Tối phân lớp bằng màu nền, không bằng bóng: `shadow-card` là `none` ở Tối. Kính nổi vẫn
  có `shadow-glass`.

| Lớp | Token | Tối | Tối · tương phản cao |
|---|---|---|---|
| Nền màn hình | `system-background` | #000000 | #000000 |
| Nhóm; nền nổi trên Android | `secondary-system-background` | #1c1c1e | #242426 |
| Lồng trong nhóm | `tertiary-system-background` | #2c2c2e | #363638 |
| Cửa sổ Mac | `window-background` | #282828 | #1c1c1c |
| Danh sách, bảng Mac | `control-background` | #1e1e1e | #141414 |

## Màu ở giao diện Tối

Màu Tối không phải màu Sáng đảo ngược: nền dịu hơn, chữ và màu sáng hơn. Mỗi token tự định nghĩa có
giá trị Tối riêng, ví dụ `accent` #197934 ở Sáng thành #3ddc6c ở Tối.

HIG: tương phản tối thiểu 4.5:1; màu tự định nghĩa nên nhắm 7:1, nhất là chữ nhỏ. Kết quả đo trên 7
nền: `system-background`, `secondary-system-background`, `tertiary-system-background`,
`system-grouped-background`, `secondary-system-grouped-background`, `window-background`,
`control-background`.

| Token | Tối | Tối · tương phản cao | Đạt 7:1 |
|---|---|---|---|
| `accent` | 7.7–11.7 | 7.5–13.0 | Có |
| `text-green` | 7.6–11.4 | 7.7–13.3 | Có |
| `text-orange` | 6.9–10.4 | 7.2–12.5 | Gần đạt (6.9 trên `tertiary-system-background`) |
| `text-red` | 4.7–7.2 | 5.4–9.4 | Chỉ trên nền đen |
| `brand-fire` | 5.0–7.5 | 5.2–9.1 | Không; chỉ cho chữ lớn |

- `text-red` đạt mức tối thiểu nhưng chưa đạt mức khuyến nghị: chỉ cho nhãn ngắn luôn kèm biểu tượng
  ("Gửi lỗi"), không cho đoạn văn.
- Chữ phụ trên Apple dùng `.secondary` của hệ thống; token `secondary-label` (5.3–6.4:1 ở Tối) chỉ
  cho Android và preview.

## Ảnh, mã QR và video

- Mã QR luôn đen trên trắng (`qr-ink` trên `qr-paper`) ở cả 4 giao diện, có vùng trắng quanh mã.
  Không đảo màu ở giao diện Tối: nhiều máy quét đọc kém mã đảo. Khung trắng chỉ rộng vừa mã
  (`size-qr`) để bớt chói.
- Khung camera (`CameraPreview`) và khung quét: nền `video-background` đen, chữ và biểu tượng
  `on-video` trắng ở mọi giao diện.
- Ảnh của người dùng (ảnh trên bảng nhớ tạm, ảnh đại diện) hiển thị nguyên bản. Minh họa của
  HandLive có bản Sáng và bản Tối; theo HIG, làm dịu nền trắng trong minh họa để không chói.
- SF Symbols tự đổi theo giao diện. Biểu tượng tự vẽ cần bản Sáng và bản Tối, thêm viền mảnh nếu
  hình tối chìm vào nền tối.
- Nền thương hiệu `brand-glow` đổi từ hồng đào (#fde9e2) sang nâu đỏ sẫm (#3b1a12), không dùng đen.

## Tăng độ tương phản và Giảm độ trong suốt

| Cài đặt | Hệ thống tự làm | HandLive làm thêm |
|---|---|---|
| Tăng độ tương phản | Màu hệ thống sang biến thể tương phản cao; viền control rõ hơn | Token lấy `light-hc`, `dark-hc`; `glass-stroke` và `separator` đậm hơn |
| Giảm độ trong suốt | Kính và material thành nền gần đục | Vật liệu tự dựng đọc `accessibilityReduceTransparency` (SwiftUI) hoặc `NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency`, rồi dùng nền đục `secondary-system-background` hoặc `window-background` |

`glass-fill` ở hai giao diện tương phản cao đã gần đục (92%), nên kính trên Android và preview trông
giống khi bật Giảm độ trong suốt.

## Ma trận kiểm thử

HIG yêu cầu kiểm giao diện Tối khi bật Tăng độ tương phản và Giảm độ trong suốt, riêng từng cái và
cùng lúc. Mỗi màn chính (`Onboarding`, `PairingCard`, `MenuBarMenu`, `CallPanel`, Tin nhắn, Cài đặt)
đi qua 4 giao diện × Giảm độ trong suốt tắt/bật = 8 tổ hợp.

| Tổ hợp | Kiểm gì |
|---|---|
| Sáng, Tối | Chữ phụ trên nền nhóm; kính trên hình nền sáng và tối; `text-red` ở Tối |
| Hai giao diện tương phản cao | Viền kính, đường phân cách, chấm trạng thái vẫn tách khỏi nền |
| Mỗi giao diện kèm Giảm độ trong suốt | Kính thành nền đục; chữ và nút vẫn đọc được |
| Chế độ Tự động | Đổi giao diện khi app đang mở: không màu nào kẹt ở giao diện cũ |
| Cửa sổ Mac không active | Mất vibrancy nhưng nội dung vẫn đọc được |

Công cụ: Environment Overrides trong Xcode (giao diện, tương phản, cỡ chữ) và Accessibility
Inspector; trên Android đổi Giao diện tối và mức tương phản của hệ thống rồi chụp so sánh.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Dùng màu động và token của giao diện hiện tại | Thêm công tắc Sáng/Tối trong app |
| Để hệ thống đổi nền base sang elevated | Tự tô đen cho sheet |
| Giữ mã QR đen trên trắng | Đảo màu mã QR ở giao diện Tối |
| Kiểm đủ 8 tổ hợp | Chỉ kiểm Sáng và Tối |
