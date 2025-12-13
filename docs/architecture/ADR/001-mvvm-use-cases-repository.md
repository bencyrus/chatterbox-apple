# ADR 001: MVVM + Use Cases + Repository Pattern

## Status
Accepted

## Context

We needed to choose an architecture pattern for the iOS app that would provide:
- Clear separation of concerns
- Testability at all layers
- Maintainability as the app grows
- Alignment with SwiftUI best practices

Traditional MVC doesn't provide enough separation for complex business logic. Pure MVVM can lead to bloated ViewModels. We needed a pattern that keeps ViewModels focused on presentation while properly organizing business logic and data access.

## Decision

We will use **MVVM + Use Cases + Repository** pattern with the following layers:

### View Layer
- SwiftUI `struct` views only
- Declarative UI binding to ViewModel state
- No business logic - only presentation logic
- Views are dumb and testable through SwiftUI previews

### ViewModel Layer
- `@Observable` classes for state management
- Handle user intents (button taps, input changes)
- Orchestrate Use Cases
- Transform domain models to view-friendly data
- Manage UI state (loading, error, success)

### Use Case Layer
- Encapsulate discrete business operations
- Coordinate between multiple repositories if needed
- Independent, testable units of business logic
- Examples: `LoginWithMagicTokenUseCase`, `LogoutUseCase`

### Repository Layer
- Abstract data sources behind protocols
- Handle API calls, local storage, etc.
- Map network DTOs to domain models
- Provide clean interface for data access
- Examples: `AuthRepository`, `CueRepository`

## Consequences

### Positive
- Clear boundaries between layers
- ViewModels stay focused and lightweight
- Business logic is isolated and testable
- Easy to mock dependencies for testing
- Repositories can be swapped (e.g., mock for tests)
- Each layer has single responsibility
- Scales well as features grow

### Negative
- More files and boilerplate initially
- Learning curve for team members
- May feel over-engineered for simple features
- Requires discipline to maintain boundaries

## Examples

### Login Flow

**View** (`LoginView.swift`):
```swift
Button("Sign In") {
    Task { await viewModel.requestMagicLink() }
}
```

**ViewModel** (`AuthViewModel.swift`):
```swift
func requestMagicLink() async {
    isRequesting = true
    let result = await requestMagicLinkUseCase.execute(identifier: identifier)
    // Handle result...
}
```

**Use Case** (`AuthUseCases.swift`):
```swift
func execute(identifier: String) async -> Result<MagicLinkResponse, Error> {
    await authRepository.requestMagicLink(identifier: identifier)
}
```

**Repository** (`AuthRepository.swift`):
```swift
func requestMagicLink(identifier: String) async throws -> MagicLinkResponse {
    try await apiClient.execute(endpoint: RequestMagicLinkEndpoint(identifier: identifier))
}
```

## Alternatives Considered

### MVC (Model-View-Controller)
- **Pros**: Simple, well-understood
- **Cons**: ViewControllers become bloated, hard to test, doesn't fit SwiftUI well
- **Decision**: Rejected - not suitable for SwiftUI

### Pure MVVM
- **Pros**: Simple two-layer approach
- **Cons**: ViewModels become too large, business logic mixed with presentation
- **Decision**: Rejected - doesn't scale well

### Clean Architecture (Full)
- **Pros**: Very strict boundaries, highly testable
- **Cons**: Too many layers for our needs, excessive boilerplate
- **Decision**: Rejected - over-engineered for iOS app

### VIPER
- **Pros**: Very modular
- **Cons**: Too much ceremony, router layer unnecessary with SwiftUI navigation
- **Decision**: Rejected - too complex for our needs

## Guidelines

### When to Create a Use Case
- Business operation that could involve multiple repositories
- Logic that might be reused in different contexts
- Operation complex enough to warrant testing in isolation

### When NOT to Create a Use Case
- Simple CRUD operations (can go directly to repository from ViewModel)
- Pure UI state management (stays in ViewModel)
- One-line delegations

### Dependency Flow
```
View → ViewModel → Use Case → Repository → API/Storage
```

No layer should depend on layers above it. Dependencies flow downward only.

## Related Decisions
- ADR 002: Using `@Observable` instead of `ObservableObject`
- ADR 003: Actor-based session management
- ADR 004: No third-party dependencies

## References
- [iOS Dev Rulebook](../../ios-dev-rulebok.md)
- [Martin Fowler - Use Case](https://martinfowler.com/bliki/UseCase.html)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)

## Revision History
- 2025-12-13: Initial version

