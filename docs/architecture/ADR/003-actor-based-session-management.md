# ADR 003: Actor-Based Session Management

## Status
Accepted

## Context

Session management requires handling authentication tokens (`accessToken`, `refreshToken`) that must be:
- Accessed from multiple concurrent tasks
- Stored securely in Keychain
- Thread-safe to prevent race conditions
- Available synchronously for API request headers
- Observable for UI updates (logged in/out state)

Traditional approaches have issues:
- **Global mutable state**: Unsafe for concurrency
- **DispatchQueues**: Manual synchronization, error-prone
- **Locks/Semaphores**: Low-level, easy to misuse
- **ObservableObject with locks**: Mixing patterns, complex

Swift's actor model provides built-in thread-safety for mutable state.

## Decision

We will use an **`actor`** for managing authentication tokens and session state, with a separate `@Observable` class for broadcasting session changes to the UI.

### Architecture

```
┌─────────────────────┐
│   SessionManager    │  @Observable class
│  - snapshot         │  (UI-observable state)
│  - sessionActor     │
└──────────┬──────────┘
           │ delegates to
           ▼
┌─────────────────────┐
│   SessionController │  actor
│  - tokens           │  (thread-safe token storage)
│  - keychain         │
└─────────────────────┘
```

### Components

**1. SessionController (Actor)**
- Manages authentication tokens
- Provides thread-safe access
- Handles Keychain persistence
- Emits state changes via AsyncStream

```swift
actor SessionController {
    private var tokens: AuthTokens?
    
    func setTokens(_ tokens: AuthTokens) async {
        self.tokens = tokens
        // Save to Keychain
        // Emit change
    }
    
    func getAccessToken() async -> String? {
        return tokens?.accessToken
    }
}
```

**2. SessionManager (@Observable Class)**
- Holds UI-observable snapshot of session state
- Coordinates session lifecycle (bootstrap, refresh)
- Bridges actor state to SwiftUI
- Orchestrates high-level operations

```swift
@Observable
final class SessionManager {
    struct Snapshot {
        let me: MeResponse
        let appConfig: AppConfigResponse
    }
    
    private(set) var snapshot: Snapshot?
    private let sessionController: SessionController
}
```

## Consequences

### Positive
- **Thread-Safety**: Actor ensures no data races on tokens
- **Swift Concurrency Native**: Uses language features, not manual locks
- **Type-Safe**: Compiler enforces async access to actor
- **Testable**: Easy to mock actor for tests
- **Clear Separation**: Token management (actor) vs UI state (observable)
- **Performant**: Actor optimizes for minimal context switching

### Negative
- **Async Required**: All token access must be `async` or from actor context
- **Two Classes**: Slightly more complex than single class
- **Learning Curve**: Team needs to understand actors
- **Debugging**: Actor isolation can make debugging trickier

## Implementation Details

### Token Access in API Client

```swift
final class DefaultAPIClient: APIClient {
    private let sessionController: SessionController
    
    func execute<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response {
        guard endpoint.requiresAuth else {
            return try await performRequest(endpoint, token: nil)
        }
        
        // Actor ensures thread-safe access
        guard let token = await sessionController.currentAccessToken() else {
            throw APIError.unauthorized
        }
        
        return try await performRequest(endpoint, token: token)
    }
}
```

### Token Refresh Flow

```swift
extension SessionController {
    func refreshTokenIfNeeded() async throws -> String {
        // Actor isolation ensures no concurrent refreshes
        guard let refreshToken = tokens?.refreshToken else {
            throw SessionError.noRefreshToken
        }
        
        let newTokens = try await api.refresh(with: refreshToken)
        await setTokens(newTokens)
        return newTokens.accessToken
    }
}
```

### Session State Stream

```swift
actor SessionController {
    private let stateContinuation: AsyncStream<SessionState>.Continuation
    
    var stateStream: AsyncStream<SessionState> {
        AsyncStream { continuation in
            self.stateContinuation = continuation
        }
    }
    
    func setTokens(_ tokens: AuthTokens) async {
        self.tokens = tokens
        stateContinuation.yield(tokens == nil ? .signedOut : .authenticated)
    }
}
```

## Actors vs. Other Approaches

### vs. Serial DispatchQueue

```swift
// ❌ Old approach - manual synchronization
class SessionManager {
    private let queue = DispatchQueue(label: "session")
    private var tokens: AuthTokens?
    
    func getToken() -> String? {
        queue.sync { tokens?.accessToken }
    }
}

// ✅ Actor - compiler-enforced safety
actor SessionController {
    private var tokens: AuthTokens?
    
    func getToken() async -> String? {
        tokens?.accessToken
    }
}
```

### vs. @Observable with Locks

```swift
// ❌ Mixing patterns - complex
@Observable
final class SessionManager {
    private let lock = NSLock()
    private var _tokens: AuthTokens?
    
    var tokens: AuthTokens? {
        lock.lock()
        defer { lock.unlock() }
        return _tokens
    }
}

// ✅ Separation of concerns - clear
actor SessionController {
    private var tokens: AuthTokens?
}

@Observable
final class SessionManager {
    private let controller: SessionController
    // Only UI state here
}
```

## When to Use Actors

### ✅ Use Actor When:
- Managing mutable state accessed concurrently
- State needs strong isolation guarantees
- Multiple async tasks modify same data
- Examples: SessionController, cache managers, coordinators

### ❌ Don't Use Actor When:
- State is read-only (use `struct`)
- Only accessed from MainActor (use `@Observable`)
- Simple value types (use local variables)
- Needs synchronous access patterns

## Testing

Actors are easy to test:

```swift
func testTokenStorage() async throws {
    let controller = SessionController()
    
    let tokens = AuthTokens(
        accessToken: "test-access",
        refreshToken: "test-refresh"
    )
    
    await controller.setTokens(tokens)
    let retrieved = await controller.getAccessToken()
    
    XCTAssertEqual(retrieved, "test-access")
}
```

## Alternatives Considered

### Single @Observable Class with Locks
- **Pros**: One class, simpler on surface
- **Cons**: Manual synchronization, error-prone, mixing concerns
- **Decision**: Rejected - actors are safer

### All Actor, No @Observable
- **Pros**: Maximum isolation
- **Cons**: Can't observe from SwiftUI, async updates only
- **Decision**: Rejected - UI needs synchronous observation

### DispatchQueue + ObservableObject
- **Pros**: Pre-Swift Concurrency approach, familiar
- **Cons**: Manual synchronization, can't use async/await naturally
- **Decision**: Rejected - actors are modern standard

## Migration from ObservableObject

Original code likely used:

```swift
class TokenManager: ObservableObject {
    @Published var isAuthenticated = false
    private var tokens: AuthTokens?
}
```

Migration path:
1. Create actor for token storage
2. Keep observable for UI state
3. Actor handles persistence, observable handles presentation
4. Update all access sites to `async`

## Related Decisions
- ADR 002: Using `@Observable` for UI state
- ADR 001: Repository pattern for data access

## References
- [Swift Concurrency: Actors](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html#ID645)
- [WWDC 2021: Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
- [Swift Evolution: SE-0306](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)

## Revision History
- 2025-12-13: Initial version

