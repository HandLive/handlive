import CoreText
import Foundation
import Testing
@testable import HLDesignSystem

@Suite("Font Be Vietnam Pro")
struct BrandFontTests {
    @Test("Chỉ đóng gói weight token dùng: SemiBold (600) và Bold (700)")
    func bundlesOnlyUsedWeights() {
        #expect(HLBrandFontFiles.postScriptNames == ["BeVietnamPro-Bold", "BeVietnamPro-SemiBold"])
        #expect(HLBrandFonts.fontURLs.count == 2)
    }

    @Test("Tên PostScript trong file font khớp tên sinh ra")
    func fontFilesDeclareExpectedPostScriptNames() {
        for (url, expected) in zip(HLBrandFonts.fontURLs, HLBrandFontFiles.postScriptNames) {
            let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] ?? []
            let names = descriptors.compactMap { CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String }
            #expect(names == [expected], "\(url.lastPathComponent)")
        }
    }

    @Test("Đăng ký được và CoreText tạo đúng font theo tên PostScript")
    func registersFontsWithCoreText() {
        #expect(HLBrandFonts.registerIfNeeded())
        #expect(HLBrandFonts.registerIfNeeded()) // gọi lại vẫn an toàn
        for name in HLBrandFontFiles.postScriptNames {
            let font = CTFontCreateWithName(name as CFString, 20, nil)
            #expect(CTFontCopyPostScriptName(font) as String == name)
            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Be Vietnam Pro")
        }
    }

    @Test("Giấy phép OFL đi kèm font trong bundle")
    func bundlesOpenFontLicense() throws {
        let url = try #require(Bundle.module.url(forResource: "OFL", withExtension: "txt", subdirectory: "Fonts"))
        let license = try String(contentsOf: url, encoding: .utf8)
        #expect(license.contains("SIL Open Font License, Version 1.1"))
    }
}
