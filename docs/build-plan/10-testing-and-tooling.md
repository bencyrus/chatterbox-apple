Status: current  
Last verified: 2025-11-27

## 10 — Testing, Tooling & Developer Workflow

### Why this exists

- Ensure Chatterbox iOS remains **reliable, maintainable, and easy to extend** by enforcing strong testing and tooling practices.

### Role in the system

- Specifies:
  - Developer experience (build configs, DI harnesses, debug flows).
  - Testing strategy (unit, integration, UI, snapshot).
  - CI expectations and coverage goals.

---

## 1. Build configurations & flags

- Configurations:
  - **Debug**: full developer tooling, verbose logging, feature flag overrides allowed.
  - **Release**: no dev tools; minimal logging; shipping configuration.
  - Optional **Staging**: production‑like settings but separate base URL.

- Swift compiler flags:
  - Use `#if DEBUG` to include:
    - Developer menu.
    - Network console.
    - Test fixtures.

---

## 2. Dependency injection for tests & previews

- `PreviewContainer`:
  - Constructs in‑memory or stubbed versions of:
    - `ConfigProvider` with canned config.
    - `APIClient` using a mock URL protocol or stub closures.
    - `SessionController` in deterministic states.
  - Provides easy `ViewModel` factories for SwiftUI previews.

- `TestContainer`:
  - Similar to `PreviewContainer`, but oriented toward XCTest usage.
  - Provides mocks for repositories and services via protocols.

---

## 3. Unit tests

- Target:
  - ViewModels.
  - Use Cases.
  - Repositories (via mocked networking).
  - Core services (`SessionController`, `RuntimeConfigLoader`, `LocalizationProvider`).

- Patterns:
  - Use protocol‑based mocks (e.g., `MockAuthRepository`, `MockConfigProvider`).
  - Use `MockURLProtocol` to intercept and stub `URLSession` calls in repository tests.
  - Adopt async XCTest support (`async` test methods with `await`).

---

## 4. Integration & UI tests

- Integration tests:
  - Compose real Core services with mocked network backend.
  - Cover flows like login, session refresh, cue load, etc., using fixtures rather than real HTTP.

- UI tests:
  - Use page‑object pattern for maintainable tests.
  - Cover:
    - Authentication (request link, follow link, success/fail).
    - Cues browsing and shuffling.
    - Settings (language change, logout).
    - Developer menu gating and basic functionality.
  - Use launch arguments/env vars to switch app into mock data mode.

---

## 5. Snapshot & visual regression testing

- If approved to use a snapshot library (e.g., Point‑Free’s `SnapshotTesting`):
  - Add snapshot tests for:
    - Key design system components (buttons, cards, banners, cues list cells).
    - Critical screens (Login, Cues, Settings) in light and dark mode.
  - Run snapshots in CI and inspect diffs as part of review.

---

## 6. Continuous integration

- Pipeline stages:
  - `lint` — SwiftLint, formatting checks.
  - `build` — `xcodebuild` for Debug and Release configurations.
  - `test` — unit & (optionally) UI tests.
  - `artifacts` — build archive or screenshots/snapshots.

- Gates:
  - Failing tests or lint errors block merges.
  - Enforce coverage thresholds for core modules (e.g., 80%+ for ViewModels and Use Cases).

---

## 7. Documentation & ADRs

- For any significant architectural decision:
  - Add/update an ADR under `docs/adr/`.
  - Reference relevant build‑plan sections in the ADR.

- PRs touching architecture, behavior, or new features:
  - Must update relevant `build-plan/*.md` and any ADRs they supersede.

---

## 8. Action checklist

- [ ] `PreviewContainer` and `TestContainer` are implemented to ease previews and tests.
- [ ] Unit tests exist for all new ViewModels, Use Cases, and Repositories.
- [ ] UI tests cover core flows using mock data and accessibility identifiers.
- [ ] CI pipeline runs lint/build/test on each PR and enforces coverage thresholds.
- [ ] Documentation and ADRs are updated when architecture or behavior changes.


