import SwiftUI

struct RecordingControlView: View {
    @Bindable var recorder: AudioRecorder
    let onSave: () async -> Void
    let onDelete: () async -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Timer display
            Text(formattedTime)
                .font(Typography.monospacedTimer)
                .foregroundColor(AppColors.textPrimary)
            
            // Control buttons based on state
            switch recorder.state {
            case .idle:
                idleStateView
                
            case .recording:
                recordingStateView
                
            case .paused:
                pausedStateView
            }
            
            // Error message if any
            if let error = recorder.error {
                Text(error.localizedDescription)
                    .font(Typography.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .alert(Strings.Recording.deleteConfirmTitle, isPresented: $showDeleteConfirmation) {
            Button(Strings.Recording.deleteConfirmNo, role: .cancel) {}
            Button(Strings.Recording.deleteConfirmYes, role: .destructive) {
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
                    Circle()
                        .stroke(AppColors.borderNeutral, lineWidth: 2)
                        .frame(width: 88, height: 88)
                    
                    Circle()
                        .fill(AppColors.recordingRed)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .disabled(!recorder.hasPermission)
            
            Text("Tap to record")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    private var recordingStateView: some View {
        Button(action: { recorder.pause() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(AppColors.borderNeutral, lineWidth: 3)
                    .frame(width: 144, height: 64)
                
                Image(systemName: "pause.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppColors.recordingRed)
            }
        }
    }
    
    private var pausedStateView: some View {
        HStack(spacing: 0) {
            // Delete button
            Button(action: { showDeleteConfirmation = true }) {
                VStack(spacing: 2) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                    Text(Strings.Recording.deleteButton)
                        .font(Typography.caption)
                }
                .foregroundColor(AppColors.recordingRedLight)
                .frame(width: 90, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.recordingRedLight, lineWidth: 2)
                )
            }
            
            Spacer()
            
            // Resume button
            Button(action: { recorder.resume() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(AppColors.recordingRed, lineWidth: 3)
                        .frame(width: 144, height: 64)
                    
                    RoundedRectangle(cornerRadius: 28)
                        .fill(AppColors.recordingBackground)
                        .frame(width: 138, height: 58)
                    
                    Text(Strings.Recording.resumeButton.uppercased())
                        .font(Typography.body.weight(.bold))
                        .foregroundColor(AppColors.recordingRedDark)
                }
            }
            
            Spacer()
            
            // Save button
            Button(action: {
                Task { await onSave() }
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
            _ = try recorder.startRecording()
        } catch {
            // Error is stored in recorder.error
        }
    }
}
