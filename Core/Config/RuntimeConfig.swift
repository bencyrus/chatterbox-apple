import Foundation

/// Immutable snapshot of runtime configuration merged from build defaults,
/// `/rpc/app_config`, and any local Debug overrides.
struct RuntimeConfig: Equatable, Codable {
    /// Cooldown (in seconds) between auth link / code requests.
    let magicLinkCooldownSeconds: Int

    /// Default number of cues to request from the backend for list screens.
    let cuesPageSize: Int

    /// Enabled feature flags.
    private let enabledFlags: Set<FeatureFlag>

    init(
        magicLinkCooldownSeconds: Int = 60,
        cuesPageSize: Int = 5,
        enabledFlags: Set<FeatureFlag> = []
    ) {
        self.magicLinkCooldownSeconds = max(0, magicLinkCooldownSeconds)
        self.cuesPageSize = max(1, cuesPageSize)
        self.enabledFlags = enabledFlags
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        enabledFlags.contains(flag)
    }

    func with(flags newFlags: Set<FeatureFlag>) -> RuntimeConfig {
        RuntimeConfig(
            magicLinkCooldownSeconds: magicLinkCooldownSeconds,
            cuesPageSize: cuesPageSize,
            enabledFlags: newFlags
        )
    }
}


