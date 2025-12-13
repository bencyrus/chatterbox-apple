# ADR 004: No Third-Party Dependencies

## Status
Accepted

## Context

Modern iOS development often relies heavily on third-party libraries for common tasks:
- Networking (Alamofire, Moya)
- Image loading (SDWebImage, Kingfisher)
- Reactive programming (RxSwift, Combine)
- Dependency injection (Swinject, Resolver)
- UI components (SnapKit, SwiftUIX)

However, third-party dependencies come with costs:
- Security vulnerabilities
- Maintenance burden
- Version compatibility issues
- App size bloat
- Learning curve for new team members
- Dependency on external maintainers
- Potential abandonment

## Decision

We will **avoid third-party dependencies** and use only Apple system frameworks and SDKs unless a dependency is explicitly approved.

### Allowed by Default
- All Apple system frameworks (Foundation, UIKit, SwiftUI, Combine, etc.)
- Apple first-party SDKs (StoreKit, CoreData, CloudKit, etc.)
- Standard library features

### Requires Approval
- Any package from Swift Package Manager
- Any CocoaPods dependency
- Any Carthage dependency
- Any manually integrated framework

## Rationale

### Why We Can Avoid Dependencies

**Networking**: `URLSession` with async/await is powerful and modern
```swift
// No need for Alamofire
let (data, response) = try await URLSession.shared.data(for: request)
```

**JSON Parsing**: `Codable` handles 99% of cases
```swift
// No need for SwiftyJSON
let user = try JSONDecoder().decode(User.self, from: data)
```

**Image Loading**: SwiftUI's `AsyncImage`, or simple cache with `URLSession`
```swift
// No need for Kingfisher
AsyncImage(url: imageURL)
```

**Reactive Programming**: Swift Concurrency (`async/await`, `AsyncStream`) or Combine
```swift
// No need for RxSwift
for await value in stream {
    // Handle value
}
```

**Dependency Injection**: Manual DI with protocols is sufficient
```swift
// No need for Swinject
let viewModel = HomeViewModel(
    cueRepository: PostgrestCueRepository(apiClient: apiClient),
    activeProfileHelper: activeProfileHelper
)
```

## Consequences

### Positive
- **Security**: No external vulnerabilities to track
- **Stability**: No breaking changes from dependency updates
- **Performance**: No overhead from abstraction layers
- **Understanding**: Team knows exactly how everything works
- **App Size**: Smaller binary, faster download
- **Build Times**: Faster compilation
- **Control**: We own our entire stack
- **Simplicity**: Less to learn for new developers

### Negative
- **More Code**: We write utilities others have written
- **Reinventing Wheels**: Solving problems that have solutions
- **Time Investment**: Initial implementation takes longer
- **Feature Gap**: May lack advanced features of mature libraries
- **Bug Risk**: Our code may have bugs that libraries have fixed

## What We Build Instead

### Networking Layer

```swift
// Core/Networking/APIClient.swift
protocol APIClient {
    func execute<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response
}

final class DefaultAPIClient: APIClient {
    private let session: URLSession
    // Custom implementation with URLSession
}
```

### Logging

```swift
// Core/Observability/Log.swift
import OSLog

enum Log {
    static let app = Logger(subsystem: "com.chatterbox", category: "app")
    static let network = Logger(subsystem: "com.chatterbox", category: "network")
}
```

### State Management

```swift
// Using Swift's native @Observable
@Observable
final class ViewModel {
    var state: State
}
```

## Approval Process

If a dependency is truly needed:

1. **Document the need** - Why can't we build it ourselves?
2. **Evaluate alternatives** - What else could we use?
3. **Security review** - Is it well-maintained? Any vulnerabilities?
4. **License check** - Is the license compatible?
5. **Maintenance plan** - Who monitors for updates?
6. **Removal strategy** - How would we remove it later?
7. **Team discussion** - Consensus required

### Approval Template

