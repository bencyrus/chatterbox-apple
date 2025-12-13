import Foundation

/// Decorator for RecordingRepository that adds caching layer.
///
/// Caches recording history and cue recordings to reduce network calls.
/// Upload operations always go to remote (no caching).
final class CachedRecordingRepository: RecordingRepository {
    private let remote: RecordingRepository
    private let cache: CacheManager
    private let cacheTTL: TimeInterval
    
    /// Initialize cached repository
    /// - Parameters:
    ///   - remote: The underlying repository to fetch from
    ///   - cache: Cache manager for storage
    ///   - cacheTTL: Time-to-live for cache entries in seconds (default: 180 = 3 minutes)
    init(
        remote: RecordingRepository,
        cache: CacheManager,
        cacheTTL: TimeInterval = 180
    ) {
        self.remote = remote
        self.cache = cache
        self.cacheTTL = cacheTTL
    }
    
    func fetchProfileRecordingHistory(profileId: Int64) async throws -> RecordingHistoryResponse {
        let cacheKey = "recording_history_\(profileId)"
        
        // Try cache first
        if let cached: CachedResponse<RecordingHistoryResponse> = try? cache.retrieve(forKey: cacheKey),
           !cached.isExpired(ttl: cacheTTL) {
            return cached.value
        }
        
        // Fetch from remote
        let response = try await remote.fetchProfileRecordingHistory(profileId: profileId)
        
        // Cache result
        let cachedResponse = CachedResponse(value: response, timestamp: Date())
        try? cache.store(cachedResponse, forKey: cacheKey)
        
        return response
    }
    
    func fetchCueWithRecordings(profileId: Int64, cueId: Int64) async throws -> (cue: CueWithRecordings?, processedFiles: [ProcessedFile]) {
        let cacheKey = "cue_recordings_\(profileId)_\(cueId)"
        
        // Try cache first - cache the response tuple
        if let cached: CachedResponse<CueWithRecordingsResponse> = try? cache.retrieve(forKey: cacheKey),
           !cached.isExpired(ttl: cacheTTL) {
            return (cue: cached.value.cue, processedFiles: cached.value.processedFiles ?? [])
        }
        
        // Fetch from remote
        let result = try await remote.fetchCueWithRecordings(profileId: profileId, cueId: cueId)
        
        // Cache result - wrap tuple in response object for caching
        let response = CueWithRecordingsResponse(
            cue: result.cue,
            files: [], // Not used for caching
            processedFiles: result.processedFiles
        )
        let cachedResponse = CachedResponse(value: response, timestamp: Date())
        try? cache.store(cachedResponse, forKey: cacheKey)
        
        return result
    }
    
    // MARK: - Write Operations (No Caching)
    
    func createRecordingUploadIntent(profileId: Int64, cueId: Int64) async throws -> CreateRecordingUploadIntentResponse {
        // Always fetch fresh intent
        let intent = try await remote.createRecordingUploadIntent(profileId: profileId, cueId: cueId)
        
        // Invalidate related caches since new recording will be created
        invalidateRecordingCaches(profileId: profileId, cueId: cueId)
        
        return intent
    }
    
    func uploadRecording(to url: URL, fileURL: URL) async throws {
        // No caching for uploads
        try await remote.uploadRecording(to: url, fileURL: fileURL)
    }
    
    func completeRecordingUpload(uploadIntentId: Int64, metadata: [String: String]?) async throws -> CompleteRecordingUploadResponse {
        // No caching for completion
        let response = try await remote.completeRecordingUpload(uploadIntentId: uploadIntentId, metadata: metadata)
        
        // Clear all recording caches since we don't know which profile/cue this affects
        cache.clear()
        
        return response
    }
    
    // MARK: - Cache Invalidation
    
    /// Invalidate caches related to recordings
    private func invalidateRecordingCaches(profileId: Int64, cueId: Int64? = nil) {
        // Invalidate history cache
        cache.remove(forKey: "recording_history_\(profileId)")
        
        // Invalidate specific cue cache if provided
        if let cueId {
            cache.remove(forKey: "cue_recordings_\(profileId)_\(cueId)")
        }
    }
    
    /// Clear all recording caches
    func clearAllCaches() {
        cache.clear()
    }
}
