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

        var isDeveloper: Bool {
            flags.contains("developer")
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
}


