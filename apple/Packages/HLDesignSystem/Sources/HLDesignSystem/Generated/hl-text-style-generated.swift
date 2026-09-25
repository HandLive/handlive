// Tệp sinh tự động bởi Scripts/generate-design-tokens.py từ shared/design-tokens/tokens.json.
// Không sửa tay: sửa tokens.json rồi chạy lại script (kiểm bằng --check).
import SwiftUI

/// Kiểu chữ Apple theo 03-kieu-chu.md: SF qua text style, Be Vietnam Pro cho chữ thương hiệu.
public enum HLTextStyle: String, CaseIterable, Sendable {
    /// Be Vietnam Pro — tiêu đề màn chào và màn ghép nối. Tối đa một lần mỗi màn; phóng theo Dynamic Type (relativeTo: .largeTitle).
    case brandLargeTitle = "brand-large-title"
    /// Be Vietnam Pro — tiêu đề trạng thái trống và bước onboarding.
    case brandTitle = "brand-title"
    /// Chữ HandLive thay logo (chưa có logo). Màu brand-fire hoặc label.
    case wordmark = "wordmark"
    /// Large Title (.largeTitle) — tiêu đề lớn hiếm dùng trên Mac.
    case macLargeTitle = "mac-large-title"
    /// Title 1 (.title) — tiêu đề cửa sổ chào.
    case macTitle1 = "mac-title-1"
    /// Title 2 (.title2) — tên người gọi trong panel cuộc gọi.
    case macTitle2 = "mac-title-2"
    /// Title 3 (.title3) — tiêu đề nhóm lớn.
    case macTitle3 = "mac-title-3"
    /// Headline (.headline) — tên hội thoại chưa đọc, tiêu đề thông báo.
    case macHeadline = "mac-headline"
    /// Body (.body) — chữ mặc định của Mac.
    case macBody = "mac-body"
    /// Callout (.callout) — số điện thoại, mô tả ngắn.
    case macCallout = "mac-callout"
    /// Subheadline (.subheadline) — dòng phụ trong danh sách.
    case macSubheadline = "mac-subheadline"
    /// Footnote (.footnote) — chú thích dưới nhóm cài đặt.
    case macFootnote = "mac-footnote"
    /// Caption 1 (.caption) — nhãn nhỏ dưới nút tròn.
    case macCaption1 = "mac-caption-1"
    /// Caption 2 (.caption2) — thông số, thời gian.
    case macCaption2 = "mac-caption-2"
    /// Large Title — tiêu đề màn gốc (co lại khi cuộn). Nhấn mạnh: Bold.
    case iosLargeTitle = "ios-large-title"
    /// Title 1 — tiêu đề màn chào. Nhấn mạnh: Bold.
    case iosTitle1 = "ios-title-1"
    /// Title 2 — tiêu đề sheet. Nhấn mạnh: Bold.
    case iosTitle2 = "ios-title-2"
    /// Title 3 — tiêu đề nhóm nổi bật. Nhấn mạnh: Semibold.
    case iosTitle3 = "ios-title-3"
    /// Headline — tên hội thoại, tiêu đề dòng quan trọng.
    case iosHeadline = "ios-headline"
    /// Body — chữ mặc định iOS.
    case iosBody = "ios-body"
    /// Callout — mô tả trong thẻ.
    case iosCallout = "ios-callout"
    /// Subhead — đoạn trích tin nhắn, giá trị dòng.
    case iosSubheadline = "ios-subheadline"
    /// Footnote — chú thích dưới nhóm, thời gian.
    case iosFootnote = "ios-footnote"
    /// Caption 1 — nhãn nhỏ, trạng thái tin gửi.
    case iosCaption1 = "ios-caption-1"
    /// Caption 2 — nhãn nhỏ nhất (11 pt là tối thiểu của iOS).
    case iosCaption2 = "ios-caption-2"
    /// Mã PIN và mã an toàn, nhóm ba ký tự. SF Mono trên Apple, Roboto Mono trên Android.
    case codePin = "code-pin"
    /// Thời lượng cuộc gọi, đếm ngược. Bật monospacedDigit (Apple) / tnum (Android) để số không nhảy.
    case timer = "timer"

