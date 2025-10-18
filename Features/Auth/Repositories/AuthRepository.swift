import Foundation

protocol AuthRepository {
    func requestCode(identifier: String) async throws
    func verifyCode(identifier: String, code: String) async throws -> AuthTokens
}

final class PostgrestAuthRepository: AuthRepository {
    private let client: HTTPClient
    private let env: AppEnvironment

    init(client: HTTPClient, environment: AppEnvironment) {
        self.client = client
        self.env = environment
    }

    func requestCode(identifier: String) async throws {
        let body = RequestCodeBody(identifier: identifier)
        _ = try await client.postJSON(path: env.requestLoginCodePath, body: body)
    }

    func verifyCode(identifier: String, code: String) async throws -> AuthTokens {
        let body = VerifyCodeBody(identifier: identifier, code: code)
        let (data, _) = try await client.postJSON(path: env.loginWithCodePath, body: body)
        let decoded = try JSONDecoder().decode(VerifyResponse.self, from: data)
        return AuthTokens(accessToken: decoded.access_token, refreshToken: decoded.refresh_token)
    }
}


