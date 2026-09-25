import Foundation

/// `b64` (RFC 4648 §4, có padding) và `b64u` (RFC 4648 §5, không padding) theo 0.3.
/// Giải mã chặt: từ chối ký tự lạ, thiếu/thừa padding, khoảng trắng.
public enum Base64Coding {
    public static func encodeB64(_ data: Data) -> String {
        data.base64EncodedString()
    }

    public static func decodeB64(_ text: String) throws -> Data {
        guard text.utf8.count % 4 == 0,
              text.utf8.allSatisfy({ isStandardAlphabet($0) || $0 == UInt8(ascii: "=") }),
              let data = Data(base64Encoded: text),
              encodeB64(data) == text
        else { throw ProtocolError.invalidBase64 }
        return data
    }

    public static func encodeB64u(_ data: Data) -> String {
        var text = data.base64EncodedString()
        text = text.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        while text.hasSuffix("=") { text.removeLast() }
        return text
    }

    public static func decodeB64u(_ text: String) throws -> Data {
        guard text.utf8.count % 4 != 1,
              text.utf8.allSatisfy({ isURLAlphabet($0) })
        else { throw ProtocolError.invalidBase64 }
        var standard = text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        standard += String(repeating: "=", count: (4 - standard.utf8.count % 4) % 4)
        // Dạng chuẩn tắc: mã hóa lại phải ra đúng chuỗi (bit thừa ở ký tự cuối = 0).
        guard let data = Data(base64Encoded: standard), encodeB64u(data) == text else {
            throw ProtocolError.invalidBase64
        }
        return data
    }

    private static func isAlnum(_ byte: UInt8) -> Bool {
        (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte)
    }

    private static func isStandardAlphabet(_ byte: UInt8) -> Bool {
        isAlnum(byte) || byte == UInt8(ascii: "+") || byte == UInt8(ascii: "/")
    }

    private static func isURLAlphabet(_ byte: UInt8) -> Bool {
        isAlnum(byte) || byte == UInt8(ascii: "-") || byte == UInt8(ascii: "_")
    }
}
