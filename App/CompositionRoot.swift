import SwiftUI
import Observation

struct CompositionRootView: View {
    @Environment(TokenManager.self) private var tokenManager
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Group {
            if tokenManager.hasValidAccessToken {
                RootTabView()
            } else {
                let authViewModel = makeAuthViewModel()
                LoginView(viewModel: authViewModel)
                    .onReceive(NotificationCenter.default.publisher(for: .didOpenMagicTokenURL)) { note in
                        guard let url = note.object as? URL else { return }
                        authViewModel.handleIncomingMagicToken(url: url)
                    }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func makeAuthViewModel() -> AuthViewModel {
        let client = APIClient(baseURL: env.baseURL, tokenProvider: tokenManager, tokenSink: tokenManager)
        let repo = PostgrestAuthRepository(client: client, environment: env)
        let logoutUC = LogoutUseCase(tokenSink: tokenManager)
        let requestMagic = RequestMagicLinkUseCase(repository: repo)
        let loginWithMagic = LoginWithMagicTokenUseCase(repository: repo, tokenSink: tokenManager)
        return AuthViewModel(
            logout: logoutUC,
            requestMagicLink: requestMagic,
            loginWithMagicToken: loginWithMagic,
            environment: env
        )
    }
}


