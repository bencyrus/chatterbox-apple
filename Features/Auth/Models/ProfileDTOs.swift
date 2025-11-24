import Foundation

// MARK: - /rpc/me

struct MeResponse: Decodable {
    let account: AccountEnvelope
    let activeProfile: ActiveProfileSummary?

    private enum CodingKeys: String, CodingKey {
        case account
        case activeProfile = "active_profile"
    }
}

struct AccountEnvelope: Decodable {
    let account: AccountSummary
    let accountRole: String
    let lastLoginAt: String?

    private enum CodingKeys: String, CodingKey {
        case account
        case accountRole = "account_role"
        case lastLoginAt = "last_login_at"
    }
}

struct AccountSummary: Decodable {
    let accountId: Int64
    let email: String?
    let phoneNumber: String?

    private enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case email
        case phoneNumber = "phone_number"
    }
}

struct ActiveProfileSummary: Decodable {
    let accountId: Int64
    let profileId: Int64
    let languageCode: String

    private enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case profileId = "profile_id"
        case languageCode = "language_code"
    }
}

// MARK: - /rpc/app_config

struct AppConfigResponse: Decodable {
    let defaultProfileLanguageCode: String
    let availableLanguageCodes: [String]

    private enum CodingKeys: String, CodingKey {
        case defaultProfileLanguageCode = "default_profile_language_code"
        case availableLanguageCodes = "available_language_codes"
    }
}


