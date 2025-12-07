import SwiftUI

struct CompositionRootView: View {
    let coordinator: AppCoordinator

    @State private var isAuthenticated: Bool = false

    var body: some View {
        Group {
            if isAuthenticated {
                let homeVM = coordinator.makeHomeViewModel()
                let historyVM = coordinator.makeHistoryViewModel()
                let settingsVM = coordinator.makeSettingsViewModel()
                let cueDetailVM = coordinator.makeCueDetailViewModel()

                RootTabView(
                    homeViewModel: homeVM,
                    historyViewModel: historyVM,
                    settingsViewModel: settingsVM,
                    cueDetailViewModel: cueDetailVM
                )
            } else {
                let authViewModel = coordinator.makeAuthViewModel()
                LoginView(viewModel: authViewModel)
            }
        }
        .task {
            await coordinator.sessionController.bootstrap()
            let initialState = await coordinator.sessionController.currentState
            await MainActor.run {
                self.isAuthenticated = (initialState == .authenticated)
            }

            // Once authenticated, eagerly load account metadata so that
            // account flags (e.g. `developer`) are applied and developer
            // tooling visibility is correct before the user navigates.
            if initialState == .authenticated {
                let settingsVM = coordinator.makeSettingsViewModel()
                await settingsVM.load()
            }

            for await state in coordinator.sessionController.stateStream {
                await MainActor.run {
                    self.isAuthenticated = (state == .authenticated)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