```markdown
## Dependency Request: [Package Name]

**Need**: Why do we need this?
**Alternatives**: What else did we consider?
**Maintenance**: Who will monitor this?
**Security**: Last audit date? Known vulnerabilities?
**License**: MIT/Apache/Other?
**Removal**: How would we remove it?
**Decision**: Approved/Rejected by [team lead] on [date]
```

## Examples

### ✅ Approved (Hypothetical)

**None currently** - We haven't needed any external dependencies

### ❌ Rejected Examples

**Alamofire**: URLSession is sufficient for our needs
**RxSwift**: Swift Concurrency and Combine provide reactive patterns
**SnapKit**: SwiftUI doesn't need constraint helpers
**SwiftLint**: Actually approved (build tool, not runtime dependency)

## When Dependencies Might Be Acceptable

### Analytics/Monitoring SDKs
- Example: Firebase Analytics, Sentry
- Reason: Specialized infrastructure we shouldn't build
- **Status**: Would require approval

### Payment Processing
- Example: Stripe SDK, Apple Pay
- Reason: Handles sensitive PCI compliance
- **Status**: Would require approval

### Complex Media Processing
- Example: FFmpeg wrappers, video codecs
- Reason: Extremely specialized, well-tested libraries
- **Status**: Would require approval

### Legal Requirements
- Example: Accessibility checkers, specific security libraries
- Reason: Mandated by regulations
- **Status**: Would require approval

## Handling Security Updates

Since we have no runtime dependencies:

1. **Apple Frameworks**: Updated via OS updates
2. **Our Code**: We fix directly
3. **Build Tools** (SwiftLint): Updated in CI, not in app

This is much simpler than monitoring dozens of dependencies for CVEs.

## What About Development Tools?

Development-time tools that don't ship in the app are more flexible:

### ✅ Allowed Development Tools
- SwiftLint (linting)
- SwiftFormat (formatting)
- xcbeautify (build output)
- Fastlane (deployment automation)

These don't affect app security or runtime behavior.

## Comparing to Other Projects

### Our Approach (Zero Dependencies)

```
Project Size: ~20MB
Dependencies: 0
Security Surface: Minimal
Update Frequency: When we choose
Build Time: ~30s
```

### Typical App (Many Dependencies)

```
Project Size: ~80MB
Dependencies: 15+
Security Surface: Large
Update Frequency: Weekly
Build Time: ~2 minutes
```

## Real-World Benefits

### Security
- **Zero Supply Chain Risk**: No compromise of external packages
- **Zero Vulnerable Dependencies**: Can't have CVEs in dependencies we don't have
- **Compliance**: Easier security audits

### Maintenance
- **No Breaking Changes**: Swift/iOS updates only
- **No Dependency Hell**: No conflict resolution
- **Long-Term Stability**: Code works indefinitely

### Development
- **Faster Onboarding**: Only need to learn Apple APIs
- **Better Debugging**: Can step through all code
- **Full Control**: Fix any bug immediately

## Alternatives Considered

### Minimal Dependencies (1-3 core libraries)
- **Pros**: Balance between features and control
- **Cons**: Still have security/maintenance burden
- **Decision**: Rejected - if we can do zero, why not?

### Standard Dependencies (10-15 common libraries)
- **Pros**: Faster initial development
- **Cons**: All the downsides listed above
- **Decision**: Rejected - long-term costs too high

### Vendor Everything (copy library code into project)
- **Pros**: Total control, no package management
- **Cons**: Licensing issues, massive maintenance burden
- **Decision**: Rejected - we'd still need to maintain it

## Related Decisions
- ADR 001: Architecture choices (MVVM works without DI framework)
- ADR 002: Observable (no RxSwift needed)
- ADR 003: Actors (no need for async libraries)

## References
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift Evolution](https://github.com/apple/swift-evolution)
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [NIST Software Supply Chain](https://www.nist.gov/itl/executive-order-improving-nations-cybersecurity/software-supply-chain-security-guidance)

## Revision History
- 2025-12-13: Initial version

## Notes

This decision reflects our current project scale and team capabilities. If the project grows significantly or requirements change dramatically, this decision can be revisited. However, the bar for adding dependencies should remain high.

