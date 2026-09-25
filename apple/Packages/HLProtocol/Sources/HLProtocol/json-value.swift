import Foundation

/// Giá trị JSON tùy ý cho phần `data` chưa có kiểu riêng (0.5.1: `data` là object theo từng op).
public enum JSONValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public static let emptyObject = JSONValue.object([:])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    public var isObject: Bool {
        if case .object = self { return true }
        return false
    }
}

/// Bộ mã hóa/giải mã JSON dùng chung: gọn, khóa sắp xếp (ổn định), không escape `/`.
public enum HLJSON {
    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder().encode(value)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch let error as ProtocolError {
            throw error
        } catch {
            throw ProtocolError.invalidJSON
        }
    }

    /// Đổi `JSONValue` sang kiểu có cấu trúc (qua JSON trung gian).
    public static func convert<T: Decodable>(_ value: JSONValue, to type: T.Type) throws -> T {
        try decode(type, from: encode(value))
    }
}
