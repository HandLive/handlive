import CryptoKit
import Foundation

/// HKDF-SHA256 (RFC 5869). Spec không ghi salt → salt rỗng (≡ 32 byte 0); không ghi L → L = 32 (0.6.3 bước 8).
public enum HKDFSHA256 {
    public static func extract(ikm: Data, salt: Data = Data()) -> Data {
        let prk = HKDF<SHA256>.extract(inputKeyMaterial: SymmetricKey(data: ikm), salt: salt)
        return Data(prk)
    }

    public static func expand(prk: Data, info: Data, length: Int) -> Data {
        let okm = HKDF<SHA256>.expand(pseudoRandomKey: prk, info: info, outputByteCount: length)
        return okm.withUnsafeBytes { Data($0) }
    }

    public static func derive(ikm: Data, salt: Data = Data(), info: String, length: Int = 32) -> Data {
        expand(prk: extract(ikm: ikm, salt: salt), info: Data(info.utf8), length: length)
    }
}

/// HMAC-SHA256 và SHA-256.
public enum HMACSHA256 {
    public static func mac(key: Data, message: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: key)))
    }

    /// So sánh hằng thời gian (CryptoKit `isValidAuthenticationCode`).
    public static func verify(_ mac: Data, key: Data, message: Data) -> Bool {
        HMAC<SHA256>.isValidAuthenticationCode(mac, authenticating: message, using: SymmetricKey(data: key))
    }

    public static func sha256(_ data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
}
