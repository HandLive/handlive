import Foundation
import Testing
@testable import HLProtocol

@Suite("Khung HL và chunk clipboard theo vector S0.1")
struct FrameAndChunkVectorTests {
    @Test("Header 11 byte, tách phần mã hóa, plaintext camera")
    func hlFrames() throws {
        for vector in try VectorFile("hl-frame.json").vectors {
            let header = HLFrameHeader(seq: UInt32(try vector.int("seq")), ts: UInt32(try vector.int("ts")))
            #expect(header.bytes == (try vector.hex("header")))
            let frame = try HLFrame.parse(try vector.hex("frame"))
            #expect(frame.header == header)
            #expect(frame.encrypted == (try vector.hex("encrypted_part")))
            #expect(frame.bytes == (try vector.hex("frame")))
            if try vector.string("channel") == "camera" {
                let track = try #require(CameraFramePayload.Track(rawValue: UInt8(try vector.int("track"))))
                let payload = CameraFramePayload(
                    track: track,
                    flags: .init(rawValue: UInt8(try vector.int("flags"))),
                    ptsUs: try vector.int("pts_us"),
                    data: try vector.hex("data")
                )
                #expect(payload.bytes == (try vector.hex("plaintext")))
                #expect(try CameraFramePayload.parse(payload.bytes) == payload)
            }
        }
    }

    @Test("Khung HL sai dạng bị từ chối")
    func rejectsBadFrames() throws {
        let good = [UInt8](try VectorFile("hl-frame.json").vectors[0].hex("frame"))
        var badMagic = good
        badMagic[0] = 0x00
        var badVersion = good
        badVersion[2] = 0x02
        #expect(throws: ProtocolError.invalidFrame("magic")) { try HLFrame.parse(Data(badMagic)) }
        #expect(throws: ProtocolError.invalidFrame("version")) { try HLFrame.parse(Data(badVersion)) }
        #expect(throws: ProtocolError.invalidFrame("too_short")) { try HLFrame.parse(Data(good.prefix(50))) }
    }

    @Test("Plaintext nhị phân clipboard/chunk khớp byte")
    func clipboardChunks() throws {
        for vector in try VectorFile("clipboard-chunk.json").vectors {
            let chunk = ClipboardChunkPlaintext(
                transferId: try vector.string("transfer_id"),
                index: Int32(try vector.int("index")),
                chunk: try vector.hex("chunk_data")
            )
            let expected = try vector.hex("plaintext_hex")
            #expect(chunk.headerJSON == Data(try vector.string("header_json").utf8))
            #expect(Int64(chunk.headerJSON.count) == (try vector.int("hdr_len")))
            #expect(try chunk.encoded() == expected)
            #expect(ClipboardChunkPlaintext.isBinaryChunk(expected))
            #expect(try ClipboardChunkPlaintext.parse(expected) == chunk)
        }
    }
}
