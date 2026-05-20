import SwiftUI

struct RecordingReportView: View {
    @Binding var recording: Recording
    let cueTitle: String
    let onRequestReport: () async -> Void
    let onRequestEvaluation: () async -> Void
    let onRefresh: () async -> Void

    @State private var isRequesting = false
    @State private var isRequestingEvaluation = false
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
                        evaluationSection
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
                if shouldPoll {
                    startPolling()
                }
            }
            .onDisappear {
                pollingTask?.cancel()
            }
        }
    }

    private var shouldPoll: Bool {
        recording.report.status == .processing ||
        recording.report.evaluation?.status == .processing
    }

    // MARK: - Header

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
            let evalStatus = recording.report.evaluation?.status ?? .none

            if recording.report.status == .ready && evalStatus == .ready {
                Badge(
                    text: Strings.Evaluation.statusEvaluated,
                    icon: "checkmark.circle",
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.textPrimary
                )
            } else if recording.report.status == .ready && evalStatus == .processing {
                Badge(
                    text: Strings.Evaluation.statusEvaluating,
                    icon: "sparkles",
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.textPrimary
                )
            } else if recording.report.status == .ready {
                Badge(
                    text: Strings.Report.statusReady,
                    icon: "checkmark.circle",
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.textPrimary
                )
            } else if recording.report.status == .processing {
                Badge(
                    text: Strings.Report.statusProcessing,
                    icon: "clock",
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.textPrimary
                )
            } else {
                Badge(
                    text: Strings.Report.statusNone,
                    icon: "doc.text",
                    backgroundColor: AppColors.divider,
                    foregroundColor: AppColors.textQuaternary
                )
            }
        }
    }

    // MARK: - No Report

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

    // MARK: - Processing (transcript)

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

    // MARK: - Transcript

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

    // MARK: - Evaluation Section

    @ViewBuilder
    private var evaluationSection: some View {
        let evalStatus = recording.report.evaluation?.status ?? .none

        switch evalStatus {
        case .none:
            evaluationRequestContent
        case .processing:
            evaluationProcessingContent
        case .ready:
            if let result = recording.report.evaluation?.result {
                evaluationResultContent(result)
            }
        }
    }

    private var evaluationRequestContent: some View {
        VStack(spacing: Spacing.lg) {
            Button(action: { Task { await requestEvaluation() } }) {
                HStack(spacing: Spacing.sm) {
                    if isRequestingEvaluation {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(AppColors.textContrast)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(Strings.Evaluation.requestButton)
                }
                .font(Typography.body.weight(.medium))
                .foregroundColor(AppColors.textContrast)
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(AppColors.darkGreen)
                .cornerRadius(24)
            }
            .disabled(isRequestingEvaluation)
        }
        .cardStyle()
    }

    private var evaluationProcessingContent: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text(Strings.Evaluation.processingMessage)
                .font(Typography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Text(Strings.Evaluation.processingHint)
                .font(Typography.caption)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .cardStyle()
    }

    private func evaluationResultContent(_ result: EvaluationResult) -> some View {
        VStack(spacing: Spacing.md) {
            evaluationSummaryCard(result)

            if !result.grammarMistakes.isEmpty {
                grammarMistakesCard(result.grammarMistakes)
            }

            if !result.unnaturalPhrases.isEmpty {
                unnaturalPhrasesCard(result.unnaturalPhrases)
            }

            if !result.unnaturalWords.isEmpty {
                unnaturalWordsCard(result.unnaturalWords)
            }

            if !result.improvedVersion.isEmpty {
                improvedVersionCard(result.improvedVersion)
            }
        }
    }

    // MARK: - Evaluation Result Cards

    private func evaluationSummaryCard(_ result: EvaluationResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppColors.darkGreen)
                Text(Strings.Evaluation.title)
                    .font(Typography.headingSmall)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(result.cefrLevel)
                    .font(Typography.labelMedium.weight(.semibold))
                    .foregroundColor(AppColors.darkGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.green.opacity(0.4))
                    .cornerRadius(8)
            }

            Text(result.summary)
                .font(Typography.body)
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle()
    }

    private func grammarMistakesCard(_ mistakes: [GrammarMistake]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red.opacity(0.8))
                Text(Strings.Evaluation.grammarMistakesTitle)
                    .font(Typography.headingSmall)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(mistakes.count)")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(Array(mistakes.enumerated()), id: \.offset) { _, mistake in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 6) {
                            Text(mistake.original)
                                .strikethrough()
                                .foregroundColor(.red.opacity(0.7))
                            Text("→")
                                .foregroundColor(AppColors.textTertiary)
                            Text(mistake.correction)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.darkGreen)
                        }
                        .font(Typography.body)

                        Text(mistake.explanation)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .cardStyle(backgroundColor: AppColors.beige)
    }

    private func unnaturalPhrasesCard(_ phrases: [UnnaturalPhrase]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundColor(.orange.opacity(0.8))
                Text(Strings.Evaluation.unnaturalPhrasesTitle)
                    .font(Typography.headingSmall)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(phrases.count)")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(Array(phrases.enumerated()), id: \.offset) { _, phrase in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 6) {
                            Text(phrase.phrase)
                                .foregroundColor(.orange.opacity(0.8))
                            Text("→")
                                .foregroundColor(AppColors.textTertiary)
                            Text(phrase.naturalReplacement)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.darkGreen)
                        }
                        .font(Typography.body)

                        Text(phrase.explanation)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .cardStyle(backgroundColor: AppColors.darkBeige)
    }

    private func unnaturalWordsCard(_ words: [UnnaturalWord]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "pencil.line")
                    .foregroundColor(AppColors.darkBlue)
                Text(Strings.Evaluation.wordChoicesTitle)
                    .font(Typography.headingSmall)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(words.count)")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 6) {
                            Text(word.word)
                                .foregroundColor(AppColors.darkBlue)
                            Text("→")
                                .foregroundColor(AppColors.textTertiary)
                            Text(word.betterWord)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.darkGreen)
                        }
                        .font(Typography.body)

                        Text(word.explanation)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .cardStyle(backgroundColor: AppColors.blue.opacity(0.3))
    }

    private func improvedVersionCard(_ improvedVersion: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppColors.darkGreen)
                Text(Strings.Evaluation.improvedVersionTitle)
                    .font(Typography.headingSmall)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(improvedVersion)
                .font(Typography.body)
                .italic()
                .foregroundColor(AppColors.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle(backgroundColor: AppColors.green.opacity(0.2))
    }

    // MARK: - Actions

    private func requestReport() async {
        isRequesting = true
        defer { isRequesting = false }

        await onRequestReport()
        startPolling()
    }

    private func requestEvaluation() async {
        isRequestingEvaluation = true
        defer { isRequestingEvaluation = false }

        await onRequestEvaluation()
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

                if !shouldPoll {
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
