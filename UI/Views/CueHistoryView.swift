import SwiftUI

struct CueHistoryView: View {
    let cueId: Int64
    let content: CueContent

    @State private var viewModel: CueHistoryViewModel
    @Bindable var cueDetailViewModel: CueDetailViewModel
    let makeRecordingDetailViewModel: () -> RecordingDetailViewModel

    init(
        cueId: Int64,
        content: CueContent,
        viewModel: CueHistoryViewModel,
        cueDetailViewModel: CueDetailViewModel,
        makeRecordingDetailViewModel: @escaping () -> RecordingDetailViewModel
    ) {
        self.cueId = cueId
        self.content = content
        _viewModel = State(initialValue: viewModel)
        self.cueDetailViewModel = cueDetailViewModel
        self.makeRecordingDetailViewModel = makeRecordingDetailViewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                cueContentCard(content: content)

                HStack {
                    Spacer()
                    newRecordingButton
                }

                Group {
                    if viewModel.isLoading && viewModel.cue == nil {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity, minHeight: 240)
                    } else if let cue = viewModel.cue, let recordings = cue.recordings, !recordings.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text(Strings.CueHistory.title)
                                .font(Typography.headingLarge)
                                .foregroundColor(AppColors.textPrimary)

                            ForEach(groupedRecordings(recordings), id: \.date) { group in
                                recordingGroupView(group: group, cue: cue)
                            }
                        }
                    } else if viewModel.cue != nil {
                        EmptyState(
                            icon: "waveform.circle",
                            title: Strings.CueHistory.emptyState
                        )
                    } else if let message = viewModel.errorMessage {
                        EmptyState(icon: "waveform.circle", title: message)
                    }
                }
            }
            .padding()
        }
        .background(AppColors.sand.ignoresSafeArea())
        .navigationTitle(Strings.CueHistory.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(cueId: cueId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .activeProfileDidChange)) { _ in
            Task { await viewModel.load(cueId: cueId) }
        }
    }

    private var newRecordingButton: some View {
        NavigationLink {
            CueDetailView(
                cue: Cue(
                    cueId: cueId,
                    stage: viewModel.cue?.stage ?? "",
                    createdAt: viewModel.cue?.createdAt ?? "",
                    createdBy: viewModel.cue?.createdBy ?? 0,
                    content: content,
                    recordings: nil
                ),
                viewModel: cueDetailViewModel,
                historyViewModel: viewModel,
                makeRecordingDetailViewModel: makeRecordingDetailViewModel
            )
        } label: {
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
        .buttonStyle(.plain)
        .accessibilityIdentifier("cueHistory.newRecording")
    }

    // MARK: - Content

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

    private struct RecordingGroup: Identifiable {
        let date: Date
        let recordings: [CueRecording]

        var id: Date { date }
    }

    private func groupedRecordings(_ recordings: [CueRecording]) -> [RecordingGroup] {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let grouped = Dictionary(grouping: recordings) { rec -> Date in
            guard let date = formatter.date(from: rec.createdAt) else { return Date() }
            return calendar.startOfDay(for: date)
        }

        return grouped.map { date, recordings in
            RecordingGroup(
                date: date,
                recordings: recordings.sorted { a, b in
                    guard let da = formatter.date(from: a.createdAt),
                          let db = formatter.date(from: b.createdAt) else { return false }
                    return da > db
                }
            )
        }
        .sorted { $0.date > $1.date }
    }

    private func recordingGroupView(group: RecordingGroup, cue: CueWithRecordings) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Badge(text: formatGroupDate(group.date), icon: "calendar")
                Badge(text: "\(group.recordings.count)", backgroundColor: AppColors.green)
                Spacer()
            }
            .padding(.bottom, Spacing.xs)

            ForEach(group.recordings, id: \.fileId) { rec in
                recordingRow(rec, cue: cue)
            }
        }
    }

    private func recordingRow(_ rec: CueRecording, cue: CueWithRecordings) -> some View {
        let recordingCue = RecordingCue(
            cueId: cue.cueId,
            stage: cue.stage,
            createdAt: cue.createdAt,
            createdBy: cue.createdBy,
            content: cue.content
        )
        let recording = Recording(
            profileCueRecordingId: rec.profileCueRecordingId,
            profileId: rec.profileId,
            cueId: rec.cueId,
            fileId: rec.fileId,
            createdAt: rec.createdAt,
            file: rec.file,
            cue: recordingCue,
            report: rec.report
        )

        return NavigationLink {
            RecordingDetailView(
                recording: recording,
                processedFiles: viewModel.processedFiles,
                viewModel: makeRecordingDetailViewModel(),
                cueDetailViewModel: cueDetailViewModel,
                makeCueHistoryViewModel: { viewModel },
                makeRecordingDetailViewModel: makeRecordingDetailViewModel
            )
        } label: {
            HStack(spacing: Spacing.md) {
                Badge(
                    text: formatRecordingTime(rec.createdAt),
                    backgroundColor: AppColors.divider,
                    foregroundColor: AppColors.textQuaternary
                )

                Spacer()

                Badge(
                    text: formattedDuration(rec.file.metadata.duration),
                    icon: "clock",
                    backgroundColor: AppColors.divider,
                    foregroundColor: AppColors.textQuaternary
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(padding: Spacing.md)
        }
        .buttonStyle(.plain)
    }

    private func formattedDuration(_ duration: TimeInterval?) -> String {
        guard let duration else { return "--:--" }
        return formatDuration(Int(duration.rounded()))
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func formatGroupDate(_ date: Date) -> String {
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

    private func formatRecordingTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

