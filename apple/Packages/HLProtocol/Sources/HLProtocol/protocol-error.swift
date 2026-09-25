/// Lỗi phân tích/dựng khung tin. Không mang nội dung payload (0.5.1 quy tắc 5: không log nội dung).
public enum ProtocolError: Error, Equatable, Sendable {
    case invalidJSON
    case missingField(String)
    case invalidField(String)
    case unsupportedVersion(Int)
    case unsupportedType(String)
    case invalidBase64
    case invalidUUID
    case invalidFrame(String)
    case payloadTooLarge(Int)
}
