import Foundation

/// Coordinates audio playback to ensure only one audio plays at a time.
@MainActor
final class AudioPlaybackCoordinator {
    static let shared = AudioPlaybackCoordinator()
    
    private weak var currentlyPlayingPlayer: AudioPlayer?
    
    private init() {}
    
    /// Registers a player as currently playing. Pauses any other playing audio.
    func didStartPlaying(_ player: AudioPlayer) {
        if let current = currentlyPlayingPlayer, current !== player {
            current.pause()
        }
        currentlyPlayingPlayer = player
    }
    
    /// Notifies that a player stopped playing.
    func didStopPlaying(_ player: AudioPlayer) {
        if currentlyPlayingPlayer === player {
            currentlyPlayingPlayer = nil
        }
    }
}

