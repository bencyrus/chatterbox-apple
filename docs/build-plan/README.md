Status: current  
Last verified: 2025-11-27

## Chatterbox iOS Build Plan

### Why this exists

- Provide a **single, canonical blueprint** for rebuilding Chatterbox iOS from scratch.
- Merge the strongest ideas from the earlier `rebuild-1/2/3` plans and `deep-research-results.md` into a **stable, generic “how we build” guide**.
- Give humans and AI assistants enough structure to implement features autonomously **without re‑inventing architecture on each task**.

### Role in the system

- This directory defines **how we do things**, not just what we might do:
  - When we handle **architecture and navigation**, we do it like `01-architecture-and-flow.md`.
  - When we handle **config and feature flags**, we do it like `02-config-and-flags.md`.
  - When we handle **auth/session**, we do it like `04-authentication-and-account.md`.
  - When we handle **voice/recording**, we do it like `08-recording-and-history.md`.
- `REBUILD_DIRECTIVE.md` (at repo root) tells an AI/engineer **how to consume this folder** and derive a step‑by‑step rebuild plan from the current codebase + swagger.

### How to use this folder

- **Before writing code**, always:
  1. Read `01-architecture-and-flow.md` and `02-config-and-flags.md`.
  2. Read the topic file(s) for the area you’re touching (auth, cues, localization, etc.).
  3. Skim `99-ai-guidelines.md` if you’re an AI agent or delegating to one.
- **While implementing**, treat these docs as **law**:
  - If current code contradicts the plan, the **plan wins**; either refactor or write an ADR to justify a change.
  - If the backend contract is missing for behavior described here, **pause and request backend changes** instead of hacking client-side logic.
- **After implementing**, update the relevant section(s) here with any architecture learnings or deviations.

### Document map

1. `01-architecture-and-flow.md` — Layered architecture, module layout, DI, navigation, deep links, state/concurrency.
2. `02-config-and-flags.md` — Environments, runtime config, feature flags, backend‑driven behavior switches.
3. `03-networking-and-session.md` — Request pipeline, HTTP error model, `SessionController`, token refresh, network logging.
4. `04-authentication-and-account.md` — Magic link/OTP, login and logout, `/rpc/me`, session safety, auth analytics hooks.
5. `05-localization-and-profiles.md` — Multi‑language policy via `/rpc/me` + `/rpc/app_config`, profile switching, settings UX.
6. `06-design-system-and-ui.md` — Design tokens, components, accessibility, Dynamic Type, localization of UI.
7. `07-cues-and-content.md` — Cues/home feature, caching, pagination/shuffle, future recording entry, backend‑driven rendering.
8. `08-recording-and-history.md` — AVFoundation setup, storage, upload pipeline, history scaffolding and threat considerations.
9. `09-observability-and-analytics.md` — Logging, diagnostics, analytics facade (session replay + first‑party metrics).
10. `10-testing-and-tooling.md` — Developer workflow, debug tools, linting/CI, unit/UI/snapshot tests and coverage.
11. `99-ai-guidelines.md` — End‑to‑end guidelines for AI agents applying this plan in code.

### Core principles (summary)

- **Backend‑driven logic**: Backend prepares display‑ready payloads; client renders them, manages state and resilience.
- **MVVM + Use Cases + Repositories**: Views are thin; business logic lives in use cases; data access behind repositories.
- **Apple‑first stack**: Swift 5.9+, SwiftUI + Observation, NavigationStack, `URLSession`, Keychain, AVFoundation, `os.Logger`, MetricKit.
- **Security & privacy first**: No PII or tokens in logs, Keychain for secrets, file protection for recordings/history.
- **Design system as law**: All colors/fonts/spacing from tokens; full support for dark mode, Dynamic Type, RTL.
- **Analytics‑ready by design**: Every meaningful intent can raise a typed analytics event, but sinks and collection are feature‑flagged.

### Relationship to other docs

- The earlier `docs/rebuild-1/2/3/` folders represent **prior iterations**; this folder is the **final, merged build plan**.
- `AUDIT.md` explains why the current app is unacceptable; this folder describes the **target state**.
- `deep-research-results.md` provides deep Apple‑aligned theory; this folder distills that theory into **practical rules and checklists**.


