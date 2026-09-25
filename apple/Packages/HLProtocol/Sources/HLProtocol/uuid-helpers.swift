import Foundation

/// Định danh uuid theo 0.2/0.3: 36 ký tự chữ thường có gạch; dạng byte 16 byte dùng trong T1/T2, salt PRK.
public enum HLUUID {
    /// Sinh UUIDv7 (RFC 9562 §5.7): 48 bit mili-giây Unix ‖ version 7 ‖ 12 bit ngẫu nhiên ‖ variant 10 ‖ 62 bit ngẫu nhiên.
    public static func v7(timestampMs: Int64 = currentTimeMs()) -> String {
        var generator = SystemRandomNumberGenerator()
        var bytes = [UInt8](repeating: 0, count: 16)
        let millis = UInt64(max(0, timestampMs)) & 0xFFFF_FFFF_FFFF
        for index in 0..<6 {
            bytes[index] = UInt8(truncatingIfNeeded: millis >> (8 * (5 - index)))
        }
        for index in 6..<16 {
            bytes[index] = generator.next()
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x70
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return string(from: Data(bytes))
    }

    public static func currentTimeMs() -> Int64 {
        Int64((Date().timeIntervalSince1970 * 1000).rounded(.down))
    }

    /// 16 byte → chuỗi uuid chữ thường.
    public static func string(from bytes: Data) -> String {
        precondition(bytes.count == 16, "uuid phải đúng 16 byte")
        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        let parts = [0..<8, 8..<12, 12..<16, 16..<20, 20..<32].map { range -> String in
            let start = hex.index(hex.startIndex, offsetBy: range.lowerBound)
            let end = hex.index(hex.startIndex, offsetBy: range.upperBound)
            return String(hex[start..<end])
        }
        return parts.joined(separator: "-")
    }

    /// Chuỗi uuid chữ thường 36 ký tự → 16 byte. Chữ hoa hoặc sai dạng bị từ chối.
    public static func bytes(from text: String) throws -> Data {
        guard isCanonical(text) else { throw ProtocolError.invalidUUID }
        let hex = text.replacingOccurrences(of: "-", with: "")
        var result = Data(capacity: 16)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { throw ProtocolError.invalidUUID }
            result.append(byte)
            index = next
        }
        return result
    }

    /// Đúng dạng 8-4-4-4-12, hex chữ thường.
    public static func isCanonical(_ text: String) -> Bool {
        let utf8 = Array(text.utf8)
        guard utf8.count == 36 else { return false }
        for (offset, char) in utf8.enumerated() {
            if [8, 13, 18, 23].contains(offset) {
                guard char == UInt8(ascii: "-") else { return false }
            } else if !((0x30...0x39).contains(char) || (0x61...0x66).contains(char)) {
                return false
            }
        }
        return true
    }

    /// Nibble version (ký tự thứ 15) của uuid đúng dạng, ví dụ 7 cho `id` envelope.
    public static func version(of text: String) -> Int? {
        guard isCanonical(text) else { return nil }
        let char = text[text.index(text.startIndex, offsetBy: 14)]
        return char.hexDigitValue
    }

    /// Đúng dạng, đúng nibble version và variant `10` (ký tự thứ 20 ∈ 8, 9, a, b).
    public static func isValid(_ text: String, version expected: Int) -> Bool {
        guard version(of: text) == expected else { return false }
        let variant = text[text.index(text.startIndex, offsetBy: 19)]
        return "89ab".contains(variant)
    }
}
