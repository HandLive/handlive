# Màu sắc

HandLive dùng màu ngữ nghĩa của hệ thống cho chữ, nền và đường phân cách; màu hệ thống cho trạng thái; xanh lá làm màu nhấn cho thao tác; màu thương hiệu chỉ ở lớp nội dung. Mục này nói token nào ứng với API nào và màu nào dùng ở đâu.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/color

## Nguyên tắc

- Mỗi màu một nghĩa. Xanh lá `accent` là thao tác; xanh lá `status-connected` là trạng thái và luôn đi kèm chữ.
- Không hard-code màu hệ thống trên Apple. Luôn gọi API (`Color(.label)`, `NSColor.windowBackgroundColor`…): Apple đã đổi giá trị màu hệ thống ngày 9/6/2025 và có thể đổi tiếp. Hex trong token chỉ là tham chiếu cho Android và preview.
- Màu tự định nghĩa có đủ 4 biến thể `light`, `dark`, `light-hc`, `dark-hc`. Trên Apple khai báo bằng Color Set trong asset catalog, bật biến thể High Contrast.
- Không đổi nghĩa màu ngữ nghĩa: không lấy `separator` làm màu chữ, không lấy `secondary-label` làm nền.

## Màu ngữ nghĩa và API

| Token | SwiftUI | UIKit | AppKit | Dùng cho |
|---|---|---|---|---|
| `label` | `.primary` | `.label` | `.labelColor` | Chữ chính |
| `secondary-label` | `.secondary` | `.secondaryLabel` | `.secondaryLabelColor` | Chữ phụ |
| `tertiary-label` | `.tertiary` | `.tertiaryLabel` | `.tertiaryLabelColor` | Gợi ý, mục không khả dụng |
| `quaternary-label` | `.quaternary` | `.quaternaryLabel` | `.quaternaryLabelColor` | Trang trí |
| `placeholder-text` | `Color(.placeholderText)` | `.placeholderText` | `.placeholderTextColor` | Chữ giữ chỗ |
| `system-background`, `secondary-`, `tertiary-system-background` | `Color(.systemBackground)` … | `.systemBackground` … | — | Nền màn hình iOS, nhóm, nhóm lồng |
| `system-grouped-background`, `secondary-`, `tertiary-system-grouped-background` | `Color(.systemGroupedBackground)` … | `.systemGroupedBackground` … | — | Nền danh sách nhóm, ô, phần tử trong ô |
| `window-background` | `Color(nsColor: .windowBackgroundColor)` | — | `.windowBackgroundColor` | Nền cửa sổ Mac |
| `control-background` | `Color(nsColor: .controlBackgroundColor)` | — | `.controlBackgroundColor` | Nền danh sách, bảng Mac |
| `system-fill` … `quaternary-system-fill` | `Color(.systemFill)` … | `.systemFill` … | `.systemFill` … (macOS 14+) | Rãnh công tắc, ô nhập |
| `separator` | `Color(.separator)` | `.separator` | `.separatorColor` | Đường phân cách nhìn xuyên |
| `opaque-separator` | `Color(.opaqueSeparator)` | `.opaqueSeparator` | — | Đường phân cách đặc |
| `link` | `Color.accentColor` | `tintColor` | `.controlAccentColor` | Liên kết, bằng `accent` |

## Màu hệ thống HandLive dùng

| Token | API | Dùng cho |
|---|---|---|
| `system-red` | `.red` · `systemRed` | Từ chối, Kết thúc, xóa, lỗi; `badge` |
| `system-orange` | `.orange` · `systemOrange` | Đang kết nối, cần chú ý |
| `system-green` | `.green` · `systemGreen` | Đã kết nối; công tắc bật (mặc định của iOS) |
| `system-yellow` | `.yellow` · `systemYellow` | Hiếm (Hỏa sinh Thổ), chỉ trong minh họa |
| `system-pink`, `system-purple` | `.pink`, `.purple` | Avatar chữ cái, minh họa (Hỏa) |
| `system-brown` | `.brown` | Avatar chữ cái, dùng ít (Thổ) |
| `system-gray` … `system-gray-6` | `.gray` · `systemGray` … `systemGray6` | Ngoại tuyến, viền, nền nhóm |

- AppKit chỉ có `systemGray`; Gray 2–6 là của iOS. Trên Mac dùng màu ngữ nghĩa (`separatorColor`, `controlBackgroundColor`) ở chỗ iOS dùng Gray 2–6.
- Không dùng (Thủy khắc Hỏa): `systemBlue`, `systemCyan`, `systemTeal`, `systemMint`, `systemIndigo` — không cho thương hiệu, mảng màu lớn, trạng thái hay avatar. Phần hệ thống vẽ theo lựa chọn của người dùng (màu nhấn, vùng chọn chữ) để nguyên.

## Màu nhấn

| Token | Dùng cho |
|---|---|
| `accent` | Liên kết, biểu tượng đang chọn, `unread`, `focus-ring`. Chữ đạt 4.5:1 trên mọi nền |
| `accent-fill` | Nền nút chính, `bubble-outgoing` |
| `on-accent` | Chữ và biểu tượng trên `accent-fill` |
| `accent-tint` | Nền nhạt vùng chọn. Không đặt chữ `accent` dưới 13 pt lên nền này |

