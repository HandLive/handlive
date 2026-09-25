# Phase 0 — M0.2 [apple] HLDesignSystem

## Việc đã làm

- Swift package `apple/Packages/HLDesignSystem` (tools 6.0, Swift 6, macOS 13+ / iOS 16+), product
  `HLDesignSystem`.
- Script sinh `Scripts/generate-design-tokens.py` (Python, chỉ thư viện chuẩn, chạy được cả với
  `/usr/bin/python3` 3.9 lẫn `tools/.venv/bin/python`). Nó đọc `shared/design-tokens/tokens.json`
  rồi sinh ra:
  - `Resources/Colors.xcassets`: 68 Color Set (mỗi token màu một Color Set, đã lần theo bí danh
    `{token}`), mỗi set đủ 4 giao diện: Any, Dark, High Contrast, Dark + High Contrast. Thêm
    `AccentColor.colorset` bằng đúng `accent`.
  - `Generated/hl-color-token-generated.swift`: `enum HLColorToken` gồm `palette` (4 giao diện) và
    `systemColor`. Token nào là màu hệ thống, hoặc là bí danh trỏ tới màu hệ thống (`status-*`,
    `badge`, `label`, `secondary-label`), thì gọi API SwiftUI (`.green`, `.secondary` …), không dùng
    hex. Làm vậy theo 01-mau-sac.md: "không hard-code màu hệ thống trên Apple".
  - `Generated/hl-text-style-generated.swift`: `enum HLTextStyle` gồm brand-*, wordmark, mac-*,
    ios-*, code-pin, timer, bỏ android-*. `HLBrandFontFiles.postScriptNames` chỉ chứa các weight mà
    token dùng.
  - `Generated/hl-metrics-generated.swift`: `HLSpacing`, `HLRadius`, `HLSize`, `HLDuration`.
  - `--check` sinh toàn bộ vào bộ nhớ rồi so với file trên đĩa. Có file thiếu, lệch hoặc thừa thì
    exit 1. Script cũng báo lỗi nếu thiếu file font cho weight mà token dùng.
- **Vì sao đặt script ở `apple/Packages/HLDesignSystem/Scripts/`** chứ không ở
  `tools/design-tokens/`: đầu ra (xcassets, Swift) chỉ dành cho Apple và nằm cạnh package. Android
  sinh bằng Gradle task riêng (A0.3). Nguồn dùng chung vẫn chỉ là `tokens.json`. Script có đường dẫn
  cố định tới gốc kho nên chạy từ thư mục nào cũng được.
- Font Be Vietnam Pro lấy từ github google/fonts (`ofl/bevietnampro`), chỉ hai weight token dùng là
  600 và 700: `Resources/Fonts/BeVietnamPro-SemiBold.ttf`, `BeVietnamPro-Bold.ttf` và `OFL.txt`. Cả
  thư mục được đóng gói bằng `.copy`, nên OFL.txt đi cùng font trong bundle.
  `HLBrandFonts.registerIfNeeded()` gọi `CTFontManagerRegisterFontsForURL` (scope `.process`), chỉ
  chạy một lần, và coi lỗi `alreadyRegistered` là thành công. Hàm này tự được gọi khi dựng font
  thương hiệu.
- Kiểu chữ (`Typography/hl-text-style-spec.swift`):
  - Chữ hệ thống: `Font.system(textStyle)`, cộng `.weight` khi token khác 400.
  - Chữ thương hiệu: `Font.custom(ps, size:, relativeTo:)`, phóng theo Dynamic Type.
  - `code-pin`: `.system(.title, design: .monospaced)`. `timer`: `.monospacedDigit()`.
  - Tracking chỉ áp cho Be Vietnam Pro và SF Mono.
  - `.hlTextStyle(_:)` đọc `legibilityWeight`: khi bật Chữ đậm, SemiBold lên Bold.
- Màu (`Colors/hl-color-palette.swift`):
  - `token.resolved(colorScheme:contrast:)` trả màu cố định cho một giao diện. Các thành phần đọc
    `\.colorScheme` và `\.colorSchemeContrast` rồi gọi hàm này, nên khi preview ghi đè môi trường
    thì màu đổi đúng cả 4 giao diện.
  - `Color.hl(token)` là màu động: thử Color Set trong bundle trước (khi dựng bằng Xcode), không có
    thì dùng provider động sinh từ cùng giá trị (`NSAppearance` aqua/darkAqua/HC,
    `UITraitCollection.accessibilityContrast`).
