# REBUILD DIRECTIVE

## Reality Check
- The current SwiftUI client does **not** follow the architecture, security, or
  localization rules documented in `build plan/`. Composition mixes concerns,
  features call services directly, design tokens are unused, and debug tooling
  bleeds into prod targets.
- Recording is not implemented anywhere in the codebase and the current swagger
  shows only placeholder RPCs for future media work—treat voice features as
  scaffolding until backend support ships.
- Token refresh _is_ available via `/rpc/refresh_tokens`, but the existing code
  handles it inconsistently. Assume nothing works correctly until verified.
- Because of these gaps, the app must be **rebuilt from scratch** following the
  new development plan. Incremental patches that leave old patterns behind are
  not acceptable.

## Mandatory Prep Before Writing Code
1. **Read the entire codebase** (`App/`, `Core/`, `Features/`, `UI/`, `Resources/`,
   `Tests/`, etc.) to inventory what actually exists. Take notes on reusable
   models, legacy shortcuts, and hidden dependencies.
2. **Study `swagger.json` end-to-end.** Confirm which RPCs exist _today_ (`/rpc/me`,
   `/rpc/get_cues`, `/rpc/request_magic_link`, `/rpc/refresh_tokens`, etc.) and
   which are aspirational (recording uploads). Never invent endpoints.
3. **Cross-reference `AUDIT.md`** to understand known defects and shortcuts.
4. **Absorb every file inside `build plan/`**. That folder is the only blueprint
   you should follow going forward.

## Required Work Categories & Step-by-Step Expectations

### 1. Core Platform & Session
1. Enforce the module layout and DI strategy from `build plan/01-architecture-and-flow.md`.
2. Replace ad-hoc config readers with `EnvironmentLoader` + `RuntimeConfigProvider`.
3. Implement the networking pipeline + middleware stack (`build plan/03`).
4. Promote `TokenManager` to a proper `SessionController` actor with bootstrap,
   refresh, logout, and deep-link handling.
5. Add feature-flag plumbing (`build plan/02`) and document new flags.

### 2. Authentication & Account Safety
1. Rebuild Auth repositories/use cases/view models following `build plan/04`.
2. Implement identifier validation, backend-driven cooldowns, analytics, and
   localized copy.
3. Harden deep-link parsing and token exchange logic through the centralized
   handler (`build plan/03`).
4. Add full unit + UI test coverage for login/OTP/logout flows.

### 3. Localization, Profiles & Settings
1. Implement the localization pipeline described in `build plan/05`.
2. Rebuild Settings UI using design-system components and runtime locale
   switching.
3. Respect backend roles/flags for developer tools and analytics opt-in.
4. Cache profile/config data for offline readiness; add tests for fallbacks.

### 4. Design System & UI Composition
1. Create the token + component catalog from `build plan/06`.
2. Refactor every existing view to use tokens/components; remove literal colors
   and fonts.
3. Add previews (light/dark, Dynamic Type, RTL) and snapshot tests where needed.

### 5. Cues & Practice Flows
1. Rebuild cue repositories/use cases/view models per `build plan/07`.
2. Implement caching, pagination/infinite scroll, shuffle cooldown, and error
   handling.
3. Wire analytics + diagnostics hooks; ensure offline behavior matches the plan.

### 6. Observability & Developer Tooling
1. Implement the analytics facade, log stack, and diagnostics bus from
   `build plan/09`.
2. Gate the developer menu behind build config + runtime flag + backend roles.
3. Add diagnostics export and network inspector only in Debug builds.

### 7. Voice, Recording & History Scaffold
1. Add the recording/session controllers, storage directories, and UI placeholders
   described in `build plan/08`.
2. Keep these features behind `enableRecordingScaffold` until backend work lands.
3. Document threat models and tests even if the UI remains disabled.

### 8. Testing, CI & Documentation
1. Follow the testing pyramid + roadmap in `build plan/10`.
2. Ensure CI covers lint/build/test and enforces coverage thresholds.
3. Update ADRs, strings, and this directive whenever structure changes.

## Final Reminder
- You are expected to **read everything first**, then execute work in the ordered
  phases above. Do not cherry-pick tasks or reuse legacy code without rewriting
  it to comply with the new plan.
- If something in the current project contradicts this directive, the directive
  wins—raise an ADR only if the change is intentional and documented.

