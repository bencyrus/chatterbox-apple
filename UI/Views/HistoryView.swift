import SwiftUI

struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    let cueDetailViewModel: CueDetailViewModel
    
    init(viewModel: HistoryViewModel, cueDetailViewModel: CueDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
        self.cueDetailViewModel = cueDetailViewModel
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            PageHeader(Strings.History.title)
            
            Group {
                if viewModel.isLoading && viewModel.groupedRecordings.isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.groupedRecordings.isEmpty {
                    Text(Strings.History.emptyState)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.lg, pinnedViews: []) {
                            ForEach(viewModel.groupedRecordings) { group in
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
                                    .padding(.horizontal)
                                    .padding(.bottom, Spacing.xs)
                                    
                                    // Recordings for this date
                                    ForEach(group.recordings) { recording in
                                        NavigationLink {
                                            CueDetailView(
                                                cue: recording.cue,
                                                viewModel: cueDetailViewModel
                                            )
                                        } label: {
                                            RecordingHistoryCardView(recording: recording)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, Spacing.sm)
                    }
                }
            }
        }
        .background(AppColors.sand.ignoresSafeArea())
        .task {
            await viewModel.loadRecordingHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .activeProfileDidChange)) { _ in
            Task {
                await viewModel.reloadForActiveProfileChange()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            viewModel.errorAlertTitle,
            isPresented: $viewModel.isShowingErrorAlert
        ) {
            Button(Strings.Errors.okButton, role: .cancel) { }
        } message: {
            Text(viewModel.errorAlertMessage)
        }
    }
    
    private func formatGroupDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let compareDate = calendar.startOfDay(for: date)
        
        if compareDate == today {
            return "Today"
        } else if compareDate == calendar.date(byAdding: .day, value: -1, to: today) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}


