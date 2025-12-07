import SwiftUI

struct AudioPlayerView: View {
    let url: URL
    let title: String?
    
    @State private var controller = AudioPlayerController()
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Title if provided
            if let title = title {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Player controls
            VStack(spacing: Spacing.sm) {
                // Time slider
                timeSlider
                
                // Time labels
                HStack {
                    Text(formatTime(controller.currentTime))
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textPrimary.opacity(0.7))
                    
                    Spacer()
                    
                    Text(formatTime(controller.duration))
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textPrimary.opacity(0.7))
                }
                
                // Playback controls
                HStack(spacing: Spacing.lg) {
                    // Skip backward 10s
                    Button {
                        controller.skip(by: -10)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .disabled(!canInteract)
                    
                    // Play/Pause button
                    Button {
                        controller.togglePlayPause()
                    } label: {
                        Image(systemName: playButtonIcon)
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .disabled(!canInteract)
                    
                    // Skip forward 10s
                    Button {
                        controller.skip(by: 10)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .disabled(!canInteract)
                }
            }
            
            // State indicator
            if case .loading = controller.state {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                    Text(Strings.AudioPlayer.loading)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textPrimary.opacity(0.7))
                }
            } else if case .error(let message) = controller.state {
                Text("\(Strings.AudioPlayer.error): \(message)")
                    .font(Typography.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.beige)
        .cornerRadius(12)
        .task {
            controller.load(url: url)
        }
    }
    
    private var timeSlider: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(AppColors.textPrimary.opacity(0.2))
                    .frame(height: 4)
                
                // Progress
                Capsule()
                    .fill(AppColors.textPrimary)
                    .frame(width: progressWidth(in: geometry.size.width), height: 4)
                
                // Thumb
                Circle()
                    .fill(AppColors.textPrimary)
                    .frame(width: 16, height: 16)
                    .offset(x: thumbOffset(in: geometry.size.width))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let percent = max(0, min(1, value.location.x / geometry.size.width))
                        controller.seek(to: percent * controller.duration)
                    }
            )
        }
        .frame(height: 16)
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard controller.duration > 0 else { return 0 }
        let progress = controller.currentTime / controller.duration
        return totalWidth * progress
    }
    
    private func thumbOffset(in totalWidth: CGFloat) -> CGFloat {
        guard controller.duration > 0 else { return 0 }
        let progress = controller.currentTime / controller.duration
        return (totalWidth * progress) - 8 // -8 to center the thumb
    }
    
    private var playButtonIcon: String {
        switch controller.state {
        case .playing:
            return "pause.circle.fill"
        case .loading:
            return "pause.circle"
        default:
            return "play.circle.fill"
        }
    }
    
    private var canInteract: Bool {
        switch controller.state {
        case .ready, .playing, .paused:
            return true
        default:
            return false
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


