Status: current  
Last verified: 2025-11-27

## 02 — Configuration, Environments & Feature Flags

### Why this exists

- Make configuration and feature flags **centralized, explicit, and testable**.
- Ensure the client can safely adapt to **Dev/Stage/Prod** environments and backend‑driven behavior toggles without ad‑hoc checks.

### Role in the system

- Defines how we:
  - Represent build‑time vs runtime configuration.
  - Load and cache `/rpc/app_config`.
  - Expose feature flags to features in a type‑safe way.
  - Guard developer tooling, analytics, and future recording features.

---

## 1. Configuration model

### 1.1 Build‑time environment

- `Core/Config/Environment.swift`:
  - Encapsulates static build info:
    - Base URLs per environment (Dev/Stage/Prod).
    - Bundle identifiers, app version/build.
    - Default logging verbosity.
  - Selection:
    - Use compile‑time flags (`#if DEBUG`) and/or Xcode schemes to choose an `Environment` value at runtime.
  - Must **never hit the network** or depend on `/rpc/app_config`.

### 1.2 Runtime config

- `Core/Config/RuntimeConfig.swift`:
  - Merges:
    - Build‑time defaults (from `Environment`).
    - Backend response from `/rpc/app_config`.
    - Optional debug overrides (DEBUG‑only).
  - Exposes:
    - Feature flags (`FeatureFlag` enum).
    - Cooldowns (e.g., magic link resend).
    - Pagination defaults (e.g., cues count).
    - Analytics toggles (session replay, first‑party events).
    - Developer menu availability.

- `RuntimeConfigLoader`:
  - On startup:
    - Uses `APIClient` to call `/rpc/app_config`.
    - Validates payload (required fields, types).
    - Caches the result to disk with TTL (e.g., 1–6 hours).
  - On failure:
    - Falls back to last cached value if present.
    - Otherwise uses build‑time defaults and surfaces user‑safe errors.

- `ConfigProvider`:
  - Offers:
    - `var snapshot: RuntimeConfig` (synchronous read).
    - `var updates: AsyncStream<RuntimeConfig>` (subscribe to changes).

---

## 2. Feature flags

### 2.1 Flag definition

- `Core/Config/FeatureFlag.swift`:

```swift
enum FeatureFlag: String, CaseIterable {
    case developerMenuEnabled
    case networkConsoleEnabled
    case analyticsEnabled
    case sessionReplayEnabled
    case recordingScaffoldEnabled
}
```

- `RuntimeConfig` provides typed access:
  - `func isEnabled(_ flag: FeatureFlag) -> Bool`
  - Optionally, **scoped flags** (`AuthFeatureFlags`, `CuesFeatureFlags`) wrap raw flags for ergonomics.

### 2.2 Flag sources & precedence

Order of precedence (lowest → highest):

1. **Build defaults** (baked into `Environment` and static defaults in `RuntimeConfig`).
2. **Backend overrides** from `/rpc/app_config`.
3. **Local developer overrides** (DEBUG only), e.g., from `debug-feature-flags.json` or `UserDefaults`.

Resolution:

- At runtime, `FeatureFlagProvider` merges these sources once and exposes a final `RuntimeConfig`.
- ONLY `FeatureFlagProvider` knows about override layering; features just call `config.isEnabled(.developerMenuEnabled)`.

### 2.3 Flag usage examples

- Developer tools:
  - `MainTabsView` includes DevTools tab **only if**:
    - `Environment` is debug‑capable, AND
    - `RuntimeConfig.isEnabled(.developerMenuEnabled)`, AND
    - Account is flagged as developer (from `/rpc/me`).

- Recording scaffold:
  - `CueDetailView` shows recording entry point **only if** `.recordingScaffoldEnabled` is true.
  - Under the hood, recording is still a stub until backend endpoints exist.

- Analytics:
  - `AnalyticsRecorder` registers sinks only if `.analyticsEnabled` is true and user has opted in.

---

## 3. Environment‑specific behavior

### 3.1 Base URLs & endpoints

- All network calls use:
  - `Environment.current.baseURL` for base path.
  - Endpoint paths defined in `Core/Networking/Endpoints.swift`.
- Do not hardcode hostnames or ports in features; only in `Environment` (and tests).

### 3.2 Logging & diagnostics per environment

- DEBUG builds:
  - Verbose logging allowed for development, but still no PII.
  - Network console and diagnostics screens enabled by flags.
- RELEASE builds:
  - Logs mostly `.error` and `.fault` with private redaction.
  - Developer tooling and extra diagnostics views **excluded** at compile‑time.

---

## 4. Offline and cache behavior

### 4.1 Config cache

- `RuntimeConfigCache`:
  - Persists a compact JSON representation of the last successful `/rpc/app_config`.
  - Uses iOS file protection (`.completeUntilFirstUserAuthentication`) for safety.
  - On cold start:
    - Load cache synchronously, then asynchronously refresh from network.
    - If both cache read and network fail, use build‑time defaults and show a non‑blocking UI notice.

### 4.2 Per‑feature configs

- Example derived fields inside `RuntimeConfig`:
  - `auth.magicLinkCooldownSeconds`
  - `cues.pageSize`
  - `devTools.maxNetworkLogEntries`
  - `analytics.flushIntervalSeconds`

Features **must not** hardcode these values; always read them from `RuntimeConfig`.

---

## 5. Security and privacy considerations

- Never put secrets (tokens, API keys) into `RuntimeConfig` or `Environment` as literals.
  - Only store ephemeral non‑secret data there (flags, TTLs, numeric limits, environment names).
- When logging config:
  - Log only **non‑sensitive keys** and coarse values (e.g., which flags are enabled), not identifiers or user data.
- Keep local override files (`debug-feature-flags.json`) out of production bundles and never commit real user‑specific flags.

---

## 6. Action checklist

- [ ] `Environment.swift` defines Dev/Stage/Prod with base URLs and build‑time defaults.
- [ ] `RuntimeConfig` models all relevant server‑driven behaviors (cooldowns, page size, analytics toggles).
- [ ] `RuntimeConfigLoader` fetches `/rpc/app_config`, validates it, and caches results with TTL.
- [ ] `ConfigProvider` exposes both snapshot and async stream APIs.
- [ ] `FeatureFlagProvider` merges build defaults, backend overrides, and debug overrides.
- [ ] All features rely on typed `FeatureFlag`/`RuntimeConfig` instead of ad‑hoc booleans.
- [ ] Developer menu, analytics, and recording scaffolds are correctly gated by flags.


