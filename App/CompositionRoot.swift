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
                LoginView(viewModel: makeAuthViewModel())
            }
        }
        .preferredColorScheme(.dark)
    }

    private func makeAuthViewModel() -> AuthViewModel {
        let client = APIClient(baseURL: env.baseURL, tokenProvider: tokenManager, tokenSink: tokenManager)
        let repo = PostgrestAuthRepository(client: client, environment: env)
        let requestUC = RequestOTPCodeUseCase(repository: repo)
        let verifyUC = VerifyOTPCodeUseCase(repository: repo, tokenSink: tokenManager)
        let logoutUC = LogoutUseCase(tokenSink: tokenManager)
        return AuthViewModel(requestCode: requestUC, verifyCode: verifyUC, logout: logoutUC)
    }
}


