# ADR 002: Use @Observable Instead of ObservableObject

## Status
Accepted

## Context

iOS 17 introduced the Observation framework with the `@Observable` macro as a modern replacement for `ObservableObject` + `@Published`. We needed to choose which approach to use for our state management in ViewModels and other observable objects.

The legacy approach (`ObservableObject`) requires:
- Importing Combine framework
- Using `@Published` property wrappers
- `@StateObject` and `@ObservedObject` in views
- All properties trigger view updates even if unused

The new approach (`@Observable`) provides:
- No Combine dependency
- Simple property declarations
- `@State` in views (consistent with other state)
- Fine-grained observation (only used properties trigger updates)

## Decision

We will use **`@Observable`** for all ViewModels and observable state classes.

### Implementation Rules

1. **ViewModels**: All ViewModels use `@Observable`
   ```swift
   @Observable
   final class HomeViewModel {
       var cues: [Cue] = []
       var isLoading = false
   }
   ```

2. **Views**: Use `@State` to hold observable objects
   ```swift
   struct HomeView: View {
       @State private var viewModel: HomeViewModel
   }
   ```

3. **Passing ViewModels**: Use `@Bindable` when binding is needed
   ```swift
   struct DetailView: View {
       @Bindable var viewModel: DetailViewModel
   }
   ```

4. **Environment**: Continue using `@Environment` for dependency injection
   ```swift
   @Environment(FeatureAccessContext.self) private var features
   ```

## Consequences

### Positive
- **Better Performance**: Fine-grained observation means views only update when properties they actually use change
- **Simpler Code**: No need for `@Published`, just regular properties
- **No Combine**: One less framework to import and understand
- **Consistency**: `@State` works for all local state, not just primitives
- **Modern API**: Aligns with Apple's current direction
- **Cleaner Syntax**: Less boilerplate code

### Negative
- **iOS 17+ Required**: Can't support older iOS versions (acceptable for this project)
- **Team Learning**: Team needs to learn new pattern
- **Migration**: Existing code using `ObservableObject` needs updates
- **Less Online Resources**: Fewer Stack Overflow answers for `@Observable`

## Example Comparison

### Before (ObservableObject)

```swift
import Combine

final class HomeViewModel: ObservableObject {
    @Published var cues: [Cue] = []
    @Published var isLoading = false
    @Published var error: Error?
}

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    
    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}
```

### After (@Observable)

```swift
// No Combine import needed

@Observable
final class HomeViewModel {
    var cues: [Cue] = []
    var isLoading = false
    var error: Error?
}

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    
    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
}
```

## Performance Benefits

### Fine-Grained Observation

With `@Observable`, views only observe the specific properties they access:

```swift
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {  // Only observes isLoading
                ProgressView()
            }
            // This view does NOT recompute when cues change
        }
    }
}
```

With `ObservableObject`, changing ANY `@Published` property triggers ALL views observing that object.

## Migration Strategy

1. New code MUST use `@Observable`
2. Existing code should be migrated opportunistically
3. No rush to migrate working code unless being modified
4. Mark deprecated `ObservableObject` code with comments

## Gotchas and Solutions

### Gotcha #1: Initialization Syntax

```swift
// ❌ Wrong
@State private var viewModel = HomeViewModel()

// ✅ Correct
@State private var viewModel: HomeViewModel

init(viewModel: HomeViewModel) {
    _viewModel = State(initialValue: viewModel)
}
```

### Gotcha #2: Computed Properties

```swift
@Observable
final class ViewModel {
    var items: [Item] = []
    
    // ✅ Computed properties work automatically
    var itemCount: Int {
        items.count
    }
}
```

### Gotcha #3: Task Cancellation

```swift
// Tasks still need to be managed the same way
func load() {
    Task {
        self.isLoading = true
        // ... async work
        self.isLoading = false
    }
}
```

## Alternatives Considered

### Continue Using ObservableObject
- **Pros**: More familiar, more documentation available
- **Cons**: Worse performance, more boilerplate, uses Combine
- **Decision**: Rejected - `@Observable` is clearly better

### Mix Both Approaches
- **Pros**: Flexibility
- **Cons**: Inconsistency, confusion, maintenance burden
- **Decision**: Rejected - standardization is important

### Use SwiftData's @Model
- **Pros**: Even newer API
- **Cons**: Specific to persistence, not general purpose
- **Decision**: Not applicable - different use case

## Related Decisions
- ADR 001: MVVM architecture uses ViewModels
- ADR 003: Actors for thread-safe state (different from `@Observable`)

## References
- [Apple WWDC 2023: Discover Observation](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [Apple Documentation: Observation framework](https://developer.apple.com/documentation/observation)
- [Swift Evolution: SE-0395](https://github.com/apple/swift-evolution/blob/main/proposals/0395-observability.md)

## Revision History
- 2025-12-13: Initial version

