Status: current
Last verified: 2025-11-27

## Chatterbox iOS Audit & Blueprint

### Why this exists
- Provide a candid assessment of the current SwiftUI client and define a modular blueprint aligned with Apple best practices for the speaking-practice roadmap.
- Capture domain boundaries, flow gaps, and phased work so the team can rebuild with confidence.

### Domain inventory & ownership

| Domain | Scope today | Key files | Observations / gaps |
| --- | --- | --- | --- |
| App shell & composition | Scene setup, dependency wiring, deep-link relay. | [`App/ChatterboxApp.swift`](App/ChatterboxApp.swift), [`App/CompositionRoot.swift`](App/CompositionRoot.swift) | Composition mixes concerns (deep-link handling, ViewModel factories, environment enforcement). Token state is stored in `@State` instead of a dedicated supervisor/DI container. No feature flags or navigation coordinator. |
| Core – Config & Environment | Info.plist-driven settings & endpoints. | [`Core/Config/Environment.swift`](Core/Config/Environment.swift) | Reads plist per process; not testable or swappable at runtime. Lacks staging/prod separation, feature flags, or per-endpoint timeouts. |
| Core – Networking & Logging | Thin `URLSession` wrapper + network log persistence. | [`Core/Networking/APIClient.swift`](Core/Networking/APIClient.swift) | Custom wrapper duplicating `URLSession` work; no request builder abstraction, retry/backoff, or typed decoding. Logging subsystem lives on main actor, persists 1k entries to disk, but is coupled directly to HTTP client. |
| Core – Security | Keychain-backed token cache. | [`Core/Security/TokenManager.swift`](Core/Security/TokenManager.swift) | Stores tokens but exposes mutable `hasValidAccessToken` and lacks refresh scheduling, biometric gating, or Keychain error handling. |
| Core – Localization | Static string enums + single `en.lproj`. | [`Core/Localization/Strings.swift`](Core/Localization/Strings.swift), [`Resources/Strings/en.lproj/Localizable.strings`](Resources/Strings/en.lproj/Localizable.strings) | Only English, no runtime language switching despite product requirement. Strings enum is flat; no pluralization or format helpers. |
| Feature – Auth | Magic-link request + login, cooldown UI, logout. | [`Features/Auth/Repositories/AuthRepository.swift`](Features/Auth/Repositories/AuthRepository.swift), [`Features/Auth/UseCases/AuthUseCases.swift`](Features/Auth/UseCases/AuthUseCases.swift), [`Features/Auth/ViewModel/AuthViewModel.swift`](Features/Auth/ViewModel/AuthViewModel.swift), [`UI/Views/LoginView.swift`](UI/Views/LoginView.swift) | Flow is single-screen; lacks identifier validation, rate-limit messaging, token refresh orchestration, or deep-link verification beyond host/path match. No analytics or lockout UX. |
| Feature – Account & Settings | `me`, `app_config`, language picker, logout button. | [`Features/Auth/Repositories/AccountRepository.swift`](Features/Auth/Repositories/AccountRepository.swift), [`Features/Auth/ViewModel/SettingsViewModel.swift`](Features/Auth/ViewModel/SettingsViewModel.swift), [`UI/Views/SettingsView.swift`](UI/Views/SettingsView.swift) | Settings screen assumes developer email for feature gating, stores language selection transiently, and logs out by hitting `TokenManager` directly instead of use case → repository chain. No profile avatar, preferences, or accessibility settings. |
| Feature – Cues / Topic discovery | Fetch/shuffle cues, list + detail rendering. | [`Features/Cues/Repositories/CueRepository.swift`](Features/Cues/Repositories/CueRepository.swift), [`Features/Cues/ViewModel/HomeViewModel.swift`](Features/Cues/ViewModel/HomeViewModel.swift), [`UI/Views/HomeView.swift`](UI/Views/HomeView.swift), [`UI/Views/CueDetailView.swift`](UI/Views/CueDetailView.swift) | Business logic lives partially in views (e.g., shuffle button triggers Task). `ActiveProfileHelper` re-fetches `me`/`app_config` repeatedly. No pagination, filtering, or history. Cue detail uses ad-hoc markdown parsing. |
| Developer tooling | Network console tab, hammer icon gating, log explorer. | [`UI/Views/RootTabView.swift`](UI/Views/RootTabView.swift), `DebugNetworkLogView`, `JSONExplorerView` | Debug UI ships in DEBUG builds only but still compiled alongside production UI. Hammer tab lives in main tab bar instead of hidden gesture/feature flag, and any authenticated user can access it. No centralized allowlist/config to restrict dev features by user email or JWT `user_id`. |
| UI / Design system | Color palette + miscellaneous reusable elements. | [`UI/DesignSystem.swift`](UI/DesignSystem.swift), `UI/Theme/` (empty), `PageHeader`, `ShuffleButton` | Theme directory is empty; typography, spacing, elevations, and control variants are hard-coded in each view. No dark mode, dynamic type, or semantic tokens. |
| Resources & assets | App icon, accent colors. | [`Resources/Assets.xcassets`](Resources/Assets.xcassets) | Minimal asset set; language-specific assets not organized. |
| Tests & docs | Single VM test + two markdown docs. | [`Tests/HomeViewModelTests.swift`](Tests/HomeViewModelTests.swift), [`docs/architecture.md`](docs/architecture.md), [`docs/auth.md`](docs/auth.md) | Tests only cover happy path for cues; auth/settings untested. Docs describe intended architecture but lag behind actual implementation (e.g., no mention of developer console). |
| Missing domains | Recording, history, AI evaluation, offline, notifications. | N/A | No scaffolding or placeholders. Will require Core Audio, storage, analytics, background permissions, and secure upload paths. |

