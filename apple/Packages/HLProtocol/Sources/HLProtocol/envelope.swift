import Foundation

/// Envelope JSON trên WS text frame (0.5.1): `{v, type, id, ts, payload}`.
/// `payload` là b64 của `nonce(24) ‖ ciphertext ‖ tag(16)`; tin bắt tay mang b64 của JSON chưa mã hóa.
public struct Envelope: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    /// Envelope ≤ 256 KiB (0.5.1 quy tắc 4).
    public static let maxWireBytes = 256 * 1024

    public let v: Int
    public let type: MessageType
    public let id: String
    public let ts: Int64
    public let payload: String

    public init(v: Int = Envelope.currentVersion, type: MessageType, id: String, ts: Int64, payload: String) {
        self.v = v
        self.type = type
        self.id = id
        self.ts = ts
        self.payload = payload
    }

    /// Tin bắt tay: payload = b64 của JSON chưa mã hóa.
    public init(type: MessageType, id: String = HLUUID.v7(), ts: Int64 = HLUUID.currentTimeMs(), plainPayload: Data) {
        self.init(type: type, id: id, ts: ts, payload: Base64Coding.encodeB64(plainPayload))
    }

    /// AAD = UTF-8 của `"<v>|<type>|<id>|<ts>"`.
    public var aad: Data {
        Data("\(v)|\(type.rawValue)|\(id)|\(ts)".utf8)
    }

    public var payloadBytes: Data {
        get throws { try Base64Coding.decodeB64(payload) }
    }

    /// Chuỗi wire gọn, đúng thứ tự khóa của 0.5.1. Mọi trường là ASCII an toàn nên không cần escape.
    public func wireString() -> String {
        "{\"v\":\(v),\"type\":\"\(type.rawValue)\",\"id\":\"\(id)\",\"ts\":\(ts),\"payload\":\"\(payload)\"}"
    }

    public func wireData() -> Data {
        Data(wireString().utf8)
    }

    /// Phân tích và kiểm chặt: `v` = 1, `type` đã biết, `id` UUIDv7, `ts` ≥ 0, `payload` b64 hợp lệ.
    public static func parse(_ data: Data) throws -> Envelope {
        guard data.count <= maxWireBytes else { throw ProtocolError.payloadTooLarge(data.count) }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProtocolError.invalidJSON
        }
        try checkKeys(object)
        guard let version = JSONNumber.integer(object["v"]) else { throw ProtocolError.invalidField("v") }
        guard version == Int64(currentVersion) else { throw ProtocolError.unsupportedVersion(Int(clamping: version)) }
        guard let typeName = object["type"] as? String else { throw ProtocolError.invalidField("type") }
        guard let type = MessageType(rawValue: typeName) else { throw ProtocolError.unsupportedType(typeName) }
        guard let id = object["id"] as? String, HLUUID.isValid(id, version: 7) else {
            throw ProtocolError.invalidField("id")
        }
        guard let ts = JSONNumber.integer(object["ts"]), ts >= 0 else { throw ProtocolError.invalidField("ts") }
        guard let payload = object["payload"] as? String else { throw ProtocolError.invalidField("payload") }
        _ = try Base64Coding.decodeB64(payload)
        return Envelope(v: currentVersion, type: type, id: id, ts: ts, payload: payload)
    }

    private static let fieldNames = ["v", "type", "id", "ts", "payload"]

    /// Đủ năm trường, không có trường lạ.
    private static func checkKeys(_ object: [String: Any]) throws {
        for key in fieldNames where object[key] == nil {
            throw ProtocolError.missingField(key)
        }
        guard Set(object.keys).isSubset(of: fieldNames) else { throw ProtocolError.invalidField("envelope") }
    }
}

/// Đọc số nguyên từ kết quả `JSONSerialization`: từ chối `bool` và số thực.
enum JSONNumber {
    static func integer(_ value: Any?) -> Int64? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let kind = String(cString: number.objCType)
        guard ["c", "s", "i", "l", "q", "C", "S", "I", "L", "Q"].contains(kind) else { return nil }
        return number.int64Value
    }
}
