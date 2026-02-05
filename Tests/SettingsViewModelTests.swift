import XCTest
@testable import Chatterbox

@MainActor
final class SettingsViewModelTests: XCTestCase {
    var mockAccountRepo: MockAccountRepository!
    var mockLogoutUC: MockLogoutUseCase!
    var mockFeatureContext: FeatureAccessContext!
    var mockConfigProvider: MockRuntimeConfigProvider!
    var mockSessionManager: MockSessionManager!
    var viewModel: SettingsViewModel!
    
    override func setUp() async throws {
        mockAccountRepo = MockAccountRepository()
        mockLogoutUC = MockLogoutUseCase()
        mockFeatureContext = FeatureAccessContext()
        mockConfigProvider = MockRuntimeConfigProvider()
        mockSessionManager = MockSessionManager()
        
        viewModel = SettingsViewModel(
            accountRepository: mockAccountRepo,
            logoutUseCase: mockLogoutUC,
            featureAccessContext: mockFeatureContext,
            configProvider: mockConfigProvider,
            sessionManager: mockSessionManager
        )
    }
    
    func testLoadSettingsSuccess() async throws {
        // Given: Mock successful session data
        let me = MeResponse(
            userId: 1,
            email: "test@example.com",
            preferredLocaleCode: "en",
            flagAdmin: false,
            flagDeveloper: false,
            flagReviewer: false,
            createdAt: "2024-01-01T00:00:00Z",
            profiles: []
        )
        
        let appConfig = AppConfigResponse(
            supportedLocales: ["en", "es", "fr"],
            featureFlags: [],
            cueContentPageSize: 10,
            recordingHistoryPageSize: 20,
            magicLinkCooldownSeconds: 60
        )
        
        let snapshot = SessionManager.Snapshot(me: me, appConfig: appConfig)
        mockSessionManager.mockSnapshot = snapshot
        
        // When: Load settings
        await viewModel.load()
        
        // Then: State updated correctly
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.email, "test@example.com")
        XCTAssertEqual(viewModel.selectedLanguageCode, "en")
        XCTAssertEqual(viewModel.availableLanguages, ["en", "es", "fr"])
    }
    
    func testLoadSettingsError() async throws {
        // Given: Session manager returns nil snapshot
        mockSessionManager.mockSnapshot = nil
        
        // When: Load settings
        await viewModel.load()
        
        // Then: Error state
        XCTAssertFalse(viewModel.isLoading)
        // No error alert shown for missing snapshot - it's a silent failure
    }
    
    func testLanguageChangeSuccess() async throws {
        // Given: Initial language is English
        let initialSnapshot = SessionManager.Snapshot(
            me: MeResponse(
                userId: 1,
                email: "test@example.com",
                preferredLocaleCode: "en",
                flagAdmin: false,
                flagDeveloper: false,
                flagReviewer: false,
                createdAt: "2024-01-01T00:00:00Z",
                profiles: []
            ),
            appConfig: AppConfigResponse(
                supportedLocales: ["en", "es", "fr"],
                featureFlags: [],
                cueContentPageSize: 10,
                recordingHistoryPageSize: 20,
                magicLinkCooldownSeconds: 60
            )
        )
        mockSessionManager.mockSnapshot = initialSnapshot
        await viewModel.load()
        
        mockAccountRepo.shouldSucceed = true
        
        // When: Change language to Spanish
        await viewModel.updateLanguage(to: "es")
        
        // Then: Language updated
        XCTAssertTrue(mockAccountRepo.updateLocaleCalled)
        XCTAssertEqual(mockAccountRepo.lastUpdatedLocale, "es")
    }
    
    func testLogout() {
        // When: Logout
        viewModel.logout()
        
        // Then: Logout use case called
        XCTAssertTrue(mockLogoutUC.logoutCalled)
    }
}

// MARK: - Mocks

class MockAccountRepository: AccountRepository {
    var shouldSucceed = true
    var setActiveProfileCalled = false
    var lastLanguageCode: String?
    
    func fetchMe() async throws -> MeResponse {
        throw NSError(domain: "test", code: -1)
    }
    
    func fetchAppConfig() async throws -> AppConfigResponse {
        throw NSError(domain: "test", code: -1)
    }
    
    func setActiveProfile(accountId: Int64, languageCode: String) async throws {
        setActiveProfileCalled = true
        lastLanguageCode = languageCode
        
        if !shouldSucceed {
            throw NSError(domain: "test", code: -1)
        }
    }
    
    func getOrCreateProfile(accountId: Int64, languageCode: String) async throws -> Int64 {
        return 1
    }
    
    func requestAccountDeletion(accountId: Int64) async throws {
        // Not tested in these scenarios
    }
}

class MockLogoutUseCase: LogoutUseCase {
    var logoutCalled = false
    
    override func execute() {
        logoutCalled = true
    }
}

class MockRuntimeConfigProvider: RuntimeConfigProvider {
    func currentConfig() -> RuntimeConfig? {
        return RuntimeConfig(
            cueContentPageSize: 10,
            recordingHistoryPageSize: 20,
            magicLinkCooldownSeconds: 60,
            enabledFeatureFlags: []
        )
    }
    
    var configStream: AsyncStream<RuntimeConfig?> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

class MockSessionManager: SessionManager {
    var mockSnapshot: SessionManager.Snapshot?
    
    override func currentSnapshot() -> SessionManager.Snapshot? {
        return mockSnapshot
    }
    
    override func bootstrap() async throws {
        // No-op for tests
    }
    
    override func refreshAccountData() async throws {
        // No-op for tests
    }
    
    override func applyAppConfig() async {
        // No-op for tests
    }
}

