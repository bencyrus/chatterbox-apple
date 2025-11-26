import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.cues.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.cues.isEmpty {
                Text(Strings.Home.emptyState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List(viewModel.cues, id: \.content.cueContentId) { cue in
                    NavigationLink {
                        CueDetailView(cue: cue)
                    } label: {
                        Text(cue.content.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .accessibilityIdentifier("home.cue.\(cue.content.cueContentId).title")
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadInitialCues()
        }
        .onReceive(NotificationCenter.default.publisher(for: .activeProfileDidChange)) { _ in
            Task {
                await viewModel.reloadForActiveProfileChange()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        await viewModel.shuffleCues()
                    }
                } label: {
                    Text(Strings.Home.shuffle)
                }
                .accessibilityIdentifier("home.shuffle")
            }
        }
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

