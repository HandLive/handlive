import Foundation

/// HChaCha20 theo draft-irtf-cfrg-xchacha-03 §2.2 (CryptoKit không có XChaCha20, xem C2):
/// trạng thái ChaCha20 = hằng ‖ khóa 32 byte ‖ nonce 16 byte, chạy 20 vòng, **không** cộng trạng thái đầu,
/// lấy từ 0–3 và 12–15 (little-endian) làm subkey 32 byte.
public enum HChaCha20 {
    public static func subkey(key: Data, nonce: Data) throws -> Data {
        try Bytes.require(key, count: 32)
        try Bytes.require(nonce, count: 16, isNonce: true)
        let keyBytes = [UInt8](key)
        let nonceBytes = [UInt8](nonce)
        var state: [UInt32] = [0x6170_7865, 0x3320_646E, 0x7962_2D32, 0x6B20_6574]
        state += (0..<8).map { littleEndianWord(keyBytes, at: 4 * $0) }
        state += (0..<4).map { littleEndianWord(nonceBytes, at: 4 * $0) }

        for _ in 0..<10 {
            quarterRound(&state, 0, 4, 8, 12)
            quarterRound(&state, 1, 5, 9, 13)
            quarterRound(&state, 2, 6, 10, 14)
            quarterRound(&state, 3, 7, 11, 15)
            quarterRound(&state, 0, 5, 10, 15)
            quarterRound(&state, 1, 6, 11, 12)
            quarterRound(&state, 2, 7, 8, 13)
            quarterRound(&state, 3, 4, 9, 14)
        }

        var output = Data(capacity: 32)
        for word in state[0..<4] + state[12..<16] {
            withUnsafeBytes(of: word.littleEndian) { output.append(contentsOf: $0) }
        }
        return output
    }

    private static func littleEndianWord(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        UInt32(bytes[offset]) | UInt32(bytes[offset + 1]) << 8
            | UInt32(bytes[offset + 2]) << 16 | UInt32(bytes[offset + 3]) << 24
    }

    // swiftlint:disable:next identifier_name
    private static func quarterRound(_ s: inout [UInt32], _ a: Int, _ b: Int, _ c: Int, _ d: Int) {
        s[a] &+= s[b]; s[d] ^= s[a]; s[d] = rotateLeft(s[d], 16)
        s[c] &+= s[d]; s[b] ^= s[c]; s[b] = rotateLeft(s[b], 12)
        s[a] &+= s[b]; s[d] ^= s[a]; s[d] = rotateLeft(s[d], 8)
        s[c] &+= s[d]; s[b] ^= s[c]; s[b] = rotateLeft(s[b], 7)
    }

    private static func rotateLeft(_ value: UInt32, _ count: UInt32) -> UInt32 {
        (value << count) | (value >> (32 - count))
    }
}
