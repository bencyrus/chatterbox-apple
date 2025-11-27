import Foundation

@MainActor
struct ActiveProfileHelper {
    private let accountRepository: AccountRepository

    init(accountRepository: AccountRepository) {
        self.accountRepository = accountRepository
    }

    func ensureActiveProfile() async throws -> ActiveProfileSummary {
        let me = try await accountRepository.fetchMe()

        if let active = me.activeProfile {
            return active
        }

        let config = try await accountRepository.fetchAppConfig()
        let accountId = me.account.accountId

        try await accountRepository.setActiveProfile(
            accountId: accountId,
            languageCode: config.defaultProfileLanguageCode
        )

        let refreshedMe = try await accountRepository.fetchMe()
        if let active = refreshedMe.activeProfile {
            return active
        }

        throw AccountError.invalidResponse
    }
}


