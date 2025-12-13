import Foundation

struct Cue: Codable, Equatable {
    let cueId: Int64
    let stage: String
    let createdAt: String
    let createdBy: Int64
    let content: CueContent
    let recordings: [CueRecording]?
    
    enum CodingKeys: String, CodingKey {
        case cueId, stage, createdAt, createdBy, content, recordings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cueId = try container.decode(Int64.self, forKey: .cueId)
        stage = try container.decode(String.self, forKey: .stage)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        createdBy = try container.decode(Int64.self, forKey: .createdBy)
        content = try container.decode(CueContent.self, forKey: .content)
        recordings = try container.decodeIfPresent([CueRecording].self, forKey: .recordings)
    }
    
    init(cueId: Int64, stage: String, createdAt: String, createdBy: Int64, content: CueContent, recordings: [CueRecording]? = nil) {
        self.cueId = cueId
        self.stage = stage
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.content = content
        self.recordings = recordings
    }
}

struct CueContent: Codable, Equatable {
    let cueContentId: Int64
    let cueId: Int64
    let title: String
    let details: String
    let languageCode: String
    let createdAt: String
}


