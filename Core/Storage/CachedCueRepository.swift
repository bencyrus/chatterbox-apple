import Foundation

/// Decorator for CueRepository that adds caching layer.
///
/// Caches successful responses to reduce network calls and improve offline experience.
/// Cache is considered stale after configured TTL.
final class CachedCueRepository: CueRepository {
    private let remote: CueRepository
    private let cache: CacheManager
    private let cacheTTL: TimeInterval
    
    /// Initialize cached repository
    /// - Parameters:
    ///   - remote: The underlying repository to fetch from
    ///   - cache: Cache manager for storage
    ///   - cacheTTL: Time-to-live for cache entries in seconds (default: 300 = 5 minutes)
    init(
        remote: CueRepository,
        cache: CacheManager,
        cacheTTL: TimeInterval = 300
    ) {
        self.remote = remote
        self.cache = cache
        self.cacheTTL = cacheTTL
    }
    
    func fetchCues(profileId: Int64, count: Int) async throws -> [Cue] {
        let cacheKey = "cues_\(profileId)_\(count)"
        
        // Try to retrieve from cache first
        if let cached: CachedResponse<[Cue]> = try? cache.retrieve(forKey: cacheKey),
           !cached.isExpired(ttl: cacheTTL) {
            return cached.value
        }
        
        // Fetch from remote
        let cues = try await remote.fetchCues(profileId: profileId, count: count)
        
        // Store in cache
        let response = CachedResponse(value: cues, timestamp: Date())
        try? cache.store(response, forKey: cacheKey)
        
        return cues
    }
    
    func shuffleCues(profileId: Int64, count: Int) async throws -> [Cue] {
        // Always fetch fresh for shuffle - invalidate existing cache
        let cacheKey = "cues_\(profileId)_\(count)"
        cache.remove(forKey: cacheKey)
        
        // Fetch from remote
        let cues = try await remote.shuffleCues(profileId: profileId, count: count)
        
        // Cache the shuffled result
        let response = CachedResponse(value: cues, timestamp: Date())
        try? cache.store(response, forKey: cacheKey)
        
        return cues
    }
}

// MARK: - Cache Invalidation

extension CachedCueRepository {
    /// Manually invalidate cache for a specific profile
    func invalidateCache(for profileId: Int64) {
        // Note: This is a simple implementation
        // A more sophisticated approach would track all cache keys
        cache.remove(forKey: "cues_\(profileId)_10")
        cache.remove(forKey: "cues_\(profileId)_20")
        cache.remove(forKey: "cues_\(profileId)_50")
    }
    
    /// Clear all caches
    func clearAllCaches() {
        cache.clear()
    }
}

