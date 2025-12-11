Status: current  
Last verified: 2025-11-27

## 04 — Authentication & Account

### Why this exists

- Define a **secure, predictable auth and account model** that fully leverages backend logic.
- Ensure login, refresh, `/rpc/me`, and logout flows are robust, testable, and analytics‑ready.

### Role in the system

- Describes:
  - Magic link and OTP flows on top of the networking/session stack.
  - How `/rpc/me` and `/rpc/app_config` are used to populate account state.
  - How Settings/Account features interact with `SessionController` and localization.

---

## 1. Auth domain overview

### 1.1 Endpoints

- From `swagger.json`:
  - `/rpc/request_magic_link`
  - `/rpc/request_login_code`
  - `/rpc/login_with_magic_token`
  - `/rpc/login_with_code`
  - `/rpc/refresh_tokens`
  - `/rpc/me`
  - `/rpc/app_config`
  - `/rpc/get_or_create_account_profile`
  - `/rpc/set_active_profile`
  - `/rpc/request_account_deletion`

### 1.2 Modules

- `Features/Auth/`
  - `Models/` — `AuthTokens`, `AuthError`, temporary DTO wrappers.
  - `Repositories/` — `AuthRepository`, `SessionRepository` (if needed), remote implementations.
  - `UseCases/` — `RequestMagicLinkUseCase`, `CompleteMagicLinkUseCase`, `RequestLoginCodeUseCase`, `LoginWithCodeUseCase`, `LogoutUseCase`.
  - `ViewModel/` — `LoginViewModel`, optional `OTPViewModel`.
  - `View/` — `LoginView`, `MagicLinkStatusView`, `OTPEntryView`.

- `Features/Account/`
  - `Models/` — `User`, `Profile`, `AccountDashboard`, etc.
  - `Repositories/` — `AccountRepository`, `ProfileRepository`.
  - `UseCases/` — `LoadAccountDashboardUseCase`, `SwitchProfileUseCase`, `UpdateLanguageUseCase`.
  - `ViewModel/` — `SettingsViewModel`.
  - `View/` — `SettingsView`, `ProfileListView`.

---

## 2. Auth flows

### 2.1 Requesting magic link / OTP

- `RequestMagicLinkUseCase`:
  - Input: raw identifier (`email` or `phone`).
  - Steps:
    1. Normalize identifier (trim spaces, lowercase emails, ensure phone format).
    2. Basic validation for UX (e.g., contains `@` or looks like phone).
    3. Check local cooldown derived from `RuntimeConfig` to avoid spamming UI.
    4. Call `/rpc/request_magic_link`.
    5. Map backend error codes to `AuthError` variants:
       - `invalid_identifier`
       - `too_many_attempts`
       - generic server failures.
    6. Emit analytics event `auth.magic_link_requested`.

- `RequestLoginCodeUseCase`:
  - Similar to magic link, but uses `/rpc/request_login_code`.
  - Only exposed when enabled by feature flag and product strategy.

### 2.2 Completing login (magic token or OTP)

- `CompleteMagicLinkUseCase`:
  - Triggered by `DeepLinkParser` when a magic link URL arrives.
  - Steps:
    1. Validate token shape (non‑empty, expected length).
    2. Call `/rpc/login_with_magic_token` to get tokens + optional profile summary.
    3. Store tokens via `SessionController`.
    4. Trigger account bootstrap: `/rpc/me` and `/rpc/app_config`.
    5. Emit analytics events: `auth.login_success`, and log failure `auth.login_failed` with error categories (no PII).

- `LoginWithCodeUseCase`:
  - Accepts `identifier` + `code` and calls `/rpc/login_with_code`.
  - Shares the same token storage and bootstrap logic.

### 2.3 Session refresh and logout

- Refresh:
  - Owned by `SessionController` + networking layer (see `03-networking-and-session.md`).
  - Auth module provides DTOs and mapping for `/rpc/refresh_tokens`.

- Logout:
  - `LogoutUseCase`:
    - Clears session via `SessionController.logout(reason:)`.
    - Optionally calls a logout RPC if backend adds one (future).
    - Logs `auth.logout` analytics event.

---

## 3. Account & `/rpc/me`

### 3.1 User and profile models

- `User`:
  - Minimal fields the client cares about (IDs, emails/phones, active profile, roles).
  - Derived from `/rpc/me` DTO.

