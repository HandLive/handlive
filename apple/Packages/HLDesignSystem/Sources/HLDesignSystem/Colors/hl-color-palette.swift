import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Một màu sRGB 8 bit mỗi kênh, lấy nguyên từ hex trong tokens.json.
public struct HLRGBA: Hashable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8, _ alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var color: Color {
        Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255,
              opacity: Double(alpha) / 255)
    }
}

/// Bốn giao diện của một token màu (02-che-do-toi.md, mục Bốn giao diện).
public struct HLColorPalette: Hashable, Sendable {
    public let light: HLRGBA
    public let dark: HLRGBA
    public let lightHighContrast: HLRGBA
    public let darkHighContrast: HLRGBA

    public func value(colorScheme: ColorScheme, contrast: ColorSchemeContrast) -> HLRGBA {
        switch (colorScheme == .dark, contrast == .increased) {
        case (false, false): light
        case (true, false): dark
        case (false, true): lightHighContrast
        case (true, true): darkHighContrast
        }
    }
}

extension HLColorToken {
    /// Màu cố định cho một giao diện cụ thể: API hệ thống nếu token là màu hệ thống, còn lại theo token.
    /// Thành phần dùng hàm này cùng `@Environment(\.colorScheme)` và `\.colorSchemeContrast`
    /// để xem trước đúng ở cả 4 giao diện khi ghi đè môi trường.
    public func resolved(colorScheme: ColorScheme, contrast: ColorSchemeContrast) -> Color {
        systemColor ?? palette.value(colorScheme: colorScheme, contrast: contrast).color
    }

    /// Màu động theo giao diện hệ thống. Ưu tiên Color Set trong asset catalog của package (khi dựng
    /// bằng Xcode); nếu không có (dựng bằng Command Line Tools) thì dùng giá trị sinh từ cùng tokens.json.
    public var color: Color {
        if let systemColor { return systemColor }
        #if canImport(AppKit)
        if let named = NSColor(named: rawValue, bundle: .module) { return Color(nsColor: named) }
        let palette = self.palette
        return Color(nsColor: NSColor(name: NSColor.Name(rawValue)) { appearance in
            let match = appearance.bestMatch(from: [
                .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
            ])
            let dark = match == .darkAqua || match == .accessibilityHighContrastDarkAqua
            let high = match == .accessibilityHighContrastAqua || match == .accessibilityHighContrastDarkAqua
            return palette.value(colorScheme: dark ? .dark : .light, contrast: high ? .increased : .standard)
                .platformColor
        })
        #elseif canImport(UIKit)
        if let named = UIColor(named: rawValue, in: .module, compatibleWith: nil) { return Color(uiColor: named) }
        let palette = self.palette
        return Color(uiColor: UIColor { traits in
            palette.value(
                colorScheme: traits.userInterfaceStyle == .dark ? .dark : .light,
                contrast: traits.accessibilityContrast == .high ? .increased : .standard
            ).platformColor
        })
        #endif
    }
}

extension Color {
    /// Màu động của một token HandLive: `Color.hl(.accentFill)`.
    public static func hl(_ token: HLColorToken) -> Color { token.color }
}

private extension HLRGBA {
    #if canImport(AppKit)
    var platformColor: NSColor {
        NSColor(srgbRed: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255,
                alpha: CGFloat(alpha) / 255)
    }
    #elseif canImport(UIKit)
    var platformColor: UIColor {
        UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255,
                alpha: CGFloat(alpha) / 255)
    }
    #endif
}
