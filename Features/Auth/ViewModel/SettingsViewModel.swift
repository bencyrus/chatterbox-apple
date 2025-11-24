import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let accountRepository: AccountRepository

    // MARK: - State

    var availableLanguages: [String] = []
    var selectedLanguageCode: String?

    var isLoading: Bool = false
    var isSaving: Bool = false

    var errorAlertTitle: String = ""
    var errorAlertMessage: String = ""
    var isShowingErrorAlert: Bool = false

    var isDeveloperUser: Bool = false

    private var accountId: Int64?

    init(accountRepository: AccountRepository) {
        self.accountRepository = accountRepository
    }

    // MARK: - Intents

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let meTask = accountRepository.fetchMe()
            async let configTask = accountRepository.fetchAppConfig()

            let (me, config) = try await (meTask, configTask)

            accountId = me.account.account.accountId
            if let email = me.account.account.email {
                isDeveloperUser = email.lowercased() == "imatiwx@gmail.com"
            } else {
                isDeveloperUser = false
            }

            availableLanguages = config.availableLanguageCodes

            if let active = me.activeProfile {
                selectedLanguageCode = active.languageCode
            } else {
                selectedLanguageCode = config.defaultProfileLanguageCode
            }
        } catch {
            presentError(title: Strings.Errors.settingsLoadTitle, message: Strings.Errors.settingsLoadFailed)
        }
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
        } catch {
            presentError(title: Strings.Errors.settingsSaveTitle, message: Strings.Errors.settingsSaveFailed)
        }
    }

    private func presentError(title: String, message: String) {
        errorAlertTitle = title
        errorAlertMessage = message
        isShowingErrorAlert = true
    }
}


