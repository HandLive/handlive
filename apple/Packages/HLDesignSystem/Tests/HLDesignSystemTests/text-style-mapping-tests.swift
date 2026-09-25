import Foundation
import SwiftUI
import Testing
@testable import HLDesignSystem

/// Một dòng bảng trong 03-kieu-chu.md: `token` | … | cỡ/dòng | weight | … (text style ở bất kỳ ô nào).
private struct DocumentedTextStyle {
    let token: String
    let size: CGFloat
    let lineHeight: CGFloat
    let weightName: String
    let textStyle: Font.TextStyle?
}

private let textStylesByName: [String: Font.TextStyle] = [
    "largeTitle": .largeTitle, "title": .title, "title2": .title2, "title3": .title3,
    "headline": .headline, "body": .body, "callout": .callout, "subheadline": .subheadline,
    "footnote": .footnote, "caption": .caption, "caption2": .caption2,
]
private let weightsByName = ["Regular": 400, "Medium": 500, "Semibold": 600, "Bold": 700]

private func documentedTextStyles() throws -> [String: DocumentedTextStyle] {
    let text = try String(contentsOf: RepositoryPaths.typographyDoc, encoding: .utf8)
    let styleNames = textStylesByName.keys.joined(separator: "|")
    let stylePattern = try NSRegularExpression(pattern: "`[^`]*?\\.(\(styleNames))\\b")
    var result: [String: DocumentedTextStyle] = [:]
    for line in text.split(separator: "\n") where line.hasPrefix("| `") {
        let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        let token = cells[0].trimmingCharacters(in: CharacterSet(charactersIn: "`"))
        guard HLTextStyle(rawValue: token) != nil,
              let sizeIndex = cells.firstIndex(where: { $0.range(of: #"^\d+/\d+$"#, options: .regularExpression) != nil })
        else { continue }
        let sizes = cells[sizeIndex].split(separator: "/").compactMap { Double($0) }
        let range = NSRange(line.startIndex..., in: line)
        let match = stylePattern.firstMatch(in: String(line), range: range)
        let styleName = match.flatMap { Range($0.range(at: 1), in: line) }.map { String(line[$0]) }
        result[token] = DocumentedTextStyle(
            token: token, size: sizes[0], lineHeight: sizes[1], weightName: cells[sizeIndex + 1],
            textStyle: styleName.flatMap { textStylesByName[$0] }
        )
    }
    return result
}

@Suite("Kiểu chữ theo 03-kieu-chu.md")
struct TextStyleMappingTests {
    @Test("Mọi kiểu chữ Apple đều có trong bảng tài liệu và khớp cỡ, dòng, weight, text style")
    func textStylesMatchDocumentTables() throws {
        let documented = try documentedTextStyles()
        #expect(documented.count == HLTextStyle.allCases.count)
        for style in HLTextStyle.allCases {
            let spec = style.spec
            guard let row = documented[style.rawValue] else {
                Issue.record("\(style.rawValue) không có trong 03-kieu-chu.md")
                continue
            }
            #expect(spec.size == row.size, "\(style.rawValue) cỡ")
            #expect(spec.lineHeight == row.lineHeight, "\(style.rawValue) dòng")
            #expect(spec.weight == weightsByName[row.weightName], "\(style.rawValue) weight \(row.weightName)")
            if let textStyle = row.textStyle {
                #expect(spec.textStyle == textStyle, "\(style.rawValue) text style")
            }
        }
    }

    @Test("Be Vietnam Pro chỉ cho chữ thương hiệu; còn lại là font hệ thống")
    func brandFontOnlyForBrandStyles() {
        for style in HLTextStyle.allCases {
            let isBrand = style.rawValue.hasPrefix("brand-") || style == .wordmark
            #expect((style.spec.family == .brand) == isBrand, "\(style.rawValue)")
            #expect((style.spec.postScriptName != nil) == isBrand, "\(style.rawValue)")
        }
        #expect(HLTextStyle.codePin.spec.family == .monospaced)
        #expect(HLTextStyle.timer.spec.monospacedDigit)
    }

    @Test("Tracking chỉ áp cho font không phải SF")
    func trackingOnlyForNonSystemFonts() {
        #expect(HLTextStyle.iosBody.spec.tracking == 0)
        #expect(abs(HLTextStyle.brandLargeTitle.spec.tracking - (-0.34)) < 0.0001)
        #expect(abs(HLTextStyle.codePin.spec.tracking - 4.2) < 0.0001)
    }
}
