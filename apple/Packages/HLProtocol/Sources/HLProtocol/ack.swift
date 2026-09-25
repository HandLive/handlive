import Foundation

/// Đối tượng lỗi trong ack (0.5.1, 0.8.1). `message` không chứa nội dung người dùng.
public struct AckError: Codable, Equatable, Sendable {
    public let code: ErrorCode
    public let message: String
    public let details: JSONValue?

    public init(code: ErrorCode, message: String, details: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

/// Plaintext của envelope `type = ack`:
/// `{"re", "ok": true, "data"}` hoặc `{"re", "ok": false, "error"}`.
public struct Ack: Codable, Equatable, Sendable {
    public let re: String
    public let ok: Bool
    public let data: JSONValue?
    public let error: AckError?

    public static func success(re: String, data: JSONValue = .emptyObject) -> Ack {
        Ack(re: re, ok: true, data: data, error: nil)
    }

    public static func failure(re: String, error: AckError) -> Ack {
        Ack(re: re, ok: false, data: nil, error: error)
    }

    private init(re: String, ok: Bool, data: JSONValue?, error: AckError?) {
        self.re = re
        self.ok = ok
        self.data = data
        self.error = error
    }

    private enum CodingKeys: String, CodingKey {
        case re, ok, data, error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        re = try container.decode(String.self, forKey: .re)
        ok = try container.decode(Bool.self, forKey: .ok)
        guard HLUUID.isValid(re, version: 7) else { throw ProtocolError.invalidField("re") }
        if ok {
            let body = try container.decode(JSONValue.self, forKey: .data)
            guard body.isObject, !container.contains(.error) else { throw ProtocolError.invalidField("data") }
            data = body
            error = nil
        } else {
            guard !container.contains(.data) else { throw ProtocolError.invalidField("data") }
            error = try container.decode(AckError.self, forKey: .error)
            data = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(re, forKey: .re)
        try container.encode(ok, forKey: .ok)
        if ok {
            try container.encode(data ?? .emptyObject, forKey: .data)
        } else {
            try container.encode(error, forKey: .error)
        }
    }

    public static func parse(_ plaintext: Data) throws -> Ack {
        try HLJSON.decode(Ack.self, from: plaintext)
    }

    public func encoded() throws -> Data {
        try HLJSON.encode(self)
    }
}