### Flow analysis & pain points

#### Magic-link authentication
1. `ChatterboxApp` listens for HTTPS universal links then broadcasts `didOpenMagicTokenURL`.
2. `CompositionRootView` decides between `LoginView` and `RootTabView` based on `TokenManager.hasValidAccessToken`.
3. `LoginView` sends `Task { await requestMagicLink }` without validation; `AuthViewModel` debounces via `cooldownSecondsRemaining`.
4. `AuthViewModel.handleIncomingMagicToken` parses `token` query param and calls `LoginWithMagicTokenUseCase`, which writes tokens back to `TokenManager`.

Issues:
- No identifier format validation, masking, or anti-abuse copy. Cooldown is client-only, so users can bypass by reinstalling.
- Deep-link handler trusts any HTTPS host listed; no nonce/challenge binding or `state`.
- Token refresh only happens opportunistically via response headers inside [`Core/Networking/APIClient.swift`](Core/Networking/APIClient.swift); there is no proactive refresh or 401 retry.
- Error surfaces are generic (`Strings.Errors.requestFailed`), no actionable hints for rate limits or invalid identifiers.

#### Profile & localization selection
1. `SettingsViewModel.load` performs parallel `fetchMe` + `fetchAppConfig`. If `activeProfile` missing, it auto-creates one by calling `setActiveProfile` with default language.
2. Picker in [`UI/Views/SettingsView.swift`](UI/Views/SettingsView.swift) binds directly to `selectedLanguageCode`, triggering `updateLanguage` on every change (no confirmation).
3. Success path posts `activeProfileDidChange`, prompting `HomeViewModel.reloadForActiveProfileChange`.

Issues:
- Language codes are raw `String` tags shown uppercase (e.g., “EN”) with no localized names.
- `SettingsView` clears tokens directly via `TokenManager.clearTokens()` instead of going through `LogoutUseCase`.
- Developer-only logic (email equality check) is hard-coded in the ViewModel, violating separation and leaking PII comparisons.
- No persistence of selected language client-side; every Settings load hits the network.

#### Cue discovery & playback preparation
1. `HomeView` launches `loadInitialCues()` via `.task`. `HomeViewModel` resolves active profile each time by fetching `me`/`app_config` through `ActiveProfileHelper`.
2. `CueRepository` posts to `/rpc/get_cues` or `/rpc/shuffle_cues` with `count = 5`. No caching; errors only shown when `cues` empty.
3. Navigating into [`UI/Views/CueDetailView.swift`](UI/Views/CueDetailView.swift) renders the text with ad-hoc formatting; recording/history is not wired.

Issues:
- Multiple redundant round trips (profile fetch, config fetch) per load; no caching or local DB.
- `HomeView` drives shuffle button by spawning a `Task`, mixing UI and orchestration.
- No instrumentation for fetch latency or errors; user gets generic “Couldn’t load cards”.
- No state for “in-progress recording” or “completed cues”, so integrating future history will require a rewrite.

#### Developer tooling flow
1. `RootTabView` conditionally adds a hammer tab (DEBUG builds) with `DebugNetworkLogView`.
2. `NetworkLogStore` (MainActor) persists logs to disk and exposes them via Observation.
3. JSON explorer presents parsed object tree with copy actions.

Issues:
- Debug dependencies (log store, hammer tab) are always injected even in release builds; should be guarded by feature flags to avoid code size & attack surface.
- Log storage runs on main actor and writes to disk per request; risk of jank under network load.
- No redaction for request bodies beyond simple heuristics; could leak PIIs for future features.

### Foundation blueprint

