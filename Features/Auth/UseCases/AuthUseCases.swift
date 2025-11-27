import Foundation

// OTP flow removed; magic token only

struct LogoutUseCase {
    let sessionController: SessionControllerProtocol

    func execute() {
        Task {
            await sessionController.logout()
        }
    }
}

struct RequestMagicLinkUseCase {
    let repository: AuthRepository
    let analytics: AnalyticsRecording?

    func execute(identifier: String) async throws {
        try await repository.requestMagicLink(identifier: identifier)
        let event = AnalyticsEvent(
            name: "auth.magic_link_requested",
            properties: [:],
            context: [:],
            timestamp: Date()
        )
        analytics?.record(event)
    }
}

struct LoginWithMagicTokenUseCase {
    let repository: AuthRepository
    let sessionController: SessionControllerProtocol
    let analytics: AnalyticsRecording?

    func execute(token: String) async throws {
        let tokens = try await repository.loginWithMagicToken(token: token)
        await sessionController.loginSucceeded(with: tokens)
        let event = AnalyticsEvent(
            name: "auth.login_success",
            properties: [:],
            context: [:],
            timestamp: Date()
        )
        analytics?.record(event)
    }
}

