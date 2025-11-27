Status: current  
Last verified: 2025-11-27

## 08 — Recording & History Scaffold

### Why this exists

- Design a **future‑ready** audio recording and history system that:
  - Respects privacy and platform constraints.
  - Integrates cleanly with cues and analytics.
  - Can be implemented incrementally as backend support arrives.

### Role in the system

- Specifies:
  - AVFoundation usage and audio session configuration.
  - File storage, protection, and upload strategy.
  - Recording and history domain models.
  - Feature flags and scaffolding patterns until endpoints exist.

---

## 1. Scope & assumptions

- Current swagger has **no recording endpoints**; client must:
  - Prepare architecture and UI scaffolding.
  - Keep recording disabled behind feature flags until backend is ready.
- Recording is primarily tied to cue practice; one or more recordings may be associated with a cue and evaluation in future.

---

## 2. Core recording services

### 2.1 RecordingSessionController

- `Core/Audio/RecordingSessionController` (actor or class with internal actor):
  - Responsibilities:
    - Manage `AVAudioSession` category, mode, and activation.
    - Request microphone permission with a clear, localized rationale.
    - Create and manage `AVAudioRecorder` (or `AVAudioEngine` later if needed).
    - Produce recording files and metadata (duration, cue association, timestamps).
  - Public API (scaffold):
    - `func prepareForRecording() async throws`
    - `func startRecording(for cueId: Int64) async throws -> RecordingHandle`
    - `func stopRecording() async throws -> RecordingResult`
    - `func discardRecording() async`

- Audio session configuration:
  - Category: `.playAndRecord`.
  - Mode: `.measurement` (for raw voice quality) or `.voiceChat` (for echo‑cancelled voice).
  - Options: `.defaultToSpeaker` where appropriate.

### 2.2 Permissions

- Microphone permission:
  - Info.plist must include `NSMicrophoneUsageDescription` describing how audio is used.
  - Permission requests:
    - Triggered only in direct response to user action (e.g., tapping a Record button).
    - If denied, show a friendly, localized message guiding user to Settings.

---

## 3. Storage & file handling

- `Core/Storage/RecordingsDirectoryProvider`:
  - Provides paths for recording files:
    - Temporary in‑progress recordings (e.g. `tmp/`).
    - Saved recordings (e.g. `Library/Application Support/Recordings/`).
  - Enforces:
    - File protection type `.complete` or `.completeUntilFirstUserAuthentication`.
    - Sanitized filenames (e.g., `cue-<id>-<timestamp>.m4a`).

- File format:
  - AAC (`kAudioFormatMPEG4AAC`) in `.m4a` container.
  - 44.1kHz or 48kHz, mono, medium bit rate.

- Cleanup:
  - On discard: delete temporary file.
  - On logout: consider deleting user‑specific recordings if required by product/privacy.

---

## 4. Upload & evaluation pipeline (future)

- Upload:
  - Use a background `URLSession` configuration for robustness (`background(withIdentifier:)`) once endpoints exist.
  - For now, stub repository methods to return `.unsupported` so callers can compile.

- Evaluation:
  - Once backend or on‑device ML is available:
    - `RecordingRepository` will:
      - Upload recording.
      - Poll or receive callback for evaluation results.
    - `EvaluationResult` will be attached to practice history and possibly displayed in cue detail.

---

## 5. History models & repository

- Domain models:
  - `Recording`:
    - `id`
    - `cueId`
    - `fileURL`
    - `duration`
    - `createdAt`
  - `PracticeSession`:
    - `id`
    - `cueId`
    - `recordingId`
    - `evaluation` (optional, future).

- Storage:
  - Use SwiftData or other persistence (e.g., SQLite/GRDB) to store history records.
  - Accessed via `HistoryRepository` with methods like `listHistory(for cueId:)`.

---

## 6. UI integration & feature flags

- Cue detail:
  - Shows recording CTA only if:
    - Feature flag `.recordingScaffoldEnabled` is true, AND
    - Any required backend flags/settings also allow it (from `/rpc/app_config`).
  - When disabled:
    - Show a subtle “Recording coming soon” indicator or hide CTA entirely.

- Recording screens:
  - Use clear indicators for “recording”, “paused”, “stopped”.
  - Provide ability to play back the recording before uploading (when implemented).

- History screens:
  - Future feature; scaffolding in `Features/History` for now:
    - Placeholder views referencing this document.

---

## 7. Threat model & privacy notes

- Consider:
  - Unauthorized access to stored audio files.
  - Interception of audio in transit.
  - Retention policies for recordings and evaluations.

- Requirements:
  - Use iOS data protection (file protection attributes) for recordings at rest.
  - Use HTTPS for all uploads.
  - Never log raw audio data or transcripts.
  - Provide users a clear path to delete recordings/history when product is ready.

---

## 8. Action checklist

- [ ] `RecordingSessionController` is implemented with safe scaffolding APIs (may return `.unsupported` until endpoints exist).
- [ ] `RecordingsDirectoryProvider` and associated storage utilities are in place with proper file protection.
- [ ] Recording UI is present but gated behind feature flags until backend support is added.
- [ ] Threat considerations and privacy implications are documented for future recording and history features.
- [ ] Tests cover basic controller lifecycle and permission handling, even if full recording is not yet enabled.


