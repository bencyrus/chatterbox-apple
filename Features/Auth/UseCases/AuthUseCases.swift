import Foundation

struct RequestOTPCodeUseCase {
    let repository: AuthRepository
    func execute(identifier: String) async throws {
        try await repository.requestCode(identifier: identifier)
    }
}

struct VerifyOTPCodeUseCase {
    let repository: AuthRepository
    weak var tokenSink: TokenSink?
    func execute(identifier: String, code: String) async throws {
        let tokens = try await repository.verifyCode(identifier: identifier, code: code)
        tokenSink?.updateTokens(tokens)
    }
}

struct LogoutUseCase {
    weak var tokenSink: TokenSink?
    func execute() {
        tokenSink?.clearTokens()
    }
}


