import Foundation
import Security

struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
}

/// Public interface used by the networking layer and composition root.
protocol SessionControllerProtocol: AnyObject {
    var stateStream: AsyncStream<SessionState> { get }
    var currentState: SessionState { get async }
    var currentAccessToken: String? { get async }
    var currentRefreshToken: String? { get async }

    func bootstrap() async
    func loginSucceeded(with tokens: AuthTokens) async
    func logout() async
}

enum SessionState: Equatable {
    case signedOut
    case authenticated
    case refreshing
    case error
}

/// Keychain‑backed token store used internally by `SessionController`.
private struct TokenStore {
    private let service = "com.chatterboxtalk.tokens"
    private let account = "default"

    func loadTokens() -> AuthTokens? {
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

    func storeTokens(_ tokens: AuthTokens) {
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

    func clearTokens() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// Central authority for session and token lifecycle.
///
/// This actor is intentionally lightweight for now – it loads tokens on
/// startup and exposes basic login/logout behavior. Refresh flows will be
/// layered in via networking middleware.
actor SessionController: SessionControllerProtocol {
    private let tokenStore = TokenStore()

    private(set) var currentTokens: AuthTokens?
    private(set) var currentState: SessionState = .signedOut

    private let stateContinuation: AsyncStream<SessionState>.Continuation
    let stateStream: AsyncStream<SessionState>

    init() {
        var continuation: AsyncStream<SessionState>.Continuation!
        self.stateStream = AsyncStream { continuation = $0 }
        self.stateContinuation = continuation
    }

    var currentAccessToken: String? {
        currentTokens?.accessToken
    }

    var currentRefreshToken: String? {
        currentTokens?.refreshToken
    }

    func bootstrap() async {
        if let tokens = tokenStore.loadTokens() {
            currentTokens = tokens
            setState(.authenticated)
        } else {
            setState(.signedOut)
        }
    }

    func loginSucceeded(with tokens: AuthTokens) async {
        tokenStore.storeTokens(tokens)
        currentTokens = tokens
        setState(.authenticated)
    }

    func logout() async {
        tokenStore.clearTokens()
        currentTokens = nil
        setState(.signedOut)
    }

    private func setState(_ newState: SessionState) {
        // Only yield to the stream when state actually changes.
        // This prevents infinite loops when token refresh responses
        // repeatedly call loginSucceeded() while already authenticated.
        guard newState != currentState else { return }
        currentState = newState
        stateContinuation.yield(newState)
    }
}

