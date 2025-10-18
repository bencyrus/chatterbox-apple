Status: current
Last verified: 2025-10-18

← Back to [`README.md`](../README.md)

## Auth (OTP Login)

### Why this exists

- Provide a simple, secure OTP-based login; store tokens in Keychain; refresh automatically.

### Role in the system

- Calls gateway endpoints to request and verify login codes. Manages access/refresh tokens.

### How it works

- Request code: `POST /rpc/request_login_code`
- Verify code: `POST /rpc/login_with_code`
- Tokens captured from gateway response headers and stored via `TokenManager`.

### Components

- API client: [`Core/Networking/APIClient.swift`](../Core/Networking/APIClient.swift)
- Token storage: [`Core/Security/TokenManager.swift`](../Core/Security/TokenManager.swift)
- Use cases: [`Features/Auth/UseCases/AuthUseCases.swift`](../Features/Auth/UseCases/AuthUseCases.swift)
- Repository: [`Features/Auth/Repositories/AuthRepository.swift`](../Features/Auth/Repositories/AuthRepository.swift)
- View model: [`Features/Auth/ViewModel/AuthViewModel.swift`](../Features/Auth/ViewModel/AuthViewModel.swift)
- UI: [`UI/Views/LoginView.swift`](../UI/Views/LoginView.swift)

### UX notes

- Rate-limit code requests, validate identifiers, and show clear error messages.

### See also

- [`architecture.md`](./architecture.md)
