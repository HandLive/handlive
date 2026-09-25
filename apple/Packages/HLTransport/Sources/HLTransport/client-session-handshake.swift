import Foundation
import HLCrypto
import HLProtocol

/// Thông tin cặp đã ghép (từ Keychain/SQLite) cần cho bắt tay.
public struct PairContext: Sendable {
    public let pairId: String
    public let clientDeviceId: String
    /// `device_id` Android đã lưu lúc ghép nối; `welcome` phải khớp.
    public let serverDeviceId: String
    public let prk: Data

    public init(pairId: String, clientDeviceId: String, serverDeviceId: String, prk: Data) {
        self.pairId = pairId
        self.clientDeviceId = clientDeviceId
        self.serverDeviceId = serverDeviceId
        self.prk = prk
    }
}

public enum HandshakeFailure: Error, Equatable, Sendable {
    /// MAC `welcome` sai → `AUTH_FAILED`.
    case authFailed
    /// `device_id` trong `welcome` không phải điện thoại đã ghép.
    case deviceMismatch
    /// Tin không phải `session/welcome` hay `session/error`.
    case unexpectedMessage
    case malformed
    /// Android trả `session/error` (AUTH_FAILED, PAIR_UNKNOWN, PAIR_REVOKED, UNSUPPORTED_VERSION, RATE_LIMITED).
    case rejected(SessionErrorData)
}

/// Bắt tay phía client trên `/v1/ctl` (0.6.3 bước 1–3), thuần logic: dựng `session/hello`,
/// kiểm `session/welcome`, trả `SessionKeys`. Hai envelope này có payload chưa mã hóa.
public struct ClientSessionHandshake: Sendable {
    public let context: PairContext
    public let ephemeralPublicKey: Data
    public let nonce: Data
    private let ephemeralPrivateKey: Data
    private let authKey: Data
    private let helloTranscript: Data

    public init(context: PairContext, ephemeralPrivateKey: Data = X25519.generatePrivateKey(),
                nonce: Data = SessionHandshakeCrypto.randomNonce()) throws {
        self.context = context
        self.ephemeralPrivateKey = ephemeralPrivateKey
        self.ephemeralPublicKey = try X25519.publicKey(privateKey: ephemeralPrivateKey)
        self.nonce = nonce
        self.authKey = try SessionHandshakeCrypto.authKey(prk: context.prk)
        self.helloTranscript = try SessionHandshakeCrypto.helloTranscript(
            pairId: context.pairId, clientDeviceId: context.clientDeviceId,
            clientEph: ephemeralPublicKey, clientNonce: nonce)
    }

    public func helloData() -> SessionHelloData {
        SessionHelloData(
            pairId: context.pairId, deviceId: context.clientDeviceId,
            eph: Base64Coding.encodeB64u(ephemeralPublicKey), nonce: Base64Coding.encodeB64u(nonce),
            mac: Base64Coding.encodeB64u(HMACSHA256.mac(key: authKey, message: helloTranscript)))
    }

    public func helloEnvelope(id: String = HLUUID.v7(), ts: Int64 = HLUUID.currentTimeMs()) throws -> Envelope {
        let plaintext = try TypedPayload(op: SessionOp.hello.rawValue, data: helloData()).encoded()
        return Envelope(type: .session, id: id, ts: ts, plainPayload: plaintext)
    }

    /// Xử lý tin đầu tiên từ Android. Thành công → khóa phiên; mọi envelope sau đó mã hóa theo chiều gửi.
    public func handleResponse(_ envelope: Envelope) throws -> SessionKeys {
        guard envelope.type == .session else { throw HandshakeFailure.unexpectedMessage }
        guard let payload = try? Payload.parse(envelope.payloadBytes) else { throw HandshakeFailure.malformed }
        switch SessionOp(rawValue: payload.op) {
        case .welcome:
            guard let welcome = try? payload.decodeData(as: SessionWelcomeData.self) else {
                throw HandshakeFailure.malformed
            }
            return try verifyWelcome(welcome)
        case .error:
            guard let error = try? payload.decodeData(as: SessionErrorData.self) else { throw HandshakeFailure.malformed }
            throw HandshakeFailure.rejected(error)
        default:
            throw HandshakeFailure.unexpectedMessage
        }
    }

    private func verifyWelcome(_ welcome: SessionWelcomeData) throws -> SessionKeys {
        guard welcome.deviceId == context.serverDeviceId else { throw HandshakeFailure.deviceMismatch }
        guard let serverEph = try? Base64Coding.decodeB64u(welcome.eph),
              let serverNonce = try? Base64Coding.decodeB64u(welcome.nonce),
              let mac = try? Base64Coding.decodeB64u(welcome.mac),
              let t2 = try? SessionHandshakeCrypto.welcomeTranscript(
                  helloTranscript: helloTranscript, serverDeviceId: welcome.deviceId,
                  serverEph: serverEph, serverNonce: serverNonce)
        else { throw HandshakeFailure.malformed }
        guard HMACSHA256.verify(mac, key: authKey, message: t2) else { throw HandshakeFailure.authFailed }
        guard let shared = try? X25519.sharedSecret(privateKey: ephemeralPrivateKey, peerPublicKey: serverEph) else {
            throw HandshakeFailure.malformed
        }
        return try SessionHandshakeCrypto.sessionKeys(ephemeralShared: shared, prk: context.prk, welcomeTranscript: t2)
    }
}
