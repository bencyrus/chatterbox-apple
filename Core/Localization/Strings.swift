import Foundation

enum Strings {
    enum Tabs {
        static let home = NSLocalizedString("tabs.home", comment: "Home tab")
        static let settings = NSLocalizedString("tabs.settings", comment: "Settings tab")
    }
    enum Login {
        static let title = NSLocalizedString("login.title", comment: "Login title")
        static let identifierPlaceholder = NSLocalizedString("login.identifier_placeholder", comment: "Identifier placeholder")
        static let codePlaceholder = NSLocalizedString("login.code_placeholder", comment: "Code placeholder")
        static let requestCode = NSLocalizedString("login.request_code", comment: "Request code button")
        static let verifyAndContinue = NSLocalizedString("login.verify_and_continue", comment: "Verify button")
    }
    enum Home {
        static let title = NSLocalizedString("home.title", comment: "Home title")
        static let latestJWT = NSLocalizedString("home.latest_jwt", comment: "Latest JWT label")
        static let noToken = NSLocalizedString("home.no_token", comment: "No token text")
    }
    enum Settings {
        static let title = NSLocalizedString("settings.title", comment: "Settings title")
        static let logout = NSLocalizedString("settings.logout", comment: "Logout button")
    }
    enum Errors {
        static let missingIdentifier = NSLocalizedString("errors.missing_identifier", comment: "Missing identifier")
        static let missingCode = NSLocalizedString("errors.missing_code", comment: "Missing code")
        static let requestFailed = NSLocalizedString("errors.request_failed", comment: "Request failed")
        static let invalidCode = NSLocalizedString("errors.invalid_code", comment: "Invalid code")
    }
    enum A11y {
        static let identifierField = NSLocalizedString("a11y.identifier_field", comment: "Identifier field")
        static let codeField = NSLocalizedString("a11y.code_field", comment: "Code field")
        static let errorLabel = NSLocalizedString("a11y.error", comment: "Error label")
        static let logout = NSLocalizedString("a11y.logout", comment: "Logout button")
    }
}


