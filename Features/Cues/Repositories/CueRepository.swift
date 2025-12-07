import Foundation

protocol CueRepository {
    func fetchCues(profileId: Int64, count: Int) async throws -> [Cue]
    func shuffleCues(profileId: Int64, count: Int) async throws -> [Cue]
}

final class PostgrestCueRepository: CueRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchCues(profileId: Int64, count: Int) async throws -> [Cue] {
        let endpoint = CueEndpoints.GetCues()
        let body = CueEndpoints.GetCues.Body(
            profileId: profileId,
            count: count
        )
        return try await client.send(endpoint, body: body)
    }

    func shuffleCues(profileId: Int64, count: Int) async throws -> [Cue] {
        let endpoint = CueEndpoints.ShuffleCues()
        let body = CueEndpoints.ShuffleCues.Body(
            profileId: profileId,
            count: count
        )
        return try await client.send(endpoint, body: body)
    }
}


