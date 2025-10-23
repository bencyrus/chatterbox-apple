import Foundation
import Observation

@Observable
final class AppEnvironment {
    // Base URL for the gateway (PostgREST sits behind it)
    var baseURL: URL

    // RPC paths
    let requestMagicLinkPath: String = "/rpc/request_magic_link"
    let loginWithMagicTokenPath: String = "/rpc/login_with_magic_token"

    // Universal link configuration (opens the app)
    // Only these hosts are accepted for magic login links
    var universalLinkAllowedHosts: Set<String>
    // Path that the app expects for magic login
    var magicLinkPath: String

    // UX: cooldown seconds between magic-link requests
    let magicLinkCooldownSeconds: Int

    // Gateway token refresh headers (outgoing from gateway to client)
    let newAccessTokenHeaderOut: String = "X-New-Access-Token"
    let newRefreshTokenHeaderOut: String = "X-New-Refresh-Token"

    init() {
        // Require Info.plist configuration; no defaults
        let info = Bundle.main

        guard let apiBaseURLString = info.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let parsedBaseURL = URL(string: apiBaseURLString) else {
            fatalError("Missing or invalid Info.plist key 'API_BASE_URL' (expected a valid https URL).")
        }
        self.baseURL = parsedBaseURL

        guard let hostsString = info.object(forInfoDictionaryKey: "UNIVERSAL_LINK_HOSTS") as? String else {
            fatalError("Missing Info.plist key 'UNIVERSAL_LINK_HOSTS' (comma-separated hostnames).")
        }
        let allowedHosts = hostsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        guard !allowedHosts.isEmpty else {
            fatalError("Info.plist 'UNIVERSAL_LINK_HOSTS' must contain at least one hostname.")
        }
        self.universalLinkAllowedHosts = Set(allowedHosts)

        guard let magicPathRaw = info.object(forInfoDictionaryKey: "MAGIC_LINK_PATH") as? String else {
            fatalError("Missing Info.plist key 'MAGIC_LINK_PATH' (e.g., '/auth/magic').")
        }
        let magicPath = magicPathRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !magicPath.isEmpty, magicPath.hasPrefix("/") else {
            fatalError("Info.plist 'MAGIC_LINK_PATH' must be a non-empty string starting with '/'.")
        }
        self.magicLinkPath = magicPath

        // Optional: cooldown; default to 60 if missing or invalid
        if let cooldown = info.object(forInfoDictionaryKey: "MAGIC_LINK_COOLDOWN_SECONDS") as? NSNumber {
            self.magicLinkCooldownSeconds = max(0, cooldown.intValue)
        } else if let cooldownStr = info.object(forInfoDictionaryKey: "MAGIC_LINK_COOLDOWN_SECONDS") as? String, let v = Int(cooldownStr) {
            self.magicLinkCooldownSeconds = max(0, v)
        } else {
            self.magicLinkCooldownSeconds = 60
        }
    }
}


