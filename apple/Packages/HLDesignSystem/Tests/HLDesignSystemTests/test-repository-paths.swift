import Foundation

/// Đường dẫn trong kho, suy từ vị trí file test (không phụ thuộc thư mục làm việc).
enum RepositoryPaths {
    static let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let repositoryRoot = packageRoot
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let tokensJSON = repositoryRoot.appendingPathComponent("shared/design-tokens/tokens.json")
    static let typographyDoc = repositoryRoot.appendingPathComponent("docs/design-system/1-foundations/03-kieu-chu.md")
    static let generatorScript = packageRoot.appendingPathComponent("Scripts/generate-design-tokens.py")
    static let colorCatalog = packageRoot.appendingPathComponent("Sources/HLDesignSystem/Resources/Colors.xcassets")

    /// Python của kho (`tools/.venv`) nếu có, không thì python3 của hệ thống; script chỉ dùng thư viện chuẩn.
    static var python: URL {
        let venv = repositoryRoot.appendingPathComponent("tools/.venv/bin/python")
        return FileManager.default.isExecutableFile(atPath: venv.path) ? venv : URL(fileURLWithPath: "/usr/bin/python3")
    }

    static func json(at url: URL) throws -> [String: Any] {
        try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] ?? [:]
    }
}
