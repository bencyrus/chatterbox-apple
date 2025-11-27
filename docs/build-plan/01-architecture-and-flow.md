Status: current  
Last verified: 2025-11-27

## 01 — Architecture & Flow

### Why this exists

- Define a **single, consistent architecture** for Chatterbox iOS so every feature, service, and helper fits the same mental model.
- Make it trivial for future contributors (including AI) to understand **where code belongs** and **how data flows** without re‑deriving patterns.

### Role in the system

- This file is the **root contract** for:
  - Project layout and module boundaries.
  - MVVM + Use Cases + Repository layering.
  - Dependency injection and app composition.
  - Navigation, coordinators, and deep links.
  - High‑level concurrency and state conventions.
- Every other document in `build-plan/` builds on these rules.

---

## 1. Layered architecture

### 1.1 Modules & directories

- `App/`
  - `ChatterboxApp.swift` — App entry point.
  - `CompositionRoot.swift` (or `AppContainer/AppCoordinator`) — DI container + top‑level navigation coordinator.
  - Scene/phase handling, deep link entry (`onOpenURL`).
- `Core/`
  - `Config/` — environment detection, runtime config, feature flags.
  - `Networking/` — request/response pipeline, endpoints, HTTP errors, network logging integration.
  - `Security/` — `SessionController`, Keychain token store, identifier masking.
  - `Localization/` — localization provider, cache, locale bridging.
  - `Storage/` — file paths, cache layer, future SwiftData/SQLite for cues/history.
  - `Observability/` — logging, diagnostics events, analytics facade.
- `UI/`
  - `Theme/` — design tokens (colors, typography, spacing, radii, shadows).
  - `Components/` — reusable controls (buttons, cards, list rows, banners, skeletons).
  - `Modifiers/` — common view modifiers (`cardStyle`, `shimmer`, etc.).
- `Features/<Domain>/`
  - `Models/`, `Repositories/`, `UseCases/`, `ViewModel/`, `View/` (+ optional `Coordinator/` when flows get complex).
  - vNext domains: `Auth`, `Account` (me/settings), `Cues`, `DeveloperTools`, `Recording` (scaffold), `History` (future).
- `Resources/`
  - `Assets.xcassets`, `Strings/<lang>.lproj/`, recordings/history directories.
- `Tests/`, `UITests/`
  - Mirror `Core/`, `Features/`, and `UI` for unit and UI tests.

### 1.2 Dependency rules

- Allowed dependencies:
  - `App` → `Core`, `Features`, `UI`, `Resources`.
  - `Features` → `Core`, `UI` (tokens/components only).
  - `UI` → `Core` (for logging types or small helpers only when necessary).
- Forbidden:
  - Features importing other features directly.
  - `Core` depending on `Features`.
  - `UI` depending on `Features`.
- Use **protocols** to invert dependencies:
  - Repositories define protocols in their feature module.
  - `Core` types (e.g. `APIClient`, `SessionController`) are injected into concrete repositories via DI.

---

## 2. MVVM + Use Cases + Repositories

### 2.1 Responsibilities

- **View (SwiftUI struct)**
  - Declares UI based on observable state.
  - Forwards user intents to a ViewModel.
  - Contains **no business logic** and **no direct networking**.

- **ViewModel (`@Observable` class, `@MainActor`)**
  - Owns screen state (view state enums, fields, derived booleans).
  - Exposes intent methods (e.g., `requestMagicLink()`, `shuffleCues()`).
  - Calls use cases; maps domain errors to user‑facing messages.
  - Contains **no direct `URLSession` or Keychain access**.

- **Use Case (value type or simple class)**
  - Encapsulates a single business operation (e.g., `RequestMagicLinkUseCase`, `LoadInitialCuesUseCase`).
  - Coordinates one or more repositories and transient business rules.
  - Is **pure domain logic** with no UIKit/SwiftUI dependencies.

- **Repository**
  - Abstracts IO (network, storage) behind protocols.
  - Implements mapping between DTOs and domain models where needed.
  - Does **not** contain view/state logic; it talks in domain types.

- **Core services**
  - `APIClient`, `SessionController`, `ConfigProvider`, `LocalizationProvider`, `AnalyticsRecorder`, etc.
  - Stateless or actor‑based; shared via DI from the composition root.

### 2.2 Standard view state

- Use a generic `ViewState` pattern for screen‑level data:

```swift
enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case error(DomainError)
}
```

- Screen ViewModels:
  - Expose a `state: ViewState<Content>` for main content.
  - Use **separate flags** for orthogonal actions (`isSaving`, `isRefreshing`) to avoid conflating concerns.

---

## 3. Composition root & dependency injection

### 3.1 App container

- `AppContainer` (or similar) is responsible for:
  - Constructing singletons/long‑lived services:
    - `EnvironmentLoader`, `ConfigProvider`, `APIClient`, `SessionController`, `LocalizationProvider`,
      `NetworkLogger`, `AnalyticsRecorder`, `PermissionCoordinator`, etc.
  - Constructing feature factories:
    - `AuthViewModelFactory`, `SettingsViewModelFactory`, `CuesViewModelFactory`, `DevToolsViewModelFactory`, etc.
  - Wiring everything together once at startup.

- No feature module may construct core services on its own; all such construction happens in `App/CompositionRoot`.

### 3.2 Factories & protocols

- For each feature, define factory protocols in the feature module:
  - Example: `protocol AuthViewModelFactory { func makeLoginViewModel() -> LoginViewModel }`.
- Provide concrete implementations in `App/CompositionRoot` that use real use cases and repositories.
- For previews/tests, provide alternative factories that wire **mocks**.

### 3.3 Environment & Observation

