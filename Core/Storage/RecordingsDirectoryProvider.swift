import Foundation

struct RecordingsDirectoryProvider {
    enum Error: Swift.Error {
        case unableToCreateDirectory
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func recordingsDirectory() throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("Recordings", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: directory.path
            )
        }
        return directory
    }

    func temporaryRecordingURL(cueId: Int64) throws -> URL {
        let directory = try recordingsDirectory()
        let filename = "cue-\(cueId)-temp.m4a"
        return directory.appendingPathComponent(filename, isDirectory: false)
    }

    func finalRecordingURL(cueId: Int64, timestamp: Date) throws -> URL {
        let directory = try recordingsDirectory()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let stamp = formatter.string(from: timestamp).replacingOccurrences(of: ":", with: "-")
        let filename = "cue-\(cueId)-\(stamp).m4a"
        return directory.appendingPathComponent(filename, isDirectory: false)
    }
}