    public var spec: HLTextStyleSpec {
        switch self {
        case .brandLargeTitle: return HLTextStyleSpec(family: .brand, size: 34, lineHeight: 41, weight: 700, letterSpacingEm: -0.01, textStyle: .largeTitle, postScriptName: "BeVietnamPro-Bold", monospacedDigit: false)
        case .brandTitle: return HLTextStyleSpec(family: .brand, size: 22, lineHeight: 28, weight: 600, letterSpacingEm: 0, textStyle: .title2, postScriptName: "BeVietnamPro-SemiBold", monospacedDigit: false)
        case .wordmark: return HLTextStyleSpec(family: .brand, size: 20, lineHeight: 24, weight: 700, letterSpacingEm: -0.01, textStyle: .title3, postScriptName: "BeVietnamPro-Bold", monospacedDigit: false)
        case .macLargeTitle: return HLTextStyleSpec(family: .system, size: 26, lineHeight: 32, weight: 400, letterSpacingEm: 0.008, textStyle: .largeTitle, postScriptName: nil, monospacedDigit: false)
        case .macTitle1: return HLTextStyleSpec(family: .system, size: 22, lineHeight: 26, weight: 400, letterSpacingEm: -0.012, textStyle: .title, postScriptName: nil, monospacedDigit: false)
        case .macTitle2: return HLTextStyleSpec(family: .system, size: 17, lineHeight: 22, weight: 400, letterSpacingEm: -0.026, textStyle: .title2, postScriptName: nil, monospacedDigit: false)
        case .macTitle3: return HLTextStyleSpec(family: .system, size: 15, lineHeight: 20, weight: 400, letterSpacingEm: -0.016, textStyle: .title3, postScriptName: nil, monospacedDigit: false)
        case .macHeadline: return HLTextStyleSpec(family: .system, size: 13, lineHeight: 16, weight: 700, letterSpacingEm: -0.006, textStyle: .headline, postScriptName: nil, monospacedDigit: false)
        case .macBody: return HLTextStyleSpec(family: .system, size: 13, lineHeight: 16, weight: 400, letterSpacingEm: -0.006, textStyle: .body, postScriptName: nil, monospacedDigit: false)
        case .macCallout: return HLTextStyleSpec(family: .system, size: 12, lineHeight: 15, weight: 400, letterSpacingEm: 0, textStyle: .callout, postScriptName: nil, monospacedDigit: false)
        case .macSubheadline: return HLTextStyleSpec(family: .system, size: 11, lineHeight: 14, weight: 400, letterSpacingEm: 0.006, textStyle: .subheadline, postScriptName: nil, monospacedDigit: false)
        case .macFootnote: return HLTextStyleSpec(family: .system, size: 10, lineHeight: 13, weight: 400, letterSpacingEm: 0.012, textStyle: .footnote, postScriptName: nil, monospacedDigit: false)
        case .macCaption1: return HLTextStyleSpec(family: .system, size: 10, lineHeight: 13, weight: 400, letterSpacingEm: 0.012, textStyle: .caption, postScriptName: nil, monospacedDigit: false)
        case .macCaption2: return HLTextStyleSpec(family: .system, size: 10, lineHeight: 13, weight: 500, letterSpacingEm: 0.012, textStyle: .caption2, postScriptName: nil, monospacedDigit: false)
        case .iosLargeTitle: return HLTextStyleSpec(family: .system, size: 34, lineHeight: 41, weight: 400, letterSpacingEm: 0.012, textStyle: .largeTitle, postScriptName: nil, monospacedDigit: false)
        case .iosTitle1: return HLTextStyleSpec(family: .system, size: 28, lineHeight: 34, weight: 400, letterSpacingEm: 0.014, textStyle: .title, postScriptName: nil, monospacedDigit: false)
        case .iosTitle2: return HLTextStyleSpec(family: .system, size: 22, lineHeight: 28, weight: 400, letterSpacingEm: -0.012, textStyle: .title2, postScriptName: nil, monospacedDigit: false)
        case .iosTitle3: return HLTextStyleSpec(family: .system, size: 20, lineHeight: 25, weight: 400, letterSpacingEm: -0.023, textStyle: .title3, postScriptName: nil, monospacedDigit: false)
        case .iosHeadline: return HLTextStyleSpec(family: .system, size: 17, lineHeight: 22, weight: 600, letterSpacingEm: -0.026, textStyle: .headline, postScriptName: nil, monospacedDigit: false)
        case .iosBody: return HLTextStyleSpec(family: .system, size: 17, lineHeight: 22, weight: 400, letterSpacingEm: -0.026, textStyle: .body, postScriptName: nil, monospacedDigit: false)
        case .iosCallout: return HLTextStyleSpec(family: .system, size: 16, lineHeight: 21, weight: 400, letterSpacingEm: -0.02, textStyle: .callout, postScriptName: nil, monospacedDigit: false)
        case .iosSubheadline: return HLTextStyleSpec(family: .system, size: 15, lineHeight: 20, weight: 400, letterSpacingEm: -0.016, textStyle: .subheadline, postScriptName: nil, monospacedDigit: false)
        case .iosFootnote: return HLTextStyleSpec(family: .system, size: 13, lineHeight: 18, weight: 400, letterSpacingEm: -0.006, textStyle: .footnote, postScriptName: nil, monospacedDigit: false)
        case .iosCaption1: return HLTextStyleSpec(family: .system, size: 12, lineHeight: 16, weight: 400, letterSpacingEm: 0, textStyle: .caption, postScriptName: nil, monospacedDigit: false)
        case .iosCaption2: return HLTextStyleSpec(family: .system, size: 11, lineHeight: 13, weight: 400, letterSpacingEm: 0.006, textStyle: .caption2, postScriptName: nil, monospacedDigit: false)
        case .codePin: return HLTextStyleSpec(family: .monospaced, size: 28, lineHeight: 34, weight: 600, letterSpacingEm: 0.15, textStyle: .title, postScriptName: nil, monospacedDigit: false)
        case .timer: return HLTextStyleSpec(family: .system, size: 17, lineHeight: 22, weight: 500, letterSpacingEm: -0.026, textStyle: .body, postScriptName: nil, monospacedDigit: true)
        }
    }
}

/// Tên PostScript của các file Be Vietnam Pro được đóng gói (chỉ weight token dùng).
public enum HLBrandFontFiles {
    public static let postScriptNames: [String] = ["BeVietnamPro-Bold", "BeVietnamPro-SemiBold"]
}
