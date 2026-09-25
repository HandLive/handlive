import Foundation
import Security

/// Keychain: `kSecClassGenericPassword`, service `app.handlive.keys`,
/// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (0.6.1, C3). Trên macOS dùng data-protection keychain
/// (cần ứng dụng đã ký có keychain access group; tiến trình test không ký sẽ nhận lỗi -34018).
public struct KeychainSecretStore: SecretStore {
    public static let service = "app.handlive.keys"

    public init() {}

    func baseQuery(account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        return query
    }

    func addQuery(_ secret: Data, account: String) -> [String: Any] {
        var query = baseQuery(account: account)
        query[kSecValueData as String] = secret
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return query
    }

    public func save(_ secret: Data, account: String) throws {
        try delete(account: account)
        try check(SecItemAdd(addQuery(secret, account: account) as CFDictionary, nil))
    }

    public func load(account: String) throws -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        try check(status)
        return result as? Data
    }

    public func delete(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        if status != errSecItemNotFound { try check(status) }
    }

    private func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else { throw CryptoError.keychain(status: status) }
    }
}
