import Foundation

/// Đọc `shared/test-vectors/*.json` và `shared/schemas/*.json` theo đường dẫn tương đối từ file này tới gốc kho.
enum RepoFiles {
    /// apple/Packages/HLCrypto/Tests/HLCryptoTests/<file> → gốc kho (lùi 6 cấp).
    static let root: URL = {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { url.deleteLastPathComponent() }
        return url
    }()

    static let vectorsDirectory = root.appendingPathComponent("shared/test-vectors")
    static let schemasDirectory = root.appendingPathComponent("shared/schemas")

    static func json(at url: URL) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    }
}

/// Một file vector: `{description, source, vectors, invalid_vectors?}`.
struct VectorFile {
    let vectors: [[String: Any]]
    let invalidVectors: [[String: Any]]

    init(_ name: String) throws {
        let object = try RepoFiles.json(at: RepoFiles.vectorsDirectory.appendingPathComponent(name))
        guard let dict = object as? [String: Any], let vectors = dict["vectors"] as? [[String: Any]] else {
            throw VectorError.malformed(name)
        }
        self.vectors = vectors
        self.invalidVectors = dict["invalid_vectors"] as? [[String: Any]] ?? []
    }
}

enum VectorError: Error {
    case malformed(String)
    case missing(String)
    case badHex(String)
}

extension Dictionary where Key == String, Value == Any {
    /// Tên vector cho thông báo lỗi (không ném lỗi, dùng được trong comment của `#expect`).
    var label: String { self["name"] as? String ?? "?" }

    func string(_ key: String) throws -> String {
        guard let value = self[key] as? String else { throw VectorError.missing(key) }
        return value
    }

    func hex(_ key: String) throws -> Data {
        try Hex.decode(string(key))
    }

    func int(_ key: String) throws -> Int64 {
        guard let value = self[key] as? NSNumber else { throw VectorError.missing(key) }
        return value.int64Value
    }

    func bool(_ key: String) throws -> Bool {
        guard let value = self[key] as? Bool else { throw VectorError.missing(key) }
        return value
    }
}

enum Hex {
    static func decode(_ text: String) throws -> Data {
        let chars = Array(text.utf8)
        guard chars.count % 2 == 0 else { throw VectorError.badHex(text) }
        var data = Data(capacity: chars.count / 2)
        var index = 0
        while index < chars.count {
            guard let pair = String(bytes: chars[index..<index + 2], encoding: .utf8),
                  let byte = UInt8(pair, radix: 16) else {
                throw VectorError.badHex(text)
            }
            data.append(byte)
            index += 2
        }
        return data
    }

    static func encode(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
