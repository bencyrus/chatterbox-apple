import AVFoundation
import Combine
import Foundation

@Observable
@MainActor
final class AudioPlayerController {
    enum PlaybackState: Equatable {
        case idle
        case loading
        case ready
        case playing
        case paused
        case error(String)
    }
    
    private(set) var state: PlaybackState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    
    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var statusObservation: NSKeyValueObservation?
    @ObservationIgnored private var rateObservation: NSKeyValueObservation?
    
    deinit {
        // Cleanup must be done synchronously in deinit
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        statusObservation?.invalidate()
        rateObservation?.invalidate()
        player?.pause()
    }
    
    func load(url: URL) {
        cleanup()
        
        state = .loading
        
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        
        // Observe player item status
        statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.handleStatusChange(item.status)
            }
        }
        
        // Observe playback rate to detect when playback finishes
        rateObservation = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
            Task { @MainActor in
                self?.handleRateChange(player.rate)
            }
        }
        
        // Add periodic time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.updateTime(time)
            }
        }
    }
    
    func play() {
        guard let player = player else { return }
        
        // If we're at the end, seek to beginning
        if currentTime >= duration && duration > 0 {
            seek(to: 0)
        }
        
        player.play()
        state = .playing
    }
    
    func pause() {
        player?.pause()
        state = .paused
    }
    
    func togglePlayPause() {
        switch state {
        case .playing:
            pause()
        case .paused, .ready:
            play()
        default:
            break
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
    }
    
    func skip(by seconds: TimeInterval) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seek(to: newTime)
    }
    
    private func handleStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            if let duration = player?.currentItem?.duration, duration.isNumeric {
                self.duration = duration.seconds
                state = .ready
            }
        case .failed:
            if let error = player?.currentItem?.error {
                state = .error(error.localizedDescription)
            } else {
                state = .error("Unknown playback error")
            }
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func handleRateChange(_ rate: Float) {
        guard state == .playing || state == .paused else { return }
        
        if rate == 0 {
            // Check if we've reached the end
            if currentTime >= duration && duration > 0 {
                state = .paused
            } else if state == .playing {
                state = .paused
            }
        } else {
            state = .playing
        }
    }
    
    private func updateTime(_ time: CMTime) {
        guard time.isNumeric else { return }
        currentTime = time.seconds
    }
    
    private func cleanup() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        statusObservation?.invalidate()
        statusObservation = nil
        
        rateObservation?.invalidate()
        rateObservation = nil
        
        player?.pause()
        player = nil
        
        currentTime = 0
        duration = 0
        state = .idle
    }
}


