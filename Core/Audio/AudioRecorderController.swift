import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class AudioRecorderController: NSObject, AVAudioRecorderDelegate {
    enum RecordingState: Equatable {
        case idle
        case recording
        case paused
        case stopped
    }
    
    enum PermissionState {
        case notDetermined
        case granted
        case denied
    }
    
    var state: RecordingState = .idle
    var currentTime: TimeInterval = 0
    var permissionState: PermissionState = .notDetermined
    var errorMessage: String?
    
    @ObservationIgnored private var audioRecorder: AVAudioRecorder?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var recordingURL: URL?
    
    override init() {
        super.init()
    }
    
    deinit {
        // Cleanup directly in deinit since it's nonisolated
        timer?.invalidate()
        audioRecorder?.stop()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    self.permissionState = granted ? .granted : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func startRecording() throws {
        guard permissionState == .granted else {
            errorMessage = "Microphone permission not granted"
            throw AudioRecordingError.permissionDenied
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
        
        // Generate unique filename
        let fileName = "recording-\(UUID().uuidString).m4a"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        recordingURL = fileURL
        
        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create and start recorder
        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.delegate = self
        audioRecorder = recorder
        
        guard recorder.record() else {
            throw AudioRecordingError.recordingFailed
        }
        
        state = .recording
        currentTime = 0
        startTimer()
    }
    
    func pauseRecording() {
        guard state == .recording, let recorder = audioRecorder else { return }
        
        recorder.pause()
        state = .paused
        stopTimer()
    }
    
    func resumeRecording() {
        guard state == .paused, let recorder = audioRecorder else { return }
        
        recorder.record()
        state = .recording
        startTimer()
    }
    
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder, let url = recordingURL else { return nil }
        
        recorder.stop()
        state = .stopped
        stopTimer()
        
        // Verify file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "Recording file not found"
            return nil
        }
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        return url
    }
    
    func deleteRecording() {
        if let recorder = audioRecorder {
            recorder.stop()
            audioRecorder = nil
        }
        
        stopTimer()
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
        
        state = .idle
        currentTime = 0
        errorMessage = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let recorder = self.audioRecorder else { return }
                self.currentTime = recorder.currentTime
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                errorMessage = "Recording failed to finish properly"
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            errorMessage = error?.localizedDescription ?? "Recording encoding error occurred"
            state = .idle
        }
    }
}

// MARK: - Audio Recording Error

enum AudioRecordingError: Error, LocalizedError {
    case permissionDenied
    case recordingFailed
    case audioSessionSetupFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission not granted"
        case .recordingFailed:
            return "Failed to start recording"
        case .audioSessionSetupFailed:
            return "Failed to configure audio session"
        }
    }
}

