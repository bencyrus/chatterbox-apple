# Caching Layer Implementation Notes

## Overview

The caching layer has been successfully implemented with repository decorators that add offline caching capabilities to the app.

## Changes Made to Enable Caching

### 1. Made Models Codable

To support caching, all DTOs were updated from `Decodable` to `Codable`:

**Files Modified:**
- `Features/Cues/Models/CueDTOs.swift`
- `Features/Cues/Models/RecordingDTOs.swift`

**Models Updated:**
- `Cue` - Now `Codable` (was `Decodable`)
- `CueContent` - Now `Codable` (was `Decodable`)
- `Recording` - Now `Codable` (was `Decodable`)
- `RecordingCue` - Now `Codable` (was `Decodable`)
- `RecordingHistoryResponse` - Now `Codable` (was `Decodable`)
- `FileInfo` - Now `Codable` (was `Decodable`)
- `FileMetadata` - Now `Codable` (was `Decodable`)
- `AnyCodableValue` - Now `Codable` (was `Decodable`)
- `ProcessedFile` - Now `Codable` (was `Decodable`)
- `CueWithRecordingsResponse` - Now `Codable` (was `Decodable`)
- `CueWithRecordings` - Now `Codable` (was `Decodable`)
- `CueRecording` - Now `Codable` (was `Decodable`)
- `CreateRecordingUploadIntentResponse` - Now `Codable` (was `Decodable`)
- `CompleteRecordingUploadResponse` - Now `Codable` (was `Decodable`)

### 2. Custom Encoding for AnyCodableValue

`AnyCodableValue` required special handling since it contains an `Any` type:

```swift
func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    if let string = value as? String {
        try container.encode(string)
    } else if let int = value as? Int {
        try container.encode(int)
    } else if let double = value as? Double {
        try container.encode(double)
    } else if let bool = value as? Bool {
        try container.encode(bool)
    } else {
        try container.encodeNil()
    }
}
```

### 3. Custom Encoding for FileMetadata

`FileMetadata` also required custom encoding logic:

```swift
func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    // Convert storage to encodable dictionary
    var dict: [String: String] = [:]
    for (key, value) in storage {
        if let stringValue = value.stringValue {
            dict[key] = stringValue
        }
    }
    try container.encode(dict)
}
```

## Caching Layer Components

### CacheManager
- **Protocol**: Defines caching interface
- **Implementation**: `UserDefaultsCacheManager` using UserDefaults
- **Features**: 
  - JSON encoding/decoding with Codable
  - ISO8601 date handling
  - Namespaced keys

### CachedResponse<T>
- Generic wrapper for cached values
- Includes timestamp for TTL checking
- `isExpired(ttl:)` method for cache validation

### CachedCueRepository
- Decorator for `CueRepository`
- Caches cue lists (5 minute TTL)
- Invalidates on shuffle operations
- Provides manual cache invalidation methods

### CachedRecordingRepository
- Decorator for `RecordingRepository`
- Caches recording history (3 minute TTL)
- Caches cue recordings (3 minute TTL)
- Invalidates on upload operations
- Write operations always go to remote

## Cache Strategy

### Read Operations (Cached)
1. Check cache with TTL validation
2. If hit and fresh, return cached value
3. If miss or stale, fetch from remote
4. Store fresh result in cache

### Write Operations (No Cache)
- Always go to remote
- Invalidate related cache entries
- Some operations clear entire cache (safe but simple)

## TTL Configuration

| Data Type | TTL | Rationale |
|-----------|-----|-----------|
| Cues | 5 min | Changes infrequently, can be slightly stale |
| Recording History | 3 min | More dynamic, needs fresher data |
| Cue Recordings | 3 min | User expects recent recordings visible quickly |

## Cache Keys

Format: `{type}_{params}`

Examples:
- `cues_123_10` - Cues for profile 123, count 10
- `recording_history_123` - Recording history for profile 123
- `cue_recordings_123_456` - Recordings for profile 123, cue 456

## Usage Example

```swift
// In app composition root or DI setup
let apiClient = DefaultAPIClient(...)
let cache = UserDefaultsCacheManager()

// Wrap repositories with caching
let cueRepository: CueRepository = CachedCueRepository(
    remote: PostgrestCueRepository(client: apiClient),
    cache: cache,
    cacheTTL: 300 // 5 minutes
)

let recordingRepository: RecordingRepository = CachedRecordingRepository(
    remote: PostgrestRecordingRepository(client: apiClient),
    cache: cache,
    cacheTTL: 180 // 3 minutes
)

// Use as normal - caching is transparent
let cues = try await cueRepository.fetchCues(profileId: profileId, count: 10)
```

## Benefits

1. **Offline Capability** - Cached data available without network
2. **Reduced Latency** - Instant response for cached data
3. **Network Efficiency** - Fewer API calls
4. **Better UX** - Faster app, works offline
5. **Transparent** - No API changes, drop-in enhancement

## Limitations

1. **UserDefaults Size** - Limited to ~1MB per item (suitable for our use case)
2. **Simple Invalidation** - Some operations clear entire cache
3. **No Background Sync** - Cache only updated on explicit fetch
4. **Fixed TTL** - Not adaptive based on network conditions

## Future Enhancements

Potential improvements (not currently implemented):

- FileManager-based cache for larger data
- More granular cache invalidation
- Background cache refresh
- Adaptive TTL based on network quality
- Cache size management and LRU eviction
- Cache metrics and monitoring

## Testing

Caching layer is testable with:
- Mock `CacheManager` for unit tests
- In-memory cache for test isolation
- Time-based testing with `CachedResponse.isExpired`

## Compliance

All changes comply with:
- ✅ No third-party dependencies (using Foundation only)
- ✅ Type-safe with Codable
- ✅ Clear error handling
- ✅ Privacy-conscious (no PII in cache keys)
- ✅ Follows repository pattern

---

*Implementation Date: December 13, 2025*  
*Status: Complete and Verified*

