import CryptoKit
import Foundation

/// Gọi thẳng CryptoKit `ChaChaPoly` (nonce 12 byte) cho vector RFC 8439.
enum ChaChaPolyReference {
    static func seal(_ vector: [String: Any]) throws -> (ciphertext: Data, tag: Data) {
        let box = try ChaChaPoly.seal(
            try vector.hex("plaintext"),
            using: SymmetricKey(data: try vector.hex("key")),
            nonce: ChaChaPoly.Nonce(data: try vector.hex("nonce")),
            authenticating: try vector.hex("aad")
        )
        return (box.ciphertext, box.tag)
    }

    static func open(_ vector: [String: Any]) throws -> Data {
        let box = try ChaChaPoly.SealedBox(
            nonce: ChaChaPoly.Nonce(data: try vector.hex("nonce")),
            ciphertext: try vector.hex("ciphertext"),
            tag: try vector.hex("tag")
        )
        return try ChaChaPoly.open(box, using: SymmetricKey(data: try vector.hex("key")),
                                   authenticating: try vector.hex("aad"))
    }
}
