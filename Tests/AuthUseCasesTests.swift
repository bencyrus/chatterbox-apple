import XCTest
@testable import Chatterbox

final class AuthUseCasesTests: XCTestCase {
    private final class MockAuthRepository: AuthRepository {
        var requestedIdentifier: String?
        var magicToken: String?

        func requestMagicLink(identifier: String) async throws {
            requestedIdentifier = identifier
        }

        func loginWithMagicToken(token: String) async throws -> AuthTokens {
            magicToken = token
            return AuthTokens(accessToken: "access-\(token)", refreshToken: "refresh-\(token)")
        }
    }

    private final class MockSessionController: SessionControllerProtocol {
        private(set) var lastTokens: AuthTokens?
        private(set) var loggedOut = false

        var stateStream: AsyncStream<SessionState> {
            AsyncStream { continuation in
                continuation.yield(.signedOut)
            }
        }

        var currentState: SessionState {
            get async { .signedOut }
        }

        var currentAccessToken: String? {
            get async { lastTokens?.accessToken }
        }

        func bootstrap() async {}

        func loginSucceeded(with tokens: AuthTokens) async {
            lastTokens = tokens
        }

        func logout() async {
            loggedOut = true
            lastTokens = nil
        }
    }

    private final class MockAnalytics: AnalyticsRecording {
        private(set) var recordedEvents: [AnalyticsEvent] = []

        func record(_ event: AnalyticsEvent) {
            recordedEvents.append(event)
        }
    }

    func testRequestMagicLinkRecordsAnalytics() async throws {
        let repo = MockAuthRepository()
        let analytics = MockAnalytics()
        let useCase = RequestMagicLinkUseCase(repository: repo, analytics: analytics)

        try await useCase.execute(identifier: "test@example.com")

        XCTAssertEqual(repo.requestedIdentifier, "test@example.com")
        XCTAssertEqual(analytics.recordedEvents.first?.name, "auth.magic_link_requested")
    }

    func testLoginWithMagicTokenUpdatesSessionAndAnalytics() async throws {
        let repo = MockAuthRepository()
        let session = MockSessionController()
        let analytics = MockAnalytics()
        let useCase = LoginWithMagicTokenUseCase(repository: repo, sessionController: session, analytics: analytics)

        try await useCase.execute(token: "abc123")

        XCTAssertEqual(repo.magicToken, "abc123")
        XCTAssertEqual(session.lastTokens?.accessToken, "access-abc123")
        XCTAssertEqual(analytics.recordedEvents.first?.name, "auth.login_success")
    }
}


