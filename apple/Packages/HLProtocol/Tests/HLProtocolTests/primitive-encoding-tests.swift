import Foundation
import Testing
@testable import HLProtocol

@Suite("b64/b64u, UUID, danh mục type và mã lỗi")
struct PrimitiveEncodingTests {
    @Test("b64 có padding, b64u không padding, giải mã chặt")
    func base64Strictness() throws {
        let bytes = Data([0xFB, 0xFF, 0x00, 0x10])
        #expect(Base64Coding.encodeB64(bytes) == "+/8AEA==")
        #expect(Base64Coding.encodeB64u(bytes) == "-_8AEA")
        #expect(try Base64Coding.decodeB64("+/8AEA==") == bytes)
        #expect(try Base64Coding.decodeB64u("-_8AEA") == bytes)
        for bad in ["+/8AEA", "+/8AEA=", "-_8AEA==", " +/8AEA==", "+/8A\nEA=="] {
            #expect(throws: ProtocolError.invalidBase64) { try Base64Coding.decodeB64(bad) }
        }
        for bad in ["-_8AEA==", "+/8AEA", "A", "AB"] {
            #expect(throws: ProtocolError.invalidBase64) { try Base64Coding.decodeB64u(bad) }
        }
    }

    @Test("eph/nonce/mac trong hello_plaintext là b64u của byte trong vector")
    func b64uMatchesHandshakeVector() throws {
        for vector in try VectorFile("session-handshake.json").vectors {
            let hello = try Payload.parse(Data(try vector.string("hello_plaintext").utf8))
            let data = try hello.decodeData(as: SessionHelloData.self)
            #expect(data.eph == Base64Coding.encodeB64u(try vector.hex("client_eph_pub")))
            #expect(data.nonce == Base64Coding.encodeB64u(try vector.hex("client_nonce")))
            #expect(data.mac == Base64Coding.encodeB64u(try vector.hex("hello_mac")))
            #expect(try Base64Coding.decodeB64u(data.eph) == (try vector.hex("client_eph_pub")))
        }
    }

    @Test("UUIDv7: 36 ký tự thường, version 7, variant 10, 48 bit thời gian")
    func uuidV7() throws {
        let timestamp: Int64 = 1_727_150_000_123
        let id = HLUUID.v7(timestampMs: timestamp)
        #expect(HLUUID.isValid(id, version: 7))
        let bytes = try HLUUID.bytes(from: id)
        let millis = bytes.prefix(6).reduce(Int64(0)) { ($0 << 8) | Int64($1) }
        #expect(millis == timestamp)
        #expect(HLUUID.string(from: bytes) == id)
        #expect(Set((0..<100).map { _ in HLUUID.v7() }).count == 100)
        #expect(throws: ProtocolError.invalidUUID) { try HLUUID.bytes(from: id.uppercased()) }
        #expect(!HLUUID.isValid("0192f3c1-7c1e-7a55-7d0b-3f4c2a1b9e10", version: 7))
    }

    @Test("uuid ↔ 16 byte khớp device-id.json")
    func uuidBytesMatchVectors() throws {
        for vector in try VectorFile("device-id.json").vectors {
            let text = try vector.string("device_id")
            #expect(try HLUUID.bytes(from: text) == (try vector.hex("device_id_bytes")))
            #expect(HLUUID.isValid(text, version: 8))
        }
    }

    @Test("MessageType đúng enum type của envelope.schema.json (0.7.1)")
    func messageTypesMatchSchema() throws {
        let schema = try RepoFiles.json(at: RepoFiles.schemasDirectory.appendingPathComponent("envelope.schema.json"))
        let defs = (schema as? [String: Any])?["$defs"] as? [String: Any]
        let values = try #require((defs?["type"] as? [String: Any])?["enum"] as? [String])
        #expect(Set(MessageType.allCases.map(\.rawValue)) == Set(values))
    }

    @Test("ErrorCode đúng bảng 0.8.1 của 00-common-specs.md và enum error.schema.json")
    func errorCodesMatchSpec() throws {
        let spec = try String(
            contentsOf: RepoFiles.root.appendingPathComponent("docs/detailed-design/00-common-specs.md"),
            encoding: .utf8
        )
        let section = try #require(spec.components(separatedBy: "### 0.8.1").dropFirst().first?
            .components(separatedBy: "### 0.8.2").first)
        let specCodes = section.split(separator: "\n").compactMap { line -> String? in
            guard line.hasPrefix("| `") else { return nil }
            return line.dropFirst(3).split(separator: "`").first.map(String.init)
        }
        let ours = ErrorCode.allCases.filter { $0 != .unrecognized }.map(\.rawValue)
        #expect(ours == specCodes)

        let schema = try RepoFiles.json(at: RepoFiles.schemasDirectory.appendingPathComponent("error.schema.json"))
        let defs = (schema as? [String: Any])?["$defs"] as? [String: Any]
        let schemaCodes = try #require((defs?["code"] as? [String: Any])?["enum"] as? [String])
        #expect(ours == schemaCodes)
    }
}
