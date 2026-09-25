import Foundation

/// Plaintext nhị phân của `clipboard` op `chunk` (0.5.1):
/// `hdr_len` (uint16 BE) ‖ JSON `{"op":"chunk","data":{"transfer_id","index"}}` ‖ byte khối (≤ `CHUNK_SIZE`).
/// Byte đầu luôn `0x00` (JSON header < 256 byte), còn plaintext JSON bắt đầu bằng `{`, nên bên nhận phân biệt được.
public struct ClipboardChunkPlaintext: Equatable, Sendable {
    /// `CHUNK_SIZE` (0.10), tính trước mã hóa.
    public static let chunkSize = 64 * 1024

    public let transferId: String
    public let index: Int32
    public let chunk: Data

    public init(transferId: String, index: Int32, chunk: Data) {
        self.transferId = transferId
        self.index = index
        self.chunk = chunk
    }

    /// Header JSON đúng thứ tự khóa của spec; `transfer_id` là uuid nên không cần escape.
    public var headerJSON: Data {
        Data("{\"op\":\"chunk\",\"data\":{\"transfer_id\":\"\(transferId)\",\"index\":\(index)}}".utf8)
    }

    public func encoded() throws -> Data {
        guard HLUUID.isCanonical(transferId) else { throw ProtocolError.invalidUUID }
        guard index >= 0 else { throw ProtocolError.invalidField("index") }
        guard chunk.count <= Self.chunkSize else { throw ProtocolError.payloadTooLarge(chunk.count) }
        let header = headerJSON
        return Data(BigEndian.bytes(UInt16(header.count))) + header + chunk
    }

    /// Plaintext đã giải mã có phải dạng nhị phân (chunk) không.
    public static func isBinaryChunk(_ plaintext: Data) -> Bool {
        plaintext.first == 0x00
    }

    public static func parse(_ plaintext: Data) throws -> ClipboardChunkPlaintext {
        let bytes = [UInt8](plaintext)
        guard bytes.count >= 2 else { throw ProtocolError.invalidFrame("chunk_too_short") }
        let headerLength = Int(BigEndian.uint16(bytes, at: 0))
        guard bytes.count >= 2 + headerLength else { throw ProtocolError.invalidFrame("chunk_header") }
        let payload = try HLJSON.decode(TypedPayload<ClipboardChunkHeader>.self, from: Data(bytes[2..<(2 + headerLength)]))
        guard payload.op == "chunk" else { throw ProtocolError.invalidField("op") }
        guard HLUUID.isValid(payload.data.transferId, version: 7) else {
            throw ProtocolError.invalidField("transfer_id")
        }
        guard payload.data.index >= 0 else { throw ProtocolError.invalidField("index") }
        let chunk = Data(bytes[(2 + headerLength)...])
        guard chunk.count <= chunkSize else { throw ProtocolError.payloadTooLarge(chunk.count) }
        return ClipboardChunkPlaintext(transferId: payload.data.transferId, index: payload.data.index, chunk: chunk)
    }
}

/// `data` của header JSON trong chunk: `{"transfer_id", "index"}`.
public struct ClipboardChunkHeader: Codable, Equatable, Sendable {
    public let transferId: String
    public let index: Int32

    enum CodingKeys: String, CodingKey {
        case transferId = "transfer_id"
        case index
    }
}
