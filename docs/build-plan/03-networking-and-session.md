Status: current  
Last verified: 2025-11-27

## 03 — Networking & Session Lifecycle

### Why this exists

- Define a **single, robust HTTP and session stack** that all features share.
- Ensure auth, retries, logging, and error handling are consistent, secure, and testable.

### Role in the system

- Specifies:
  - Endpoint and DTO patterns (aligned with `swagger.json`).
  - Request pipeline and middleware chain.
  - SessionController, token storage, and refresh strategy.
  - Network logging and developer console hooks.

---

## 1. Endpoints & DTOs

### 1.1 Endpoint protocol

- `Core/Networking/Endpoint.swift`:
  - Each endpoint is a small struct describing path, method, auth needs, timeouts, and types:

```swift
protocol APIEndpoint {
    associatedtype RequestBody: Encodable
    associatedtype ResponseBody: Decodable

    var path: String { get }
    var method: HTTPMethod { get }
    var requiresAuth: Bool { get }
    var timeout: TimeInterval { get }
    var idempotencyKeyStrategy: IdempotencyKeyStrategy { get }
}
```

- Endpoints grouped by domain:
  - `AuthEndpoints` (`/rpc/request_magic_link`, `/rpc/login_with_magic_token`, `/rpc/refresh_tokens`, etc.).
  - `AccountEndpoints` (`/rpc/me`, `/rpc/app_config`, `/rpc/set_active_profile`, `/rpc/get_or_create_account_profile`).
  - `CueEndpoints` (`/rpc/get_cues`, `/rpc/shuffle_cues`, `/rpc/update_cue_stage`).

### 1.2 DTOs and domain models

- DTOs mirror backend JSON exactly.
  - Use snake_case decoding strategy for JSON where appropriate.
  - Keep DTOs in the same file/module as their endpoint group.
- Domain models:
  - Created in feature `Models/` only when the UI needs a simpler shape or extra semantics.
  - Repositories handle mapping from DTO → domain model, never the views.

---

## 2. Request pipeline & middleware

### 2.1 Core pieces

- `RequestBuilder`
  - Combines `Environment.baseURL` with endpoint path.
  - Adds headers (`Content-Type`, `Accept`, `X-Request-ID`).
  - Encodes JSON bodies using configured `JSONEncoder`.

- `APIClient`
  - Central entry point for all network calls.
  - Signature:

```swift
protocol APIClient {
    func send<E: APIEndpoint>(
        _ endpoint: E,
        body: E.RequestBody
    ) async throws -> E.ResponseBody
}
```

### 2.2 Middleware chain

- Ordered middleware for each request:

1. **Request ID middleware**
   - Adds a unique request ID header (e.g., `X-Request-ID`) for correlation.
2. **Auth middleware**
   - Injects `Authorization: Bearer <access_token>` when `requiresAuth == true`.
   - If no valid token, throws `NetworkError.unauthorized` early.
3. **Retry/backoff middleware**
   - Retries transient transport errors and 5xx responses for idempotent endpoints.
   - Exponential backoff (e.g., 1s, 2s, 4s) capped to a reasonable max.
4. **401/refresh handling**
   - On 401 for an authenticated endpoint:
     - Ask `SessionController` to refresh once.
     - Retry the original request with new credentials.
     - If refresh fails, surface a session error and trigger logout.
5. **Logging & metrics middleware**
   - In DEBUG builds, logs sanitized request/response metadata via `NetworkLogger` and `os.Logger`.
   - Records timing metrics for analytics.

### 2.3 Error modeling

- `NetworkError`:
  - `.unauthorized`
  - `.forbidden`
  - `.notFound`
  - `.rateLimited(retryAfterSeconds: Int?)`
  - `.server(statusCode: Int)`
  - `.transport(URLError)`
  - `.unexpectedPayload`
  - `.offline`
  - `.cancelled`

- Domain layers wrap `NetworkError` in domain‑specific enums:
  - `AuthError`, `CueError`, `AccountError`, etc.

---

## 3. SessionController & token lifecycle

### 3.1 SessionController actor

- `Core/Security/SessionController.swift`:
  - Actor responsible for:
    - Loading tokens from Keychain on startup.
    - Exposing `SessionState` (`signedOut`, `authenticated`, `refreshing`, `error`).
    - Providing the current access token to auth middleware.
    - Running refresh token flows (`/rpc/refresh_tokens`) safely.

- `SessionState`:
  - Includes user/account summary where available so coordinators can decide which flows to show.

### 3.2 Token storage

- `TokenStore` (Keychain‑backed):
  - Stores `accessToken`, `refreshToken`, `expiry`, and optional metadata (e.g., `preferredLanguageCode`).
  - Uses appropriate accessibility (`.afterFirstUnlockThisDeviceOnly`).
  - Returns typed `TokenStoreError` on failure; SessionController maps to domain errors.