1. **Layered architecture:** Formalize `App` (entry + navigation), `Core` (config, networking, security, localization, logging), `Features/*` (per domain: Models → Repositories → UseCases → ViewModels → Views), `UI` (design system + shared components), `Resources`, `Tests`, `Docs`. Enforce one-way dependencies via Swift Package Manager or Xcode workspace targets.
2. **Composition & navigation:** Replace `CompositionRootView` with a dedicated `AppCoordinator` that owns navigation stacks, handles session changes, and injects view models via factories (protocol-based). Move deep-link parsing into `Core/DeepLink/DeepLinkParser.swift` to validate tokens/state before dispatching intents.
3. **Networking:** Keep `URLSession` but introduce a `RequestBuilder` + `ResponseDecoder` pipeline with middleware (auth header injection, logging, retry/backoff). Separate `NetworkLogger` service from HTTP client to decouple persistence. Support environment-based base URLs (Dev/Stage/Prod) and per-endpoint timeout & idempotency metadata.
4. **Token lifecycle:** Expand `TokenManager` into `SessionController` that stores tokens, tracks expiry, refreshes proactively (using `refresh_token` endpoint), and exposes `SessionState` via `AsyncStream`. Handle 401 by pausing inflight requests, refreshing once, then resuming.
5. **Localization & theming:** Move string keys to `.stringsdict` for pluralization; introduce `LocalizationProvider` that can switch languages at runtime by selecting the user’s profile language (until backend drives). Flesh out `UI/Theme/` with typography scales, spacing, semantic colors, shape tokens, and Compose-style modifiers; ensure dynamic type & dark mode are supported.
6. **State & error handling:** Standardize `ViewState` models (loading/loaded/error/empty), typed domain errors (e.g., `AuthError.invalidIdentifier`, `CueError.network`), and user-friendly copy with retry guidance. Use `@Observable` or new Observation macros carefully, but keep heavy work off main actor via `Task`/`async let`.
7. **Instrumentation & diagnostics:** Add lightweight analytics hooks (protocol-based) for auth success/failure, cue fetch latency, and upcoming recording events. Gate developer tooling behind an environment flag and hide in production builds, backed by a centralized feature-access config (allowlisted user IDs/emails from JWT claims).
8. **Storage & offline readiness:** Introduce `Core/Storage` (e.g., `FileManager` wrappers) for future audio files and cached cues. Consider SQLite/CoreData or GRDB if history needs persistence.

### Domain rebuild roadmap

| Domain | vNext objectives | Key deliverables |
| --- | --- | --- |
| Auth & Session | Harden magic-link + refresh. | Input validation, rate-limit UX, deep-link parser, refresh use case, Keychain error surfacing, analytics, logout flow via use case. |
| Profiles & Localization | Make language selection first-class. | `ProfileRepository`, cached `AppConfig`, localized picker labels, runtime language switch, profile avatar & metadata, tests for `SettingsViewModel`. |
| Cues & Practice | Prepare for recording/history. | `CueListViewModel` with pagination, caching, skeleton states; `CueDetail` with structured content model; placeholder for recording CTA; domain errors + tests. |
| Recording & History (future) | Capture & review audio, feed AI evaluator. | `RecordingSessionController` (AVAudioSession management), encrypted file storage, upload pipeline via `URLSessionUploadTask`, history repository + UI, evaluation results surface. |
| Developer Tooling | Safer diagnostics. | Feature-flagged debug tools, background log flush, redaction review, integration with analytics toggle, doc updates in `docs/`. |
| Design System & UI Platform | Ensure consistency + accessibility. | Tokenized theme (`UI/Theme/`), SwiftUI modifiers (buttons, cards, typography), dynamic type testing, color contrast audit, snapshot tests. |
| Docs & Tests | Keep architecture traceable. | Update `docs/architecture.md`, add ADR for networking & session, expand `Tests/` to cover Auth, Settings, Session, Networking; add UI test targets for core flows. |

### Implementation sequencing
1. **Stabilize session/auth** before adding new features to avoid rework when tokens/refresh change.
2. **Extract Core services** (config, networking, logger, localization) into protocols + default implementations, then migrate features incrementally.
3. **Refactor Settings/Profile** to rely on cached `AppConfig` and typed language models, enabling multi-language UI.
4. **Rebuild cue experience** with new ViewModel/use cases, prepping for recording CTA and history.
5. **Introduce design system tokens** to unify UI and enable theming/dark mode.
6. **Add recording/history scaffolding** (even if feature-flagged) so future AI evaluator can plug into a stable interface.
7. **Tighten developer tooling & docs** to keep production build lean and compliance-friendly.

### See also
- [`docs/architecture.md`](docs/architecture.md)
- [`docs/auth.md`](docs/auth.md)


