import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            PageHeader(Strings.Home.title) {
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
                Text(Strings.Home.emptyState)
                        .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.cues, id: \.content.cueContentId) { cue in
                    NavigationLink {
                        CueDetailView(cue: cue)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(AppColors.darkBeige)
            .cornerRadius(12)
            .accessibilityIdentifier("home.cue.\(cue.content.cueContentId).title")
    }
}

private struct ShuffleButton: View {
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "shuffle")
            Text(Strings.Home.shuffle)
        }
        .font(.callout.bold())
        .foregroundColor(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.black, in: Capsule())
        .contentShape(Capsule())
        .onTapGesture {
            onTap()
        }
        .accessibilityIdentifier("home.shuffle")
    }
}

struct PageHeader<Actions: View>: View {
    let title: String
    @ViewBuilder let actions: () -> Actions

    init(_ title: String, @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }) {
        self.title = title
        self.actions = actions
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions()
        }
        .padding(.horizontal)
    }
}
