import Foundation
import Observation

/// Shared, user-scoped state describing whether the current account should
/// have access to developer tooling such as the network console.
@MainActor
@Observable
final class DeveloperToolsState {
    /// Set to `true` when `/rpc/me` marks the current user as a developer.
    var isDeveloperUser: Bool = false
}



