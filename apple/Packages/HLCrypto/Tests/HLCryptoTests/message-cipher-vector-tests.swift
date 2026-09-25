import Foundation
import HLProtocol
import Testing
@testable import HLCrypto

/// Envelope, ack, clipboard/chunk và khung HL mã hóa bằng khóa cố định (S0.1).
@Suite("Vector mã hóa envelope và khung HL")
struct MessageCipherVectorTests {
    @Test("Envelope mã hóa: seal với nonce cố định khớp wire byte, open ra plaintext",
          arguments: ["envelope.json", "ack.json", "clipboard-chunk.json"])
    func encryptedEnvelopes(file: String) throws {
        for vector in try VectorFile(file).vectors where try vector.bool("encrypted") {
            let plaintext = vector["plaintext"] is String
                ? Data(try vector.string("plaintext").utf8) : try vector.hex("plaintext_hex")
            let type = try #require(MessageType(rawValue: try vector.string("type")))
            let sealed = try EnvelopeCipher.seal(type: type, plaintext: plaintext, key: try vector.hex("key"),
                                                 id: try vector.string("id"), ts: try vector.int("ts"),
                                                 nonce: try vector.hex("nonce"))
            #expect(sealed.wireString() == (try vector.string("envelope")), "\(vector.label)")
            let received = try Envelope.parse(Data(try vector.string("envelope").utf8))
            #expect(try EnvelopeCipher.open(received, key: try vector.hex("key")) == plaintext)
            if file == "clipboard-chunk.json" {
                let chunk = try ClipboardChunkPlaintext.parse(plaintext)
                #expect(chunk.chunk == (try vector.hex("chunk_data")))
            }
        }
    }

    @Test("Envelope hỏng bị từ chối: tag sai, AAD sai (ts/type sửa), payload < 40 byte",
          arguments: ["envelope.json", "ack.json", "clipboard-chunk.json"])
    func invalidEnvelopes(file: String) throws {
        let invalid = try VectorFile(file).invalidVectors
        #expect(!invalid.isEmpty)
        for vector in invalid {
            let envelope = try Envelope.parse(Data(try vector.string("envelope").utf8))
            let expected: CryptoError = try vector.string("reason") == "payload_too_short"
                ? .payloadTooShort : .authenticationFailed
            #expect(throws: expected, "\(vector.label)") {
                try EnvelopeCipher.open(envelope, key: try vector.hex("key"))
            }
        }
    }

    @Test("Khung HL: seal khớp byte, open ra header + plaintext")
    func hlFrames() throws {
        for vector in try VectorFile("hl-frame.json").vectors {
            let header = HLFrameHeader(seq: UInt32(try vector.int("seq")), ts: UInt32(try vector.int("ts")))
            let frame = try HLFrameCipher.seal(header: header, plaintext: try vector.hex("plaintext"),
                                               key: try vector.hex("key"), nonce: try vector.hex("nonce"))
            #expect(Hex.encode(frame) == (try vector.string("frame")), "\(vector.label)")
            let opened = try HLFrameCipher.open(frame, key: try vector.hex("key"))
            let expected = try vector.hex("plaintext")
            #expect(opened.header == header)
            #expect(opened.plaintext == expected)
        }
        for vector in try VectorFile("hl-frame.json").invalidVectors {
            #expect(throws: CryptoError.authenticationFailed, "\(vector.label)") {
                try HLFrameCipher.open(try vector.hex("frame"), key: try vector.hex("key"))
            }
        }
    }
}

@Suite("Kho bí mật")
struct SecretStoreTests {
    @Test("InMemorySecretStore lưu/đọc/xóa theo account")
    func inMemory() throws {
        let store: any SecretStore = InMemorySecretStore()
        let account = SecretAccount.pairKey(pairId: "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d")
        #expect(try store.load(account: account) == nil)
        try store.save(Data([1, 2, 3]), account: account)
        try store.save(Data([4]), account: SecretAccount.signingKey)
        #expect(try store.load(account: account) == Data([1, 2, 3]))
        try store.delete(account: account)
        #expect(try store.load(account: account) == nil)
        #expect(try store.load(account: SecretAccount.signingKey) == Data([4]))
    }

    @Test("Truy vấn Keychain: generic password, service app.handlive.keys, WhenUnlockedThisDeviceOnly")
    func keychainQuery() {
        let query = KeychainSecretStore().addQuery(Data([9]), account: SecretAccount.keyAgreementKey)
        #expect(query[kSecClass as String] as? String == kSecClassGenericPassword as String)
        #expect(query[kSecAttrService as String] as? String == "app.handlive.keys")
        #expect(query[kSecAttrAccount as String] as? String == "ik_dh")
        #expect(query[kSecAttrAccessible as String] as? String
                == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        #expect(query[kSecValueData as String] as? Data == Data([9]))
    }
}
