import Foundation
import Observation
import os

enum NetworkError: Error, Equatable {
    case invalidURL
    case encodingFailed
    case requestFailed(Int)
    case requestFailedWithBody(Int, String)
    case noData
    case decodingFailed
}

@MainActor
protocol NetworkLogStoring: AnyObject {
    var entries: [NetworkLogEntry] { get }
    func append(_ entry: NetworkLogEntry)
    func clear()
}

struct NetworkLogEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let method: String
    let path: String
    let fullURL: String
    let statusCode: Int?
    let durationMs: Int?
    let requestHeaders: [String: String]
    let requestBodyPreview: String?
    let responseHeaders: [String: String]
    let responseBodyPreview: String?
    let errorDescription: String?
}

@MainActor
@Observable
final class NetworkLogStore: NetworkLogStoring {
    private(set) var entries: [NetworkLogEntry] = []

    private let maxEntries = 1000
    private let maxAge: TimeInterval = 7 * 24 * 60 * 60
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileURL = NetworkLogStore.makeFileURL(fileManager: fileManager)
        loadFromDisk(fileManager: fileManager)
        prune()
    }

    func append(_ entry: NetworkLogEntry) {
        entries.append(entry)
        prune()
        persistSnapshot()
    }

    func clear() {
        entries.removeAll()
        persistSnapshot()
    }

    private func prune() {
        let cutoff = Date().addingTimeInterval(-maxAge)
        entries = entries.filter { $0.timestamp >= cutoff }
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    private func loadFromDisk(fileManager: FileManager) {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode([NetworkLogEntry].self, from: data)
            entries = decoded
        } catch {
            // Ignore corrupt or unreadable log files; logging must never crash the app.
        }
    }

    private func persistSnapshot() {
        let entriesSnapshot = entries
        let fileURL = self.fileURL
        Task.detached {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            do {
                let data = try encoder.encode(entriesSnapshot)
                let directoryURL = fileURL.deletingLastPathComponent()
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: directoryURL.path) {
                    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                }
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                // Swallow persistence errors; debug logging must not affect runtime behavior.
            }
        }
    }

    private static func makeFileURL(fileManager: FileManager) -> URL {
        let baseDirectory: URL
        if let url = try? fileManager.url(for: .applicationSupportDirectory,
                                          in: .userDomainMask,
                                          appropriateFor: nil,
                                          create: true) {
            baseDirectory = url
        } else {
            baseDirectory = fileManager.temporaryDirectory
        }
        let logsDirectory = baseDirectory.appendingPathComponent("DebugLogs", isDirectory: true)
        return logsDirectory.appendingPathComponent("network_logs.json", isDirectory: false)
    }
}

enum NetworkLogRedactor {
    private static let sensitiveHeaderKeys: Set<String> = [
        "authorization",
        "cookie",
        "x-new-access-token",
        "x-new-refresh-token"
    ]

    static func redactedHeaders(_ headers: [String: String]) -> [String: String] {
        var result: [String: String] = [:]

        for (key, value) in headers {
            let lowerKey = key.lowercased()
            if sensitiveHeaderKeys.contains(lowerKey) {
                result[key] = "[REDACTED]"
            } else {
                result[key] = redactedText(value)
            }
        }

        return result
    }

    static func redactedBody(data: Data?, contentType: String?) -> String? {
        guard let data, !data.isEmpty else { return nil }

        let rawText: String

        if let contentType, contentType.contains("application/json") {
            if
                let object = try? JSONSerialization.jsonObject(with: data),
                let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
                let prettyText = String(data: prettyData, encoding: .utf8)
            {
                rawText = prettyText
            } else {
                rawText = String(data: data, encoding: .utf8) ?? "<non-utf8 body (\(data.count) bytes)>"
            }
        } else {
            rawText = String(data: data, encoding: .utf8) ?? "<non-utf8 body (\(data.count) bytes)>"
        }

        let redacted = redactedText(rawText)
        return truncate(redacted)
    }

    static func redactedText(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var tokens: [String] = []
        tokens.reserveCapacity(text.split(whereSeparator: { $0.isWhitespace }).count)

        for rawToken in text.split(whereSeparator: { $0.isWhitespace }) {
            var token = String(rawToken)

            if let atIndex = token.firstIndex(of: "@"), atIndex > token.startIndex {
                let first = token[token.startIndex]
                let domain = token[atIndex...]
                token = "\(first)***\(domain)"
            }

            let digitCount = token.filter(\.isNumber).count
            if digitCount >= 7 {
                var masked = ""
                masked.reserveCapacity(token.count)

                var seenDigits = 0
                for character in token {
                    if character.isNumber {
                        seenDigits += 1
                        if seenDigits <= 2 || seenDigits > digitCount - 2 {
                            masked.append(character)
                        } else {
                            masked.append("*")
                        }
                    } else {
                        masked.append(character)
                    }
                }

                token = masked
            }

            tokens.append(token)
        }

        return tokens.joined(separator: " ")
    }

    private static func truncate(_ text: String, maxLength: Int = 4000) -> String {
        guard text.count > maxLength else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<endIndex]) + "… (truncated)"
    }
}

