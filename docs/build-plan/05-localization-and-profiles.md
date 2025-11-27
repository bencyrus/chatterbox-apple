Status: current  
Last verified: 2025-11-27

## 05 — Localization & Profiles

### Why this exists

- Define how Chatterbox uses `/rpc/me` and `/rpc/app_config` to drive **UI language and profile selection**.
- Ensure multi‑language behavior is **backend‑driven, deterministic, and accessible**.

### Role in the system

- Specifies:
  - Source of truth for language and profiles.
  - Localization provider and cache.
  - Settings/profile UX and flows.
  - Offline behavior and error handling.

---

## 1. Sources of truth

### 1.1 `/rpc/me`

- Returns:
  - Account metadata (IDs, emails, phones).
  - `active_profile_id` and profile list.
  - Per‑profile metadata, including `language_code`.
  - Optional roles/flags (`isDeveloper`, etc.).

### 1.2 `/rpc/app_config`

- Returns:
  - Supported language codes and (optionally) localized display names.
  - Defaults (e.g., `default_language_code`).
  - Cooldowns, feature flags, and other configuration consumed by `RuntimeConfig`.

### 1.3 Local resources

- `Resources/Strings/<lang>.lproj/Localizable.strings` and `.stringsdict`.
- Optional language‑specific assets in `Assets.xcassets` using localization variants.

---

## 2. Localization pipeline

### 2.1 LocalizationProvider

- `Core/Localization/LocalizationProvider`:
  - Stores:
    - Current locale identifier.
    - Available language options (from backend).
  - Provides:
    - `var locale: Locale` to inject into SwiftUI environment.
    - `var state: LocalizationState` representing active language and choices.
    - Methods:
      - `setLanguage(code:)` — invoked when backend confirms a new language.
      - `bootstrapFrom(serverUser: appConfig:)` — combine `/rpc/me` + `/rpc/app_config`.

- Uses:
  - `LocalizationCache` to persist last known state for offline use.

### 2.2 Strings helper

- `Strings` (or `L10n`) API:
  - Strongly typed namespaces per feature (`Strings.Auth.title`, `Strings.Settings.languageLabel`, etc.).
  - Uses the bundle corresponding to `LocalizationProvider.locale`.
  - Supports formatted and plural strings via `.stringsdict`.

### 2.3 Locale injection

- Root view tree uses:

```swift
rootView
    .environment(\.locale, localizationProvider.locale)
```

- This allows dynamic language changes where supported by the OS; some system UI may still require restart, but app strings will update immediately.

---

## 3. Profile & settings flows

### 3.1 Loading localization and profiles

- `ProfileLocalizationUseCase`:
  - Fetches `/rpc/me` and `/rpc/app_config` in parallel.
  - Merges data into `LocalizationState` and `AccountDashboard` models.
  - Updates:
    - `LocalizationProvider`.
    - `RuntimeConfig` (via `ConfigProvider`) if config changed.

### 3.2 Language change

- `UpdateLanguageUseCase`:
  - Sends `/rpc/set_active_profile` with `account_id` and desired `language_code`.
  - On success:
    - Updates `LocalizationProvider` with new language.
    - Persists in `LocalizationCache` and optionally `TokenStore` metadata.
    - Refreshes cues/config as needed (via dedicated use cases).
  - On failure:
    - Shows localized error.
    - Revert selection in UI.

### 3.3 Profile switching

- `SwitchProfileUseCase`:
  - Uses `/rpc/set_active_profile` (or dedicated RPC if provided) to switch `active_profile`.
  - On success:
    - Updates active profile in account state.
    - Updates `LocalizationProvider`’s language if profile language changes.
    - Triggers a new cues load for the active profile.

---

## 4. SettingsView UX rules

- Display:
  - Profile card:
    - Display name/email/phone (from backend).
    - Active profile language and other metadata (if provided).
  - Language section:
    - Language picker with display names:
      - Prefer backend‑provided; fallback to `Locale.localizedString(forLanguageCode:)`.
    - Show both name and code (`Español (ES)`).
  - Analytics/diagnostics toggles:
    - Only if allowed by backend flags and `RuntimeConfig`.
  - Developer tools:
    - Visible only when backend marks user as developer **and** flags allow.

- Behavior:
  - Changing language or profile:
    - Optionally confirm via sheet if it triggers non‑trivial network work.
    - Indicate loading state while server change is applied.
  - Logout:
    - Uses `LogoutUseCase`; Settings must not call `TokenStore` directly.

---

## 5. Offline & fallback behavior

- Localization:
  - On startup:
    - Load cached `LocalizationState` if available.
    - Use that state to show UI while attempting to refresh from network.
  - If both cache and network fail:
    - Use English as hard fallback.
    - Show non‑blocking banner: “Using default language; connect to update.”

- Profiles:
  - Do **not** allow profile or language changes while offline.
  - Display a clear error if user attempts such actions.

---

## 6. Accessibility & UX

- Dynamic Type:
  - All localization UI must support large fonts without clipping or truncation.

- VoiceOver:
  - Announce both localized language name and code:
    - e.g., “Español (ES), current language”.
  - Use `accessibilityHint` to explain actions:
    - “Double tap to switch app language to Español.”

- RTL:
  - Validate layout under RTL locales (Arabic/Hebrew or pseudolanguage).
  - Avoid hardcoded `.leading`/`.trailing` where `.horizontal` or generic padding would suffice.

---

## 7. Action checklist

- [ ] `/rpc/me` and `/rpc/app_config` are integrated via a dedicated localization/profile use case.
- [ ] `LocalizationProvider` and `LocalizationCache` are implemented and used by root SwiftUI view.
- [ ] Language and profile changes always go through use cases, not direct repository calls from views.
- [ ] Settings UI is fully localized, accessible, and uses design tokens.
- [ ] Offline behavior for localization is sensible and well‑communicated to the user.


