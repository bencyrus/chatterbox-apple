import Foundation

// MARK: - Repository Protocol

protocol RecordingRepository {
    func fetchProfileRecordingHistory(profileId: Int64) async throws -> RecordingHistoryResponse
    func fetchCueWithRecordings(profileId: Int64, cueId: Int64) async throws -> (cue: CueWithRecordings?, processedFiles: [ProcessedFile])
    func createRecordingUploadIntent(profileId: Int64, cueId: Int64) async throws -> CreateRecordingUploadIntentResponse
    func uploadRecording(to url: URL, fileURL: URL) async throws
    func completeRecordingUpload(uploadIntentId: Int64, metadata: [String: String]?) async throws -> CompleteRecordingUploadResponse
}

// MARK: - Postgrest Implementation

final class PostgrestRecordingRepository: RecordingRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchProfileRecordingHistory(profileId: Int64) async throws -> RecordingHistoryResponse {
        let endpoint = RecordingEndpoints.GetProfileRecordingHistory()
        let body = RecordingEndpoints.GetProfileRecordingHistory.Body(profileId: profileId)
        return try await client.send(endpoint, body: body)
    }

    func fetchCueWithRecordings(profileId: Int64, cueId: Int64) async throws -> (cue: CueWithRecordings?, processedFiles: [ProcessedFile]) {
        let endpoint = RecordingEndpoints.GetCueForProfile()
        let body = RecordingEndpoints.GetCueForProfile.Body(profileId: profileId, cueId: cueId)
        let response = try await client.send(endpoint, body: body)
        return (cue: response.cue, processedFiles: response.processedFiles ?? [])
    }
    
    func createRecordingUploadIntent(profileId: Int64, cueId: Int64) async throws -> CreateRecordingUploadIntentResponse {
        let endpoint = RecordingEndpoints.CreateRecordingUploadIntent()
        let body = RecordingEndpoints.CreateRecordingUploadIntent.Body(
            profileId: profileId,
            cueId: cueId,
            mimeType: "audio/mp4"
        )
        return try await client.send(endpoint, body: body)
    }
    
    func uploadRecording(to url: URL, fileURL: URL) async throws {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw NSError(
                domain: "RecordingUpload",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Recording file not found"]
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("audio/mp4", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // 60 second timeout for upload
        
        do {
            let (_, response) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(
                    domain: "RecordingUpload",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"]
                )
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NSError(
                    domain: "RecordingUpload",
                    code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Upload failed with status code \(httpResponse.statusCode)"
                    ]
                )
            }
        } catch {
            // Re-throw with more context
            throw NSError(
                domain: "RecordingUpload",
                code: (error as NSError).code,
                userInfo: [
                    NSLocalizedDescriptionKey: "Upload error: \(error.localizedDescription)",
                    NSUnderlyingErrorKey: error
                ]
            )
        }
    }
    
    func completeRecordingUpload(uploadIntentId: Int64, metadata: [String: String]?) async throws -> CompleteRecordingUploadResponse {
        let endpoint = RecordingEndpoints.CompleteRecordingUpload()
        let body = RecordingEndpoints.CompleteRecordingUpload.Body(
            uploadIntentId: uploadIntentId,
            metadata: metadata
        )
        return try await client.send(endpoint, body: body)
    }
}


