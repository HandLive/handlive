import Foundation

/// Lỗi mã hóa. Không mang khóa hay plaintext.
public enum CryptoError: Error, Equatable, Sendable {
    case invalidKeyLength(expected: Int, actual: Int)
    case invalidNonceLength(expected: Int, actual: Int)
    /// Tag Poly1305 sai (tag/AAD/ciphertext bị sửa hoặc sai khóa) → `DECRYPT_FAILED`.
    case authenticationFailed
    /// Phần mã hóa ngắn hơn nonce(24) + tag(16).
    case payloadTooShort
    case invalidPublicKey
    case keychain(status: Int32)
}

enum Bytes {
    static func require(_ data: Data, count: Int, isNonce: Bool = false) throws {
        guard data.count == count else {
            throw isNonce
                ? CryptoError.invalidNonceLength(expected: count, actual: data.count)
                : CryptoError.invalidKeyLength(expected: count, actual: data.count)
        }
    }

    /// Byte ngẫu nhiên từ CSPRNG của hệ thống.
    static func random(_ count: Int) -> Data {
        var generator = SystemRandomNumberGenerator()
        return Data((0..<count).map { _ in generator.next() })
    }
}
