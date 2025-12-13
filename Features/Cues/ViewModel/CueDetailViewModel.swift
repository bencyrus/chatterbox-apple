import Foundation
import Observation

@MainActor
@Observable
final class CueDetailViewModel {
    var isUploading = false
    var uploadError: String?
    var isLoadingRecordings = false
    var recordings: [CueRecording] = []
    var processedFiles: [ProcessedFile] = []
    
    private let recordingRepository: RecordingRepository
    private let activeProfileHelper: ActiveProfileHelper
    
    init(
        recordingRepository: RecordingRepository,
        activeProfileHelper: ActiveProfileHelper
    ) {
        self.recordingRepository = recordingRepository
        self.activeProfileHelper = activeProfileHelper
    }
    
    func loadRecordingsForCue(cueId: Int64) async {
        isLoadingRecordings = true
        defer { isLoadingRecordings = false }
        
        do {
            let activeProfile = try await activeProfileHelper.ensureActiveProfile()
            let result = try await recordingRepository.fetchCueWithRecordings(
                profileId: activeProfile.profileId,
                cueId: cueId
            )
            recordings = result.cue?.recordings ?? []
            processedFiles = result.processedFiles
        } catch {
            print("Failed to load recordings for cue: \(error)")
            recordings = []
            processedFiles = []
        }
    }
    
    func uploadRecording(cueId: Int64, fileURL: URL, cueName: String, duration: TimeInterval) async throws {
        isUploading = true
        uploadError = nil
        defer { isUploading = false }
        
        do {
            let activeProfile = try await activeProfileHelper.ensureActiveProfile()
            
            // 1. Create upload intent
            let intent = try await recordingRepository.createRecordingUploadIntent(
                profileId: activeProfile.profileId,
                cueId: cueId
            )
            
            // 2. Upload file to GCS
            guard let uploadURL = URL(string: intent.uploadUrl) else {
                throw UploadError.invalidUploadURL
            }
            
            try await recordingRepository.uploadRecording(
                to: uploadURL,
                fileURL: fileURL
            )
            
            // 3. Complete upload with metadata
            let durationString = String(format: "%.2f", duration)
            _ = try await recordingRepository.completeRecordingUpload(
                uploadIntentId: intent.uploadIntentId,
                metadata: [
                    "name": cueName,
                    "duration": durationString
                ]
            )
        } catch {
            uploadError = error.localizedDescription
            throw error
        }
    }
}

enum UploadError: Error, LocalizedError {
    case invalidUploadURL
    
    var errorDescription: String? {
        switch self {
        case .invalidUploadURL:
            return "Invalid upload URL received"
        }
    }
}
