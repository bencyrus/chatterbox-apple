import SwiftUI

struct CueDetailView: View {
    // Display data
    let content: CueContent
    let cueId: Int64
    let initiallyShowRecordingSection: Bool
    
    // Dependencies
    @Bindable var viewModel: CueDetailViewModel
    
    // Recording state
    @State private var recorder: AudioRecorder?
    @State private var recordingURL: URL?
    @State private var showRecordingSuccessMessage = false
    @State private var showNavigationConfirmation = false
    @State private var pendingNavigationAction: (() -> Void)?
    @State private var isRecordingMode = false
    @State private var isSaving = false
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    // Init for existing cue without recordings (from subjects tab)
    init(cue: Cue, viewModel: CueDetailViewModel) {
        self.content = cue.content
        self.cueId = cue.cueId
        self.initiallyShowRecordingSection = true
        self.viewModel = viewModel
    }
    
    // Init for cue with recordings (from history tab)
    init(cue: RecordingCue, viewModel: CueDetailViewModel) {
        self.content = cue.content
        self.cueId = cue.cueId
        self.initiallyShowRecordingSection = false
        self.viewModel = viewModel
    }
    
    private var showRecordingSection: Bool {
        initiallyShowRecordingSection || isRecordingMode
    }
    
    private var isRecordingActive: Bool {
        recorder?.state == .paused || recorder?.state == .recording
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                cueContentCard
                
                if showRecordingSection {
                    recordingSection
                        .padding(.top, Spacing.lg)
                    
                    if showRecordingSuccessMessage {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(Strings.Recording.successMessage)
                                .font(Typography.body.weight(.medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.darkGreen)
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            
                if !showRecordingSection {
                    recordingsHistorySection
                }
            }
            .padding()
        }
        .background(AppColors.sand.ignoresSafeArea())
        .navigationTitle(Strings.CueDetail.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(showRecordingSection && isRecordingActive)
        .toolbar {
            if showRecordingSection && isRecordingActive {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showNavigationConfirmation = true }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
        .alert(Strings.Recording.deleteConfirmTitle, isPresented: $showNavigationConfirmation) {
            Button(Strings.Recording.deleteConfirmNo, role: .cancel) {}
            Button(Strings.Recording.deleteConfirmYes, role: .destructive) {
                recorder?.cancel()
                recordingURL = nil
                if let action = pendingNavigationAction {
                    action()
                } else {
                    dismiss()
                }
            }
        }
        .task {
            if !initiallyShowRecordingSection {
                await viewModel.loadRecordingsForCue(cueId: cueId)
            }
            
            if initiallyShowRecordingSection {
                recorder = AudioRecorder()
                _ = await recorder?.requestPermission()
            }
        }
    }
    
    // MARK: - View Components
    
    private var cueContentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(content.title)
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(Array(content.details.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)

                    if trimmed.hasPrefix("### ") {
                        Text(String(trimmed.dropFirst(4)))
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                    } else if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") {
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.body)
                            Text(String(trimmed.dropFirst(2)))
                                .font(.body)
                        }
                        .foregroundColor(AppColors.textPrimary)
                    } else if trimmed.isEmpty {
                        Spacer().frame(height: 4)
                    } else {
                        Text(trimmed)
                            .font(.body)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(AppColors.darkBeige)
        .cornerRadius(12)
    }
    
    private var recordingSection: some View {
        VStack(alignment: .center, spacing: Spacing.lg) {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity)
            } else if let recorder {
                RecordingControlView(
                    recorder: recorder,
                    onSave: handleSaveRecording,
                    onDelete: handleDeleteRecording
                )
            } else if !viewModel.isUploading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private var recordingsHistorySection: some View {
        if viewModel.isLoadingRecordings {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        } else if !viewModel.recordings.isEmpty {
            recordingsHistoryContent
        }
    }
    
    private var recordingsHistoryContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Spacer()
                recordAnotherTakeButton
            }
            
