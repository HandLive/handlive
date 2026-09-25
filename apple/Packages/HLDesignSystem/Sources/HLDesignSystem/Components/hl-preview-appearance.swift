import SwiftUI

/// Bốn giao diện dùng để xem trước thành phần (02-che-do-toi.md).
/// Ghi đè môi trường bằng `\.colorScheme` và `\._colorSchemeContrast` (khóa môi trường có dấu gạch dưới
/// của SwiftUI, ghi được; `\.colorSchemeContrast` công khai chỉ đọc). Trong Xcode còn có thể đổi bằng
/// Environment Overrides hoặc biến thể "Color Scheme" của canvas.
enum HLPreviewAppearance: String, CaseIterable, Identifiable {
    case light = "Sáng"
    case dark = "Tối"
    case lightHighContrast = "Sáng · tương phản cao"
    case darkHighContrast = "Tối · tương phản cao"

    var id: String { rawValue }
    var colorScheme: ColorScheme { self == .dark || self == .darkHighContrast ? .dark : .light }
    var contrast: ColorSchemeContrast {
        self == .lightHighContrast || self == .darkHighContrast ? .increased : .standard
    }
}

extension View {
    /// Đặt view vào một giao diện, trên nền cửa sổ (Mac) hoặc nền nhóm (iOS) của đúng giao diện đó.
    func hlPreviewAppearance(_ appearance: HLPreviewAppearance) -> some View {
        #if os(macOS)
        let background = HLColorToken.windowBackground
        #else
        let background = HLColorToken.systemGroupedBackground
        #endif
        return padding(HLSpacing.space20)
            .background(background.resolved(colorScheme: appearance.colorScheme, contrast: appearance.contrast))
            .environment(\.colorScheme, appearance.colorScheme)
            .environment(\._colorSchemeContrast, appearance.contrast)
    }
}
