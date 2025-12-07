import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let accountRepository: AccountRepository
    private let logoutUseCase: LogoutUseCase
    private let featureAccessContext: FeatureAccessContext
    private let configProvider: ConfigProviding
    private let sessionManager: SessionManager

    // MARK: - State

    var email: String?
    var availableLanguages: [String] = []
    var selectedLanguageCode: String?

    var isLoading: Bool = false
    var isSaving: Bool = false

    var errorAlertTitle: String = ""
    var errorAlertMessage: String = ""
    var isShowingErrorAlert: Bool = false

    private var accountId: Int64?

    init(
        accountRepository: AccountRepository,
        logoutUseCase: LogoutUseCase,
        featureAccessContext: FeatureAccessContext,
        configProvider: ConfigProviding,
        sessionManager: SessionManager
    ) {
        self.accountRepository = accountRepository
        self.logoutUseCase = logoutUseCase
        self.featureAccessContext = featureAccessContext
        self.configProvider = configProvider
        self.sessionManager = sessionManager
    }

    // MARK: - Intents

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let snapshot = sessionManager.snapshot {
                try await apply(me: snapshot.me, config: snapshot.appConfig)
            } else {
                await sessionManager.handleAppBecameActive()
                guard let snapshot = sessionManager.snapshot else {
                    presentError(title: Strings.Errors.settingsLoadTitle, message: Strings.Errors.settingsLoadFailed)
                    return
                }
                try await apply(me: snapshot.me, config: snapshot.appConfig)
            }
        } catch {
            presentError(title: Strings.Errors.settingsLoadTitle, message: Strings.Errors.settingsLoadFailed)
        }
    }

    func logout() {
        logoutUseCase.execute()
    }

    func updateLanguage(to newCode: String) async {
        guard !newCode.isEmpty else { return }
        guard newCode != selectedLanguageCode else { return }
        guard let currentAccountId = accountId else {
            presentError(title: Strings.Errors.settingsSaveTitle, message: Strings.Errors.settingsAccountMissing)
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await accountRepository.setActiveProfile(accountId: currentAccountId, languageCode: newCode)
            selectedLanguageCode = newCode
            NotificationCenter.default.post(name: .activeProfileDidChange, object: nil)
        } catch {
            presentError(title: Strings.Errors.settingsSaveTitle, message: Strings.Errors.settingsSaveFailed)
        }
    }

    // MARK: - Internal

    private func apply(me: MeResponse, config: AppConfigResponse) async throws {
        // Update shared feature access context based on account flags and current config.
        featureAccessContext.accountEntitlements = me.account.entitlements
        featureAccessContext.runtimeConfig = configProvider.snapshot

        accountId = me.account.accountId
        email = me.account.email

        availableLanguages = config.availableLanguageCodes

        if let active = me.activeProfile {
            selectedLanguageCode = active.languageCode
            return
        }

        try await accountRepository.setActiveProfile(
            accountId: me.account.accountId,
            languageCode: config.defaultProfileLanguageCode
        )

        let refreshed = try await sessionManager.refreshAfterProfileChange()
        if let active = refreshed.me.activeProfile {
            selectedLanguageCode = active.languageCode
        } else {
            selectedLanguageCode = config.defaultProfileLanguageCode
        }
    }

    private func presentError(title: String, message: String) {
        errorAlertTitle = title
        errorAlertMessage = message
        isShowingErrorAlert = true
    }
}