- Apple: AccentColor khai báo trong asset catalog (4 biến thể), control hệ thống tự lấy; control tự dựng dùng `Color.accentColor` hoặc `NSColor.controlAccentColor`.
- Tiết chế: mỗi màn một nút tô màu, tối đa hai. Phân biệt mức ưu tiên bằng kiểu nút, không bằng cỡ.
- macOS: màu nhấn của app chỉ hiện khi người dùng để Màu nhấn là Nhiều màu (Cài đặt hệ thống › Giao diện). Người dùng chọn màu khác thì control theo màu đó; HandLive không ép xanh lá. Màu mang nghĩa cố định (trạng thái, nút cuộc gọi) không đổi theo. Chọn Graphite thì nền cửa sổ nhuốm màu hình nền; control tự dựng ở trạng thái trung tính nên hơi trong suốt.
- Liquid Glass: chỉ tô nền của một hành động chính trên lớp kính (`.buttonStyle(.glassProminent)`, `Glass.tint(_:)`); không tô chữ hay biểu tượng trên kính; không tô nhiều control cùng lúc. Chấm trạng thái trên kính được phép.
- Lệch có chủ đích: liên kết dùng `accent` thay màu `link` xanh dương của hệ thống (Thủy khắc Hỏa); liên kết luôn nằm trong ngữ cảnh rõ ràng, không chỉ dựa vào màu.

## Trạng thái

| Trạng thái | Chấm, biểu tượng | Chữ màu cỡ nhỏ | Chữ đi kèm |
|---|---|---|---|
| Đã kết nối | `status-connected` (systemGreen) | `text-green` | "Đã kết nối" |
| Đang kết nối, cần chú ý | `status-connecting` (systemOrange) | `text-orange` | "Đang kết nối…" |
| Ngoại tuyến | `status-offline` (systemGray) | `secondary-label` | "Ngoại tuyến" |
| Lỗi | `status-error` (systemRed) | `text-red` | "Cần ghép nối lại" |

- systemGreen và systemOrange ở giao diện Sáng chỉ đạt 1.9–2.3:1 trên nền trắng hoặc xám: chỉ dùng cho chấm và biểu tượng. Chữ màu cỡ nhỏ dùng `text-red`, `text-orange`, `text-green` (≥ 4.5:1 trên mọi nền, cả 4 giao diện).
- Chữ trạng thái mặc định vẫn là `label` hoặc `secondary-label`; chỉ tô màu khi màu thêm nghĩa, ví dụ lý do tính năng chưa dùng được viết bằng `text-orange`.
- `destructive-text` (= `text-red`) cho nút phá hủy dạng chữ. `badge` (= `system-red`) cho huy hiệu số: dùng API badge của hệ thống, không tự vẽ.

## Nút cuộc gọi

| Token | Nút | Ghi chú |
|---|---|---|
| `call-accept-fill` | Trả lời | Đậm hơn systemGreen để biểu tượng trắng đạt ≥ 3:1 (systemGreen chỉ 2.2:1) |
| `call-decline-fill` | Từ chối, Kết thúc, nút phá hủy dạng đặc | Chữ trắng ≥ 4.5:1 |
| `on-call-fill` | Biểu tượng và chữ trên hai nền trên | Trắng |

Luôn kèm biểu tượng khác hình (`phone.fill`, `phone.down.fill`), vị trí cố định (Từ chối bên trái, Trả lời bên phải) và nhãn chữ dưới nút.

## Đỏ, xanh lá và mù màu

- Người mù màu khó phân biệt đỏ với xanh lá. Mọi cặp đỏ–xanh lá của HandLive phải khác nhau ở cả ba lớp: biểu tượng, vị trí, chữ.
- Khi bật Phân biệt không dùng màu (Differentiate Without Color), chấm trạng thái đổi thành biểu tượng có hình, ví dụ `checkmark.circle.fill`, `exclamationmark.triangle.fill`. Android không có cài đặt này nên luôn hiện chữ trạng thái.

## Tương phản cao

Màu hệ thống tự đổi sang biến thể tương phản cao; màu tự định nghĩa lấy `light-hc`, `dark-hc`. Cách đọc cài đặt và kiểm thử: xem mục Chế độ Tối và tương phản cao.

## Android dùng token

- Token là nguồn màu duy nhất: sinh bốn bảng màu Compose (`light`, `dark`, `light-hc`, `dark-hc`), chọn theo `isSystemInDarkTheme()` và `UiModeManager.getContrast()` (Android 14+, ≥ 0.5 thì dùng bộ `-hc`).
- Không dùng màu động (Material You) hay bảng màu Material.
- Màu có alpha (`separator`, `system-fill`, `glass-fill`…) vẽ đè lên nền của đúng lớp, không quy đổi thành màu đặc.
- `secondary-label` bản token đậm hơn giá trị gốc của Apple (75% thay 60% ở Sáng) để đạt 4.5:1; trên Apple vẫn dùng `.secondary` của hệ thống.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Gọi API màu ngữ nghĩa trên Apple | Chép hex `#FF383C` vào code Swift |
| Tô màu một nút chính mỗi màn | Tô `accent-fill` cho mọi nút |
| Chữ màu cỡ nhỏ dùng `text-*` | Chữ nhỏ màu `system-green`, `system-orange` |
| Đỏ son chỉ ở lớp nội dung | Nút hay trạng thái màu `brand-fire` |