- Thành phần SwiftUI:
  - `hlButtonStyle(_:)` với 5 kiểu `prominent`, `glass`, `tinted`, `plain`, `destructive`. Dùng kiểu
    nút hệ thống đúng như bảng trong Button/README (`.borderedProminent`/`.bordered`/`.borderless`;
    từ 26 dùng `.glassProminent` /`.glass`, bọc trong `#if compiler(>=6.2)` và `#available`). iOS
    dùng capsule, nút chính `.large`.
  - `StatusIndicator` với `HLConnectionStatus`: đủ 8 trạng thái, chữ lấy nguyên văn README; hai dạng
    inline và pill (pill có nhãn ngắn "LAN").
    - VoiceOver: `accessibilityElement(children: .ignore)` và nhãn là câu đầy đủ, ví dụ "Đã kết nối qua Wi-Fi với Pixel 8 của Lan".
    - Chấm nhấp nháy theo `duration-pulse` bằng `TimelineView`; bật Giảm chuyển động thì chấm đứng yên. Bật Phân biệt không dùng màu thì chấm đổi thành biểu tượng có hình.
  - `GroupedList`, `GroupedSection`, `GroupedRowLabel`, `GroupedActionRow`, `HLFeatureGroup`:
    - iOS dùng `List` `.insetGrouped`, macOS dùng `Form` `.grouped`. Header đặt `.textCase(nil)`.
    - Ô biểu tượng 30 pt, bo 8 pt, màu theo nhóm chức năng. Lý do chưa dùng được viết bằng `text-orange`.
- `#Preview` ở 4 giao diện (Sáng, Tối, Sáng · tương phản cao, Tối · tương phản cao) cho cả 3 thành
  phần, qua `hlPreviewAppearance(_:)`:
  - Ghi đè `.environment(\.colorScheme, …)` và `.environment(\._colorSchemeContrast, …)`. Khóa có
    gạch dưới là khóa ghi được của SwiftUI; `\.colorSchemeContrast` công khai chỉ đọc. Nền của
    preview đổi theo giao diện.
  - Chuỗi trong preview lấy nguyên văn Button/README và 2-patterns/04-cai-dat.md.

## Ràng buộc Command Line Tools và cách xử lý

| Vấn đề (đã kiểm tại máy) | Xử lý |
|---|---|
| `.process("…xcassets")` làm `swift build` lỗi: "tool 'actool' requires Xcode" | `Package.swift` xem thư mục developer đang dùng (`DEVELOPER_DIR`, nếu không có thì symlink `/var/db/xcode_select_link`).<br>Có Xcode thì `.process` catalog.<br>Chỉ có CLT thì `exclude` catalog, màu lấy từ mã Swift sinh cùng lượt (cùng giá trị, `--check` bảo đảm).<br>Test đọc thẳng JSON của Color Set để kiểm giá trị. |
| `#Preview` lỗi "plugin for module 'PreviewsMacros' not found" | Chỉ có CLT thì define `HL_COMMAND_LINE_TOOLS_ONLY`. Các khối `#Preview` nằm trong `#if !HL_COMMAND_LINE_TOOLS_ONLY`. Nội dung preview (`*PreviewGallery`, `hlPreviewAppearance`) vẫn biên dịch mọi lúc, nên lỗi kiểu vẫn bị bắt. |
| SDK macOS 27 biến `@State` thành macro (`SwiftUIMacros.StateMacro`), CLT không có plugin | Thành phần không dùng `@State`: nhịp chấm dùng `TimelineView`, preview dùng `.constant(…)` |
| Không có SDK iOS | Nhánh `#if os(iOS)` / `canImport(UIKit)` **chưa được biên dịch tại máy** |

## Lệnh test và kết quả

