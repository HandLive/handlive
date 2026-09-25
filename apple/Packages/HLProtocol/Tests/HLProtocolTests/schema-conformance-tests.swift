import Foundation
import Testing
@testable import HLProtocol

/// Đối chiếu JSON do HLProtocol sinh ra và plaintext trong vector với `shared/schemas/` (S0.2)
/// bằng bộ kiểm JSON Schema rút gọn (xem json-schema-subset-validator.swift).
@Suite("Đối chiếu JSON Schema S0.2")
struct SchemaConformanceTests {
    let validator: SchemaValidator

    init() throws {
        validator = try SchemaValidator()
    }

    private func object(_ data: Data) throws -> Any {
        try JSONSerialization.jsonObject(with: data)
    }

    private func expectValid(_ data: Data, _ ref: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let errors = validator.errors(try object(data), ref: ref)
        #expect(errors.isEmpty, "\(ref): \(errors)", sourceLocation: sourceLocation)
    }

    @Test("Envelope và plaintext trong mọi vector qua schema")
    func vectorsConform() throws {
        for file in ["envelope.json", "ack.json", "clipboard-chunk.json"] {
            for vector in try VectorFile(file).vectors {
                try expectValid(Data(try vector.string("envelope").utf8), "envelope.schema.json")
                guard let plaintext = vector["plaintext"] as? String else { continue }
                let ref = file == "ack.json" ? "ack.schema.json"
                    : (try vector.string("type") == "session" ? "session-hello.schema.json" : "payload.schema.json")
                try expectValid(Data(plaintext.utf8), ref)
            }
        }
        for vector in try VectorFile("session-handshake.json").vectors {
            try expectValid(Data(try vector.string("hello_envelope").utf8), "envelope.schema.json")
            try expectValid(Data(try vector.string("hello_plaintext").utf8), "session-hello.schema.json")
            try expectValid(Data(try vector.string("welcome_plaintext").utf8), "session-welcome.schema.json")
        }
        for vector in try VectorFile("session-rekey.json").vectors {
            try expectValid(Data(try vector.string("request_plaintext").utf8), "session-rekey.schema.json")
            let data = try HLJSON.decode(JSONValue.self, from: Data(try vector.string("ack_data").utf8))
            let ack = Ack.success(re: HLUUID.v7(), data: data)
            try expectValid(try ack.encoded(), "session-rekey.schema.json#/$defs/ack")
        }
    }

    @Test("JSON sinh từ kiểu Swift qua schema: envelope, ack, session, capability")
    func generatedMessagesConform() throws {
        let b64u32 = Base64Coding.encodeB64u(Data(repeating: 7, count: 32))
        let deviceId = "21fe31df-a154-8261-a26b-f854046fd227"
        let envelope = Envelope(type: .clipboard, plainPayload: Data(count: 40))
        try expectValid(envelope.wireData(), "envelope.schema.json")

        try expectValid(try Ack.success(re: HLUUID.v7()).encoded(), "ack.schema.json")
        let failure = Ack.failure(re: HLUUID.v7(), error: AckError(
            code: .permissionMissing, message: "Thiếu quyền", details: .object(["permission": .string("READ_SMS")])
        ))
        try expectValid(try failure.encoded(), "ack.schema.json")

        let hello = SessionHelloData(pairId: "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d", deviceId: deviceId,
                                     eph: b64u32, nonce: b64u32, mac: b64u32)
        try expectValid(try TypedPayload(op: "hello", data: hello).encoded(), "session-hello.schema.json")
        let welcome = SessionWelcomeData(deviceId: deviceId, eph: b64u32, nonce: b64u32, mac: b64u32)
        try expectValid(try TypedPayload(op: "welcome", data: welcome).encoded(), "session-welcome.schema.json")
        for error in [SessionErrorData(code: .unsupportedVersion, message: "x", minProtocol: 2),
                      SessionErrorData(code: .authFailed, message: "x", minProtocol: 2)] {
            try expectValid(try TypedPayload(op: "error", data: error).encoded(), "session-error.schema.json")
        }
        let rekey = SessionRekeyData(epoch: 1, eph: b64u32, nonce: b64u32)
        try expectValid(try TypedPayload(op: "rekey", data: rekey).encoded(), "session-rekey.schema.json")
        let rekeyAck = Ack.success(re: HLUUID.v7(), data: try HLJSON.decode(JSONValue.self, from: HLJSON.encode(rekey)))
        try expectValid(try rekeyAck.encoded(), "session-rekey.schema.json#/$defs/ack")
        let bye = TypedPayload(op: "bye", data: SessionByeData(reason: .revoked))
        try expectValid(try bye.encoded(), "session-bye.schema.json")

        let mac = CapabilityData(appVersion: "1.0.0 (100)", platform: .macos, osVersion: "15.1", model: "Mac15,3",
                                 features: Features(
                                     clipboard: ClipboardFeature(enabled: true, autoSend: true,
                                                                 maxTextBytes: 1_048_576, maxImageBytes: 10_485_760,
                                                                 mimes: ["text/plain", "image/png"]),
                                     sms: SmsFeature(enabled: true),
                                     call: CallFeature(enabled: true),
                                     callAudio: CallAudioFeature(enabled: false, btAddress: "A1:B2:C3:D4:E5:F6",
                                                                 consented: false),
                                     camera: CameraFeature(enabled: true),
                                     relay: RelayFeature(enabled: true)))
        try expectValid(try TypedPayload(op: "hello", data: mac).encoded(), "capability-hello.schema.json")
        try expectValid(try TypedPayload(op: "update", data: mac).encoded(), "capability-update.schema.json")
    }

