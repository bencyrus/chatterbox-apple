Status: current  
Last verified: 2025-11-27

## 09 — Observability, Analytics & Developer Tooling

### Why this exists

- Provide a **coherent observability story** for Chatterbox:
  - Logging that’s safe and useful.
  - Analytics hooks that are pluggable and privacy‑aware.
  - Developer tools that are powerful in DEBUG but invisible in production.

### Role in the system

- Specifies:
  - Logging strategy with `os.Logger` and network log store.
  - Analytics facade with multiple future sinks (session replay + first‑party).
  - Developer menu, network console, diagnostics export.

---

## 1. Logging layers

### 1.1 OSLog / Logger

- Define category constants in `Core/Observability/Log.swift`:
  - `com.chatterbox.app`
  - `com.chatterbox.network`
  - `com.chatterbox.session`
  - `com.chatterbox.analytics`
  - `com.chatterbox.ui`

- Use `Logger` with privacy:
  - Default to `.private` for interpolated values.
  - Explicitly mark technical metadata as `.public` only when safe (e.g., status codes, durations).

- Levels:
  - `.debug` — development details; may be suppressed in release.
  - `.info` — high‑level flow events.
  - `.error` — recoverable issues.
  - `.fault` — serious bugs.

### 1.2 Network log store

- `NetworkLogger` (actor):
  - Receives `NetworkEvent` from `APIClient`:
    - `id`, `timestamp`, `method`, `path`, `status`, `duration`, optional sanitized bodies.
  - Writes events to:
    - In‑memory ring buffer.
    - Optional disk persistence in DEBUG builds.

- `NetworkLogStore` (observation wrapper):
  - Exposes read‑only list of recent events for SwiftUI views.
  - Supports filters and clear operations.

---

## 2. Analytics facade

### 2.1 Event model

- `AnalyticsEvent`:
  - `name` — namespaced identifier (`auth.login_success`, `cues.shuffle`, `settings.language_change`).
  - `properties` — small dictionary of primitives (no PII).
  - `context` — optional metadata (app version, language, environment).

### 2.2 Sinks and recorder

- `AnalyticsSink` protocol:
  - `func record(_ event: AnalyticsEvent) async`

- `AnalyticsRecorder`:
  - Holds registered sinks.
  - `func record(_ event: AnalyticsEvent)` fans out to sinks on background tasks.
  - Sinks:
    - `OSLogAnalyticsSink` — logs event summaries.
    - `InMemoryAnalyticsSink` — stores recent events for developer UI.
    - Future: `SessionReplaySink`, `FirstPartyAPISink`.

### 2.3 Configuration

- Controlled by:
  - `RuntimeConfig` flags (`analyticsEnabled`, `sessionReplayEnabled`).
  - User‑level opt‑in/opt‑out stored in account/profile settings.

- Rules:
  - If user has opted out or config disables analytics, `AnalyticsRecorder` may be a no‑op.
  - Session replay (third‑party) must always be behind explicit opt‑in and environment gating.

---

## 3. Developer tools

### 3.1 Developer menu

- Activation:
  - DEBUG builds only.
  - Plus runtime flags from `RuntimeConfig` and `/rpc/me` developer roles.
  - Hidden behind non‑obvious gesture (e.g., multiple taps on version label).

- Content:
  - Network log viewer (pulls from `NetworkLogStore`).
  - Analytics event stream viewer (from `InMemoryAnalyticsSink`).
  - Config snapshot viewer (current `RuntimeConfig` and environment).
  - MetricKit dump viewer (if integrated).

### 3.2 Network console

- Views:
  - `NetworkLogListView` — list of recent events with search/filter.
  - `NetworkLogDetailView` — full details for a single event.
  - `JSONExplorerView` — tree viewer for JSON payloads.

- Requirements:
  - Redact tokens, emails, phone numbers, and any other PII from displayed bodies.
  - Export logs (DEBUG only) as a sanitized JSON file for bug reports.
  - Excluded entirely from release builds via `#if DEBUG`.

---

## 4. Diagnostics & metrics

- Diagnostics events:
  - `DiagnosticsEventRecorder` collects structured events (flag toggles, config changes, slow operations).
  - Short retention (e.g., last 24 hours).
  - Exposed only in debug tooling.

- MetricKit (optional):
  - `MetricKitManager` subscribes to `MXMetricManager`.
  - Can expose collected metrics via developer tools.
  - Any upload of diagnostics to backend must be opt‑in and anonymized.

---

## 5. Privacy & compliance

- PII handling:
  - Use a dedicated `PIIRedactor` helper for:
    - Email patterns.
    - Phone numbers.
    - Tokens and other credentials.
  - Apply redaction before logs enter `NetworkLogStore` or analytics sinks.

- User consent:
  - Analytics & diagnostic toggles live in Settings.
  - Respect OS‑level privacy settings and App Store privacy rules.

---

## 6. Action checklist

- [ ] `Logger` categories are defined and used consistently across modules.
- [ ] `NetworkLogger` and `NetworkLogStore` exist and are wired into `APIClient`.
- [ ] Analytics facade (`AnalyticsRecorder`, `AnalyticsSink`, core event types) is implemented.
- [ ] Developer menu and network console are available only in DEBUG builds and behind flags + roles.
- [ ] All logging and analytics outputs are free of PII and tokens, using a central redaction helper.


