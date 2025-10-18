import Foundation
import Observation
import Security

struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
}

protocol TokenProvider {
    var accessToken: String? { get }
    var refreshToken: String? { get }
}

protocol TokenSink: AnyObject {
    func updateTokens(_ tokens: AuthTokens)
    func clearTokens()
}

@Observable
final class TokenManager: TokenProvider, TokenSink {
    private let service = "com.chatterbox.ios.tokens"
    private let account = "default"

    private(set) var cachedTokens: AuthTokens? {
        didSet { self.hasValidAccessToken = cachedTokens?.accessToken.isEmpty == false }
    }

    var hasValidAccessToken: Bool = false

    init() {
        self.cachedTokens = loadTokens()
        self.hasValidAccessToken = cachedTokens?.accessToken.isEmpty == false
    }

    var accessToken: String? { cachedTokens?.accessToken }
    var refreshToken: String? { cachedTokens?.refreshToken }

    func updateTokens(_ tokens: AuthTokens) {
        storeTokens(tokens)
        cachedTokens = tokens
    }

    func clearTokens() {
        deleteTokens()
        cachedTokens = nil
    }

    // MARK: - Keychain
    private func storeTokens(_ tokens: AuthTokens) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private func loadTokens() -> AuthTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(AuthTokens.self, from: data)
    }

    private func deleteTokens() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}


