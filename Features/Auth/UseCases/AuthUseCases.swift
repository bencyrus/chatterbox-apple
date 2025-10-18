import Foundation

// OTP flow removed; magic token only

struct LogoutUseCase {
    weak var tokenSink: TokenSink?
    func execute() {
        tokenSink?.clearTokens()
    }
}

struct RequestMagicLinkUseCase {
    let repository: AuthRepository
    func execute(identifier: String) async throws {
        try await repository.requestMagicLink(identifier: identifier)
    }
}

struct LoginWithMagicTokenUseCase {
    let repository: AuthRepository
    weak var tokenSink: TokenSink?
    func execute(token: String) async throws {
        let tokens = try await repository.loginWithMagicToken(token: token)
        tokenSink?.updateTokens(tokens)
    }
}


