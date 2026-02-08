import SwiftUI

struct CueDetailView: View {
    // Display data
    let content: CueContent
    let cueId: Int64

    // Dependencies
    @Bindable var viewModel: CueDetailViewModel
    @State private var historyViewModel: CueHistoryViewModel
    let makeRecordingDetailViewModel: () -> RecordingDetailViewModel

    // Recording state
    @State private var recorder: AudioRecorder?
    @State private var recordingURL: URL?
    @State private var showRecordingSuccessMessage = false
    @State private var showNavigationConfirmation = false
    @State private var pendingNavigationAction: (() -> Void)?
    @State private var isSaving = false
    @State private var showCueHistory = false

    @SwiftUI.Environment(\.dismiss) private var dismiss

    init(
        cue: Cue,
        viewModel: CueDetailViewModel,
        historyViewModel: CueHistoryViewModel,
        makeRecordingDetailViewModel: @escaping () -> RecordingDetailViewModel
    ) {
        self.content = cue.content
        self.cueId = cue.cueId
        self.viewModel = viewModel
        _historyViewModel = State(initialValue: historyViewModel)
        self.makeRecordingDetailViewModel = makeRecordingDetailViewModel
    }
    
    private var isRecordingActive: Bool {
        recorder?.state == .paused || recorder?.state == .recording
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                cueContentCard

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
            .padding()
        }
        .background(AppColors.sand.ignoresSafeArea())
        .navigationTitle(Strings.CueDetail.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(isRecordingActive)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                recordingsCountButton
            }

            if isRecordingActive {
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
            recorder = AudioRecorder()
            _ = await recorder?.requestPermission()
            await historyViewModel.load(cueId: cueId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .activeProfileDidChange)) { _ in
            viewModel.reloadForActiveProfileChange()
            Task { await historyViewModel.load(cueId: cueId) }
        }
        .navigationDestination(isPresented: $showCueHistory) {
            CueHistoryView(
                cueId: cueId,
                content: content,
                viewModel: historyViewModel,
                cueDetailViewModel: viewModel,
                makeRecordingDetailViewModel: makeRecordingDetailViewModel
            )
        }
    }
    
    // MARK: - View Components
    
    private var cueContentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(content.title)
                .font(Typography.headingLarge)
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
        .textSelection(.enabled)
        .cardStyle()
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
    
    private var recordingsCountButton: some View {
        Button {
            showCueHistory = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar")
                Text(Strings.Recording.recordingsCount(historyViewModel.cue?.recordings?.count ?? 0))
                    .font(.callout.weight(.semibold))
                Text(Strings.Recording.viewAll)
                    .font(.callout.weight(.medium))
            }
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("cueDetail.viewCueHistory")
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
                languageCode: content.languageCode,
                fileURL: fileURL,
                cueName: content.title,
                duration: duration
            )
            
            // Clean up file
            try? FileManager.default.removeItem(at: fileURL)
            
            // Refresh count/history for this cue (for header + cue history page)
            await historyViewModel.load(cueId: cueId)
            
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
