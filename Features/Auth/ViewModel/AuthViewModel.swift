import Foundation
import Observation

@Observable
final class AuthViewModel {
    var identifier: String = ""
    var isRequesting: Bool = false
    var errorMessage: String = ""
    var isShowingErrorAlert: Bool = false
    var errorAlertTitle: String = ""
    var errorAlertMessage: String = ""
    var cooldownSecondsRemaining: Int = 0
    private var cooldownTask: Task<Void, Never>? = nil

    private let logoutUC: LogoutUseCase
    private let requestMagicLinkUC: RequestMagicLinkUseCase
    private let loginWithMagicTokenUC: LoginWithMagicTokenUseCase

    init(logout: LogoutUseCase, requestMagicLink: RequestMagicLinkUseCase, loginWithMagicToken: LoginWithMagicTokenUseCase) {
        self.logoutUC = logout
        self.requestMagicLinkUC = requestMagicLink
        self.loginWithMagicTokenUC = loginWithMagicToken
    }


    // Magic Link: request link
    @MainActor
    func requestMagicLink() async {
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            presentSignInError(message: Strings.Errors.missingIdentifier)
            return
        }
        guard cooldownSecondsRemaining == 0 else { return }
        isRequesting = true
        defer { isRequesting = false }
        do {
            try await requestMagicLinkUC.execute(identifier: identifier)
            // Start a 60s cooldown
            startCooldown(seconds: 60)
        } catch {
            presentSignInError(message: Strings.Errors.requestFailed)
        }
    }

    // Magic Link: handle incoming deeplink
    func handleIncomingMagicToken(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let tokenItem = comps.queryItems?.first(where: { $0.name == "token" }),
              let token = tokenItem.value, !token.isEmpty else {
            return
        }
        let loginUseCase = loginWithMagicTokenUC
        let viewModel = self
        Task {
            do {
                try await loginUseCase.execute(token: token)
            } catch {
                await MainActor.run {
                    if case AuthError.invalidMagicLink = error {
                        viewModel.presentSignInError(message: Strings.Errors.invalidMagicLink)
                    } else {
                        viewModel.presentSignInError(message: Strings.Errors.requestFailed)
                    }
                }
            }
        }
    }

    @MainActor
    private func presentSignInError(message: String) {
        self.errorMessage = message
        self.errorAlertTitle = Strings.Errors.signInErrorTitle
        self.errorAlertMessage = message
        self.isShowingErrorAlert = true
    }

    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()
        cooldownSecondsRemaining = max(0, seconds)
        let task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                await MainActor.run {
                    if self.cooldownSecondsRemaining > 0 {
                        self.cooldownSecondsRemaining -= 1
                    }
                }
                if await MainActor.run(body: { self.cooldownSecondsRemaining }) == 0 {
                    break
                }
            }
        }
        cooldownTask = task
    }

    deinit {
        cooldownTask?.cancel()
    }

    func logout() {
        logoutUC.execute()
    }
}


