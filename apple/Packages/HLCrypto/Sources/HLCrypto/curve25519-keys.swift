import CryptoKit
import Foundation

/// X25519 (RFC 7748) trên CryptoKit. Khóa riêng 32 byte (CryptoKit tự clamp), khóa công khai 32 byte.
public enum X25519 {
    public static func generatePrivateKey() -> Data {
        Curve25519.KeyAgreement.PrivateKey().rawRepresentation
    }

    public static func publicKey(privateKey: Data) throws -> Data {
        try Bytes.require(privateKey, count: 32)
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
    }

    public static func sharedSecret(privateKey: Data, peerPublicKey: Data) throws -> Data {
        try Bytes.require(privateKey, count: 32)
        try Bytes.require(peerPublicKey, count: 32)
        let ours = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey)
        guard let peer = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey),
              let shared = try? ours.sharedSecretFromKeyAgreement(with: peer)
        else { throw CryptoError.invalidPublicKey }
        return shared.withUnsafeBytes { Data($0) }
    }
}

/// Ed25519 (RFC 8032) cho `ik_sig`: khóa riêng là seed 32 byte.
public enum Ed25519 {
    public static func generateSeed() -> Data {
        Curve25519.Signing.PrivateKey().rawRepresentation
    }

    public static func publicKey(seed: Data) throws -> Data {
        try Bytes.require(seed, count: 32)
        return try Curve25519.Signing.PrivateKey(rawRepresentation: seed).publicKey.rawRepresentation
    }

    public static func sign(_ message: Data, seed: Data) throws -> Data {
        try Bytes.require(seed, count: 32)
        return try Curve25519.Signing.PrivateKey(rawRepresentation: seed).signature(for: message)
    }

    public static func verify(_ signature: Data, message: Data, publicKey: Data) -> Bool {
        guard let key = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKey) else { return false }
        return key.isValidSignature(signature, for: message)
    }
}
