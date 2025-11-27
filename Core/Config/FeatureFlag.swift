import Foundation

/// Known feature flags exposed to the client.
///
/// These are resolved by `RuntimeConfig` using build defaults, `/rpc/app_config`,
/// and optional local overrides in Debug builds.
enum FeatureFlag: String, CaseIterable, Codable, Hashable {
    case developerMenuEnabled
    case networkConsoleEnabled
    case analyticsEnabled
    case sessionReplayEnabled
    case recordingScaffoldEnabled
}


