import Foundation

protocol AccountRepository {
    func fetchMe() async throws -> MeResponse
    func fetchAppConfig() async throws -> AppConfigResponse
    func setActiveProfile(accountId: Int64, languageCode: String) async throws
    func getOrCreateProfile(accountId: Int64, languageCode: String) async throws -> Int64
    func requestAccountDeletion(accountId: Int64) async throws
}

enum AccountError: Error, Equatable {
    case requestFailed
    case invalidResponse
}

final class PostgrestAccountRepository: AccountRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchMe() async throws -> MeResponse {
        let endpoint = AccountEndpoints.Me()
        return try await client.send(endpoint, body: EmptyRequestBody())
    }

    func fetchAppConfig() async throws -> AppConfigResponse {
        let endpoint = AccountEndpoints.AppConfig()
        return try await client.send(endpoint, body: EmptyRequestBody())
    }

    func setActiveProfile(accountId: Int64, languageCode: String) async throws {
        let endpoint = AccountEndpoints.SetActiveProfile()
        let body = AccountEndpoints.SetActiveProfile.Body(
            accountId: accountId,
            languageCode: languageCode
        )
        _ = try await client.send(endpoint, body: body)
    }
    
    func getOrCreateProfile(accountId: Int64, languageCode: String) async throws -> Int64 {
        let endpoint = AccountEndpoints.GetOrCreateProfile()
        let body = AccountEndpoints.GetOrCreateProfile.Body(
            accountId: accountId,
            languageCode: languageCode
        )
        let response = try await client.send(endpoint, body: body)
        return response.profileId
    }

    func requestAccountDeletion(accountId: Int64) async throws {
        let endpoint = AccountEndpoints.RequestAccountDeletion()
        let body = AccountEndpoints.RequestAccountDeletion.Body(accountId: accountId)
        _ = try await client.send(endpoint, body: body)
    }
}