```
cd apple/Packages/HLDesignSystem && HL_SWIFT_TESTING_PACKAGE=1 swift test
...
✔ Test "Màu hệ thống gọi API, không dùng hex" with 6 test cases passed after 0.001 seconds.
✔ Test "Be Vietnam Pro chỉ cho chữ thương hiệu; còn lại là font hệ thống" passed after 0.001 seconds.
✔ Test "VoiceOver đọc câu đầy đủ kèm tên thiết bị" passed after 0.005 seconds.
✔ Test "Tracking chỉ áp cho font không phải SF" passed after 0.005 seconds.
✔ Test "Ngoại tuyến là xám, đỏ chỉ khi phải làm gì đó; chỉ hai trạng thái nhấp nháy" passed after 0.005 seconds.
✔ Test "Màu tự định nghĩa chọn đúng giao diện" passed after 0.005 seconds.
✔ Test "Chữ lấy nguyên văn StatusIndicator/README.md" passed after 0.005 seconds.
✔ Test "AccentColor = accent" passed after 0.005 seconds.
✔ Test "Mọi kiểu chữ Apple đều có trong bảng tài liệu và khớp cỡ, dòng, weight, text style" passed after 0.005 seconds.
✔ Suite "StatusIndicator" passed after 0.006 seconds.
✔ Suite "Kiểu chữ theo 03-kieu-chu.md" passed after 0.006 seconds.
✔ Test "Mã Swift sinh ra có cùng giá trị với tokens.json" passed after 0.006 seconds.
✔ Test "Chỉ đóng gói weight token dùng: SemiBold (600) và Bold (700)" passed after 0.007 seconds.
✔ Test "Giấy phép OFL đi kèm font trong bundle" passed after 0.007 seconds.
✔ Test "Tên PostScript trong file font khớp tên sinh ra" passed after 0.008 seconds.
✔ Test "Đăng ký được và CoreText tạo đúng font theo tên PostScript" passed after 0.012 seconds.
✔ Suite "Font Be Vietnam Pro" passed after 0.012 seconds.
✔ Test "Mỗi màu trong tokens.json có Color Set đủ 4 giao diện, đúng giá trị" passed after 0.014 seconds.
✔ Suite "Color Sets 4 giao diện" passed after 0.015 seconds.
✔ Test "--check không lệch với tokens.json" passed after 0.067 seconds.
✔ Suite "Script sinh token" passed after 0.067 seconds.
✔ Test run with 16 tests in 5 suites passed after 0.068 seconds.
```

```
tools/.venv/bin/python apple/Packages/HLDesignSystem/Scripts/generate-design-tokens.py --check
OK: 73 file khớp tokens.json          (exit 0)
```

- Đã thử sửa tay `accent.colorset` (0x34 → 0x35): `--check` in ra "lệch:
  …/accent.colorset/Contents.json" và exit 1. Khôi phục lại thì exit 0.
- Test kiểu chữ không so với một bảng chép tay mà đọc thẳng các bảng trong `03-kieu-chu.md`. Kết
  quả: 27 kiểu, khớp cỡ/dòng, weight và text style.
- Build không có cảnh báo nào từ mã của package. Cảnh báo "PIF … DoesNotExist" đến từ gói
  swift-testing.

## Đường dẫn

- `apple/Packages/HLDesignSystem/Package.swift`
- `apple/Packages/HLDesignSystem/Scripts/`: `generate-design-tokens.py`, `design_tokens_model.py`,
  `design_tokens_asset_catalog.py`, `design_tokens_swift_sources.py`
- `apple/Packages/HLDesignSystem/Sources/HLDesignSystem/`:
  - `Colors/hl-color-palette.swift`
  - `Typography/hl-text-style-spec.swift`, `Typography/hl-brand-fonts.swift`
  - `Components/hl-button-style.swift`, `hl-status-indicator.swift`, `hl-connection-status.swift`,
    `hl-grouped-list.swift`, `hl-preview-appearance.swift`
  - `Generated/*` (sinh), `Resources/Colors.xcassets/*` (sinh), `Resources/Fonts/*`
- `apple/Packages/HLDesignSystem/Tests/HLDesignSystemTests/*.swift` (6 file)
- `apple/Packages/HLDesignSystem/Package.resolved`: SwiftPM tự sinh khi chạy với
  `HL_SWIFT_TESTING_PACKAGE=1`, ghim swift-testing. Người commit quyết định giữ hay bỏ.

## Điểm lệch với tài liệu và đề xuất

