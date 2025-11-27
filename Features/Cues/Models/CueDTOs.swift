import Foundation

struct Cue: Decodable, Equatable {
    let cueId: Int64
    let stage: String
    let createdAt: String
    let createdBy: Int64
    let content: CueContent
}

struct CueContent: Decodable, Equatable {
    let cueContentId: Int64
    let cueId: Int64
    let title: String
    let details: String
    let languageCode: String
    let createdAt: String
}