protocol HTTPClient {
    func postJSON<T: Encodable>(path: String, body: T) async throws -> (Data, HTTPURLResponse)
    func getJSON(path: String) async throws -> (Data, HTTPURLResponse)
}

final class APIClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: TokenProvider
    private weak var tokenSink: TokenSink?
    private let logger = Logger(subsystem: "com.chatterbox.ios", category: "network")
    private let networkLogStore: NetworkLogStoring?

    init(
        baseURL: URL,
        tokenProvider: TokenProvider,
        tokenSink: TokenSink?,
        session: URLSession = .shared,
        networkLogStore: NetworkLogStoring? = nil
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.tokenSink = tokenSink
        self.session = session
        self.networkLogStore = networkLogStore
    }

    func postJSON<T: Encodable>(path: String, body: T) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = tokenProvider.accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONEncoder().encode(body)

        let startedAt = Date()
        let requestHeaders = req.allHTTPHeaderFields ?? [:]
        let redactedRequestHeaders = NetworkLogRedactor.redactedHeaders(requestHeaders)
        let requestBodyPreview = NetworkLogRedactor.redactedBody(
            data: req.httpBody,
            contentType: req.value(forHTTPHeaderField: "Content-Type")
        )

        let (data, response) = try await session.data(for: req)
        let finishedAt = Date()

        guard let http = response as? HTTPURLResponse else { throw NetworkError.noData }
        captureRefreshedTokens(from: http)

        let durationMs = Int(finishedAt.timeIntervalSince(startedAt) * 1000)
        let responseHeaders = http.allHeaderFields.reduce(into: [String: String]()) { partialResult, pair in
            if let key = pair.key as? String, let value = pair.value as? String {
                partialResult[key] = value
            }
        }
        let redactedResponseHeaders = NetworkLogRedactor.redactedHeaders(responseHeaders)
        let responseBodyPreview = NetworkLogRedactor.redactedBody(
            data: data,
            contentType: http.value(forHTTPHeaderField: "Content-Type")
        )

        let isSuccess = (200..<300).contains(http.statusCode)
        let logEntry = NetworkLogEntry(
            id: UUID(),
            timestamp: finishedAt,
            method: "POST",
            path: path,
            fullURL: url.absoluteString,
            statusCode: http.statusCode,
            durationMs: durationMs,
            requestHeaders: redactedRequestHeaders,
            requestBodyPreview: requestBodyPreview,
            responseHeaders: redactedResponseHeaders,
            responseBodyPreview: responseBodyPreview,
            errorDescription: isSuccess ? nil : "HTTP \(http.statusCode)"
        )
        logNetworkEntry(logEntry)

        guard (200..<300).contains(http.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            #if DEBUG
            logger.error("HTTP \(http.statusCode) \(path, privacy: .public) body: \(responseBody, privacy: .private)")
            #endif
            throw NetworkError.requestFailedWithBody(http.statusCode, responseBody)
        }
        return (data, http)
    }

    func getJSON(path: String) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if let token = tokenProvider.accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let startedAt = Date()
        let requestHeaders = req.allHTTPHeaderFields ?? [:]
        let redactedRequestHeaders = NetworkLogRedactor.redactedHeaders(requestHeaders)

        let (data, response) = try await session.data(for: req)
        let finishedAt = Date()

        guard let http = response as? HTTPURLResponse else { throw NetworkError.noData }
        captureRefreshedTokens(from: http)

        let durationMs = Int(finishedAt.timeIntervalSince(startedAt) * 1000)
        let responseHeaders = http.allHeaderFields.reduce(into: [String: String]()) { partialResult, pair in
            if let key = pair.key as? String, let value = pair.value as? String {
                partialResult[key] = value
            }
        }
        let redactedResponseHeaders = NetworkLogRedactor.redactedHeaders(responseHeaders)
        let responseBodyPreview = NetworkLogRedactor.redactedBody(
            data: data,
            contentType: http.value(forHTTPHeaderField: "Content-Type")
        )

        let isSuccess = (200..<300).contains(http.statusCode)
        let logEntry = NetworkLogEntry(
            id: UUID(),
            timestamp: finishedAt,
            method: "GET",
            path: path,
            fullURL: url.absoluteString,
            statusCode: http.statusCode,
            durationMs: durationMs,
            requestHeaders: redactedRequestHeaders,
            requestBodyPreview: nil,
            responseHeaders: redactedResponseHeaders,
            responseBodyPreview: responseBodyPreview,
            errorDescription: isSuccess ? nil : "HTTP \(http.statusCode)"
        )
        logNetworkEntry(logEntry)

        guard (200..<300).contains(http.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            #if DEBUG
            logger.error("HTTP \(http.statusCode) \(path, privacy: .public) body: \(responseBody, privacy: .private)")
            #endif
            throw NetworkError.requestFailedWithBody(http.statusCode, responseBody)
        }
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

    private func logNetworkEntry(_ entry: NetworkLogEntry) {
        guard networkLogStore != nil else { return }
        Task {
            await MainActor.run {
                networkLogStore?.append(entry)
            }
        }
    }
}


