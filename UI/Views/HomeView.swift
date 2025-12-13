import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    let cueDetailViewModel: CueDetailViewModel

    init(viewModel: HomeViewModel, cueDetailViewModel: CueDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
        self.cueDetailViewModel = cueDetailViewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            PageHeader(Strings.Subjects.title) {
                ShuffleButton {
                    Task {
                        await viewModel.shuffleCues()
                    }
                }
            }

            Group {
                if viewModel.isLoading && viewModel.cues.isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.cues.isEmpty {
                    EmptyState(
                        icon: "rectangle.stack",
                        title: Strings.Subjects.emptyState
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(viewModel.cues.enumerated()), id: \.offset) { _, cue in
                                NavigationLink {
                                    CueDetailView(cue: cue, viewModel: cueDetailViewModel)
                                } label: {
                                    CueCardView(cue: cue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(AppColors.sand.ignoresSafeArea())
        .task {
            await viewModel.loadInitialCues()
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
}

private struct CueCardView: View {
    let cue: Cue

    var body: some View {
        Text(cue.content.title)
            .font(.headline)
            .foregroundColor(AppColors.textPrimary)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Slightly taller than exactly 3 line-heights so three full lines fit comfortably
            .frame(height: 22 * 3.5, alignment: .topLeading)
            .cardStyle()
            .accessibilityIdentifier("subjects.cue.\(cue.content.cueContentId).title")
    }
}

private struct ShuffleButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "shuffle")
                Text(Strings.Subjects.shuffle)
            }
            .font(.callout.bold())
            .foregroundColor(AppColors.textContrast)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(AppColors.textPrimary)
            .cornerRadius(24)
        }
        .accessibilityIdentifier("subjects.shuffle")
    }
}
