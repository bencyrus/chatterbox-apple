import Foundation
import os

/// HTTP verb.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

/// Strategy for idempotency keys on POST requests.
enum IdempotencyKeyStrategy {
    case none
    case generated
    case custom(String)
}

/// High‑level description of an API endpoint.
protocol APIEndpoint {
    associatedtype RequestBody: Encodable
    associatedtype ResponseBody: Decodable

    var path: String { get }
    var method: HTTPMethod { get }
    var requiresAuth: Bool { get }
    var timeout: TimeInterval { get }
    var idempotencyKeyStrategy: IdempotencyKeyStrategy { get }
}

/// Core HTTP client used by all repositories.
protocol APIClient {
    func send<E: APIEndpoint>(
        _ endpoint: E,
        body: E.RequestBody
    ) async throws -> E.ResponseBody
}

/// Default implementation of `APIClient` backed by `URLSession`.
///
/// This type is intentionally generic and free of feature‑specific concerns;
/// auth, logging, retries, and refresh are handled here so repositories remain
/// thin and focused on mapping DTOs.
final class DefaultAPIClient: APIClient {
    private let environment: Environment
    private let urlSession: URLSession
    private let sessionController: SessionControllerProtocol
    private let configProvider: ConfigProviding
    private let networkLogStore: NetworkLogStoring?

    init(
        environment: Environment,
        urlSession: URLSession = .shared,
        sessionController: SessionControllerProtocol,
        configProvider: ConfigProviding,
        networkLogStore: NetworkLogStoring? = nil
    ) {
        self.environment = environment
        self.urlSession = urlSession
        self.sessionController = sessionController
        self.configProvider = configProvider
        self.networkLogStore = networkLogStore
    }