    @Test("Ví dụ capability/hello của 0.7.2 decode được, mã hóa lại vẫn qua schema")
    func specCapabilityExampleRoundTrips() throws {
        let example = """
        {"op":"hello","data":{"protocol":1,"app_version":"1.0.0 (100)","platform":"android","os_version":"15",
        "model":"Pixel 8","features":{"clipboard":{"enabled":true,"auto_send":true,"max_text_bytes":1048576,
        "max_image_bytes":10485760,"mimes":["text/plain","image/png","image/jpeg"]},
        "sms":{"enabled":true,"can_send":true,"sims":[{"sub_id":1,"slot":0,"label":"SIM 1"}]},
        "call":{"enabled":true,"can_answer":true,"can_end":true,"caller_id":true},
        "call_audio":{"enabled":false,"bt_address":null,"hfp_connected":false,
        "opus_fallback":{"available":false,"downlink":false,"uplink":false,"reason":"shizuku_not_running"}},
        "camera":{"enabled":true,"cameras":["front","back"],"max_width":1920,"max_height":1080,"max_fps":30,
        "codecs":["h264"]},"relay":{"enabled":true}},"permissions_missing":["READ_CALL_LOG"]}}
        """
        try expectValid(Data(example.utf8), "capability-hello.schema.json")
        let decoded = try HLJSON.decode(TypedPayload<CapabilityData>.self, from: Data(example.utf8))
        #expect(decoded.data.features.callAudio?.opusFallback?.reason == .shizukuNotRunning)
        #expect(decoded.data.features.sms?.sims?.first?.label == "SIM 1")
        try expectValid(try decoded.encoded(), "capability-hello.schema.json")
    }

    @Test("Bộ kiểm schema từ chối mẫu hỏng (tự kiểm bộ kiểm)")
    func validatorRejectsBrokenSamples() throws {
        let id = "0192f3e8-1b2c-7d3f-8a01-5a6b7c8d9e10"
        let payload = Base64Coding.encodeB64(Data(count: 40))
        let broken: [(String, String)] = [
            ("{\"v\":2,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":1,\"payload\":\"\(payload)\"}", "envelope.schema.json"),
            ("{\"v\":1,\"type\":\"mms\",\"id\":\"\(id)\",\"ts\":1,\"payload\":\"\(payload)\"}", "envelope.schema.json"),
            ("{\"v\":1,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":1}", "envelope.schema.json"),
            ("{\"re\":\"\(id)\",\"ok\":false,\"error\":{\"code\":\"NOPE\",\"message\":\"x\"}}", "ack.schema.json"),
            ("{\"re\":\"\(id)\",\"ok\":true}", "ack.schema.json"),
            ("{\"op\":\"error\",\"data\":{\"code\":\"AUTH_FAILED\",\"message\":\"x\",\"min_protocol\":2}}",
             "session-error.schema.json"),
            ("{\"op\":\"bye\",\"data\":{\"reason\":\"other\"}}", "session-bye.schema.json"),
            ("{\"op\":\"rekey\",\"data\":{\"epoch\":0,\"eph\":\"AA\",\"nonce\":\"AA\"}}", "session-rekey.schema.json")
        ]
        for (json, ref) in broken {
            #expect(!validator.errors(try object(Data(json.utf8)), ref: ref).isEmpty, "\(ref) phải từ chối \(json)")
        }
    }
}
