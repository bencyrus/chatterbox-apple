import Foundation

@MainActor
final class AppCoordinator {
    let environment: Environment
    let sessionController: SessionControllerProtocol
    let configProvider: ConfigProviding
    let networkLogStore: NetworkLogStore
    let analyticsRecorder: AnalyticsRecording
    let featureAccessContext: FeatureAccessContext
    let sessionManager: SessionManager

    private let deepLinkParser = DeepLinkParser()
    private let apiClient: APIClient

    init(
        environment: Environment,
        sessionController: SessionControllerProtocol,
        configProvider: ConfigProviding,
        networkLogStore: NetworkLogStore,
        analyticsRecorder: AnalyticsRecording,
        featureAccessContext: FeatureAccessContext,
        apiClient: APIClient,
        sessionManager: SessionManager
    ) {
        self.environment = environment
        self.sessionController = sessionController
        self.configProvider = configProvider
        self.networkLogStore = networkLogStore
        self.analyticsRecorder = analyticsRecorder
        self.featureAccessContext = featureAccessContext
        self.apiClient = apiClient
        self.sessionManager = sessionManager
    }

    // MARK: - Lifecycle

    func handleSceneBecameActive() {
        Task {
            await sessionManager.handleAppBecameActive()
        }
    }

    // MARK: - Deep links

    func handle(url: URL) {
        guard let intent = deepLinkParser.parse(url: url) else { return }

        switch intent {
        case .magicToken(let token):
            let authRepo = PostgrestAuthRepository(client: apiClient)
            let useCase = LoginWithMagicTokenUseCase(
                repository: authRepo,
                sessionController: sessionController,
                analytics: analyticsRecorder
            )
            Task {
                try? await useCase.execute(token: token)
            }
        }
    }

    // MARK: - ViewModel factories

    func makeAuthViewModel() -> AuthViewModel {
        let authRepo = PostgrestAuthRepository(client: apiClient)
        let logoutUC = LogoutUseCase(sessionController: sessionController)
        let requestMagic = RequestMagicLinkUseCase(repository: authRepo, analytics: analyticsRecorder)
        let loginWithMagic = LoginWithMagicTokenUseCase(
            repository: authRepo,
            sessionController: sessionController,
            analytics: analyticsRecorder
        )
        return AuthViewModel(
            logout: logoutUC,
            requestMagicLink: requestMagic,
            loginWithMagicToken: loginWithMagic,
            configProvider: configProvider
        )
    }

    func makeHomeViewModel() -> HomeViewModel {
        let accountRepo = PostgrestAccountRepository(client: apiClient)
        let activeProfileHelper = ActiveProfileHelper(
            accountRepository: accountRepo,
            sessionManager: sessionManager
        )
        let cueRepo = PostgrestCueRepository(client: apiClient)
        return HomeViewModel(
            activeProfileHelper: activeProfileHelper,
            cueRepository: cueRepo,
            configProvider: configProvider
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        let accountRepo = PostgrestAccountRepository(client: apiClient)
        let logoutUC = LogoutUseCase(sessionController: sessionController)
        return SettingsViewModel(
            accountRepository: accountRepo,
            logoutUseCase: logoutUC,
            featureAccessContext: featureAccessContext,
            configProvider: configProvider,
            sessionManager: sessionManager
        )
    }
    
    func makeHistoryViewModel() -> HistoryViewModel {
        let recordingRepo = PostgrestRecordingRepository(client: apiClient)
        let accountRepo = PostgrestAccountRepository(client: apiClient)
        let activeProfileHelper = ActiveProfileHelper(
            accountRepository: accountRepo,
            sessionManager: sessionManager
        )
        return HistoryViewModel(
            recordingRepository: recordingRepo,
            activeProfileHelper: activeProfileHelper
        )
    }
    
    func makeCueDetailViewModel() -> CueDetailViewModel {
        let recordingRepo = PostgrestRecordingRepository(client: apiClient)
        let accountRepo = PostgrestAccountRepository(client: apiClient)
        let activeProfileHelper = ActiveProfileHelper(
            accountRepository: accountRepo,
            sessionManager: sessionManager
        )
        return CueDetailViewModel(
            recordingRepository: recordingRepo,
            activeProfileHelper: activeProfileHelper
        )
    }
}

