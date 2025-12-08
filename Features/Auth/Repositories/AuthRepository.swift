import Foundation

protocol AuthRepository {
    func requestMagicLink(identifier: String) async throws -> AuthTokens?
    func loginWithMagicToken(token: String) async throws -> AuthTokens
}

public enum AuthError: Error, Equatable {
    case invalidMagicLink
}

final class PostgrestAuthRepository: AuthRepository {
    private let client: APIClient
    private let environment: Environment

    init(client: APIClient, environment: Environment) {
        self.client = client
        self.environment = environment
    }

    func requestMagicLink(identifier: String) async throws -> AuthTokens? {
        // Check if this is the reviewer account
        if let reviewerEmail = environment.reviewerEmail,
           identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == reviewerEmail.lowercased() {
            // Use the reviewer login endpoint that returns tokens immediately
            let endpoint = AuthEndpoints.ReviewerLogin()
            let body = RequestMagicLinkBody(identifier: identifier)
            let response = try await client.send(endpoint, body: body)
            return AuthTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        }
        
        // Normal magic link flow
        let endpoint = AuthEndpoints.RequestMagicLink()
        let body = RequestMagicLinkBody(identifier: identifier)
        _ = try await client.send(endpoint, body: body)
        return nil
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

