/// `data` của các op `session` (0.6.3, 0.7.1; CONN-01 API 4–6, CONN-02 API 3, PAIR-03 API 2)
/// và `stream_hello`/`stream_welcome` của `camera`/`call_audio` (0.6.3 bước 7).
/// `eph`, `nonce`, `mac` là b64u 32 byte.
public enum SessionOp: String, Sendable {
    case hello, welcome, error, rekey, bye
}

public enum StreamOp: String, Sendable {
    case streamHello = "stream_hello"
    case streamWelcome = "stream_welcome"
}

/// Phiên bản giao thức hiện tại (`protocol` trong session/hello, capability/hello).
public let currentProtocolVersion: Int32 = 1

public struct SessionHelloData: Codable, Equatable, Sendable {
    public let protocolVersion: Int32
    public let pairId: String
    public let deviceId: String
    public let eph: String
    public let nonce: String
    public let mac: String

    public init(protocolVersion: Int32 = currentProtocolVersion, pairId: String, deviceId: String,
                eph: String, nonce: String, mac: String) {
        self.protocolVersion = protocolVersion
        self.pairId = pairId
        self.deviceId = deviceId
        self.eph = eph
        self.nonce = nonce
        self.mac = mac
    }

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol"
        case pairId = "pair_id"
        case deviceId = "device_id"
        case eph, nonce, mac
    }
}

public struct SessionWelcomeData: Codable, Equatable, Sendable {
    public let deviceId: String
    public let eph: String
    public let nonce: String
    public let mac: String

    public init(deviceId: String, eph: String, nonce: String, mac: String) {
        self.deviceId = deviceId
        self.eph = eph
        self.nonce = nonce
        self.mac = mac
    }

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case eph, nonce, mac
    }
}

/// `session/error`: `code` ∈ {AUTH_FAILED, PAIR_UNKNOWN, PAIR_REVOKED, UNSUPPORTED_VERSION, RATE_LIMITED};
/// `min_protocol` chỉ đi kèm UNSUPPORTED_VERSION.
public struct SessionErrorData: Codable, Equatable, Sendable {
    public static let allowedCodes: Set<ErrorCode> = [
        .authFailed, .pairUnknown, .pairRevoked, .unsupportedVersion, .rateLimited
    ]

    public let code: ErrorCode
    public let message: String
    public let minProtocol: Int32?

    public init(code: ErrorCode, message: String, minProtocol: Int32? = nil) {
        self.code = code
        self.message = message
        self.minProtocol = code == .unsupportedVersion ? minProtocol : nil
    }

    enum CodingKeys: String, CodingKey {
        case code, message
        case minProtocol = "min_protocol"
    }
}

/// `session/rekey` và `data` của ack tương ứng.
public struct SessionRekeyData: Codable, Equatable, Sendable {
    public let epoch: Int32
    public let eph: String
    public let nonce: String

    public init(epoch: Int32, eph: String, nonce: String) {
        self.epoch = epoch
        self.eph = eph
        self.nonce = nonce
    }
}

public struct SessionByeData: Codable, Equatable, Sendable {
    public enum Reason: String, Codable, Sendable {
        case revoked, shutdown, replaced, update
    }

    public let reason: Reason

    public init(reason: Reason) {
        self.reason = reason
    }
}

/// `stream_hello` / `stream_welcome` trên `/v1/stream/<kênh>`.
public struct StreamHandshakeData: Codable, Equatable, Sendable {
    public let sessionId: String
    public let nonce: String
    public let mac: String

    public init(sessionId: String, nonce: String, mac: String) {
        self.sessionId = sessionId
        self.nonce = nonce
        self.mac = mac
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case nonce, mac
    }
}
