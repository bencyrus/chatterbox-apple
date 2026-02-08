import SwiftUI

struct RecordingReportView: View {
    @Binding var recording: Recording
    let cueTitle: String
    let onRequestReport: () async -> Void
    let onRefresh: () async -> Void

    @State private var isRequesting = false
    @State private var pollingTask: Task<Void, Never>?
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection

                    switch recording.report.status {
                    case .none:
                        noReportContent
                    case .processing:
                        processingContent
                    case .ready:
                        if let transcript = recording.report.transcript {
                            transcriptContent(transcript)
                        }
                    }
                }
                .padding()
            }
            .background(AppColors.sand.ignoresSafeArea())
            .navigationTitle(Strings.Report.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Common.ok) { dismiss() }
                }
            }
            .onAppear {
                if recording.report.status == .processing {
                    startPolling()
                }
            }
            .onDisappear {
                pollingTask?.cancel()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(cueTitle)
                .font(Typography.headingLarge)
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: Spacing.sm) {
                Badge(
                    text: formatDate(recording.createdAt),
                    icon: "calendar",
                    backgroundColor: AppColors.divider,
                    foregroundColor: AppColors.textQuaternary
                )

                statusBadge
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var statusBadge: some View {
        Group {
            switch recording.report.status {
            case .none:
                Badge(
                    text: Strings.Report.statusNone,
                    icon: "doc.text",
                    backgroundColor: AppColors.divider,
                    foregroundColor: AppColors.textQuaternary
                )
            case .processing:
                Badge(
                    text: Strings.Report.statusProcessing,
                    icon: "clock",
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.textPrimary
                )
            case .ready:
                Badge(
                    text: Strings.Report.statusReady,
                    icon: "checkmark.circle",
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.textPrimary
                )
            }
        }
    }

    private var noReportContent: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)

            Text(Strings.Report.noReportMessage)
                .font(Typography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: { Task { await requestReport() } }) {
                HStack(spacing: Spacing.sm) {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(AppColors.textContrast)
                    } else {
                        Image(systemName: "doc.text")
                    }
                    Text(Strings.Report.requestButton)
                }
                .font(Typography.body.weight(.medium))
                .foregroundColor(AppColors.textContrast)
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.xl)
                .background(AppColors.darkGreen)
                .cornerRadius(24)
            }
            .disabled(isRequesting)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .cardStyle()
    }

    private var processingContent: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text(Strings.Report.processingMessage)
                .font(Typography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Text(Strings.Report.processingHint)
                .font(Typography.caption)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .cardStyle()
    }

    private func transcriptContent(_ transcript: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(AppColors.darkGreen)
                Text(Strings.Report.transcriptTitle)
                    .font(Typography.headingSmall)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(transcript)
                .font(Typography.body)
                .foregroundColor(AppColors.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle()
    }

    private func requestReport() async {
        isRequesting = true
        defer { isRequesting = false }

        await onRequestReport()
        startPolling()
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            let maxAttempts = 100
            var attempts = 0

            while !Task.isCancelled && attempts < maxAttempts {
                try? await Task.sleep(for: .seconds(3))
                if Task.isCancelled { break }

                await onRefresh()

                if recording.report.status != .processing {
                    break
                }

                attempts += 1
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "d MMM yyyy, HH:mm"
        return displayFormatter.string(from: date)
    }
}