- `Profile`:
  - Represents a language profile, not global account:
    - `profileId`
    - `languageCode`
    - optional display name or metadata.

### 3.2 AccountRepository responsibilities

- Methods:
  - `fetchMe()` → `User`
  - `fetchAppConfig()` → `AppConfig` (see config doc).
  - `getOrCreateProfile(accountId, languageCode)` → `Profile`
  - `setActiveProfile(accountId, languageCode)` → `Profile`

- Behavior:
  - Always treat backend as source of truth:
    - Do not attempt to create local profiles without backend.
    - Do not store additional state beyond what backend returns, except for caches.
  - When `/rpc/me` returns missing fields:
    - Use backend defaults from `/rpc/app_config` (e.g., default language).
    - Log structured `AccountError.missingField(fieldName)` but show safe copy to user.

---

## 4. Settings & account UI

### 4.1 SettingsViewModel

- State:
  - Account information (name/email/phone if applicable).
  - Active profile and available profiles.
  - List of supported languages and current `LanguageCode`.
  - Analytics/diagnostics opt‑in or out.
  - Developer access flags, when backend indicates.

- Intents:
  - `load()` — runs `LoadAccountDashboardUseCase`.
  - `selectLanguage(code:)` — triggers `UpdateLanguageUseCase`.
  - `switchProfile(profileId:)` — triggers `SwitchProfileUseCase`.
  - `toggleAnalyticsOptIn()` — toggles local setting and backend if supported.
  - `logout()` — uses `LogoutUseCase`.

### 4.2 SettingsView

- Structure:
  - Profile card (account summary).
  - Language & profile section.
  - Analytics & diagnostics section (opt‑ins).
  - Developer tools section (dev users only when flags allow).
  - Danger zone:
    - Delete account (in-app, with confirmation).
    - Logout.

- Rules:
  - All labels and microcopy localized via `Strings` and `.stringsdict`.
  - Buttons and toggles driven by backend flags (e.g., whether analytics opt‑out is allowed).
  - Use design system tokens and components only; no bespoke styling.
  - Account deletion UX:
    - Expose a clearly labeled “Delete account” action in Settings.
    - Show a confirmation dialog explaining that deletion is permanent and may take time.
    - On confirm, call `/rpc/request_account_deletion` via `AccountRepository.requestAccountDeletion()`, then log out on success.

---

## 5. Error handling & UX

- Map backend error codes to `AuthError`/`AccountError` enums.
- Provide localized, actionable messages:
  - For invalid identifiers, highlight the field with message from `Strings.Auth.Error.*`.
  - For rate limits, show countdown based on backend durations.
  - For expired links, instruct user to request a new one.
- Do not show raw HTTP codes or technical messages to users; log those via `os.Logger` instead.

---

## 6. Analytics hooks

- Use the generic analytics facade (see `09-observability-and-analytics.md`) to emit:
  - `auth.magic_link_requested`
  - `auth.login_success`
  - `auth.login_failed` (with coarse error category).
  - `auth.logout`
  - `settings.opened`
  - `settings.language_change`
  - `settings.analytics_opt_in_changed`

- Events should:
  - Contain only anonymous identifiers (e.g., flags, language codes).
  - Respect user opt‑in/opt‑out stored in account metadata and local settings.

---

## 7. Security considerations

- Tokens:
  - Always stored in Keychain via `SessionController`/`TokenStore`.
  - Never logged or interpolated into analytics or network logs.

- Deep links:
  - Accept only URLs from trusted domains configured in Associated Domains.
  - Validate presence and format of `token` before calling backend.

- Rate limiting:
  - Client enforces **minimum** cooldown UX.
  - Backend remains ultimate arbiter; do not bypass error responses.

---

## 8. Action checklist

- [ ] All auth endpoints in `swagger.json` are modeled by typed endpoints and DTOs.
- [ ] `AuthRepository` and `AccountRepository` follow the patterns described above.
- [ ] `LoginViewModel` and `SettingsViewModel` expose clear state and intents, with no embedded networking.
- [ ] `/rpc/me` and `/rpc/app_config` drive language/profile state and flags.
- [ ] Logs and analytics use coarse categories with no PII.
- [ ] Error messages are localized and actionable, with generic fallbacks.


