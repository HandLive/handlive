import Foundation
import HLProtocol

/// `device_id` tự chứng thực (0.2, C4): UUIDv8 = 16 byte đầu SHA-256(`ik_sig_pub`),
/// byte 6 = `(b & 0x0f) | 0x80` (version 8), byte 8 = `(b & 0x3f) | 0x80` (variant 10).
public enum DeviceIdentity {
    public static func deviceIdBytes(signingPublicKey: Data) throws -> Data {
        try Bytes.require(signingPublicKey, count: 32)
        var bytes = [UInt8](HMACSHA256.sha256(signingPublicKey).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x80
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return Data(bytes)
    }

    public static func deviceId(signingPublicKey: Data) throws -> String {
        HLUUID.string(from: try deviceIdBytes(signingPublicKey: signingPublicKey))
    }

    /// Bất kỳ bên nào cũng kiểm được `device_id` khớp khóa công khai.
    public static func matches(deviceId: String, signingPublicKey: Data) -> Bool {
        (try? self.deviceId(signingPublicKey: signingPublicKey)) == deviceId
    }
}
