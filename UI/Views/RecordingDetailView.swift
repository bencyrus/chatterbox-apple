import SwiftUI

struct RecordingDetailView: View {
    @State private var viewModel: RecordingDetailViewModel
    @Bindable var cueDetailViewModel: CueDetailViewModel
    let makeCueHistoryViewModel: () -> CueHistoryViewModel
    let makeRecordingDetailViewModel: () -> RecordingDetailViewModel

    @State private var showReportSheet: Bool = false
    @State private var showCueHistory: Bool = false
    @State private var showCueDetail: Bool = false

    init(
        recording: Recording,
        processedFiles: [ProcessedFile],
        viewModel: RecordingDetailViewModel,
        cueDetailViewModel: CueDetailViewModel,
        makeCueHistoryViewModel: @escaping () -> CueHistoryViewModel,
        makeRecordingDetailViewModel: @escaping () -> RecordingDetailViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.cueDetailViewModel = cueDetailViewModel
        self.makeCueHistoryViewModel = makeCueHistoryViewModel
        self.makeRecordingDetailViewModel = makeRecordingDetailViewModel
        viewModel.setInitial(recording: recording, processedFiles: processedFiles)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let recording = viewModel.recording {
                    cueContentCard(content: recording.cue.content)

                    // New Recording (go back to cue detail)
                    HStack {
                        Spacer()
                        newRecordingButton(cueId: recording.cueId, cue: recording.cue)
                    }

                    // Date badge
                    HStack(spacing: Spacing.sm) {
                        Badge(
                            text: formatDateLabel(recording.createdAt),
                            icon: "calendar",
                            backgroundColor: AppColors.divider,
                            foregroundColor: AppColors.textQuaternary
                        )
                        Spacer()
                    }

                    recordingCard(recording: recording)
                } else if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    EmptyState(
                        icon: "waveform.circle",
                        title: viewModel.errorMessage ?? "Couldn't load recording"
                    )
                }
            }
            .padding()
        }
        .background(AppColors.sand.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let recording = viewModel.recording {
                    recordingsCountButton(cueId: recording.cueId)
                }
            }
        }
        .task {
            if let recording = viewModel.recording {
                await viewModel.loadRecordingCountForCue(cueId: recording.cueId)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if viewModel.recording != nil {
                RecordingReportView(
                    recording: Binding(
                        get: { viewModel.recording! },
                        set: { viewModel.recording = $0 }
                    ),
                    cueTitle: viewModel.recording!.cue.content.title,
                    onRequestReport: {
                        await viewModel.requestTranscription(profileCueRecordingId: viewModel.recording!.profileCueRecordingId)
                    },
                    onRefresh: {
                        await viewModel.refreshRecording()
                    }
                )
            }
        }
        .navigationDestination(isPresented: $showCueHistory) {
            if let recording = viewModel.recording {
                CueHistoryView(
                    cueId: recording.cueId,
                    content: recording.cue.content,
                    viewModel: makeCueHistoryViewModel(),
                    cueDetailViewModel: cueDetailViewModel,
                    makeRecordingDetailViewModel: makeRecordingDetailViewModel
                )
            }
        }
        .navigationDestination(isPresented: $showCueDetail) {
            if let recording = viewModel.recording {
                CueDetailView(
                    cue: Cue(
                        cueId: recording.cue.cueId,
                        stage: recording.cue.stage,
                        createdAt: recording.cue.createdAt,
                        createdBy: recording.cue.createdBy,
                        content: recording.cue.content,
                        recordings: nil
                    ),
                    viewModel: cueDetailViewModel,
                    historyViewModel: makeCueHistoryViewModel(),
                    makeRecordingDetailViewModel: makeRecordingDetailViewModel
                )
            }
        }
    }

    // MARK: - Subviews

    private func cueContentCard(content: CueContent) -> some View {
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

    private func recordingCard(recording: Recording) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(formatTimeLabel(recording.createdAt))
                .font(Typography.caption)
                .foregroundColor(AppColors.textTertiary)

            if let url = audioURL(for: recording.fileId) {
                AudioPlayerView(url: url, title: "")
            }

            Button(action: { showReportSheet = true }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: reportIcon(for: recording.report.status))
                    Text(Strings.Report.buttonLabel)
                }
                .font(Typography.body.weight(.medium))
                .foregroundColor(AppColors.textContrast)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(AppColors.darkGreen)
                .cornerRadius(12)
            }
        }
        .cardStyle(padding: Spacing.md)
    }

    private func recordingsCountButton(cueId: Int64) -> some View {
        Button {
            showCueHistory = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar")
                Text(Strings.Recording.recordingsCount(viewModel.recordingCountForCue ?? 0))
                    .font(.callout.weight(.semibold))
                Text(Strings.Recording.viewAll)
                    .font(.callout.weight(.medium))
            }
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recordingDetail.viewCueHistory")
    }

    private func newRecordingButton(cueId: Int64, cue: RecordingCue) -> some View {
        Button(action: { showCueDetail = true }) {
            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .symbolRenderingMode(.monochrome)
                Text(Strings.Recording.newRecordingButton)
            }
            .font(.callout.bold())
            .foregroundColor(AppColors.textContrast)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(AppColors.darkGreen)
            .cornerRadius(24)
        }
        .accessibilityIdentifier("recordingDetail.newRecording")
    }

    // MARK: - Helpers

    private func audioURL(for fileId: Int64) -> URL? {
        guard let processedFile = viewModel.processedFiles.first(where: { $0.fileId == fileId }) else {
            return nil
        }
        return URL(string: processedFile.url)
    }

    private func reportIcon(for status: ReportStatus) -> String {
        switch status {
        case .none: return "doc.text.magnifyingglass"
        case .processing: return "clock.fill"
        case .ready: return "doc.text.fill"
        }
    }

    private func formatDateLabel(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return dateString }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return Strings.Common.today }
        if calendar.isDateInYesterday(date) { return Strings.Common.yesterday }

        let display = DateFormatter()
        display.dateStyle = .medium
        return display.string(from: date)
    }

    private func formatTimeLabel(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return dateString }

        let display = DateFormatter()
        display.timeStyle = .short
        return display.string(from: date)
    }
}