1. **Nút chính trên macOS.** Hai tài liệu mâu thuẫn:
   - Button/README ghi token `accent-fill` cho nút prominent.
   - 01-mau-sac.md ghi: trên Mac, control theo Màu nhấn mà người dùng chọn, "HandLive không ép xanh
     lá".

   Đã chọn: iOS tô `accent-fill`; macOS để hệ thống quyết định (khi người dùng để "Nhiều màu" thì hệ
   thống lấy AccentColor = `accent`). Hệ quả cần biết: ở giao diện Tối, `accent` (#3ddc6c) với chữ
   trắng có tương phản thấp. Đề xuất: tài liệu nói rõ trường hợp này, hoặc cho phép tô `accent-fill`
   trên Mac.
2. **Thiếu token cho glyph trắng trên ô biểu tượng** của GroupedList. Tạm dùng `on-accent`
   (#ffffff). Đề xuất thêm token `on-icon-fill`. Cỡ ô 30 pt và bo 8 pt cũng chưa có token nên đang
   là hằng số có chú thích. Đề xuất thêm `size-row-icon` và `radius-row-icon`.
3. **tokens.json thiếu hai loại thông tin:** text style "phóng theo" (`relativeTo`) của
   `brand-title`, `wordmark`, `code-pin`, `timer`, và cột "Nhấn mạnh".
   - Script đang giữ `relativeTo` trong một bảng nhỏ, lấy theo 03-kieu-chu.md. Riêng `timer` tài
     liệu không ghi nên chọn `.body` (cùng 17/22 với iOS body).
   - Cột "Nhấn mạnh" chưa sinh.
   - Đề xuất thêm trường `relativeTo` và `emphasisWeight` vào tokens.json.
4. **Chữ đậm (Bold Text) cho chữ thương hiệu.** 03-kieu-chu.md yêu cầu tăng một bậc weight. Đang
   đóng gói đúng hai weight token dùng, nên Bold không lên được ExtraBold (SemiBold lên Bold thì
   được). Muốn đủ thì cần thêm `BeVietnamPro-ExtraBold.ttf` (+140 KB).
5. **Phân biệt không dùng màu.** Tài liệu chỉ nêu ví dụ, chưa quy định biểu tượng cho "Đang kết
   nối…" và "Đang phát camera". Đã chọn `ellipsis.circle.fill` và `record.circle`, cần duyệt.
6. **Màu ngữ nghĩa.** Mọi token màu đều có Color Set, đúng như thẻ việc yêu cầu. Tuy vậy chỉ 10
   token (8 màu hệ thống, `label`, `secondary-label`) và các bí danh của chúng được đổi sang API
   SwiftUI. Những màu như `tertiary-system-fill` (nền viên StatusIndicator), `system-background`,
   `window-background` (nền preview) vẫn lấy theo hex của token. Lý do: macOS 13 không có
   `Color(.tertiarySystemFill)` (NSColor hỗ trợ từ macOS 14). Đề xuất khi có Xcode: mở rộng bảng
   `SYSTEM_SWIFTUI_COLORS` bằng biểu thức theo nền tảng.
7. **AccentColor.** Color Set `AccentColor` trong catalog của package không tự thành màu nhấn toàn
   app. Target app (project.yml, M0.1/M1.x) phải đưa `Colors.xcassets` này vào nguồn và đặt
   `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`.
8. **Tên file Swift** dùng kebab-case theo `docs/code-standards.md` (ví dụ
   `hl-status-indicator.swift`). Nếu M0.1 chọn PascalCase thì cần thống nhất.

```text
Status: DONE_WITH_CONCERNS
Summary: HLDesignSystem có script sinh Color Sets 4 giao diện (AccentColor = accent), mã Swift cho màu, chữ, khoảng cách, bo góc, font Be Vietnam Pro 600/700 kèm OFL, và ba thành phần SwiftUI có #Preview 4 giao diện; 16 test swift-testing xanh, --check exit 0.
Concerns/Blockers: Chưa kiểm bằng Xcode: asset catalog được biên dịch, #Preview hiển thị, nhánh iOS biên dịch (máy chỉ có CLT, không có SDK iOS). Cần chủ dự án quyết điểm lệch 1 (nút chính trên Mac) và 2–3 (token còn thiếu).
```
