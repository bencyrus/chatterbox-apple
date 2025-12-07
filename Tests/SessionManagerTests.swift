import XCTest
@testable import Chatterbox

final class SessionManagerTests: XCTestCase {
    private final class MockSessionController: SessionControllerProtocol {
        var stateStream: AsyncStream<SessionState> {
            AsyncStream { continuation in
                continuation.yield(currentStateStorage)
                continuation.finish()
            }
        }

        var currentStateStorage: SessionState = .signedOut

        var currentState: SessionState {
            get async { currentStateStorage }
        }

        var currentAccessToken: String? {
            get async { nil }
        }

        var currentRefreshToken: String? {
            get async { nil }
        }

        func bootstrap() async {}

        func loginSucceeded(with tokens: AuthTokens) async {}

        func logout() async {}
    }

    private final class MockAccountRepository: AccountRepository {
        var fetchMeCalls = 0
        var fetchAppConfigCalls = 0
        var meResponse: MeResponse!
        var appConfigResponse: AppConfigResponse!
        var error: Error?

        func fetchMe() async throws -> MeResponse {
            fetchMeCalls += 1
            if let error {
                throw error
            }
            return meResponse
        }

        func fetchAppConfig() async throws -> AppConfigResponse {
            fetchAppConfigCalls += 1
            if let error {
                throw error
            }
            return appConfigResponse
        }

        func setActiveProfile(accountId: Int64, languageCode: String) async throws {
            // Not used in bootstrap tests.
        }
    }

    private final class MockConfigProvider: ConfigProviding {
        private let provider = RuntimeConfigProvider()

        var snapshot: RuntimeConfig {
            provider.snapshot
        }

        var updates: AsyncStream<RuntimeConfig> {
            provider.updates
        }

        func update(_ config: RuntimeConfig) {
            provider.update(config)
        }
    }

    func testHandleAppBecameActive_bootstrapsWhenAuthenticated() async {
        let sessionController = MockSessionController()
        sessionController.currentStateStorage = .authenticated

        let accountRepo = MockAccountRepository()
        accountRepo.meResponse = MeResponse(
            account: .init(
                email: nil,
                flags: [AccountFlag.developer.rawValue],
                accountId: 1,
                accountRole: "user",
                phoneNumber: nil,
                lastLoginAt: nil
            ),
            activeProfile: nil
        )
        accountRepo.appConfigResponse = AppConfigResponse(
            defaultProfileLanguageCode: "en",
            availableLanguageCodes: ["en"],
            flags: [FeatureFlag.developerMenuEnabled.rawValue]
        )

        let configProvider = MockConfigProvider()
        let featureAccessContext = FeatureAccessContext()

        let manager = SessionManager(
            sessionController: sessionController,
            accountRepository: accountRepo,
            configProvider: configProvider,
            featureAccessContext: featureAccessContext
        )

        await manager.handleAppBecameActive()

        XCTAssertEqual(accountRepo.fetchMeCalls, 1)
        XCTAssertEqual(accountRepo.fetchAppConfigCalls, 1)
        XCTAssertTrue(featureAccessContext.accountEntitlements.has(.developer))
        XCTAssertTrue(configProvider.snapshot.isEnabled(.developerMenuEnabled))
    }

    func testHandleAppBecameActive_doesNothingWhenSignedOut() async {
        let sessionController = MockSessionController()
        sessionController.currentStateStorage = .signedOut

        let accountRepo = MockAccountRepository()
        let configProvider = MockConfigProvider()
        let featureAccessContext = FeatureAccessContext()

        let manager = SessionManager(
            sessionController: sessionController,
            accountRepository: accountRepo,
            configProvider: configProvider,
            featureAccessContext: featureAccessContext
        )

        await manager.handleAppBecameActive()

        XCTAssertEqual(accountRepo.fetchMeCalls, 0)
        XCTAssertEqual(accountRepo.fetchAppConfigCalls, 0)
    }
}