### 3.3 Bootstrap, refresh, logout

- **Bootstrap**
  - On app launch, `SessionController.bootstrap()`:
    - Reads refresh token from `TokenStore`.
    - If present, calls `/rpc/refresh_tokens`.
    - On success: sets `SessionState.authenticated`, triggers `/rpc/me` and `/rpc/app_config` fetch via use cases.
    - On failure: clears tokens and sets `SessionState.signedOut`.

- **Refresh**
  - Only one refresh in flight at a time; performed within the actor.
  - For scheduled refresh:
    - Optionally, pre‑emptively refresh before token expiry (e.g., 2 minutes early).
  - For 401 responses:
    - Pause dependent HTTP calls, run refresh once, then retry waiting requests.

- **Logout**
  - `SessionController.logout(reason:)`:
    - Clears tokens, cached user-specific data (profile caches, config).
    - Emits `SessionState.signedOut`.
    - Optionally, calls a logout RPC when the backend provides one.

---

## 4. Magic link & login code flows

### 4.1 Requesting a link or code

- Endpoints:
  - `/rpc/request_magic_link`
  - `/rpc/request_login_code`

- Use case behavior:
  - Normalize and validate identifier (email/phone) on client for UX only.
  - Use `RuntimeConfig` to determine **minimum cooldown**.
  - Call backend and map server codes (`too_many_attempts`, `invalid_identifier`, etc.) to domain errors.
  - Do **not** implement real rate limiting client‑side; rely on backend.

### 4.2 Completing login

- Deep link via universal links:
  - `DeepLinkParser` extracts a `token` and optional `state` from the URL.
  - `CompleteMagicLinkUseCase` calls `/rpc/login_with_magic_token` and updates `SessionController`.

- OTP flow:
  - Optional; uses `/rpc/login_with_code`.
  - Shares the same token storage and refresh behavior.

---

## 5. Network logging & developer tooling

### 5.1 NetworkLogger

- `Core/Observability/NetworkLogger.swift`:
  - Actor that receives `NetworkEvent` structs from `APIClient`.
  - Each event contains:
    - Request metadata: timestamp, HTTP method, path, status, duration.
    - Optional sanitized request/response bodies (DEBUG only).
  - Stores a bounded ring buffer (size derived from `RuntimeConfig`).

### 5.2 NetworkLogStore & dev UI

- `NetworkLogStore`:
  - Observable wrapper around a subset of events (for SwiftUI dev tools).
  - Provides:
    - Filtered views (by method, status, endpoint).
    - Export API for debug logs (e.g., zipped JSON).

- Dev tools:
  - In DEBUG builds and when allowed by flags:
    - Show a Network Console tab or screen listing entries.
    - Provide detail views and JSON expansion.
    - Never show raw tokens, emails, or phone numbers; always redacted.

---

## 6. Offline, retries & rate limiting

### 6.1 Offline detection

- Use `NWPathMonitor` (or simply network errors) to:
  - Short‑circuit calls when clearly offline.
  - Map to `NetworkError.offline` and show user‑friendly messages.

### 6.2 Retries

- Automatic retries allowed only for:
  - Safe, idempotent endpoints flagged as such in endpoint metadata.
  - Transient errors (network timeouts, connection lost, 5xx).

- Non‑idempotent POSTs:
  - Bubble errors to ViewModel; let user trigger manual retries explicitly.

### 6.3 Rate limiting

- On server‑signalled rate limits (HTTP 429):
  - Parse `Retry-After` if given and map to `NetworkError.rateLimited`.
  - Propagate domain error with `retryAfterSeconds`.
  - UI shows a cooldown message using localized strings and backend durations.

---

## 7. Security & privacy

- Enforce ATS; all base URLs must be HTTPS.
- Never log:
  - Access/refresh tokens.
  - Raw emails or phone numbers.
  - Content of potentially sensitive bodies (request/response) unless explicitly marked safe and only in DEBUG.
- Use `os.Logger` with privacy annotations and categories (`network`, `session`, `auth`).
- Consider certificate pinning only if the backend provides pins and rotation strategy; otherwise document why not.

---

## 8. Action checklist

- [ ] All RPCs in `swagger.json` are represented by typed endpoint structs.
- [ ] All repositories use `APIClient` and `RequestBuilder` (no ad‑hoc `URLSession` usage).
- [ ] `NetworkError` is the only error type emitted by the networking layer.
- [ ] `SessionController` owns token lifecycle, refresh logic, and session state.
- [ ] Magic link and OTP flows use `/rpc/*` endpoints as described; no invented endpoints.
- [ ] `NetworkLogger` and `NetworkLogStore` exist and are integrated, with proper redaction.
- [ ] Retries are limited to idempotent operations and transient errors.
- [ ] ATS is enabled and no HTTP/unencrypted endpoints are used.


