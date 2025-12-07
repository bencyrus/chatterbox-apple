import SwiftUI

struct RecordingControlView: View {
    @Bindable var recorder: AudioRecorderController
    let onSave: () async -> Void
    let onDelete: () async -> Void
    
    @State private var showDeleteConfirmation = false
    
    private var redColor: Color {
        Color(hex: 0xd98f8f)
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Timer display
            Text(formattedTime)
                .font(.system(size: 36, weight: .medium, design: .monospaced))
                .foregroundColor(AppColors.textPrimary)
            
            // Control buttons based on state
            switch recorder.state {
            case .idle:
                idleStateView
                
            case .recording:
                recordingStateView
                
            case .paused:
                pausedStateView
                
            case .stopped:
                stoppedStateView
            }
            
            // Error message if any
            if let error = recorder.errorMessage {
                Text(error)
                    .font(Typography.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .alert(Strings.Recording.deleteConfirmTitle, isPresented: $showDeleteConfirmation) {
            Button(Strings.Recording.deleteConfirmNo, role: .cancel) {}
            Button(Strings.Recording.deleteConfirmYes, role: .destructive) {
                recorder.state = .stopped
                Task {
                    await onDelete()
                }
            }
        }
    }
    
    // MARK: - State Views
    
    private var idleStateView: some View {
        VStack(spacing: Spacing.md) {
            Button(action: startRecording) {
                ZStack {
                    // Gray stroke border with 2px gap
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 88, height: 88)
                    
                    // Bold red circle
                    Circle()
                        .fill(Color(hex: 0xE74C3C))
                        .frame(width: 80, height: 80)
                    
                    // Microphone icon
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .disabled(recorder.permissionState == .denied)
            
            // Hint text
            Text("Tap to record")
                .font(Typography.caption)
                .foregroundColor(AppColors.textPrimary.opacity(0.6))
        }
    }
    
    private var recordingStateView: some View {
        Button(action: {
            recorder.pauseRecording()
        }) {
            ZStack {
                // Gray stroke border
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 144, height: 64)
                
                // Pause icon
                Image(systemName: "pause.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color(hex: 0xE74C3C))
            }
        }
    }
    
    private var pausedStateView: some View {
        HStack(spacing: 0) {
            // Delete button (left side)
            Button(action: {
                showDeleteConfirmation = true
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                    Text(Strings.Recording.deleteButton)
                        .font(Typography.caption)
                }
                .foregroundColor(Color(hex: 0xd98f8f))
                .frame(width: 90, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: 0xd98f8f), lineWidth: 2)
                )
            }
            
            Spacer()
            
            // Resume button (center)
            Button(action: {
                recorder.resumeRecording()
            }) {
                ZStack {
                    // Red stroke border
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(hex: 0xE74C3C), lineWidth: 3)
                        .frame(width: 144, height: 64)
                    
                    // Light pink/beige background
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: 0xE5C4B8))
                        .frame(width: 138, height: 58)
                    
                    // Resume text
                    Text(Strings.Recording.resumeButton.uppercased())
                        .font(Typography.body.weight(.bold))
                        .foregroundColor(Color(hex: 0xC0392B))
                }
            }
            
            Spacer()
            
            // Save button (right side)
            Button(action: {
                recorder.state = .stopped
                Task {
                    await onSave()
                }
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 18))
                    Text(Strings.Recording.saveButton)
                        .font(Typography.caption)
                }
                .foregroundColor(AppColors.darkGreen)
                .frame(width: 90, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.darkGreen, lineWidth: 2)
                )
            }
        }
    }
    
    private var stoppedStateView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
    }
    
    // MARK: - Helpers
    
    private var formattedTime: String {
        let hours = Int(recorder.currentTime / 3600)
        let minutes = Int((recorder.currentTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func startRecording() {
        do {
            try recorder.startRecording()
        } catch {
            recorder.errorMessage = error.localizedDescription
        }
    }
}

