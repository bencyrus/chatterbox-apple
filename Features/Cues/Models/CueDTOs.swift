import Foundation

struct Cue: Decodable, Equatable {
    let cueId: Int64
    let stage: String
    let createdAt: String
    let createdBy: Int64
    let content: CueContent

    private enum CodingKeys: String, CodingKey {
        case cueId = "cue_id"
        case stage
        case createdAt = "created_at"
        case createdBy = "created_by"
        case content
    }
}

struct CueContent: Decodable, Equatable {
    let cueContentId: Int64
    let cueId: Int64
    let title: String
    let details: String
    let languageCode: String
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case cueContentId = "cue_content_id"
        case cueId = "cue_id"
        case title
        case details
        case languageCode = "language_code"
        case createdAt = "created_at"
    }
}