- Keep use of global `@EnvironmentObject` minimal; prefer **explicit injection** via initializers.
- Allowed environment usage:
  - Themed values (`Theme`, `ColorScheme`, `DynamicTypeSize`).
  - Locale (`\Environment(\.locale)` via `LocalizationProvider`).
  - Read‑only config/flags via custom environment keys when this improves ergonomics.
- Global session state comes from `SessionController` (actor) and is subscribed to by coordinators, not scattered via `@EnvironmentObject` in many views.

---

## 4. Navigation, coordinators & deep links

### 4.1 Navigation model

- Root navigation is driven by a **single `NavigationStack`** per high‑level flow:
  - Unauthenticated flow (login/OTP).
  - Authenticated main tabs (home/cues, settings, optional dev tools).
- Use **typed route enums**:

```swift
enum MainRoute: Hashable {
    case home
    case cueDetail(id: Int64)
    case settings
    case devTools   // gated by flags
}
```

### 4.2 Coordinators

- `AppCoordinator` responsibilities:
  - Subscribe to `SessionController`’s `AsyncStream<SessionState>`.
  - Decide which root flow to show (`LoginFlowView`, `MainTabsView`).
  - Handle app lifecycle changes (e.g., re‑bootstrap on foreground).
  - Dispatch validated deep links to feature coordinators (Auth, Cues, Recording when active).

- Feature coordinators (optional when flows are non‑trivial):
  - `AuthCoordinator`, `PracticeCoordinator`, `SettingsCoordinator`, `DevToolsCoordinator`.
  - Own typed navigation path(s) and map view‑model events to route changes.

### 4.3 Deep link handling

- All deep link parsing lives in `Core/DeepLink/DeepLinkParser`.
  - Accept only known hosts/schemes (configured in Associated Domains).
  - Map URLs to `DeepLinkIntent` enums such as:
    - `.magicToken(token: String)`
    - `.openSettings`
    - `.openCue(id: Int64)`
  - Validate required parameters; reject malformed URLs with safe logging.

- `ChatterboxApp` calls into `AppCoordinator.handle(url:)` which:
  - Uses `DeepLinkParser` to produce a `DeepLinkIntent`.
  - For auth intents, forwards to the relevant use case (`CompleteMagicLinkUseCase`).
  - For navigation intents, updates route stack appropriately.

### 4.4 Back behavior

- Never pop navigation stacks implicitly on background operations.
  - Example: on successful login, **coordinator** swaps from login flow to main tabs,
    but within a flow, background network calls should just update state (show banner, etc.).
- Respect platform expectations for back gestures and tabs. Do not override with custom navigation hacks.

---

## 5. Concurrency & state model

### 5.1 Observation & threading

- Use Swift 5.9+ Observation:
  - ViewModels annotated with `@Observable` and `@MainActor`.
  - Heavy work moved off the main actor via `Task {}` / `async let` / actor‑isolated services.
- Shared mutable state (session, logs, analytics buffers) is protected via **actors**:
  - `actor SessionController`
  - `actor NetworkLogger`
  - `actor DiagnosticsEventRecorder`

### 5.2 Task lifecycle

- All view‑initiated async work must be **cancellable**:
  - Avoid storing unstructured `Task`s without cancellation.
  - Use SwiftUI `.task(id:)` where possible so tasks cancel when the view disappears.
- When switching profiles, flows, or tabs:
  - Cancel in‑flight cue loads or settings fetches to avoid racing updates.

### 5.3 Error propagation

- Use **typed domain errors** per area (`AuthError`, `NetworkError`, `CueError`, `LocalizationError`).
- Repositories convert HTTP/transport errors into `NetworkError`.
- Use cases convert transport errors into domain errors.
- ViewModels expose domain errors via `ViewState.error(DomainError)` and user‑friendly messages via helpers (`error.userMessage`).

---

## 6. Backend‑driven rendering

### 6.1 Rule: backend decides, client renders

- For all `rpc/*` endpoints (see `swagger.json`):
  - Backend is responsible for:
    - What records exist, in what order.
    - Which cues or actions are allowed.
    - Any stage/state semantics for cues or profiles.
    - Display text (titles, subtitles, button labels) where possible.
  - Client is responsible for:
    - Validating that required fields are present and well‑typed.
    - Mapping DTOs to simple domain models only when necessary for UI ergonomics.
    - Handling loading/empty/error states and transitions.

### 6.2 What the client must NOT do

- Invent behavior that contradicts backend:
  - No local filtering/sorting of cues beyond trivial UI needs.
  - No client‑side derivation of cue stages or unlocking rules.
  - No reimplementation of cooldown logic; render server‑provided cooldowns.
- Assume unknown fields are **reserved for future**; do not strip them in logs or DTOs if not needed, but do not act on them either.

---

## 7. Implementation guardrails

- **Do not**:
  - Add new top‑level modules or cross‑feature dependencies without updating this file.
  - Put business logic in `View` or `Repository` layers.
  - Introduce new global singletons outside of `App/CompositionRoot`.

- **Always**:
  - Start new work by confirming how it fits into this architecture.
  - Keep public APIs small and explicit; prefer value types for models.
  - Write or update tests when adding new use cases or view models.

---

## 8. Action checklist

- [ ] Directory structure matches the layers described above.
- [ ] All features follow `View → ViewModel → UseCase → Repository → Core` flow.
- [ ] `App/CompositionRoot` is the only place where core singletons are constructed.
- [ ] Navigation is driven via typed route enums and coordinators.
- [ ] Deep links are parsed and validated in `Core/DeepLink`.
- [ ] Shared mutable state is isolated behind actors.
- [ ] Domain errors are typed and mapped to user‑friendly messages.
- [ ] No feature directly imports another feature.

If an implementation cannot meet one of these items for a good reason, record the reasoning in an ADR and link it back here.


