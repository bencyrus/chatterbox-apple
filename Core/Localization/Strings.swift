import Foundation

enum Strings {
    enum Tabs {
        static let home = NSLocalizedString("tabs.home", comment: "Home tab")
        static let settings = NSLocalizedString("tabs.settings", comment: "Settings tab")
    }
    enum Login {
        static let title = NSLocalizedString("login.title", comment: "Login title")
        static let identifierPlaceholder = NSLocalizedString("login.identifier_placeholder", comment: "Identifier placeholder")
        static let requestLink = NSLocalizedString("login.request_link", comment: "Request link button")
        static let linkSentHint = NSLocalizedString("login.link_sent_hint", comment: "Hint about checking email/SMS")
        static let linkSentAt = NSLocalizedString("login.link_sent_at", comment: "Link sent at time label")
        static let cooldownMessage = NSLocalizedString("login.cooldown_message", comment: "Cooldown countdown label")
    }
    enum Home {
        static let title = NSLocalizedString("home.title", comment: "Home title")
        static let latestJWT = NSLocalizedString("home.latest_jwt", comment: "Latest JWT label")
        static let noToken = NSLocalizedString("home.no_token", comment: "No token text")
    }
    enum Settings {
        static let title = NSLocalizedString("settings.title", comment: "Settings title")
        static let logout = NSLocalizedString("settings.logout", comment: "Logout button")
        static let languagePickerTitle = NSLocalizedString("settings.language_picker_title", comment: "Language picker title")
    }
    enum Errors {
        static let missingIdentifier = NSLocalizedString("errors.missing_identifier", comment: "Missing identifier")
        static let requestFailed = NSLocalizedString("errors.request_failed", comment: "Request failed")
        static let invalidMagicLink = NSLocalizedString("errors.invalid_magic_link", comment: "Invalid magic link")
        static let signInErrorTitle = NSLocalizedString("errors.sign_in_error_title", comment: "Sign-in error title")
        static let settingsLoadTitle = NSLocalizedString("errors.settings_load_title", comment: "Settings load error title")
        static let settingsLoadFailed = NSLocalizedString("errors.settings_load_failed", comment: "Settings load failed")
        static let settingsSaveTitle = NSLocalizedString("errors.settings_save_title", comment: "Settings save error title")
        static let settingsSaveFailed = NSLocalizedString("errors.settings_save_failed", comment: "Settings save failed")
        static let settingsAccountMissing = NSLocalizedString("errors.settings_account_missing", comment: "Settings account missing")
    }
    enum A11y {
        static let identifierField = NSLocalizedString("a11y.identifier_field", comment: "Identifier field")
        static let errorLabel = NSLocalizedString("a11y.error", comment: "Error label")
        static let logout = NSLocalizedString("a11y.logout", comment: "Logout button")
    }
    enum Common {
        static let ok = NSLocalizedString("common.ok", comment: "OK button")
    }
}


