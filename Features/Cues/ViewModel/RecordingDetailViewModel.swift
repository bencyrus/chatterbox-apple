import Foundation
import Observation

@MainActor
@Observable
final class RecordingDetailViewModel {
    private let recordingRepository: RecordingRepository
    private let activeProfileHelper: ActiveProfileHelper

    var recording: Recording?
    var processedFiles: [ProcessedFile] = []
    var recordingCountForCue: Int? = nil

    var isLoading: Bool = false
    var errorMessage: String? = nil

    init(
        recordingRepository: RecordingRepository,
        activeProfileHelper: ActiveProfileHelper
    ) {
        self.recordingRepository = recordingRepository
        self.activeProfileHelper = activeProfileHelper
    }

    func setInitial(recording: Recording, processedFiles: [ProcessedFile]) {
        self.recording = recording
        self.processedFiles = processedFiles
        self.errorMessage = nil
    }

    func refreshRecording() async {
        guard let recording else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await activeProfileHelper.ensureActiveProfile()
            let response = try await recordingRepository.fetchProfileRecordingHistory(profileId: profile.profileId)

            processedFiles = response.processedFiles ?? []

            if let updated = response.recordings.first(where: { $0.profileCueRecordingId == recording.profileCueRecordingId }) {
                self.recording = updated
                errorMessage = nil
            } else {
                errorMessage = "Recording not found"
            }
        } catch {
            errorMessage = "Failed to refresh recording"
        }
    }

    func loadRecordingCountForCue(cueId: Int64) async {
        do {
            let profile = try await activeProfileHelper.ensureActiveProfile()
            let result = try await recordingRepository.fetchCueWithRecordings(
                profileId: profile.profileId,
                cueId: cueId
            )
            recordingCountForCue = result.cue?.recordings?.count ?? 0
        } catch {
            recordingCountForCue = 0
        }
    }

    func requestTranscription(profileCueRecordingId: Int64) async {
        do {
            _ = try await recordingRepository.requestTranscription(profileCueRecordingId: profileCueRecordingId)
        } catch {
            // Keep UI simple: the report view already communicates status and retries.
        }

        // Refresh so status updates from .none -> .processing, etc.
        await refreshRecording()
    }
}

