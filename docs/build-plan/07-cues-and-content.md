Status: current  
Last verified: 2025-11-27

## 07 — Cues & Content Flow

### Why this exists

- Define how Chatterbox fetches, displays, and manages cue content in a way that is:
  - **Backend‑driven** (no client business rules),
  - **Ready for recording/history**, and
  - **Resilient to network/offline conditions**.

### Role in the system

- Specifies:
  - How `/rpc/get_cues`, `/rpc/shuffle_cues`, and `/rpc/update_cue_stage` are used.
  - Cue domain models, repositories, and use cases.
  - ViewModel patterns and states for lists/detail.
  - Caching, pagination/shuffle behavior, and analytics hooks.

---

## 1. Endpoints & models

### 1.1 Endpoints

- `/rpc/get_cues`
  - Inputs: `profile_id`, `count`.
  - Returns: list of cues for active profile.

- `/rpc/shuffle_cues`
  - Inputs: `profile_id`, `count`.
  - Returns: random cues for variety.

- `/rpc/update_cue_stage`
  - Inputs: `cue_id`, `stage` (backend enum).
  - Updates cue progress/status.

### 1.2 Models

- DTOs:
  - `CueDTO` — matches backend fields exactly (including any display labels, tags, markdown fields).

- Domain:
  - `Cue` — simplified model for UI:
    - `id`, `title`, `details`, `languageCode`, optional metadata.
    - May also carry backend‑provided display hints (badge labels, CTA labels, etc.).

---

## 2. CueRepository & use cases

### 2.1 CueRepository

- `protocol CueRepository`:
  - `func fetchCues(profileId: Int64, count: Int) async throws -> [Cue]`
  - `func shuffleCues(profileId: Int64, count: Int) async throws -> [Cue]`
  - `func updateCueStage(cueId: Int64, stage: CueStage) async throws`

- Implementation:
  - Uses `APIClient` endpoints and DTOs.
  - Performs minimal mapping from DTO → `Cue`.
  - Does **not** invent additional semantics; leaves ordering, selection, and stage statuses to backend.

### 2.2 Use cases

- `LoadInitialCuesUseCase`:
  - Ensures an active profile is present (via Account/Profile use cases).
  - Reads default `count` from `RuntimeConfig`.
  - Uses `CueRepository.fetchCues`.
  - Applies caching rules (see below).

- `ShuffleCuesUseCase`:
  - Same pattern but calls `shuffleCues`.
  - Honors backend‑driven cooldowns (if present in payload or via config).

- `UpdateCueStageUseCase`:
  - Posts stage updates to `/rpc/update_cue_stage`.
  - Supports optimistic UI updates when safe.

---

## 3. ViewModels & view state

### 3.1 Cue list screen

- `CuesViewModel` (or `HomeViewModel`):
  - State:
    - `state: ViewState<[Cue]>` (idle/loading/loaded/empty/error).
    - Optional `isShuffling` and `isRefreshing` flags.
    - Optional `practiceSessionId` for analytics and recording tie‑in.
  - Intents:
    - `loadInitial()`
    - `refresh()`
    - `shuffle()`
    - `selectCue(_:)` → coordinator navigation to detail.

- Behavior:
  - On first appear (`.task`), call `loadInitial()`.
  - Expose skeleton state while loading.
  - On shuffle:
    - Show loading indicator for shuffle operation.
    - Respect backend cooldowns and disable button when not allowed.

### 3.2 Cue detail screen

- `CueDetailViewModel`:
  - Input: a `Cue` (or ID and a repository for lazy fetch).
  - State:
    - `cue: Cue`
    - `recordingState` placeholder (not yet implemented).
    - Optional `evaluation` placeholder for future AI feedback.
  - Intents:
    - `markStage(stage:)` via `UpdateCueStageUseCase`.
    - `startRecording()` stub that will later call into `RecordingSessionController`.

---

## 4. Rendering & backend‑driven behavior

- Client renders:
  - Titles, details, badges, and CTA labels as provided by backend.
  - Markdown/rich text using safe subset of markdown; fallback to plain text on parse failure.

- Client does **not**:
  - Decide which cues to show or in which order beyond what backend returns.
  - Recompute stages or filter out cues based on ad‑hoc rules.
  - Hardcode stage names; uses backend text or localization keys.

---

## 5. Caching & offline readiness

- Cache strategy:
  - Cache last successful cue list per `profileId` + `languageCode`.
  - Use `Core/Storage` to persist small JSON snapshots with file protection.
  - On startup:
    - Load cached cues immediately for fast UI.
    - Trigger background refresh; update UI when fresh data arrives.

- Offline behavior:
  - If network failures occur, show cached cues with `isStale` indicator if possible.
  - Provide explicit retry control.
  - If no cache exists and network fails, show a well‑phrased empty/error state with a retry option.

---

## 6. Analytics & diagnostics

- Emit events via analytics facade for:
  - `cues.initial_load` (with duration, success/failure).
  - `cues.shuffle` (including count and whether from offline cache).
  - `cues.detail_opened` (anon cue ID, not text).

- Network diagnostics:
  - `NetworkLogger` automatically records relevant calls.
  - Developer console can filter on `get_cues` and `shuffle_cues`.

---

## 7. Future recording & history integration

- `Cue` model:
  - Reserve fields to attach recording and evaluation results later (e.g., optional `recordingInfo`).

- `CueDetailView`:
  - Shows a **disabled** recording CTA with clear “coming soon” copy until recording scaffold is enabled.
  - Once the flag `.recordingScaffoldEnabled` is on, call into `RecordingSessionController` via a dedicated use case.

- History:
  - Future `History` feature will associate completed recordings with cues via IDs and timestamps.
  - Keep `practiceSessionId` in mind so analytics and history can tie events together.

---

## 8. Action checklist

- [ ] `CueRepository` abstracts all cue RPCs and uses `APIClient`.
- [ ] `CuesViewModel` and `CueDetailViewModel` expose clear view states and intents, using use cases exclusively.
- [ ] Cue list and detail views use design system components (cards, typography, spacing).
- [ ] Caching and offline behaviors are implemented as described.
- [ ] Analytics events are wired for cue loads, shuffles, and detail opens.
- [ ] Recording and history integrations are scaffolded but safely disabled until backend support exists.


