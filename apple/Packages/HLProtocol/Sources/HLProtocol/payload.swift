import Foundation

/// Plaintext chung của payload (0.5.1): `{"op": "<thao tác>", "data": {…}}`.
public struct Payload: Codable, Equatable, Sendable {
    public let op: String
    public let data: JSONValue

    public init(op: String, data: JSONValue = .emptyObject) {
        self.op = op
        self.data = data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        op = try container.decode(String.self, forKey: .op)
        data = try container.decode(JSONValue.self, forKey: .data)
        guard data.isObject else { throw ProtocolError.invalidField("data") }
    }

    public static func parse(_ plaintext: Data) throws -> Payload {
        try HLJSON.decode(Payload.self, from: plaintext)
    }

    public func encoded() throws -> Data {
        try HLJSON.encode(self)
    }

    public func decodeData<T: Decodable>(as type: T.Type) throws -> T {
        try HLJSON.convert(data, to: type)
    }
}

/// Plaintext có kiểu cho một op cụ thể, cùng hình dạng `{op, data}`.
public struct TypedPayload<Body: Codable & Sendable & Equatable>: Codable, Equatable, Sendable {
    public let op: String
    public let data: Body

    public init(op: String, data: Body) {
        self.op = op
        self.data = data
    }

    public func encoded() throws -> Data {
        try HLJSON.encode(self)
    }
}
