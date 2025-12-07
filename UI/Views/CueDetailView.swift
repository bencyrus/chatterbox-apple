import SwiftUI

struct CueDetailView: View {
    // Display data
    let content: CueContent
    let cueId: Int64
    let initiallyShowRecordingSection: Bool
    
    // Dependencies
    @Bindable var viewModel: CueDetailViewModel
    
    // Recording state
    @State private var recorder: AudioRecorderController?
    @State private var showRecordingSuccessMessage = false
    @State private var showNavigationConfirmation = false
    @State private var pendingNavigationAction: (() -> Void)?
    @State private var isRecordingMode = false
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    // Init for existing cue without recordings (from subjects tab)
    init(cue: Cue, viewModel: CueDetailViewModel) {
        self.content = cue.content
        self.cueId = cue.cueId
        self.initiallyShowRecordingSection = true // Show recording button from subjects
        self.viewModel = viewModel
    }
    
    // Init for cue with recordings (from history tab)
    init(cue: RecordingCue, viewModel: CueDetailViewModel) {
        self.content = cue.content
        self.cueId = cue.cueId
        self.initiallyShowRecordingSection = false // Hide recording button from history
        self.viewModel = viewModel
    }
    
    private var showRecordingSection: Bool {
        initiallyShowRecordingSection || isRecordingMode
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                cueContentCard
                
                // Recording section (only show when opened from subjects tab)
                if showRecordingSection {
                    recordingSection
                        .padding(.top, Spacing.lg)
                    
                    // Success message (appears right below recording controls)
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
            
                // Recordings section (only show when NOT in recording mode)
                if !showRecordingSection {
                    recordingsHistorySection
                }
            }
            .padding()
        }
        .background(AppColors.sand.ignoresSafeArea())
        .navigationTitle(Strings.CueDetail.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(showRecordingSection && (recorder?.state == .paused || recorder?.state == .recording))
        .toolbar {
            if showRecordingSection && (recorder?.state == .paused || recorder?.state == .recording) {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showNavigationConfirmation = true
                    }) {
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
                recorder?.deleteRecording()
                if let action = pendingNavigationAction {
                    action()
                } else {
                    dismiss()
                }
            }
        }
        .task {
            // Load recordings only when viewing from History (not from Subjects)
            if !initiallyShowRecordingSection {
                await viewModel.loadRecordingsForCue(cueId: cueId)
            }
            
            if initiallyShowRecordingSection {
                recorder = AudioRecorderController()
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
                        // Heading level 3
                        Text(String(trimmed.dropFirst(4)))
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                    } else if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") {
                        // Bullet item
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.body)
                            Text(String(trimmed.dropFirst(2)))
                                .font(.body)
                        }
                        .foregroundColor(AppColors.textPrimary)
                    } else if trimmed.isEmpty {
                        // Preserve spacing between paragraphs
                        Spacer().frame(height: 4)
                    } else {
                        // Regular paragraph
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
            if let recorder = recorder {
                RecordingControlView(
                    recorder: recorder,
                    onSave: handleSaveRecording,
                    onDelete: handleDeleteRecording
                )
            } else if recorder == nil && !viewModel.isUploading {
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
            // Date header with badges
            HStack(spacing: Spacing.sm) {
                // Date badge
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
                
                // Count badge
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
            
            // Recordings for this date
            ForEach(group.recordings, id: \.fileId) { recording in
                recordingCardView(recording: recording)
            }
        }
    }
    
    private func recordingCardView(recording: CueRecording) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Time stamp
            Text(formatRecordingTime(recording.createdAt))
                .font(Typography.caption)
                .foregroundColor(AppColors.textPrimary.opacity(0.7))
            
            // Audio player
            if let url = getAudioURL(for: recording.fileId) {
                AudioPlayerView(
                    url: url,
                    title: ""
                )
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
                recorder = AudioRecorderController()
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
        
        // Group recordings by date
        let grouped = Dictionary(grouping: viewModel.recordings) { recording -> Date in
            guard let date = formatter.date(from: recording.createdAt) else {
                return Date()
            }
            return calendar.startOfDay(for: date)
        }
        
        // Sort by date descending (newest first)
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
        guard let recorder = recorder, let fileURL = recorder.stopRecording() else {
            recorder?.errorMessage = Strings.Recording.noRecordingFile
            recorder?.state = .paused
            return
        }
        
        // Capture duration before upload
        let duration = recorder.currentTime
        
        do {
            try await viewModel.uploadRecording(
                cueId: cueId,
                fileURL: fileURL,
                cueName: content.title,
                duration: duration
            )
            
            // Success! Delete the file and show success message
            recorder.deleteRecording()
            
            withAnimation {
                showRecordingSuccessMessage = true
            }
            
            // Hide success message after 5 seconds
            Task {
                try? await Task.sleep(for: .seconds(5))
                withAnimation {
                    showRecordingSuccessMessage = false
                }
            }
        } catch {
            // Upload failed - show error and return to paused state
            // Keep the file so user can retry
            let errorDescription = (error as NSError).localizedDescription
            recorder.errorMessage = String(
                format: Strings.Recording.uploadFailedWithDetail,
                errorDescription
            )
            recorder.state = .paused
        }
    }
    
    func handleDeleteRecording() async {
        // Small delay to ensure loading state is visible
        try? await Task.sleep(for: .milliseconds(500))
        recorder?.deleteRecording()
    }
}
