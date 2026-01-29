import Foundation

@MainActor
final class SessionManager {
    private let sessionController: SessionControllerProtocol
    private let accountRepository: AccountRepository
    private let configProvider: ConfigProviding
    private let featureAccessContext: FeatureAccessContext

    enum SessionError: Error {
        case missingSnapshot
    }

    struct Snapshot {
        let me: MeResponse
        let appConfig: AppConfigResponse
    }

    private(set) var snapshot: Snapshot?

    init(
        sessionController: SessionControllerProtocol,
        accountRepository: AccountRepository,
        configProvider: ConfigProviding,
        featureAccessContext: FeatureAccessContext
    ) {
        self.sessionController = sessionController
        self.accountRepository = accountRepository
        self.configProvider = configProvider
        self.featureAccessContext = featureAccessContext
    }

    /// Entry point called when the app becomes active (launch or foreground).
    func handleAppBecameActive() async {
        let state = await sessionController.currentState
        guard state == .authenticated else {
            return
        }

        do {
            try await runBootstrapPipeline()
        } catch {
            if let networkError = error as? NetworkError, case .unauthorized = networkError {
                // On unauthorized, the API client will already have triggered a logout
                // via SessionController. We treat this as a session-ending event and
                // avoid surfacing an additional error from the bootstrap path.
                return
            }

            Log.session.error(
                """
                Session bootstrap failed: \(String(describing: error), privacy: .private)
                """
            )
        }
    }

    /// Clears any cached, user-scoped session state.
    ///
    /// This must be called when the user signs out to prevent stale `me`/profile
    /// data from being reused after a subsequent login to a different account.
    func resetForSignOut() {
        snapshot = nil
        featureAccessContext.accountEntitlements = AccountEntitlements(flags: [])
        // Note: we intentionally do not clear `runtimeConfig` here; it is app-wide
        // and will be refreshed on the next successful bootstrap anyway.
    }

    // MARK: - Internal

    /// Re-runs the bootstrap pipeline after a mutation that affects account state
    /// (e.g. active profile change) and returns the fresh snapshot.
    func refreshAfterProfileChange() async throws -> Snapshot {
        try await runBootstrapPipeline()
        guard let snapshot else {
            throw SessionError.missingSnapshot
        }
        return snapshot
    }

    /// Orchestrates all bootstrap tasks that should run when the app becomes active.
    private func runBootstrapPipeline() async throws {
        let me = try await accountRepository.fetchMe()
        let config = try await accountRepository.fetchAppConfig()

        snapshot = Snapshot(me: me, appConfig: config)

        applyAccountState(from: me)
        applyRuntimeConfig(from: config)
    }

    private func applyAccountState(from me: MeResponse) {
        // Update shared feature access context based on account flags and current config.
        featureAccessContext.accountEntitlements = me.account.entitlements
    }

    private func applyRuntimeConfig(from config: AppConfigResponse) {
        // Update runtime config flags using values returned by /rpc/app_config.
        if let runtimeProvider = configProvider as? RuntimeConfigProvider {
            let current = runtimeProvider.snapshot
            let flags = Set(config.flags.compactMap(FeatureFlag.init(rawValue:)))
            let updated = current.with(flags: flags)
            runtimeProvider.update(updated)
        }
    }
}


