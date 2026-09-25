import Foundation
import Testing
@testable import HLProtocol

/// 0.5.1 quy tắc 6: trong cùng major `protocol`, bên nhận bỏ qua trường lạ và không hỏng tin vì giá trị enum lạ.
@Suite("Tương thích tiến: trường lạ, giá trị enum lạ")
struct ForwardCompatibilityTests {
    private let decoder = JSONDecoder()

    @Test("Ack có mã lỗi mới hơn vẫn giải được, mã thành .unrecognized, giữ message")
    func unknownErrorCode() throws {
        let json = #"{"re":"0192f3c1-7c1e-7a55-9d0b-3f4c2a1b9e10","ok":false,"#
            + #""error":{"code":"SMS_QUOTA_NEW","message":"Hết hạn mức"}}"#
        let ack = try decoder.decode(Ack.self, from: Data(json.utf8))
        #expect(ack.error?.code == .unrecognized)
        #expect(ack.error?.message == "Hết hạn mức")
    }

    @Test("session/error và session/bye với giá trị lạ vẫn giải được")
    func unknownSessionValues() throws {
        let error = try decoder.decode(SessionErrorData.self, from: Data(#"{"code":"NEW_CODE","message":"x"}"#.utf8))
        #expect(error.code == .unrecognized)
        let bye = try decoder.decode(SessionByeData.self, from: Data(#"{"reason":"migrated","extra":1}"#.utf8))
        #expect(bye.reason == .unrecognized)
    }

    @Test("capability từ phiên bản mới hơn: platform, codec, facing, reason lạ và trường lạ")
    func newerCapability() throws {
        let json = #"""
        {"protocol":1,"app_version":"1.4.0 (140)","platform":"visionos","os_version":"3","model":"X","future":true,
         "features":{"camera":{"enabled":true,"cameras":["front","external"],"codecs":["h264","h265"]},
                     "call_audio":{"enabled":true,"bt_address":null,"hfp_connected":false,
                                   "opus_fallback":{"available":false,"downlink":false,"uplink":false,"reason":"new_reason"}},
                     "hologram":{"enabled":true}}}
        """#
        let data = try decoder.decode(CapabilityData.self, from: Data(json.utf8))
        #expect(data.platform == .unrecognized)
        #expect(data.features.camera?.codecs == [.h264, .unrecognized])
        #expect(data.features.camera?.cameras == [.front, .unrecognized])
        #expect(data.features.callAudio?.opusFallback?.reason == .unrecognized)
    }

    @Test("Envelope có trường lạ vẫn phân tích được")
    func envelopeUnknownField() throws {
        let id = "0192f3c1-7c1e-7a55-9d0b-3f4c2a1b9e10"
        let wire = "{\"v\":1,\"type\":\"sms\",\"id\":\"\(id)\",\"ts\":1,\"payload\":\"AAAA\",\"x\":1}"
        let envelope = try Envelope.parse(Data(wire.utf8))
        #expect(envelope.id == id)
    }
}
