import Foundation

/// Public interface for reading runtime configuration.
///
/// Features should depend on this protocol rather than concrete types so that
/// tests can inject custom configurations.
protocol ConfigProviding: AnyObject {
    var snapshot: RuntimeConfig { get }
    var updates: AsyncStream<RuntimeConfig> { get }
}

/// In‑memory `ConfigProviding` implementation.
///
/// A separate loader is responsible for fetching `/rpc/app_config` and
/// calling `update(_:)` when fresh configuration is available.
final class RuntimeConfigProvider: ConfigProviding {
    private let lock = NSLock()
    private var _snapshot: RuntimeConfig

    private let continuation: AsyncStream<RuntimeConfig>.Continuation
    let updates: AsyncStream<RuntimeConfig>

    init(initial: RuntimeConfig = RuntimeConfig()) {
        self._snapshot = initial

        var continuation: AsyncStream<RuntimeConfig>.Continuation!
        self.updates = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    var snapshot: RuntimeConfig {
        lock.lock()
        defer { lock.unlock() }
        return _snapshot
    }

    /// Replace the current snapshot and notify subscribers.
    func update(_ newValue: RuntimeConfig) {
        lock.lock()
        _snapshot = newValue
        lock.unlock()

        continuation.yield(newValue)
    }
}


