import Foundation
import HLProtocol

/// `PRK` của một cặp (0.6.2): HKDF-SHA256(ikm = X25519(`ik_dh` mình, `ik_dh` đối phương) ‖ `pairing_secret`,
/// salt = SHA-256(`device_id` nhỏ hơn ‖ lớn hơn, 16 byte, so byte không dấu), info `"handlive/v1/pair"`, L = 32).
public enum PairingKeyDerivation {
    public static let info = "handlive/v1/pair"

    public static func salt(deviceIdA: String, deviceIdB: String) throws -> Data {
        let first = try HLUUID.bytes(from: deviceIdA)
        let second = try HLUUID.bytes(from: deviceIdB)
        let ordered = first.lexicographicallyPrecedes(second) ? first + second : second + first
        return HMACSHA256.sha256(ordered)
    }

    public static func prk(ownDHPrivateKey: Data, peerDHPublicKey: Data, pairingSecret: Data,
                           ownDeviceId: String, peerDeviceId: String) throws -> Data {
        try Bytes.require(pairingSecret, count: 32)
        let shared = try X25519.sharedSecret(privateKey: ownDHPrivateKey, peerPublicKey: peerDHPublicKey)
        let salt = try salt(deviceIdA: ownDeviceId, deviceIdB: peerDeviceId)
        return HKDFSHA256.derive(ikm: shared + pairingSecret, salt: salt, info: info, length: 32)
    }
}
