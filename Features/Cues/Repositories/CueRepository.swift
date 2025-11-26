import Foundation

protocol CueRepository {
    func fetchCues(profileId: Int64, count: Int) async throws -> [Cue]
    func shuffleCues(profileId: Int64, count: Int) async throws -> [Cue]
}

enum CueError: Error, Equatable {
    case requestFailed
    case invalidResponse
}

final class PostgrestCueRepository: CueRepository {
    private let client: HTTPClient
    private let env: AppEnvironment

    init(client: HTTPClient, environment: AppEnvironment) {
        self.client = client
        self.env = environment
    }

    func fetchCues(profileId: Int64, count: Int) async throws -> [Cue] {
        struct Body: Encodable {
            let profile_id: Int64
            let count: Int
        }

        let (data, _) = try await client.postJSON(
            path: env.getCuesPath,
            body: Body(profile_id: profileId, count: count)
        )
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([Cue].self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    func shuffleCues(profileId: Int64, count: Int) async throws -> [Cue] {
        struct Body: Encodable {
            let profile_id: Int64
            let count: Int
        }

        let (data, _) = try await client.postJSON(
            path: env.shuffleCuesPath,
            body: Body(profile_id: profileId, count: count)
        )
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([Cue].self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}


