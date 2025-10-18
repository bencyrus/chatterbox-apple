import Foundation

enum NetworkError: Error, Equatable {
    case invalidURL
    case encodingFailed
    case requestFailed(Int)
    case noData
    case decodingFailed
}

protocol HTTPClient {
    func postJSON<T: Encodable>(path: String, body: T) async throws -> (Data, HTTPURLResponse)
}

final class APIClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: TokenProvider
    private weak var tokenSink: TokenSink?

    init(baseURL: URL, tokenProvider: TokenProvider, tokenSink: TokenSink?, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.tokenSink = tokenSink
        self.session = session
    }

    func postJSON<T: Encodable>(path: String, body: T) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = tokenProvider.accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.noData }
        captureRefreshedTokens(from: http)
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.requestFailed(http.statusCode) }
        return (data, http)
    }

    private func captureRefreshedTokens(from response: HTTPURLResponse) {
        guard let sink = tokenSink else { return }
        // Read new tokens if present; gateway attaches via headers
        let headers = response.allHeaderFields as? [String: Any] ?? [:]
        let access = headers["X-New-Access-Token"] as? String
        let refresh = headers["X-New-Refresh-Token"] as? String
        if let a = access, let r = refresh, !a.isEmpty, !r.isEmpty {
            sink.updateTokens(AuthTokens(accessToken: a, refreshToken: r))
        }
    }
}


