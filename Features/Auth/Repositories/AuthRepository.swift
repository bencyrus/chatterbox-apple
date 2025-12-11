import Foundation

protocol AuthRepository {
    func requestMagicLink(identifier: String) async throws -> AuthTokens?
    func loginWithMagicToken(token: String) async throws -> AuthTokens
}

public enum AuthError: Error, Equatable {
    case invalidMagicLink
    case accountDeleted(message: String)
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
        do {
            _ = try await client.send(endpoint, body: body)
            return nil
        } catch {
            if case NetworkError.requestFailedWithBody(_, let responseBody) = error {
                if responseBody.contains("\"hint\":\"account_deleted\"") || responseBody.contains("account_deleted") {
                    // Try to surface the backend-provided *details* field so that
                    // we show the full, user-facing explanation (including the
                    // restore URL). Fall back to a generic copy if parsing fails.
                    let message = Self.extractPostgrestUserMessage(from: responseBody)
                        ?? "Your account was deleted. Visit chatterboxtalk.com to contact support to reactivate your account."
                    throw AuthError.accountDeleted(message: message)
                }
            }
            throw error
        }
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

            if case NetworkError.requestFailedWithBody(_, let responseBody) = error,
               responseBody.contains("\"hint\":\"account_deleted\"") || responseBody.contains("account_deleted") {
                let message = Self.extractPostgrestUserMessage(from: responseBody)
                    ?? "Your account was deleted. Visit chatterboxtalk.com to contact support to reactivate your account."
                throw AuthError.accountDeleted(message: message)
            }
            throw error
        }
    }

    /// Best-effort extraction of a user-facing message from a PostgREST-style error body.
    /// Prefers the `"details"` field when present (since it contains the full copy),
    /// otherwise falls back to `"message"`.
    private static func extractPostgrestUserMessage(from responseBody: String) -> String? {
        if let details = extractPostgrestField(named: "details", from: responseBody) {
            return details
        }
        return extractPostgrestField(named: "message", from: responseBody)
    }

    /// Lightweight extraction of a JSON string field (e.g. `"details":"..."`) from the body.
    private static func extractPostgrestField(named field: String, from responseBody: String) -> String? {
        guard let fieldRange = responseBody.range(of: "\"\(field)\"") else {
            return nil
        }

        let sliced = responseBody[fieldRange.upperBound...]
        guard let colonRange = sliced.firstIndex(of: ":") else {
            return nil
        }
        let afterColon = sliced[sliced.index(after: colonRange)...]

        // Expecting a JSON string; look for the first and second quote.
        guard let firstQuote = afterColon.firstIndex(of: "\"") else {
            return nil
        }
        let remainder = afterColon[afterColon.index(after: firstQuote)...]
        guard let secondQuote = remainder.firstIndex(of: "\"") else {
            return nil
        }

        let message = remainder[..<secondQuote]
        return String(message)
    }
}

