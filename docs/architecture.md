Status: current
Last verified: 2025-10-18

← Back to [`README.md`](../README.md)

## Architecture

### Why this exists

- Document the app’s structure and conventions to keep implementation clean and consistent.

### Role in the system

- iOS SwiftUI client that talks to the gateway API using `URLSession` and stores tokens securely.

### How it works

- Pattern: MVVM + Use Cases + Repository.
- Views bind-only. Business logic in Use Cases and Repositories.
- Concurrency via async/await (Swift 5.9+). Observation for view models when applicable.

### Directories and key files

- `App/`
  - [`App/ChatterboxApp.swift`](../App/ChatterboxApp.swift)
  - [`App/CompositionRoot.swift`](../App/CompositionRoot.swift)
- `Core/`
  - Config: [`Core/Config/Environment.swift`](../Core/Config/Environment.swift)
  - Networking: [`Core/Networking/APIClient.swift`](../Core/Networking/APIClient.swift)
  - Security: [`Core/Security/TokenManager.swift`](../Core/Security/TokenManager.swift)
  - Localization helpers: [`Core/Localization/Strings.swift`](../Core/Localization/Strings.swift)
- `Features/Auth/`
  - Models: [`Features/Auth/Models/AuthDTOs.swift`](../Features/Auth/Models/AuthDTOs.swift)
  - Repositories: [`Features/Auth/Repositories/AuthRepository.swift`](../Features/Auth/Repositories/AuthRepository.swift)
  - Use Cases: [`Features/Auth/UseCases/AuthUseCases.swift`](../Features/Auth/UseCases/AuthUseCases.swift)
  - ViewModel: [`Features/Auth/ViewModel/AuthViewModel.swift`](../Features/Auth/ViewModel/AuthViewModel.swift)
- `UI/`
  - Views: [`UI/Views/LoginView.swift`](../UI/Views/LoginView.swift), [`UI/Views/HomeView.swift`](../UI/Views/HomeView.swift), [`UI/Views/SettingsView.swift`](../UI/Views/SettingsView.swift), [`UI/Views/RootTabView.swift`](../UI/Views/RootTabView.swift)
- `Resources/`
  - Localized strings: [`Resources/Strings/en.lproj/Localizable.strings`](../Resources/Strings/en.lproj/Localizable.strings)

### Configuration

- Centralized in `Environment` with base URL and endpoints. Keep secrets out of the repo.

### Operations

- Open `Chatterbox.xcodeproj` with Xcode 15+, run on iOS 17+.

### See also

- [`auth.md`](./auth.md)
