import Foundation
import Testing
@testable import HLCrypto

/// Vector nguyên thủy S0.1: HChaCha20, XChaCha20-Poly1305, ChaCha20-Poly1305, X25519, HKDF, Ed25519/device_id.
@Suite("Vector nguyên thủy mã hóa")
struct PrimitiveVectorTests {
    @Test("HChaCha20 khớp draft §2.2.1 và mọi vector")
    func hchacha20() throws {
        let file = try VectorFile("hchacha20.json")
        #expect(try file.vectors[0].string("name") == "draft §2.2.1")
        for vector in file.vectors {
            let subkey = try HChaCha20.subkey(key: try vector.hex("key"), nonce: try vector.hex("nonce"))
            #expect(Hex.encode(subkey) == (try vector.string("subkey")), "\(vector.label)")
        }
    }

    @Test("XChaCha20-Poly1305: seal khớp byte, open ra plaintext, tham số dẫn xuất khớp")
    func xchacha20Poly1305() throws {
        let file = try VectorFile("xchacha20-poly1305.json")
        #expect(try file.vectors[0].string("name") == "draft A.3.1")
        for vector in file.vectors {
            let key = try vector.hex("key"), nonce = try vector.hex("nonce"), aad = try vector.hex("aad")
            let params = try XChaCha20Poly1305.derivedChaChaParameters(key: key, nonce: nonce)
            #expect(Hex.encode(params.subkey) == (try vector.string("hchacha20_subkey")))
            #expect(Hex.encode(params.nonce) == (try vector.string("chacha20_nonce")))
            let sealed = try XChaCha20Poly1305.seal(try vector.hex("plaintext"), key: key, nonce: nonce, aad: aad)
            #expect(Hex.encode(sealed.ciphertext) == (try vector.string("ciphertext")))
            #expect(Hex.encode(sealed.tag) == (try vector.string("tag")))
            let opened = try XChaCha20Poly1305.open(ciphertext: sealed.ciphertext, tag: sealed.tag,
                                                    key: key, nonce: nonce, aad: aad)
            #expect(opened == (try vector.hex("plaintext")))
        }
        for vector in file.invalidVectors {
            #expect(throws: CryptoError.authenticationFailed, "\(vector.label)") {
                try XChaCha20Poly1305.open(ciphertext: try vector.hex("ciphertext"), tag: try vector.hex("tag"),
                                           key: try vector.hex("key"), nonce: try vector.hex("nonce"),
                                           aad: try vector.hex("aad"))
            }
        }
    }

    @Test("ChaCha20-Poly1305 RFC 8439 (CryptoKit ChaChaPoly) — lớp dưới của XChaCha")
    func chacha20Poly1305() throws {
        let file = try VectorFile("chacha20-poly1305.json")
        for vector in file.vectors {
            let result = try ChaChaPolyReference.seal(vector)
            #expect(Hex.encode(result.ciphertext) == (try vector.string("ciphertext")))
            #expect(Hex.encode(result.tag) == (try vector.string("tag")))
        }
        for vector in file.invalidVectors {
            #expect(throws: (any Error).self, "\(vector.label)") {
                try ChaChaPolyReference.open(vector)
            }
        }
    }

    @Test("X25519 RFC 7748 §5.2, §6.1")
    func x25519() throws {
        for vector in try VectorFile("x25519.json").vectors {
            let output = try X25519.sharedSecret(privateKey: try vector.hex("scalar"), peerPublicKey: try vector.hex("u"))
            #expect(Hex.encode(output) == (try vector.string("output")), "\(vector.label)")
            if try vector.string("u") == "09" + String(repeating: "0", count: 62) {
                #expect(Hex.encode(try X25519.publicKey(privateKey: try vector.hex("scalar"))) == (try vector.string("output")))
            }
        }
    }

    @Test("HKDF-SHA256 RFC 5869 A.1–A.3 (extract + expand, salt rỗng)")
    func hkdf() throws {
        for vector in try VectorFile("hkdf-sha256.json").vectors {
            let prk = HKDFSHA256.extract(ikm: try vector.hex("ikm"), salt: try vector.hex("salt"))
            #expect(Hex.encode(prk) == (try vector.string("prk")))
            let okm = HKDFSHA256.expand(prk: prk, info: try vector.hex("info"), length: Int(try vector.int("length")))
            #expect(Hex.encode(okm) == (try vector.string("okm")))
        }
    }

    @Test("Ed25519 seed → khóa công khai RFC 8032; device_id UUIDv8 khớp device-id.json")
    func deviceIdentity() throws {
        for vector in try VectorFile("device-id.json").vectors {
            let publicKey = try Ed25519.publicKey(seed: try vector.hex("ik_sig_seed"))
            #expect(Hex.encode(publicKey) == (try vector.string("ik_sig_pub")))
            #expect(Hex.encode(HMACSHA256.sha256(publicKey)) == (try vector.string("sha256")))
            #expect(Hex.encode(try DeviceIdentity.deviceIdBytes(signingPublicKey: publicKey))
                    == (try vector.string("device_id_bytes")))
            #expect(try DeviceIdentity.deviceId(signingPublicKey: publicKey) == (try vector.string("device_id")))
            #expect(DeviceIdentity.matches(deviceId: try vector.string("device_id"), signingPublicKey: publicKey))
            let signature = try Ed25519.sign(Data("HLAUTH1".utf8), seed: try vector.hex("ik_sig_seed"))
            #expect(Ed25519.verify(signature, message: Data("HLAUTH1".utf8), publicKey: publicKey))
        }
    }

    @Test("Nonce ngẫu nhiên: 24 byte, khác nhau; seal/open vòng tròn")
    func randomNonceRoundTrip() throws {
        let key = Data(repeating: 1, count: 32)
        let first = try XChaCha20Poly1305.seal(Data("a".utf8), key: key, aad: Data())
        let second = try XChaCha20Poly1305.seal(Data("a".utf8), key: key, aad: Data())
        #expect(first.nonce.count == 24 && first.nonce != second.nonce)
        #expect(try XChaCha20Poly1305.open(combined: first.combined, key: key, aad: Data()) == Data("a".utf8))
        #expect(throws: CryptoError.payloadTooShort) {
            try XChaCha20Poly1305.open(combined: Data(count: 39), key: key, aad: Data())
        }
    }
}
