Status: current
Last verified: 2025-10-18

← Back to [`README.md`](../README.md)

## Auth (Magic Token)

### Why this exists

- Provide a secure magic-link login; store tokens in Keychain; refresh automatically.

### Role in the system

- Calls gateway endpoints to request and verify magic links. Manages access/refresh tokens.

### How it works

- Magic Token: Request link `POST /rpc/request_magic_link`; app opens via HTTPS universal link and exchanges via `POST /rpc/login_with_magic_token`.
- Tokens are returned in the login response body and may also be refreshed via gateway response headers; both are stored via `TokenManager`.

### Components

- API client + network debug logging: [`Core/Networking/APIClient.swift`](../Core/Networking/APIClient.swift)
- Token storage: [`Core/Security/TokenManager.swift`](../Core/Security/TokenManager.swift)
- Use cases: [`Features/Auth/UseCases/AuthUseCases.swift`](../Features/Auth/UseCases/AuthUseCases.swift)
- Repository: [`Features/Auth/Repositories/AuthRepository.swift`](../Features/Auth/Repositories/AuthRepository.swift)
- View model: [`Features/Auth/ViewModel/AuthViewModel.swift`](../Features/Auth/ViewModel/AuthViewModel.swift)
- UI: [`UI/Views/LoginView.swift`](../UI/Views/LoginView.swift), developer network console exposed via hammer icon overlay in [`UI/Views/RootTabView.swift`](../UI/Views/RootTabView.swift)

### UX notes

- Validate identifiers; show clear error messages.
- Magic links open the app and log in automatically; provide a fallback to copy/paste token only in development.

### Deep links

- Universal Link: `https://<your-domain>/auth/magic?token=<token>` (configure Associated Domains).

### Configuration

- Info.plist:
  - `API_BASE_URL` (String): e.g., https://api.glovee.io
  - `UNIVERSAL_LINK_HOSTS` (String, comma-separated): e.g., glovee.io
  - `MAGIC_LINK_PATH` (String): e.g., /auth/magic
- Associated Domains (Xcode Capability): add `applinks:<your-domain>` (e.g., `applinks:glovee.io`).
- Server config via secrets (Postgres migrations):
  - `MAGIC_LOGIN_LINK_HTTPS_BASE_URL=https://<your-domain>/auth/magic`

### See also

- [`architecture.md`](./architecture.md)
