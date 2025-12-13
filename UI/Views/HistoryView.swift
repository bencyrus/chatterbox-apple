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
                    EmptyState(
                        icon: "waveform.circle",
                        title: Strings.History.emptyState
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.lg, pinnedViews: []) {
                            ForEach(viewModel.groupedRecordings) { group in
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    // Date header with badges
                                    HStack(spacing: Spacing.sm) {
                                        // Date badge
                                        Badge(
                                            text: formatGroupDate(group.date),
                                            icon: "calendar"
                                        )
                                        
                                        // Count badge
                                        Badge(
                                            text: "\(group.recordings.count)",
                                            backgroundColor: AppColors.green
                                        )
                                        
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
            return Strings.Common.today
        } else if compareDate == calendar.date(byAdding: .day, value: -1, to: today) {
            return Strings.Common.yesterday
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}


