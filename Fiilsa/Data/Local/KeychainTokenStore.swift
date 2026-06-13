import Foundation
import Security

actor KeychainTokenStore: TokenStore {
    private enum Key {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
    }

    private let service: String
    private var cachedAccessToken: String?
    private var cachedRefreshToken: String?

    init(service: String = Bundle.main.bundleIdentifier ?? "com.fillsa.ios") {
        self.service = service
    }

    func accessToken() async -> String {
        if let cachedAccessToken {
            return cachedAccessToken
        }

        let token = read(key: Key.accessToken)
        cachedAccessToken = token
        return token
    }

    func refreshToken() async -> String {
        if let cachedRefreshToken {
            return cachedRefreshToken
        }

        let token = read(key: Key.refreshToken)
        cachedRefreshToken = token
        return token
    }

    func update(accessToken: String, refreshToken: String) async throws {
        try save(accessToken, key: Key.accessToken)
        try save(refreshToken, key: Key.refreshToken)
        cachedAccessToken = accessToken
        cachedRefreshToken = refreshToken
    }

    func clear() async throws {
        try delete(key: Key.accessToken)
        try delete(key: Key.refreshToken)
        cachedAccessToken = nil
        cachedRefreshToken = nil
    }

    private func read(key: String) -> String {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return ""
        }

        return String(data: data, encoding: .utf8) ?? ""
    }

    private func save(_ value: String, key: String) throws {
        let data = Data(value.utf8)
        let query = baseQuery(key: key)
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainTokenStoreError.unhandledStatus(updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainTokenStoreError.unhandledStatus(addStatus)
        }
    }

    private func delete(key: String) throws {
        let status = SecItemDelete(baseQuery(key: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainTokenStoreError.unhandledStatus(status)
        }
    }

    private func baseQuery(key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

enum KeychainTokenStoreError: Error, Equatable {
    case unhandledStatus(OSStatus)
}
