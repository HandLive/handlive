# Kiểu chữ

HandLive dùng San Francisco qua text style của hệ thống trên Mac, iPhone và iPad; Inter với cùng thang cỡ trên Android; Be Vietnam Pro chỉ cho tiêu đề thương hiệu. Mục này gồm bảng cỡ chữ, cỡ tối thiểu và quy tắc cho chữ tiếng Việt.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/typography

## Font theo nền tảng

| Dùng cho | macOS, iOS, iPadOS | Android |
|---|---|---|
| Giao diện | SF Pro, gọi qua text style; không nhúng file font | Inter, đóng gói trong app (OFL) |
| Mã, số | SF Mono (`design: .monospaced`) | Roboto Mono |
| Tiêu đề thương hiệu | Be Vietnam Pro, đóng gói trong app | Be Vietnam Pro |

SF Pro và SF Mono chỉ dùng trên nền tảng Apple theo giấy phép của Apple: không nhúng vào app Android, không dùng trong logo.

## macOS: bảng cỡ cố định

macOS không có Dynamic Type; cỡ chữ theo bảng dưới.

| Token | Text style | Cỡ/dòng (pt) | Weight | Nhấn mạnh |
|---|---|---|---|---|
| `mac-large-title` | Large Title `.largeTitle` | 26/32 | Regular | Bold |
| `mac-title-1` | Title 1 `.title` | 22/26 | Regular | Bold |
| `mac-title-2` | Title 2 `.title2` | 17/22 | Regular | Bold |
| `mac-title-3` | Title 3 `.title3` | 15/20 | Regular | Semibold |
| `mac-headline` | Headline `.headline` | 13/16 | Bold | Heavy |
| `mac-body` | Body `.body` | 13/16 | Regular | Semibold |
| `mac-callout` | Callout `.callout` | 12/15 | Regular | Semibold |
| `mac-subheadline` | Subheadline `.subheadline` | 11/14 | Regular | Semibold |
| `mac-footnote` | Footnote `.footnote` | 10/13 | Regular | Semibold |
| `mac-caption-1` | Caption 1 `.caption` | 10/13 | Regular | Medium |
| `mac-caption-2` | Caption 2 `.caption2` | 10/13 | Medium | Semibold |

Chữ trong control (nút, menu, ô nhập) để control tự chọn font; chỉ đặt text style cho chữ nội dung.

## iOS và iPadOS: Dynamic Type

Cỡ mặc định (Large). Android dùng token `android-*` cùng tên đuôi (`ios-body` ↔ `android-body`), cùng cỡ, dòng và weight, tính bằng sp.

| Token | Text style | Cỡ/dòng (pt) | Weight | Nhấn mạnh |
|---|---|---|---|---|
| `ios-large-title` | `.largeTitle` | 34/41 | Regular | Bold |
| `ios-title-1` | `.title` | 28/34 | Regular | Bold |
| `ios-title-2` | `.title2` | 22/28 | Regular | Bold |
| `ios-title-3` | `.title3` | 20/25 | Regular | Semibold |
| `ios-headline` | `.headline` | 17/22 | Semibold | Semibold |
| `ios-body` | `.body` | 17/22 | Regular | Semibold |
| `ios-callout` | `.callout` | 16/21 | Regular | Semibold |
| `ios-subheadline` | `.subheadline` | 15/20 | Regular | Semibold |
| `ios-footnote` | `.footnote` | 13/18 | Regular | Semibold |
| `ios-caption-1` | `.caption` | 12/16 | Regular | Semibold |
| `ios-caption-2` | `.caption2` | 11/13 | Regular | Semibold |

Tracking: SF tự chỉnh theo cỡ. Token `android-*` dùng tracking động của Inter (Body −0.013 em thay −0.026 em của SF).

Trường phụ của kiểu chữ — `relativeTo` (phóng theo Dynamic Type), `emphasisWeight` (cột Nhấn mạnh), `fontFeatures` (như `tnum` của `timer`) — nằm trong `shared/design-tokens/type-extras.json`, tách khỏi `tokens.json` để giữ định dạng của artifact; bộ sinh mã đọc cả hai.

## Body từ xSmall đến AX5

| xSmall | Small | Medium | Large | xLarge | xxLarge | xxxLarge | AX1 | AX2 | AX3 | AX4 | AX5 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 14/19 | 15/20 | 16/21 | 17/22 | 19/24 | 21/26 | 23/29 | 28/34 | 33/40 | 40/48 | 47/56 | 53/62 |

- Layout chịu được mọi cỡ, kể cả AX1–AX5 (Cỡ chữ lớn hơn trong Trợ năng). Ở cỡ trợ năng (`dynamicTypeSize.isAccessibilitySize`), dòng có biểu tượng, chữ và giá trị chuyển sang xếp dọc.
- HIG yêu cầu phóng được ít nhất 200%. Android: font scale đến 200% (Android 14 phóng phi tuyến); cỡ chữ và line height đều tính bằng sp.
- Biểu tượng mang nghĩa phóng theo chữ; SF Symbols tự phóng khi đặt cùng text style.

