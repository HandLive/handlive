import Foundation

/// Kho bí mật (0.2, 0.6.1): account `ik_sig`, `ik_dh`, `db_key`, `<pair_id>` (PRK từng cặp).
/// Ứng dụng dùng `KeychainSecretStore`; test dùng `InMemorySecretStore`.
public protocol SecretStore: Sendable {
    func save(_ secret: Data, account: String) throws
    func load(account: String) throws -> Data?
    func delete(account: String) throws
}

public enum SecretAccount {
    public static let signingKey = "ik_sig"
    public static let keyAgreementKey = "ik_dh"
    public static let databaseKey = "db_key"

    /// `PRK` của cặp lưu theo account = `pair_id`.
    public static func pairKey(pairId: String) -> String { pairId }
}

/// Kho trong bộ nhớ cho test và preview. Không bền vững.
public final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]

    public init() {}

    public func save(_ secret: Data, account: String) throws {
        locked { items[account] = secret }
    }

    public func load(account: String) throws -> Data? {
        locked { items[account] }
    }

    public func delete(account: String) throws {
        locked { _ = items.removeValue(forKey: account) }
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
