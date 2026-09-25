import Foundation
import HLProtocol

/// Kênh stream `/v1/stream/<kênh>`.
public enum StreamChannel: String, Sendable, CaseIterable {
    case camera
    case callAudio = "call-audio"
}

/// `K_stream` (0.6.3 bước 7, 8) = HKDF(`secret` của bắt tay epoch 0, salt rỗng,
/// info `"handlive/v1/stream/<kênh>/<session_id>"`, L = 96) → `k_auth` ‖ `k_c2s` ‖ `k_s2c`.
public struct StreamKeys: Equatable, Sendable {
    public let auth: Data
    public let clientToServer: Data
    public let serverToClient: Data

    public static func info(channel: StreamChannel, sessionId: String) -> String {
        "handlive/v1/stream/\(channel.rawValue)/\(sessionId)"
    }

    public init(handshakeSecret: Data, channel: StreamChannel, sessionId: String) throws {
        try Bytes.require(handshakeSecret, count: 64)
        guard HLUUID.isCanonical(sessionId) else { throw ProtocolError.invalidUUID }
        let okm = HKDFSHA256.derive(ikm: handshakeSecret, info: Self.info(channel: channel, sessionId: sessionId),
                                    length: 96)
        auth = okm.prefix(32)
        clientToServer = okm.subdata(in: 32..<64)
        serverToClient = okm.suffix(32)
    }

    /// `"HLSTREAM1|"` ‖ `session_id` 16 byte ‖ `nonce_c` 32 byte.
    public static func helloMessage(sessionId: String, clientNonce: Data) throws -> Data {
        try Bytes.require(clientNonce, count: 32, isNonce: true)
        return Data("HLSTREAM1|".utf8) + (try HLUUID.bytes(from: sessionId)) + clientNonce
    }

    /// `"HLSTREAM1|welcome|"` ‖ `session_id` 16 ‖ `nonce_c` 32 ‖ `nonce_s` 32 — gắn cả hai nonce, chống phát lại.
    public static func welcomeMessage(sessionId: String, clientNonce: Data, serverNonce: Data) throws -> Data {
        try Bytes.require(clientNonce, count: 32, isNonce: true)
        try Bytes.require(serverNonce, count: 32, isNonce: true)
        return Data("HLSTREAM1|welcome|".utf8) + (try HLUUID.bytes(from: sessionId)) + clientNonce + serverNonce
    }
}
