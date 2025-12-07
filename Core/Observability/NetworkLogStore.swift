import Foundation
import Observation
import os

enum NetworkError: Error, Equatable {
    case invalidURL
    case encodingFailed
    case requestFailedWithBody(Int, String)
    case noData
    case decodingFailed
    case unauthorized
    case forbidden
    case notFound
    case rateLimited(retryAfterSeconds: Int?)
    case server(statusCode: Int)
    case transport(URLError)
    case offline
    case cancelled
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

    private let maxEntries = 1_000
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
        if let url = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
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
                result[key] = maskSensitiveHeader(value)
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

    /// Partially mask sensitive header values while preserving enough for debugging.
    /// Example: abcdefghijklmnopqrstuvwxyz -> abcdefgh****uvwxyz
    private static func maskSensitiveHeader(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = trimmed.count
        guard count > 12 else {
            return String(repeating: "*", count: count)
        }

        let prefixCount = 8
        let suffixCount = 6

        let prefix = trimmed.prefix(prefixCount)
        let suffix = trimmed.suffix(suffixCount)
        return "\(prefix)****\(suffix)"
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

    private static func truncate(_ text: String, maxLength: Int = 4_000) -> String {
        guard text.count > maxLength else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<endIndex]) + "… (truncated)"
    }
}


