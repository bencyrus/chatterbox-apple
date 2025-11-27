import Foundation
import Observation

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

/// Typed representation of per-account flags returned by `/rpc/me`.
///
/// Raw values must stay in sync with the Postgres enum / domain so that
/// server-side checks and client expectations match exactly.
enum AccountFlag: String, CaseIterable, Codable, Hashable {
    case developer
}

/// Immutable view of an account's entitlements derived from account flags.
struct AccountEntitlements: Equatable {
    private let flags: Set<AccountFlag>

    init(flags: some Sequence<AccountFlag>) {
        self.flags = Set(flags)
    }

    /// Returns `true` if the account has the given flag.
    func has(_ flag: AccountFlag) -> Bool {
        flags.contains(flag)
    }

    /// Returns `true` only if the account has *all* required flags.
    func hasAll<S: Sequence>(_ required: S) -> Bool where S.Element == AccountFlag {
        Set(required).isSubset(of: flags)
    }

    /// Returns `true` if the account has *any* of the required flags.
    func hasAny<S: Sequence>(_ required: S) -> Bool where S.Element == AccountFlag {
        !Set(required).isDisjoint(with: flags)
    }
}

/// Declarative description of the flags required to access a feature.
///
/// Only the feature module should know which concrete flags are required;
/// callers work with higher-level feature-specific helpers.
struct FeatureGate: Equatable {
    let requiredAccountFlags: Set<AccountFlag>
    let requiredAppFlags: Set<FeatureFlag>

    init(
        requiredAccountFlags: Set<AccountFlag> = [],
        requiredAppFlags: Set<FeatureFlag> = []
    ) {
        self.requiredAccountFlags = requiredAccountFlags
        self.requiredAppFlags = requiredAppFlags
    }

    func isVisible(
        account: AccountEntitlements,
        config: RuntimeConfig
    ) -> Bool {
        let hasAccount = requiredAccountFlags.isEmpty || account.hasAll(requiredAccountFlags)
        let hasApp = requiredAppFlags.isEmpty || requiredAppFlags.allSatisfy { config.isEnabled($0) }
        return hasAccount && hasApp
    }
}

/// Access rules for developer tooling features.
enum DeveloperToolsFeature {
    /// Gate for showing the in-app developer / network console surfaces.
    ///
    /// For now this only requires the `developer` account flag so behavior
    /// matches the previous implementation. Once `/rpc/app_config` begins
    /// supplying runtime flags, we can extend this to also require specific
    /// `FeatureFlag` values sourced from `RuntimeConfig`.
    static let gate = FeatureGate(
        requiredAccountFlags: [.developer],
        requiredAppFlags: []
    )
}

/// Shared, user-scoped view of which features should be accessible based on
/// account flags and runtime configuration.
@MainActor
@Observable
final class FeatureAccessContext {
    /// Entitlements for the currently signed-in account.
    var accountEntitlements: AccountEntitlements = AccountEntitlements(flags: [])

    /// Current runtime configuration snapshot.
    var runtimeConfig: RuntimeConfig = RuntimeConfig()

    func canSee(_ gate: FeatureGate) -> Bool {
        gate.isVisible(account: accountEntitlements, config: runtimeConfig)
    }
}


