import Foundation

// MARK: - /rpc/me

struct MeResponse: Decodable {
    struct Account: Decodable {
        let email: String?
        let flags: [String]
        let accountId: Int64
        let accountRole: String
        let phoneNumber: String?
        let lastLoginAt: String?

        /// Typed view of the account's entitlement flags.
        var entitlements: AccountEntitlements {
            let typedFlags = flags.compactMap(AccountFlag.init(rawValue:))
            return AccountEntitlements(flags: typedFlags)
        }
    }

    let account: Account
    let activeProfile: ActiveProfileSummary?
}

struct ActiveProfileSummary: Decodable {
    let accountId: Int64
    let profileId: Int64
    let languageCode: String
}

// MARK: - /rpc/app_config

struct AppConfigResponse: Decodable {
    let defaultProfileLanguageCode: String
    let availableLanguageCodes: [String]

    /// Backend-provided runtime flags for the app.
    ///
    /// These are intentionally kept as raw strings at the DTO boundary so they
    /// can be mapped into the typed `FeatureFlag` enum by the config loader.
    /// Example JSON:
    /// {
    ///   "available_language_codes": ["en", "fr", "de"],
    ///   "default_profile_language_code": "en",
    ///   "flags": ["developerMenuEnabled"]
    /// }
    let flags: [String]
}


