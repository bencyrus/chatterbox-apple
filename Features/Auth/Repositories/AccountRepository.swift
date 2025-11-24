import Foundation

protocol AccountRepository {
    func fetchMe() async throws -> MeResponse
    func fetchAppConfig() async throws -> AppConfigResponse
    func setActiveProfile(accountId: Int64, languageCode: String) async throws
}

enum AccountError: Error, Equatable {
    case requestFailed
    case invalidResponse
}

final class PostgrestAccountRepository: AccountRepository {
    private let client: HTTPClient
    private let env: AppEnvironment

    init(client: HTTPClient, environment: AppEnvironment) {
        self.client = client
        self.env = environment
    }

    func fetchMe() async throws -> MeResponse {
        let (data, _) = try await client.getJSON(path: env.mePath)
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(MeResponse.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    func fetchAppConfig() async throws -> AppConfigResponse {
        let (data, _) = try await client.getJSON(path: env.appConfigPath)
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(AppConfigResponse.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    func setActiveProfile(accountId: Int64, languageCode: String) async throws {
        struct Body: Encodable {
            let account_id: Int64
            let language_code: String
        }
        _ = try await client.postJSON(path: env.setActiveProfilePath, body: Body(account_id: accountId, language_code: languageCode))
    }
}


