import Foundation
import HLProtocol
import Testing
@testable import HLCrypto

/// Liên nền tảng (phase-00 Kiểm thử): Apple ghi `envelope-roundtrip-apple.json` khi `HL_WRITE_ROUNDTRIP=1`
/// (khóa cố định lấy từ envelope.json, nonce và id mới), và luôn giải mã file của mình
/// cùng `envelope-roundtrip.json` do Android (A0.1) ghi nếu có.
@Suite("Envelope liên nền tảng")
struct EnvelopeRoundTripTests {
    static let appleFile = "envelope-roundtrip-apple.json"
    static let androidFile = "envelope-roundtrip.json"

    @Test("Ghi envelope-roundtrip-apple.json",
          .enabled(if: ProcessInfo.processInfo.environment["HL_WRITE_ROUNDTRIP"] == "1"))
    func writeAppleRoundTrip() throws {
        var vectors: [[(String, Any)]] = []
        for source in try VectorFile("envelope.json").vectors where try source.bool("encrypted") {
            let key = try source.hex("key")
            let plaintext = try source.string("plaintext")
            let type = try #require(MessageType(rawValue: try source.string("type")))
            let nonce = XChaCha20Poly1305.randomNonce()
            let envelope = try EnvelopeCipher.seal(type: type, plaintext: Data(plaintext.utf8), key: key, nonce: nonce)
            let sealed = try Base64Coding.decodeB64(envelope.payload)
            vectors.append([
                ("name", "Apple: \(source.label)"), ("encrypted", true), ("direction", try source.string("direction")),
                ("key", Hex.encode(key)), ("key_source", try source.string("key_source")), ("v", envelope.v),
                ("type", type.rawValue), ("id", envelope.id), ("ts", envelope.ts),
                ("aad", String(bytes: envelope.aad, encoding: .utf8) ?? ""), ("aad_hex", Hex.encode(envelope.aad)),
                ("plaintext", plaintext), ("nonce", Hex.encode(nonce)),
                ("ciphertext", Hex.encode(sealed.subdata(in: 24..<(sealed.count - 16)))),
                ("tag", Hex.encode(sealed.suffix(16))), ("payload_b64", envelope.payload),
                ("envelope", envelope.wireString())
            ])
        }
        let text = try OrderedJSONWriter.document(
            description: "Envelope do Apple (HLCrypto: HChaCha20 + CryptoKit ChaChaPoly) mã hóa bằng khóa cố định "
                + "của envelope.json, nonce và id mới; Android/relay phải giải mã được. Cùng định dạng envelope.json.",
            source: "apple/Packages/HLCrypto/Tests/HLCryptoTests/envelope-roundtrip-tests.swift (HL_WRITE_ROUNDTRIP=1)",
            vectors: vectors)
        try Data(text.utf8).write(to: RepoFiles.vectorsDirectory.appendingPathComponent(Self.appleFile))
    }

    @Test("Giải mã file roundtrip của Apple và Android (nếu có)", arguments: [appleFile, androidFile])
    func decryptRoundTrip(file: String) throws {
        let url = RepoFiles.vectorsDirectory.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let vectors = try VectorFile(file).vectors
        #expect(vectors.count >= 2)
        for vector in vectors where (vector["encrypted"] as? Bool) ?? true {
            let envelope = try Envelope.parse(Data(try vector.string("envelope").utf8))
            let plaintext = try EnvelopeCipher.open(envelope, key: try vector.hex("key"))
            #expect(plaintext == Data(try vector.string("plaintext").utf8), "\(file): \(vector.label)")
            // Plaintext phải là JSON hợp lệ theo loại: ack → {re, ok, …}, còn lại → {op, data}.
            if envelope.type == .ack {
                _ = try Ack.parse(plaintext)
            } else {
                _ = try Payload.parse(plaintext)
            }
            if let nonce = vector["nonce"] as? String, let tag = vector["tag"] as? String,
               let ciphertext = vector["ciphertext"] as? String {
                #expect(Hex.encode(try envelope.payloadBytes) == nonce + ciphertext + tag)
            }
        }
    }
}

/// Ghi JSON giữ thứ tự khóa, thụt 2 dấu cách, UTF-8 không escape — cùng kiểu các file vector do Python sinh.
enum OrderedJSONWriter {
    static func document(description: String, source: String, vectors: [[(String, Any)]]) throws -> String {
        let items = try vectors.map { vector in
            try "    {\n" + vector.map { "      \(try scalar($0.0)): \(try scalar($0.1))" }.joined(separator: ",\n") + "\n    }"
        }
        return "{\n  \"description\": \(try scalar(description)),\n  \"source\": \(try scalar(source)),\n"
            + "  \"vectors\": [\n" + items.joined(separator: ",\n") + "\n  ]\n}\n"
    }

    private static func scalar(_ value: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .withoutEscapingSlashes])
        return String(bytes: data, encoding: .utf8) ?? ""
    }
}