    func send<E: APIEndpoint>(
        _ endpoint: E,
        body: E.RequestBody
    ) async throws -> E.ResponseBody {
        let request = try await buildRequest(for: endpoint, body: body)

        let startedAt = Date()
        let requestHeaders = request.allHTTPHeaderFields ?? [:]
        let redactedRequestHeaders = NetworkLogRedactor.redactedHeaders(requestHeaders)
        let requestBodyPreview = NetworkLogRedactor.redactedBody(
            data: request.httpBody,
            contentType: request.value(forHTTPHeaderField: "Content-Type")
        )

        do {
            let (data, response) = try await urlSession.data(for: request)
            let finishedAt = Date()

            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.noData
            }

            let durationMs = Int(finishedAt.timeIntervalSince(startedAt) * 1_000)
            let responseHeaders = http.allHeaderFields.reduce(into: [String: String]()) { partial, pair in
                if let key = pair.key as? String, let value = pair.value as? String {
                    partial[key] = value
                }
            }
            let redactedResponseHeaders = NetworkLogRedactor.redactedHeaders(responseHeaders)
            let responseBodyPreview = NetworkLogRedactor.redactedBody(
                data: data,
                contentType: http.value(forHTTPHeaderField: "Content-Type")
            )

            logNetworkEntry(
                method: endpoint.method.rawValue,
                path: endpoint.path,
                url: request.url?.absoluteString ?? "",
                statusCode: http.statusCode,
                durationMs: durationMs,
                requestHeaders: redactedRequestHeaders,
                requestBodyPreview: requestBodyPreview,
                responseHeaders: redactedResponseHeaders,
                responseBodyPreview: responseBodyPreview,
                errorDescription: (200..<300).contains(http.statusCode) ? nil : "HTTP \(http.statusCode)"
            )

            // Update stored tokens when gateway returns refreshed ones.
            if
                let newAccessToken = http.value(forHTTPHeaderField: "X-New-Access-Token"),
                let newRefreshToken = http.value(forHTTPHeaderField: "X-New-Refresh-Token"),
                !newAccessToken.isEmpty,
                !newRefreshToken.isEmpty
            {
                let tokens = AuthTokens(accessToken: newAccessToken, refreshToken: newRefreshToken)
                await sessionController.loginSucceeded(with: tokens)
            }

            if let error = mapHTTPErrorIfNeeded(http, data: data) {
                if case NetworkError.unauthorized = error {
                    await sessionController.logout()
                }
                throw error
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                return try decoder.decode(E.ResponseBody.self, from: data)
            } catch {
                #if DEBUG
                let bodyPreview = String(data: data, encoding: .utf8) ?? "<non-utf8 body (\(data.count) bytes)>"
                Log.network.error(
                    """
                    Decoding failed for \(endpoint.path, privacy: .public): \
                    \(String(describing: error), privacy: .private). \
                    Body preview: \(bodyPreview, privacy: .private)
                    """
                )
                #else
                Log.network.error("Decoding failed for \(endpoint.path, privacy: .public): \(String(describing: error), privacy: .private)")
                #endif
                throw NetworkError.decodingFailed
            }
        } catch {
            if let urlError = error as? URLError {
                if urlError.code == .cancelled {
                    throw NetworkError.cancelled
                }
                if urlError.code == .notConnectedToInternet {
                    throw NetworkError.offline
                }
                throw NetworkError.transport(urlError)
            }
            throw error
        }
    }

    private func buildRequest<E: APIEndpoint>(
        for endpoint: E,
        body: E.RequestBody
    ) async throws -> URLRequest {
        guard let url = URL(string: endpoint.path, relativeTo: environment.baseURL) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: endpoint.timeout)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Idempotency keys for safe retries (future use).
        switch endpoint.idempotencyKeyStrategy {
        case .none:
            break
        case .generated:
            request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
        case .custom(let value):
            request.setValue(value, forHTTPHeaderField: "Idempotency-Key")
        }

        if endpoint.requiresAuth {
            if let token = await sessionController.currentAccessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw NetworkError.unauthorized
            }

            if let refreshToken = await sessionController.currentRefreshToken {
                request.setValue(refreshToken, forHTTPHeaderField: "X-Refresh-Token")
            }
        }

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            if !(body is EmptyRequestBody) {
                request.httpBody = try encoder.encode(body)
            }
        } catch {
            throw NetworkError.encodingFailed
        }

        return request
    }

    private func mapHTTPErrorIfNeeded(_ response: HTTPURLResponse, data: Data) -> NetworkError? {
        guard !(200..<300).contains(response.statusCode) else {
            return nil
        }

        switch response.statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            let retryAfterSeconds: Int?
            if let retryHeader = response.value(forHTTPHeaderField: "Retry-After"),
               let seconds = Int(retryHeader) {
                retryAfterSeconds = seconds
            } else {
                retryAfterSeconds = nil
            }
            return .rateLimited(retryAfterSeconds: retryAfterSeconds)
        case 500...599:
            return .server(statusCode: response.statusCode)
        default:
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            return .requestFailedWithBody(response.statusCode, bodyString)
        }
    }

    private func logNetworkEntry(
        method: String,
        path: String,
        url: String,
        statusCode: Int,
        durationMs: Int,
        requestHeaders: [String: String],
        requestBodyPreview: String?,
        responseHeaders: [String: String],
        responseBodyPreview: String?,
        errorDescription: String?
    ) {
        guard let networkLogStore else { return }

        let entry = NetworkLogEntry(
            id: UUID(),
            timestamp: Date(),
            method: method,
            path: path,
            fullURL: url,
            statusCode: statusCode,
            durationMs: durationMs,
            requestHeaders: requestHeaders,
            requestBodyPreview: requestBodyPreview,
            responseHeaders: responseHeaders,
            responseBodyPreview: responseBodyPreview,
            errorDescription: errorDescription
        )

        Task { @MainActor in
            networkLogStore.append(entry)
        }
    }
}

/// Marker type used for endpoints with no request body.
struct EmptyRequestBody: Encodable {}

