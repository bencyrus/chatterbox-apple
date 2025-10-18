import Foundation

protocol AuthRepository {
    func requestMagicLink(identifier: String) async throws
    func loginWithMagicToken(token: String) async throws -> AuthTokens
}

final class PostgrestAuthRepository: AuthRepository {
    private let client: HTTPClient
    private let env: AppEnvironment

    init(client: HTTPClient, environment: AppEnvironment) {
        self.client = client
        self.env = environment
    }

    func requestMagicLink(identifier: String) async throws {
        let body = RequestMagicLinkBody(identifier: identifier)
        _ = try await client.postJSON(path: env.requestMagicLinkPath, body: body)
    }

    func loginWithMagicToken(token: String) async throws -> AuthTokens {
        struct LoginWithMagicTokenBody: Encodable { let token: String }
        let (data, _) = try await client.postJSON(path: env.loginWithMagicTokenPath, body: LoginWithMagicTokenBody(token: token))
        let decoded = try JSONDecoder().decode(LoginWithMagicTokenResponse.self, from: data)
        return AuthTokens(accessToken: decoded.access_token, refreshToken: decoded.refresh_token)
    }
}


