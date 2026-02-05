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
    private let accountRepository: AccountRepository
    private let activeProfileHelper: ActiveProfileHelper
    private let sessionManager: SessionManager
    
    init(
        recordingRepository: RecordingRepository,
        accountRepository: AccountRepository,
        activeProfileHelper: ActiveProfileHelper,
        sessionManager: SessionManager
    ) {
        self.recordingRepository = recordingRepository
        self.accountRepository = accountRepository
        self.activeProfileHelper = activeProfileHelper
        self.sessionManager = sessionManager
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
    
    func reloadForActiveProfileChange() {
        // Clear cached profile when user switches profiles (e.g., language change in settings)
        activeProfileHelper.clearCache()
    }
    
    func requestTranscription(for profileCueRecordingId: Int64) async {
        do {
            _ = try await recordingRepository.requestTranscription(profileCueRecordingId: profileCueRecordingId)
        } catch {
            print("Failed to request transcription: \(error)")
        }
    }
    
    /// Uploads a recording for a cue, associating it with the profile that matches the cue's language.
    /// - Parameters:
    ///   - cueId: The ID of the cue being recorded
    ///   - languageCode: The language code of the cue (determines which profile to use)
    ///   - fileURL: The local URL of the recorded audio file
    ///   - cueName: The name/title of the cue for metadata
    ///   - duration: The duration of the recording in seconds
    func uploadRecording(cueId: Int64, languageCode: String, fileURL: URL, cueName: String, duration: TimeInterval) async throws {
        isUploading = true
        uploadError = nil
        defer { isUploading = false }
        
        do {
            // Get the account ID from the session
            guard let snapshot = sessionManager.snapshot else {
                throw UploadError.sessionMissing
            }
            let accountId = snapshot.me.account.accountId
            
            // Get or create the profile for the cue's language
            // This ensures recording is associated with the correct language profile
            let profileId = try await accountRepository.getOrCreateProfile(
                accountId: accountId,
                languageCode: languageCode
            )
            
            // 1. Create upload intent with the cue's language profile
            let intent = try await recordingRepository.createRecordingUploadIntent(
                profileId: profileId,
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
    case sessionMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidUploadURL:
            return "Invalid upload URL received"
        case .sessionMissing:
            return "Session not available"
        }
    }
}
