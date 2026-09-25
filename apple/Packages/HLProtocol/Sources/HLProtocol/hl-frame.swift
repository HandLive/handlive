import Foundation

/// Khung nhị phân HL trên `/v1/stream/*` (0.5.2):
/// `0x48 0x4C` ‖ ver `0x01` ‖ seq (uint32 BE) ‖ ts (uint32 BE) ‖ `nonce(24) ‖ ciphertext ‖ tag(16)`; AAD = 11 byte đầu.
public struct HLFrameHeader: Equatable, Sendable {
    public static let magic: [UInt8] = [0x48, 0x4C]
    public static let version: UInt8 = 0x01
    public static let byteCount = 11

    public let seq: UInt32
    public let ts: UInt32

    public init(seq: UInt32, ts: UInt32) {
        self.seq = seq
        self.ts = ts
    }

    /// 11 byte đầu khung, cũng là AAD.
    public var bytes: Data {
        var data = Data(Self.magic)
        data.append(Self.version)
        data.append(contentsOf: BigEndian.bytes(seq))
        data.append(contentsOf: BigEndian.bytes(ts))
        return data
    }
}

/// Khung HL đã tách header; phần `encrypted` giải mã ở HLCrypto.
public struct HLFrame: Equatable, Sendable {
    /// nonce 24 + tag 16.
    public static let minEncryptedBytes = 40

    public let header: HLFrameHeader
    public let encrypted: Data

    public init(header: HLFrameHeader, encrypted: Data) {
        self.header = header
        self.encrypted = encrypted
    }

    public var bytes: Data {
        header.bytes + encrypted
    }

    public static func parse(_ frame: Data) throws -> HLFrame {
        let bytes = [UInt8](frame)
        guard bytes.count >= HLFrameHeader.byteCount + minEncryptedBytes else {
            throw ProtocolError.invalidFrame("too_short")
        }
        guard Array(bytes[0..<2]) == HLFrameHeader.magic else { throw ProtocolError.invalidFrame("magic") }
        guard bytes[2] == HLFrameHeader.version else { throw ProtocolError.invalidFrame("version") }
        let header = HLFrameHeader(seq: BigEndian.uint32(bytes, at: 3), ts: BigEndian.uint32(bytes, at: 7))
        return HLFrame(header: header, encrypted: Data(bytes[HLFrameHeader.byteCount...]))
    }
}

/// Plaintext kênh `/v1/stream/camera`: `track`(1) ‖ `flags`(1) ‖ `pts_us`(int64 BE) ‖ dữ liệu.
public struct CameraFramePayload: Equatable, Sendable {
    public enum Track: UInt8, Sendable {
        case videoH264 = 0x01
        case audioOpus = 0x02
    }

    public struct Flags: OptionSet, Equatable, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let keyframe = Flags(rawValue: 1 << 0)
        public static let codecConfig = Flags(rawValue: 1 << 1)
        public static let discontinuity = Flags(rawValue: 1 << 2)
    }

    public static let headerByteCount = 10

    public let track: Track
    public let flags: Flags
    public let ptsUs: Int64
    public let data: Data

    public init(track: Track, flags: Flags, ptsUs: Int64, data: Data) {
        self.track = track
        self.flags = flags
        self.ptsUs = ptsUs
        self.data = data
    }

    public var bytes: Data {
        var result = Data([track.rawValue, flags.rawValue])
        result.append(contentsOf: BigEndian.bytes(UInt64(bitPattern: ptsUs)))
        return result + data
    }

    public static func parse(_ plaintext: Data) throws -> CameraFramePayload {
        let bytes = [UInt8](plaintext)
        guard bytes.count >= headerByteCount else { throw ProtocolError.invalidFrame("camera_too_short") }
        guard let track = Track(rawValue: bytes[0]) else { throw ProtocolError.invalidFrame("track") }
        var pts: UInt64 = 0
        for index in 2..<10 {
            pts = (pts << 8) | UInt64(bytes[index])
        }
        return CameraFramePayload(
            track: track,
            flags: Flags(rawValue: bytes[1]),
            ptsUs: Int64(bitPattern: pts),
            data: Data(bytes[headerByteCount...])
        )
    }
}

/// Ghi/đọc số nguyên big-endian.
enum BigEndian {
    static func bytes<T: FixedWidthInteger>(_ value: T) -> [UInt8] {
        (0..<(T.bitWidth / 8)).reversed().map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) }
    }

    static func uint32(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        bytes[offset..<(offset + 4)].reduce(0) { ($0 << 8) | UInt32($1) }
    }

    static func uint16(_ bytes: [UInt8], at offset: Int) -> UInt16 {
        (UInt16(bytes[offset]) << 8) | UInt16(bytes[offset + 1])
    }
}
