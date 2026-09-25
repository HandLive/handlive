import Foundation
import Testing
@testable import HLProtocol

/// Phần không cần khóa của envelope.json, ack.json, clipboard-chunk.json: dạng wire, AAD, tách payload.
/// Giải mã/mã hóa kiểm ở HLCrypto.
@Suite("Envelope theo vector S0.1")
struct EnvelopeVectorTests {
    @Test("Parse → wire khớp byte, AAD khớp, payload tách đúng", arguments: [
        "envelope.json", "ack.json", "clipboard-chunk.json"
    ])
    func envelopeFields(file: String) throws {
        for vector in try VectorFile(file).vectors {
            let wire = try vector.string("envelope")
            let envelope = try Envelope.parse(Data(wire.utf8))
            #expect(envelope.wireString() == wire)
            #expect(envelope.type.rawValue == (try vector.string("type")))
            #expect(Int64(envelope.v) == (try vector.int("v")))
            #expect(envelope.id == (try vector.string("id")))
            #expect(envelope.ts == (try vector.int("ts")))
            #expect(envelope.payload == (try vector.string("payload_b64")))
            if try vector.bool("encrypted") {
                #expect(envelope.aad == Data(try vector.string("aad").utf8))
                #expect(envelope.aad == (try vector.hex("aad_hex")))
                let combined = try vector.hex("nonce") + vector.hex("ciphertext") + vector.hex("tag")
                #expect(try envelope.payloadBytes == combined)
            } else {
                #expect(try envelope.payloadBytes == Data(try vector.string("plaintext").utf8))
            }
        }
    }

    @Test("Envelope bắt tay trong session-handshake và stream-keys parse được, payload là JSON {op, data}")
    func handshakeEnvelopes() throws {
        let pairs: [(String, [String])] = [
            ("session-handshake.json", ["hello", "welcome"]),
            ("stream-keys.json", ["stream_hello", "stream_welcome"])
        ]
        for (file, names) in pairs {
            for vector in try VectorFile(file).vectors {
                for name in names {
                    let envelope = try Envelope.parse(Data(try vector.string("\(name)_envelope").utf8))
                    let payload = try Payload.parse(try envelope.payloadBytes)
                    let expected = try Payload.parse(Data(try vector.string("\(name)_plaintext").utf8))
                    #expect(payload == expected)
                    #expect(payload.op == name)
                }
            }
        }
    }

    @Test("Plaintext ack trong ack.json: re, ok, error.code")
    func ackPlaintexts() throws {
        for vector in try VectorFile("ack.json").vectors {
            let ack = try Ack.parse(Data(try vector.string("plaintext").utf8))
            #expect(ack.re == (try vector.string("re")))
            #expect(ack.ok == (try vector.bool("ok")))
            if !ack.ok {
                #expect(ack.error?.code == .smsNoService)
            }
            #expect(try Ack.parse(ack.encoded()) == ack)
        }
    }

    @Test("Envelope sai dạng bị từ chối")
    func rejectsMalformedEnvelopes() {
        let payload = Base64Coding.encodeB64(Data(count: 40))
        let id = "0192f3e8-1b2c-7d3f-8a01-5a6b7c8d9e10"
        let cases: [(String, ProtocolError)] = [
            ("{\"v\":2,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":1,\"payload\":\"\(payload)\"}", .unsupportedVersion(2)),
            ("{\"v\":1,\"type\":\"mms\",\"id\":\"\(id)\",\"ts\":1,\"payload\":\"\(payload)\"}", .unsupportedType("mms")),
            ("{\"v\":1,\"type\":\"sms\",\"id\":\"\(id.uppercased())\",\"ts\":1,\"payload\":\"\(payload)\"}",
             .invalidField("id")),
            ("{\"v\":1,\"type\":\"sms\",\"id\":\"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d\",\"ts\":1,\"payload\":\"\(payload)\"}",
             .invalidField("id")),
            ("{\"v\":1,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":true,\"payload\":\"\(payload)\"}", .invalidField("ts")),
            ("{\"v\":1,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":-1,\"payload\":\"\(payload)\"}", .invalidField("ts")),
            ("{\"v\":1,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":1,\"payload\":\"AAA\"}", .invalidBase64),
            ("{\"v\":1,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":1}", .missingField("payload")),
            ("{\"v\":1,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":1,\"payload\":\"\(payload)\",\"x\":1}",
             .invalidField("envelope"))
        ]
        for (wire, expected) in cases {
            #expect(throws: expected) { try Envelope.parse(Data(wire.utf8)) }
        }
    }

    @Test("Envelope bắt tay dựng từ plaintext: payload = b64 của JSON")
    func plainEnvelope() throws {
        let plaintext = Data("{\"op\":\"bye\",\"data\":{\"reason\":\"shutdown\"}}".utf8)
        let envelope = Envelope(type: .session, plainPayload: plaintext)
        #expect(HLUUID.isValid(envelope.id, version: 7))
        let parsed = try Envelope.parse(envelope.wireData())
        #expect(parsed == envelope)
        #expect(try parsed.payloadBytes == plaintext)
    }
}
