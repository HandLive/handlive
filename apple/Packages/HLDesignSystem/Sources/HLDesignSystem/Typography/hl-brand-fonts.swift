import CoreText
import Foundation

/// Đăng ký Be Vietnam Pro (OFL, `Resources/Fonts/OFL.txt`) với CoreText cho tiến trình hiện tại.
/// Gọi tự động khi dựng font thương hiệu; gọi lại nhiều lần vẫn an toàn.
public enum HLBrandFonts {
    /// Kết quả đăng ký: `true` khi mọi file font đã sẵn sàng (kể cả đã đăng ký từ trước).
    @discardableResult
    public static func registerIfNeeded() -> Bool { registration }

    /// URL các file font đóng gói, theo tên PostScript sinh từ tokens.json.
    public static var fontURLs: [URL] {
        HLBrandFontFiles.postScriptNames.compactMap {
            Bundle.module.url(forResource: $0, withExtension: "ttf", subdirectory: "Fonts")
        }
    }

    /// Weight Bold dùng khi người dùng bật Chữ đậm.
    static let boldPostScriptName: String = HLTextStyle.allCases
        .map(\.spec)
        .first { $0.family == .brand && $0.weight == 700 }?
        .postScriptName ?? ""

    private static let registration: Bool = {
        let urls = fontURLs
        guard urls.count == HLBrandFontFiles.postScriptNames.count else { return false }
        return urls.allSatisfy { url in
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) { return true }
            let code = error.map { CFErrorGetCode($0.takeRetainedValue()) } ?? 0
            return code == CTFontManagerError.alreadyRegistered.rawValue
        }
    }()
}
