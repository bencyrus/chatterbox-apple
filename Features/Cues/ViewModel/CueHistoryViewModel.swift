import Foundation
import Observation

@MainActor
@Observable
final class CueHistoryViewModel {
    private let recordingRepository: RecordingRepository
    private let activeProfileHelper: ActiveProfileHelper

    private(set) var cue: CueWithRecordings?
    private(set) var processedFiles: [ProcessedFile] = []

    var isLoading: Bool = false
    var errorMessage: String? = nil

    init(
        recordingRepository: RecordingRepository,
        activeProfileHelper: ActiveProfileHelper
    ) {
        self.recordingRepository = recordingRepository
        self.activeProfileHelper = activeProfileHelper
    }

    func load(cueId: Int64) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await activeProfileHelper.ensureActiveProfile()
            let result = try await recordingRepository.fetchCueWithRecordings(
                profileId: profile.profileId,
                cueId: cueId
            )
            cue = result.cue
            processedFiles = result.processedFiles
            errorMessage = nil
        } catch {
            cue = nil
            processedFiles = []
            errorMessage = "Couldn't load history"
        }
    }
}

