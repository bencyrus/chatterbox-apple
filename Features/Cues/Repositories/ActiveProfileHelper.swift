import Foundation

@MainActor
final class ActiveProfileHelper {
    private let accountRepository: AccountRepository
    private let sessionManager: SessionManager
    private var cachedActiveProfile: ActiveProfileSummary?

    init(accountRepository: AccountRepository, sessionManager: SessionManager) {
        self.accountRepository = accountRepository
        self.sessionManager = sessionManager
    }

    func clearCache() {
        cachedActiveProfile = nil
    }

    func ensureActiveProfile() async throws -> ActiveProfileSummary {
        if let cached = cachedActiveProfile {
            return cached
        }

        // Ensure we have a current session snapshot.
        if sessionManager.snapshot == nil {
            await sessionManager.handleAppBecameActive()
        }

        guard let snapshot = sessionManager.snapshot else {
            throw AccountError.requestFailed
        }

        let me = snapshot.me
        let config = snapshot.appConfig

        if let active = me.activeProfile {
            cachedActiveProfile = active
            return active
        }

        // No active profile yet – create one using default language from app config.
        let accountId = me.account.accountId

        try await accountRepository.setActiveProfile(
            accountId: accountId,
            languageCode: config.defaultProfileLanguageCode
        )

        let refreshed = try await sessionManager.refreshAfterProfileChange()
        if let active = refreshed.me.activeProfile {
            cachedActiveProfile = active
            return active
        }

        throw AccountError.invalidResponse
    }
}


