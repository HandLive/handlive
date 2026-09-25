import Foundation
import HLProtocol

/// Mã hóa envelope (0.5.1): payload = b64(`nonce(24) ‖ ciphertext ‖ tag(16)`), AAD = `"<v>|<type>|<id>|<ts>"`.
public enum EnvelopeCipher {
    public static func seal(type: MessageType, plaintext: Data, key: Data, id: String = HLUUID.v7(),
                            ts: Int64 = HLUUID.currentTimeMs(),
                            nonce: Data = XChaCha20Poly1305.randomNonce()) throws -> Envelope {
        let aad = Envelope(type: type, id: id, ts: ts, payload: "").aad
        let sealed = try XChaCha20Poly1305.seal(plaintext, key: key, nonce: nonce, aad: aad)
        return Envelope(type: type, id: id, ts: ts, payload: Base64Coding.encodeB64(sealed.combined))
    }

    /// Bên nhận dựng AAD từ chính các trường của envelope; sửa `type`/`id`/`ts` → `authenticationFailed`.
    public static func open(_ envelope: Envelope, key: Data) throws -> Data {
        try XChaCha20Poly1305.open(combined: try envelope.payloadBytes, key: key, aad: envelope.aad)
    }
}

/// Mã hóa khung HL (0.5.2): AAD = 11 byte header.
public enum HLFrameCipher {
    public static func seal(header: HLFrameHeader, plaintext: Data, key: Data,
                            nonce: Data = XChaCha20Poly1305.randomNonce()) throws -> Data {
        let sealed = try XChaCha20Poly1305.seal(plaintext, key: key, nonce: nonce, aad: header.bytes)
        return HLFrame(header: header, encrypted: sealed.combined).bytes
    }

    public static func open(_ frame: Data, key: Data) throws -> (header: HLFrameHeader, plaintext: Data) {
        let parsed = try HLFrame.parse(frame)
        let plaintext = try XChaCha20Poly1305.open(combined: parsed.encrypted, key: key, aad: parsed.header.bytes)
        return (parsed.header, plaintext)
    }
}
