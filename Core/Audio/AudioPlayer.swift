import AVFoundation
import Observation

/// Simple audio player for playback of recorded voice notes.
@MainActor
@Observable
final class AudioPlayer {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case playing
        case paused
        case failed(String)
    }
    
    private(set) var state: State = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    
    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var statusObserver: NSKeyValueObservation?
    @ObservationIgnored private var rateObserver: NSKeyValueObservation?
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        statusObserver?.invalidate()
        rateObserver?.invalidate()
        player?.pause()
    }
    
    // MARK: - Loading
    
    func load(url: URL) {
        reset()
        state = .loading
        
        configureSession()
        
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        
        // Observe status
        statusObserver = item.observe(\.status) { [weak self] item, _ in
            Task { @MainActor in
                self?.handleStatus(item.status, item: item)
            }
        }
        
        // Observe rate for play/pause detection
        rateObserver = newPlayer.observe(\.rate) { [weak self] player, _ in
            Task { @MainActor in
                self?.handleRateChange(player.rate)
            }
        }
        
        // Time updates
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                if time.isNumeric {
                    self?.currentTime = time.seconds
                }
            }
        }
    }
    
    // MARK: - Playback Controls
    
    func play() {
        guard let player else { return }
        
        // Restart if at end
        if currentTime >= duration && duration > 0 {
            seek(to: 0)
        }
        
        // Notify coordinator to pause other players
        AudioPlaybackCoordinator.shared.didStartPlaying(self)
        
        player.play()
        state = .playing
    }
    
    func pause() {
        player?.pause()
        state = .paused
        AudioPlaybackCoordinator.shared.didStopPlaying(self)
    }
    
    func togglePlayback() {
        if state == .playing {
            pause()
        } else if state == .ready || state == .paused {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
    }
    
    func skip(seconds: TimeInterval) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seek(to: newTime)
    }
    
    // MARK: - Private
    
    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // For playback, allow routing to AirPlay + Bluetooth devices.
        // (Bluetooth A2DP is typical for playback, but we also allow HFP routing for edge cases.)
        try? session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP, .allowBluetoothHFP])
        try? session.setActive(true)
    }
    
    private func handleStatus(_ status: AVPlayerItem.Status, item: AVPlayerItem) {
        switch status {
        case .readyToPlay:
            if item.duration.isNumeric {
                duration = item.duration.seconds
                state = .ready
            }
        case .failed:
            state = .failed(item.error?.localizedDescription ?? "Playback failed")
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func handleRateChange(_ rate: Float) {
        guard state == .playing || state == .paused else { return }
        
        if rate == 0 {
            if currentTime >= duration && duration > 0 {
                state = .paused
                AudioPlaybackCoordinator.shared.didStopPlaying(self)
            } else if state == .playing {
                state = .paused
                AudioPlaybackCoordinator.shared.didStopPlaying(self)
            }
        } else {
            state = .playing
        }
    }
    
    private func reset() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
        rateObserver?.invalidate()
        rateObserver = nil
        
        player?.pause()
        player = nil
        currentTime = 0
        duration = 0
        state = .idle
    }
}

