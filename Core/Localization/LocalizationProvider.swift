import Foundation
import Observation

/// Immutable snapshot of localization‑relevant configuration.
struct LocalizationState: Equatable, Codable {
    /// Currently selected BCP‑47 language code (for example "en", "fr").
    let languageCode: String
    /// Languages the backend has declared as supported for this account/app.
    let availableLanguageCodes: [String]
}

/// Runtime localization provider that owns the app's active `Locale`.
///
/// - Exposes a simple `locale` for SwiftUI via `\.locale`.
/// - Can be bootstrapped from `/rpc/me` and `/rpc/app_config`.
/// - Supports safe, validated language changes at runtime.
@MainActor
@Observable
final class LocalizationProvider {
    private(set) var state: LocalizationState

    /// The `Locale` corresponding to the current language code.
    var locale: Locale {
        Locale(identifier: state.languageCode)
    }

    /// Creates a provider with an initial localization state.
    init(initialState: LocalizationState = LocalizationState(languageCode: Locale.current.identifier,
                                                             availableLanguageCodes: [Locale.current.identifier])) {
        self.state = initialState
    }

    /// Initializes localization from the authenticated user and app configuration.
    ///
    /// This chooses the active language in the following order:
    /// 1. The user's active profile language (if present).
    /// 2. The backend's `defaultProfileLanguageCode` from app config.
    func bootstrap(from me: MeResponse, appConfig: AppConfigResponse) {
        let activeCode = me.activeProfile?.languageCode ?? appConfig.defaultProfileLanguageCode
        state = LocalizationState(
            languageCode: activeCode,
            availableLanguageCodes: appConfig.availableLanguageCodes
        )
    }

    /// Attempts to switch the current language to the given code.
    ///
    /// The change is ignored if the code is unchanged or not in `availableLanguageCodes`.
    func setLanguage(code: String) {
        guard !code.isEmpty else { return }
        guard state.languageCode != code else { return }
        guard state.availableLanguageCodes.contains(code) else { return }

        state = LocalizationState(
            languageCode: code,
            availableLanguageCodes: state.availableLanguageCodes
        )
    }
}

