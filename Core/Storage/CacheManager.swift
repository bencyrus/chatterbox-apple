import Foundation

/// Protocol for caching Codable values with expiration support.
protocol CacheManager {
    /// Store a value for a given key
    func store<T: Codable>(_ value: T, forKey key: String) throws
    
    /// Retrieve a value for a given key
    func retrieve<T: Codable>(forKey key: String) throws -> T?
    
    /// Remove a value for a given key
    func remove(forKey key: String)
    
    /// Clear all cached values
    func clear()
}

/// UserDefaults-based cache implementation for simple data caching.
///
/// Note: This is suitable for small-to-medium data sizes (< 1MB per item).
/// For larger data, consider using FileManager-based caching.
final class UserDefaultsCacheManager: CacheManager {
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let cachePrefix = "com.chatterbox.cache"
    
    init(
        defaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
        
        // Configure date handling
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func store<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try encoder.encode(value)
        defaults.set(data, forKey: cacheKey(for: key))
    }
    
    func retrieve<T: Codable>(forKey key: String) throws -> T? {
        guard let data = defaults.data(forKey: cacheKey(for: key)) else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }
    
    func remove(forKey key: String) {
        defaults.removeObject(forKey: cacheKey(for: key))
    }
    
    func clear() {
        let dictionary = defaults.dictionaryRepresentation()
        for key in dictionary.keys where key.hasPrefix(cachePrefix) {
            defaults.removeObject(forKey: key)
        }
    }
    
    private func cacheKey(for key: String) -> String {
        return "\(cachePrefix).\(key)"
    }
}

// MARK: - Cached Response Wrapper

/// Wraps a cached value with timestamp for expiration checking.
struct CachedResponse<T: Codable>: Codable {
    let value: T
    let timestamp: Date
    
    /// Check if the cached response has expired based on TTL
    func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