## Cỡ tối thiểu và weight

| Nền tảng | Mặc định | Tối thiểu |
|---|---|---|
| iOS, iPadOS | 17 pt | 11 pt |
| macOS | 13 pt | 10 pt |
| Android | 17 sp | 11 sp |

- Không dùng Ultralight, Thin, Light, nhất là ở cỡ nhỏ. Dùng Regular, Medium, Semibold, Bold; Heavy chỉ là mức nhấn của Headline trên macOS.
- Nhấn mạnh theo cột "Nhấn mạnh": SwiftUI `.bold()` hoặc `.fontWeight(_:)`, UIKit `traitBold`.
- Thứ bậc bằng weight, cỡ và màu (`label`, `secondary-label`); không thêm typeface nào ngoài font hệ thống và Be Vietnam Pro.

## Chữ thương hiệu

| Token | Cỡ/dòng | Weight | Phóng theo | Dùng cho |
|---|---|---|---|---|
| `brand-large-title` | 34/41 | Bold | `.largeTitle` | Tiêu đề màn chào, màn ghép nối; tối đa một lần mỗi màn |
| `brand-title` | 22/28 | Semibold | `.title2` | Tiêu đề trạng thái trống, bước `Onboarding` |
| `wordmark` | 20/24 | Bold | `.title3` | Chữ HandLive thay logo, màu `brand-fire` hoặc `label` |

- Phóng theo Dynamic Type: `Font.custom("BeVietnamPro-Bold", size: 34, relativeTo: .largeTitle)`; UIKit `UIFontMetrics(forTextStyle:)`. macOS giữ cỡ cố định.
- Hỗ trợ Chữ đậm (Bold Text): khi `legibilityWeight == .bold` thì tăng một bậc weight; Android 12+ đọc `Configuration.fontWeightAdjustment`.
- Không dùng Be Vietnam Pro cho chữ thân, nút hay nhãn control.

## Chữ tiếng Việt

- Chữ hoa có dấu chồng (Ấ, Ổ, Ặ, Ộ) cao hơn chữ Latin thường: không giảm line height dưới giá trị của text style, không đặt chiều cao cố định rồi cắt khung chữ. Kiểm dòng đầu của tiêu đề và chữ trong nút.
- Không viết HOA TOÀN BỘ: dấu khó đọc, và HIG đã bỏ header viết hoa. iOS 16–18 tự viết hoa section header của `List`, nên thêm `.textCase(nil)`.
- Kiểm ở AX5 (iOS) và 200% (Android) với chuỗi dài thật: "Nguyễn Thị Ngọc Huyền", "Đã kết nối qua cùng mạng Wi-Fi". Chữ xuống dòng, không cắt giữa từ; tên người gọi được hai dòng trước khi cắt đuôi.
- Không thêm letter-spacing ngoài token cho chữ có dấu.

## Số và mã

| Token | Cỡ/dòng | Weight | Cách dựng | Ví dụ |
|---|---|---|---|---|
| `code-pin` | 28/34 | Semibold | Apple `.system(.title, design: .monospaced)`, Android Roboto Mono; tracking 0.15 em | Mã PIN nhóm ba chữ số "482 915" |
| `timer` | 17/22 | Medium | SwiftUI `.monospacedDigit()`, AppKit `NSFont.monospacedDigitSystemFont(ofSize:weight:)`, Android `fontFeatureSettings = "tnum"` | Thời lượng "02:15" |

Chữ số đều bề rộng để số đếm không nhảy. `code-pin` phóng theo `.title` trên iOS.

## API

| Nền tảng | API |
|---|---|
| SwiftUI | `Font.TextStyle`, `.font(.body)`, `Font.custom(_:size:relativeTo:)`, `.monospacedDigit()`, `dynamicTypeSize`, `legibilityWeight` |
| UIKit | `UIFont.preferredFont(forTextStyle:)`, `adjustsFontForContentSizeCategory`, `UIFontMetrics` |
| AppKit | `NSFont.preferredFont(forTextStyle:)`, `NSFont.systemFont(ofSize:weight:)` |
| Compose | `TextStyle(fontFamily = Inter, fontSize = 17.sp, lineHeight = 22.sp, letterSpacing = (-0.013).em)`, gom trong bộ chữ riêng của HandLive (không dùng thang chữ Material) |

## Nên và không nên

| Nên | Không nên |
|---|---|
| Dùng text style của hệ thống | Đặt cỡ cố định cho chữ trên iOS |
| Phóng font thương hiệu theo Dynamic Type | Dùng Be Vietnam Pro cho chữ thân |
| Kiểm chữ có dấu ở AX5 và 200% | Giảm line height cho gọn |
| Số đếm dùng chữ số đều bề rộng | Viết hoa toàn bộ tiêu đề |