            Text(Strings.Recording.historySectionTitle)
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
            
            ForEach(groupedRecordings, id: \.date) { group in
                recordingGroupView(group: group)
            }
        }
    }
    
    private func recordingGroupView(group: RecordingGroup) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(formatGroupDate(group.date))
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
                
                Text("\(group.recordings.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.green)
                    .cornerRadius(6)
                
                Spacer()
            }
            .padding(.bottom, Spacing.xs)
            
            ForEach(group.recordings, id: \.fileId) { recording in
                recordingCardView(recording: recording)
            }
        }
    }
    
    private func recordingCardView(recording: CueRecording) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(formatRecordingTime(recording.createdAt))
                .font(Typography.caption)
                .foregroundColor(AppColors.textPrimary.opacity(0.7))
            
            if let url = getAudioURL(for: recording.fileId) {
                AudioPlayerView(url: url, title: "")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.md)
        .background(AppColors.darkBeige)
        .cornerRadius(12)
    }
    
    private var recordAnotherTakeButton: some View {
        Button(action: {
            isRecordingMode = true
            Task {
                recorder = AudioRecorder()
                _ = await recorder?.requestPermission()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "mic.circle.fill")
                Text(Strings.Recording.newRecordingButton)
            }
            .font(.callout.bold())
            .foregroundColor(AppColors.textContrast)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(AppColors.darkGreen)
            .cornerRadius(24)
        }
    }
    
    // MARK: - Computed Properties & Helper Methods
    
    struct RecordingGroup {
        let date: Date
        let recordings: [CueRecording]
    }
    
    var groupedRecordings: [RecordingGroup] {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let grouped = Dictionary(grouping: viewModel.recordings) { recording -> Date in
            guard let date = formatter.date(from: recording.createdAt) else {
                return Date()
            }
            return calendar.startOfDay(for: date)
        }
        
        return grouped.map { date, recordings in
            RecordingGroup(
                date: date,
                recordings: recordings.sorted { rec1, rec2 in
                    guard let date1 = formatter.date(from: rec1.createdAt),
                          let date2 = formatter.date(from: rec2.createdAt) else {
                        return false
                    }
                    return date1 > date2
                }
            )
        }.sorted { $0.date > $1.date }
    }
    
    func getAudioURL(for fileId: Int64) -> URL? {
        guard let processedFile = viewModel.processedFiles.first(where: { $0.fileId == fileId }) else {
            return nil
        }
        return URL(string: processedFile.url)
    }
    
    func formatGroupDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let compareDate = calendar.startOfDay(for: date)
        
        if compareDate == today {
            return Strings.Common.today
        } else if compareDate == calendar.date(byAdding: .day, value: -1, to: today) {
            return Strings.Common.yesterday
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    func formatRecordingTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        
        return displayFormatter.string(from: date)
    }
    
    // MARK: - Recording Actions
    
    func handleSaveRecording() async {
        guard let recorder else { return }
        
        let duration = recorder.currentTime
        guard let fileURL = recorder.stop() else {
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await viewModel.uploadRecording(
                cueId: cueId,
                fileURL: fileURL,
                cueName: content.title,
                duration: duration
            )
            
            // Clean up file
            try? FileManager.default.removeItem(at: fileURL)
            
            // Reset recorder to fresh state for next recording
            self.recorder = AudioRecorder()
            _ = await self.recorder?.requestPermission()
            
            withAnimation {
                showRecordingSuccessMessage = true
            }
            
            Task {
                try? await Task.sleep(for: .seconds(5))
                withAnimation {
                    showRecordingSuccessMessage = false
                }
            }
        } catch {
            // Keep file for retry, restore recorder state
            self.recorder = AudioRecorder()
            _ = await self.recorder?.requestPermission()
        }
    }
    
    func handleDeleteRecording() async {
        try? await Task.sleep(for: .milliseconds(300))
        recorder?.cancel()
    }
}
