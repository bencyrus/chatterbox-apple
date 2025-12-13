import SwiftUI

struct AudioPlayerView: View {
    let url: URL
    let title: String?
    
    @State private var player = AudioPlayer()
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            if let title {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(spacing: Spacing.sm) {
                timeSlider
                
                HStack {
                    Text(formatTime(player.currentTime))
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Spacer()
                    
                    Text(formatTime(player.duration))
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                HStack(spacing: Spacing.lg) {
                    Button { player.skip(seconds: -10) } label: {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .disabled(!canInteract)
                    
                    Button { player.togglePlayback() } label: {
                        Image(systemName: playButtonIcon)
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .disabled(!canInteract)
                    
                    Button { player.skip(seconds: 10) } label: {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .disabled(!canInteract)
                }
            }
            
            if case .loading = player.state {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                    Text(Strings.AudioPlayer.loading)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            } else if case .failed(let message) = player.state {
                Text("\(Strings.AudioPlayer.error): \(message)")
                    .font(Typography.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .cardStyle(backgroundColor: AppColors.surfaceLight)
        .task {
            player.load(url: url)
        }
    }
    
    private var timeSlider: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.divider)
                    .frame(height: 4)
                
                Capsule()
                    .fill(AppColors.textPrimary)
                    .frame(width: progressWidth(in: geometry.size.width), height: 4)
                
                Circle()
                    .fill(AppColors.textPrimary)
                    .frame(width: 16, height: 16)
                    .offset(x: thumbOffset(in: geometry.size.width))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let percent = max(0, min(1, value.location.x / geometry.size.width))
                        player.seek(to: percent * player.duration)
                    }
            )
        }
        .frame(height: 16)
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard player.duration > 0 else { return 0 }
        return totalWidth * (player.currentTime / player.duration)
    }
    
    private func thumbOffset(in totalWidth: CGFloat) -> CGFloat {
        guard player.duration > 0 else { return 0 }
        return (totalWidth * (player.currentTime / player.duration)) - 8
    }
    
    private var playButtonIcon: String {
        switch player.state {
        case .playing: "pause.circle.fill"
        case .loading: "pause.circle"
        default: "play.circle.fill"
        }
    }
    
    private var canInteract: Bool {
        switch player.state {
        case .ready, .playing, .paused: true
        default: false
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
