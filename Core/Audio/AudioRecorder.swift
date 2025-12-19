import AVFoundation
import Observation

/// Simple voice recorder optimized for voice memo quality.
/// Uses `.spokenAudio` mode for clear voice capture without VoIP echo cancellation.
@MainActor
@Observable
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    enum State: Equatable {
        case idle
        case recording
        case paused
    }
    
    private(set) var state: State = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var error: Error?
    
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var fileURL: URL?
    
    var hasPermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Recording
    
    func startRecording() throws -> URL {
        guard hasPermission else {
            throw RecorderError.permissionDenied
        }
        
        try configureSession()
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording-\(UUID().uuidString).m4a")
        
        // High quality voice settings - AAC at 48kHz mono
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128_000,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        let newRecorder = try AVAudioRecorder(url: url, settings: settings)
        newRecorder.delegate = self
        newRecorder.isMeteringEnabled = true
        
        guard newRecorder.record() else {
            throw RecorderError.failedToStart
        }
        
        recorder = newRecorder
        fileURL = url
        state = .recording
        currentTime = 0
        error = nil
        startTimer()
        
        return url
    }
    
    func pause() {
        guard state == .recording else { return }
        recorder?.pause()
        state = .paused
        stopTimer()
    }
    
    func resume() {
        guard state == .paused else { return }
        recorder?.record()
        state = .recording
        startTimer()
    }
    
    func stop() -> URL? {
        recorder?.stop()
        stopTimer()
        deactivateSession()
        
        let url = fileURL
        state = .idle
        recorder = nil
        
        return url
    }
    
    func cancel() {
        recorder?.stop()
        stopTimer()
        deactivateSession()
        
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        state = .idle
        currentTime = 0
        recorder = nil
        fileURL = nil
        error = nil
    }
    
    // MARK: - Session
    
    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        
        // `.spokenAudio` mode is optimized for voice recordings (podcasts, voice memos)
        // Unlike `.voiceChat`, it doesn't apply aggressive echo cancellation that dampens audio
        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            // IMPORTANT:
            // - `.allowBluetoothHFP` enables Bluetooth HFP, which is what AirPods/headsets use for
            //   input/output when using `.playAndRecord`.
            // - Avoid `.defaultToSpeaker` so routing respects the active output (AirPods, etc).
            //
            // We also include `.allowBluetoothA2DP` so output can use higher-quality A2DP routes
            // when available (input recording will still be constrained by the active input).
            options: [.allowBluetoothHFP, .allowBluetoothA2DP]
        )
        try session.setActive(true)
    }
    
    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let recorder = self.recorder else { return }
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
        if !flag {
            Task { @MainActor in
                self.error = RecorderError.recordingInterrupted
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.error = error ?? RecorderError.encodingFailed
            self.state = .idle
        }
    }
}

// MARK: - Error

enum RecorderError: LocalizedError {
    case permissionDenied
    case failedToStart
    case recordingInterrupted
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Microphone access required"
        case .failedToStart: "Could not start recording"
        case .recordingInterrupted: "Recording was interrupted"
        case .encodingFailed: "Recording encoding failed"
        }
    }
}

