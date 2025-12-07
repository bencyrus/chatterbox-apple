import Foundation

// MARK: - Recording History Response

struct RecordingHistoryResponse: Decodable {
    let recordings: [Recording]
    let files: [Int64]
    let processedFiles: [ProcessedFile]?
}

// MARK: - Recording

struct Recording: Decodable, Identifiable {
    let profileCueRecordingId: Int64
    let profileId: Int64
    let cueId: Int64
    let fileId: Int64
    let createdAt: String
    let file: FileInfo
    let cue: RecordingCue
    
    var id: Int64 { profileCueRecordingId }
}

// MARK: - Recording Cue (simplified cue structure in recording context)

struct RecordingCue: Decodable, Equatable {
    let cueId: Int64
    let stage: String
    let createdAt: String
    let createdBy: Int64
    let content: CueContent
}

// MARK: - File Info

struct FileInfo: Decodable, Equatable {
    let fileId: Int64
    let createdAt: String
    let mimeType: String
    let metadata: FileMetadata
    
    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        lhs.fileId == rhs.fileId &&
        lhs.createdAt == rhs.createdAt &&
        lhs.mimeType == rhs.mimeType
    }
}

// MARK: - File Metadata

struct FileMetadata: Decodable, Equatable {
    private let storage: [String: AnyCodableValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dict = try container.decode([String: AnyCodableValue].self)
        self.storage = dict
    }
    
    subscript(key: String) -> String? {
        storage[key]?.stringValue
    }
    
    var name: String {
        self["name"] ?? ""
    }
    
    var duration: TimeInterval? {
        guard let durationString = self["duration"] else { return nil }
        return Double(durationString)
    }
    
    static func == (lhs: FileMetadata, rhs: FileMetadata) -> Bool {
        // Compare the string representations of the storage
        // Since AnyCodableValue is not Equatable, we compare keys
        lhs.name == rhs.name
    }
}

// MARK: - AnyCodable Helper

struct AnyCodableValue: Decodable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            value = NSNull()
        }
    }
    
    var stringValue: String? {
        value as? String
    }
}

// MARK: - Processed File

struct ProcessedFile: Decodable, Identifiable, Equatable {
    let fileId: Int64
    let url: String
    
    var id: Int64 { fileId }
}

// MARK: - Cue With Recordings Response

struct CueWithRecordingsResponse: Decodable {
    let cue: CueWithRecordings?
    let files: [Int64]
    let processedFiles: [ProcessedFile]?
}

struct CueWithRecordings: Decodable {
    let cueId: Int64
    let stage: String
    let createdAt: String
    let createdBy: Int64
    let content: CueContent
    let recordings: [CueRecording]?
}

struct CueRecording: Decodable, Identifiable, Equatable {
    let profileCueRecordingId: Int64
    let profileId: Int64
    let cueId: Int64
    let fileId: Int64
    let createdAt: String
    let file: FileInfo
    
    var id: Int64 { profileCueRecordingId }
}

// MARK: - Create Recording Upload Intent Response

struct CreateRecordingUploadIntentResponse: Decodable, Equatable {
    let uploadIntentId: Int64
    let uploadUrl: String
}

// MARK: - Complete Recording Upload Response

struct CompleteRecordingUploadResponse: Decodable, Equatable {
    let success: Bool
    let file: FileInfo
    let files: [Int64]
    let processedFiles: [ProcessedFile]
}


