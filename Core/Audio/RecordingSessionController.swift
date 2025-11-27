import Foundation
import AVFoundation
import AVFAudio

enum RecordingError: Error {
    case unsupported
    case microphonePermissionDenied
    case failedToStart
}

enum RecordingState: Equatable {
    case idle
    case preparing
    case recording
    case finished(URL)
}

actor RecordingSessionController {
    private let directoryProvider: RecordingsDirectoryProvider
    private var audioRecorder: AVAudioRecorder?
    private(set) var state: RecordingState = .idle

    init(directoryProvider: RecordingsDirectoryProvider = RecordingsDirectoryProvider()) {
        self.directoryProvider = directoryProvider
    }

    func prepareForRecording() async throws {
        let session = AVAudioSession.sharedInstance()
        let granted = await requestMicrophonePermission()
        guard granted else {
            throw RecordingError.microphonePermissionDenied
        }

        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try session.setActive(true, options: [])
        } catch {
            throw RecordingError.failedToStart
        }

        state = .preparing
    }

    func startRecording(for cueId: Int64) async throws {
        // Scaffold only: we create a local file but do not integrate upload/history yet.
        let url = try directoryProvider.temporaryRecordingURL(cueId: cueId)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            state = .recording
        } catch {
            throw RecordingError.failedToStart
        }
    }

    func stopRecording(for cueId: Int64) async throws {
        guard let recorder = audioRecorder else {
            state = .idle
            return
        }

        recorder.stop()
        audioRecorder = nil

        let finalURL = try directoryProvider.finalRecordingURL(cueId: cueId, timestamp: Date())
        try FileManager.default.moveItem(at: recorder.url, to: finalURL)

        state = .finished(finalURL)

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // Non-fatal.
        }
    }

    func discardRecording() async {
        if case .finished(let url) = state {
            try? FileManager.default.removeItem(at: url)
        }
        audioRecorder?.stop()
        audioRecorder = nil
        state = .idle

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: - Permissions

    /// Requests microphone recording permission from the user.
    ///
    /// This wraps `AVAudioSession.requestRecordPermission(_:)` in an async API
    /// and should be called from a user‑initiated context (e.g. tapping record).
    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}


