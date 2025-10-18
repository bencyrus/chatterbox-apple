Status: current
Last verified: 2025-10-18

← Back to [`README.md`](../README.md)

## Auth (Magic Token)

### Why this exists

- Provide a simple, secure OTP-based login; store tokens in Keychain; refresh automatically.

### Role in the system

- Calls gateway endpoints to request and verify login codes. Manages access/refresh tokens.

### How it works

- Magic Token: Request link `POST /rpc/request_magic_link`; app opens via HTTPS universal link and exchanges via `POST /rpc/login_with_magic_token`.
- Tokens captured from gateway response headers and stored via `TokenManager`.

### Components

- API client: [`Core/Networking/APIClient.swift`](../Core/Networking/APIClient.swift)
- Token storage: [`Core/Security/TokenManager.swift`](../Core/Security/TokenManager.swift)
- Use cases: [`Features/Auth/UseCases/AuthUseCases.swift`](../Features/Auth/UseCases/AuthUseCases.swift)
- Repository: [`Features/Auth/Repositories/AuthRepository.swift`](../Features/Auth/Repositories/AuthRepository.swift)
- View model: [`Features/Auth/ViewModel/AuthViewModel.swift`](../Features/Auth/ViewModel/AuthViewModel.swift)
- UI: [`UI/Views/LoginView.swift`](../UI/Views/LoginView.swift)

### UX notes

- Validate identifiers; show clear error messages.
- Magic links open the app and log in automatically; provide a fallback to copy/paste token only in development.

### Deep links

- Universal Link: `https://<your-domain>/auth/magic?token=<token>` (configure Associated Domains).

### See also

- [`architecture.md`](./architecture.md)
