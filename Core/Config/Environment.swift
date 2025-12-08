import Foundation

/// Identifies the high-level build environment for the app.
///
/// The actual base URL and other details are resolved by `EnvironmentLoader`
/// so tests can override them easily.
enum AppEnvironmentKind: String {
    case development
    case production
}

/// Build‑time environment description.
///
/// This type intentionally contains only static configuration derived from
/// the bundle / build settings – it never hits the network.
struct Environment {
    let kind: AppEnvironmentKind
    let baseURL: URL
    let bundleIdentifier: String
    let appVersion: String
    let buildNumber: String
    let reviewerEmail: String?
}

/// Loads the current `Environment` from `Info.plist` and compile‑time flags.
///
/// This replaces ad‑hoc reads of individual keys scattered throughout the app.
enum EnvironmentLoader {
    enum Error: Swift.Error {
        case missingOrInvalidBaseURL
    }

    static func load(from bundle: Bundle = .main) throws -> Environment {
        #if DEBUG
        let kind: AppEnvironmentKind = .development
        #else
        let kind: AppEnvironmentKind = .production
        #endif

        guard
            let apiBaseURLString = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
            let baseURL = URL(string: apiBaseURLString)
        else {
            throw Error.missingOrInvalidBaseURL
        }

        let bundleIdentifier = bundle.bundleIdentifier ?? "com.chatterboxtalk"
        let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        let reviewerEmail = bundle.object(forInfoDictionaryKey: "REVIEWER_EMAIL") as? String

        return Environment(
            kind: kind,
            baseURL: baseURL,
            bundleIdentifier: bundleIdentifier,
            appVersion: appVersion,
            buildNumber: buildNumber,
            reviewerEmail: reviewerEmail
        )
    }
}

