import CryptoKit
import Foundation

/// AEAD_XChaCha20_Poly1305 = HChaCha20(key, nonce[0:16]) → subkey, rồi CryptoKit `ChaChaPoly`
/// với nonce 12 byte = `0x00000000` ‖ nonce[16:24] (00-common-specs 0.6.1).
public enum XChaCha20Poly1305 {
    public static let keyByteCount = 32
    public static let nonceByteCount = 24
    public static let tagByteCount = 16

    public struct Sealed: Equatable, Sendable {
        public let nonce: Data
        public let ciphertext: Data
        public let tag: Data

        /// `nonce(24) ‖ ciphertext ‖ tag(16)` — dạng dùng trong payload envelope và khung HL.
        public var combined: Data { nonce + ciphertext + tag }
    }

    public static func randomNonce() -> Data {
        Bytes.random(nonceByteCount)
    }

    /// Subkey và nonce 12 byte cho `ChaChaPoly` (lộ ra để test đối chiếu `hchacha20_subkey`, `chacha20_nonce`).
    public static func derivedChaChaParameters(key: Data, nonce: Data) throws -> (subkey: Data, nonce: Data) {
        try Bytes.require(key, count: keyByteCount)
        try Bytes.require(nonce, count: nonceByteCount, isNonce: true)
        let subkey = try HChaCha20.subkey(key: key, nonce: nonce.prefix(16))
        return (subkey, Data(count: 4) + nonce.suffix(8))
    }

    public static func seal(_ plaintext: Data, key: Data, nonce: Data = randomNonce(), aad: Data) throws -> Sealed {
        let params = try derivedChaChaParameters(key: key, nonce: nonce)
        let box = try ChaChaPoly.seal(
            plaintext,
            using: SymmetricKey(data: params.subkey),
            nonce: ChaChaPoly.Nonce(data: params.nonce),
            authenticating: aad
        )
        return Sealed(nonce: Data(nonce), ciphertext: box.ciphertext, tag: box.tag)
    }

    public static func open(ciphertext: Data, tag: Data, key: Data, nonce: Data, aad: Data) throws -> Data {
        let params = try derivedChaChaParameters(key: key, nonce: nonce)
        guard tag.count == tagByteCount else { throw CryptoError.authenticationFailed }
        do {
            let box = try ChaChaPoly.SealedBox(
                nonce: ChaChaPoly.Nonce(data: params.nonce), ciphertext: ciphertext, tag: tag
            )
            return try ChaChaPoly.open(box, using: SymmetricKey(data: params.subkey), authenticating: aad)
        } catch {
            throw CryptoError.authenticationFailed
        }
    }

    /// Mở `nonce(24) ‖ ciphertext ‖ tag(16)`; ngắn hơn 40 byte → `payloadTooShort`.
    public static func open(combined: Data, key: Data, aad: Data) throws -> Data {
        let bytes = Data(combined)
        guard bytes.count >= nonceByteCount + tagByteCount else { throw CryptoError.payloadTooShort }
        return try open(
            ciphertext: bytes.subdata(in: nonceByteCount..<(bytes.count - tagByteCount)),
            tag: bytes.suffix(tagByteCount),
            key: key,
            nonce: bytes.prefix(nonceByteCount),
            aad: aad
        )
    }
}
