import Foundation

protocol AuthRepository {
    func requestMagicLink(identifier: String) async throws
    func loginWithMagicToken(token: String) async throws -> AuthTokens
}

public enum AuthError: Error, Equatable {
    case invalidMagicLink
}

final class PostgrestAuthRepository: AuthRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func requestMagicLink(identifier: String) async throws {
        let endpoint = AuthEndpoints.RequestMagicLink()
        let body = RequestMagicLinkBody(identifier: identifier)
        _ = try await client.send(endpoint, body: body)
    }

    func loginWithMagicToken(token: String) async throws -> AuthTokens {
        let endpoint = AuthEndpoints.LoginWithMagicToken()
        let body = AuthEndpoints.LoginWithMagicToken.Body(token: token)
        do {
            let response = try await client.send(endpoint, body: body)
            return AuthTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        } catch {
            if case NetworkError.requestFailedWithBody(_, let responseBody) = error,
               responseBody.contains("\"hint\":\"invalid_magic_link\"") || responseBody.contains("invalid_magic_link") {
                throw AuthError.invalidMagicLink
            }
            throw error
        }
    }
}

