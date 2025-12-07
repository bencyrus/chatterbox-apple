import SwiftUI

@main
struct ChatterboxApp: App {
    private let environment: Environment
    private let sessionController = SessionController()
    private let configProvider = RuntimeConfigProvider()
    private let featureAccessContext = FeatureAccessContext()

    private let analyticsRecorder: AnalyticsRecording
    private let apiClient: APIClient
    private let sessionManager: SessionManager

    @State private var networkLogStore: NetworkLogStore
    @State private var coordinator: AppCoordinator
    @State private var localizationProvider = LocalizationProvider()

    @SwiftUI.Environment(\.scenePhase) private var scenePhase

    init() {
        // In a production app we would surface a nicer fatal error, but for
        // now failing fast keeps configuration problems obvious during setup.
        do {
            environment = try EnvironmentLoader.load()
        } catch {
            fatalError("Failed to load Environment: \(error)")
        }

        // Analytics: enable OSLog sink only when allowed by config snapshot.
        if configProvider.snapshot.isEnabled(.analyticsEnabled) {
            analyticsRecorder = AnalyticsRecorder(sinks: [OSLogAnalyticsSink()])
        } else {
            analyticsRecorder = AnalyticsRecorder(sinks: [])
        }

        let logStore = NetworkLogStore()
        _networkLogStore = State(initialValue: logStore)

        let apiClient = DefaultAPIClient(
            environment: environment,
            sessionController: sessionController,
            configProvider: configProvider,
            networkLogStore: logStore
        )
        self.apiClient = apiClient

        let accountRepo = PostgrestAccountRepository(client: apiClient)
        let sessionManager = SessionManager(
            sessionController: sessionController,
            accountRepository: accountRepo,
            configProvider: configProvider,
            featureAccessContext: featureAccessContext
        )
        self.sessionManager = sessionManager

        _networkLogStore = State(initialValue: logStore)
        _coordinator = State(
            initialValue: AppCoordinator(
                environment: environment,
                sessionController: sessionController,
                configProvider: configProvider,
                networkLogStore: logStore,
                analyticsRecorder: analyticsRecorder,
                featureAccessContext: featureAccessContext,
                apiClient: apiClient,
                sessionManager: sessionManager
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            CompositionRootView(
                coordinator: coordinator
            )
            .environment(networkLogStore)
            .environment(featureAccessContext)
            .environment(\.locale, localizationProvider.locale)
            .preferredColorScheme(.light)
            .onOpenURL { url in
                coordinator.handle(url: url)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    coordinator.handleSceneBecameActive()
                }
            }
        }
    }
}

extension Notification.Name {
    static let activeProfileDidChange = Notification.Name("activeProfileDidChange")
}

