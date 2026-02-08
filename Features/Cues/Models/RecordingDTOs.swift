import Foundation

// MARK: - Recording History Response

struct RecordingHistoryResponse: Codable {
    let recordings: [Recording]
    let files: [Int64]
    let processedFiles: [ProcessedFile]?
}

// MARK: - Report Status

enum ReportStatus: String, Codable {
    case none
    case processing
    case ready
}

// MARK: - Recording Report

struct RecordingReport: Codable, Equatable {
    let status: ReportStatus
    let transcript: String?
}

// MARK: - Recording

struct Recording: Codable, Identifiable {
    let profileCueRecordingId: Int64
    let profileId: Int64
    let cueId: Int64
    let fileId: Int64
    let createdAt: String
    let file: FileInfo
    let cue: RecordingCue
    let report: RecordingReport
    
    var id: Int64 { profileCueRecordingId }
}

// MARK: - Recording Cue (simplified cue structure in recording context)

struct RecordingCue: Codable, Equatable {
    let cueId: Int64
    let stage: String
    let createdAt: String
    let createdBy: Int64
    let content: CueContent
}

// MARK: - File Info

struct FileInfo: Codable, Equatable {
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

struct FileMetadata: Codable, Equatable {
    private let storage: [String: AnyCodableValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dict = try container.decode([String: AnyCodableValue].self)
        self.storage = dict
    }
    
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
    
    subscript(key: String) -> String? {
        storage[key]?.stringValue
    }
    
    var name: String {
        self["name"] ?? ""
    }
    
    var duration: TimeInterval? {
        guard let durationString = self["duration"] else { return nil }
        // Preferred format is numeric seconds (e.g. "8" or "8.5")
        if let seconds = Double(durationString) {
            return seconds
        }

        // Backwards/other-clients: allow "MM:SS" or "HH:MM:SS"
        let parts = durationString.split(separator: ":").map { String($0) }
        guard parts.count == 2 || parts.count == 3 else { return nil }

        func parse(_ s: String) -> Double? { Double(s.trimmingCharacters(in: .whitespaces)) }

        if parts.count == 2,
           let minutes = parse(parts[0]),
           let seconds = parse(parts[1]) {
            return minutes * 60 + seconds
        }

        if parts.count == 3,
           let hours = parse(parts[0]),
           let minutes = parse(parts[1]),
           let seconds = parse(parts[2]) {
            return hours * 3600 + minutes * 60 + seconds
        }

        return nil
    }
    
    static func == (lhs: FileMetadata, rhs: FileMetadata) -> Bool {
        // Compare the string representations of the storage
        // Since AnyCodableValue is not Equatable, we compare keys
        lhs.name == rhs.name
    }
}

// MARK: - AnyCodable Helper

struct AnyCodableValue: Codable {
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
    
    var stringValue: String? {
        if let s = value as? String { return s }
        if let i = value as? Int { return String(i) }
        if let d = value as? Double { return String(d) }
        if let b = value as? Bool { return String(b) }
        return nil
    }
}

// MARK: - Processed File

struct ProcessedFile: Codable, Identifiable, Equatable {
    let fileId: Int64
    let url: String
    
    var id: Int64 { fileId }
}

// MARK: - Cue With Recordings Response

struct CueWithRecordingsResponse: Codable {
    let cue: CueWithRecordings?
    let files: [Int64]
    let processedFiles: [ProcessedFile]?
}

struct CueWithRecordings: Codable {
    let cueId: Int64
    let stage: String
    let createdAt: String
    let createdBy: Int64
    let content: CueContent
    let recordings: [CueRecording]?
}

struct CueRecording: Codable, Identifiable, Equatable {
    let profileCueRecordingId: Int64
    let profileId: Int64
    let cueId: Int64
    let fileId: Int64
    let createdAt: String
    let file: FileInfo
    let report: RecordingReport
    
    var id: Int64 { profileCueRecordingId }
}

// MARK: - Create Recording Upload Intent Response

struct CreateRecordingUploadIntentResponse: Codable, Equatable {
    let uploadIntentId: Int64
    let uploadUrl: String
}

// MARK: - Complete Recording Upload Response

struct CompleteRecordingUploadResponse: Codable, Equatable {
    let success: Bool
    let file: FileInfo
    let files: [Int64]
    let processedFiles: [ProcessedFile]
}

// MARK: - Request Transcription Response

struct TranscriptionRequestResponse: Codable {
    let status: String  // "started", "in_progress", "already_transcribed"
    let recordingTranscriptionTaskId: Int64?
}


