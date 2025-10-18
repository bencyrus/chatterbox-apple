import Foundation
import Observation

@Observable
final class AuthViewModel {
    var identifier: String = ""
    var isRequesting: Bool = false
    var errorMessage: String = ""

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
        errorMessage = ""
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = Strings.Errors.missingIdentifier
            return
        }
        isRequesting = true
        defer { isRequesting = false }
        do {
            try await requestMagicLinkUC.execute(identifier: identifier)
        } catch {
            errorMessage = Strings.Errors.requestFailed
        }
    }

    // Magic Link: handle incoming deeplink
    func handleIncomingMagicToken(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let tokenItem = comps.queryItems?.first(where: { $0.name == "token" }),
              let token = tokenItem.value, !token.isEmpty else {
            return
        }
        Task { [weak self] in
            do { try await self?.loginWithMagicTokenUC.execute(token: token) } catch {
                await MainActor.run { self?.errorMessage = Strings.Errors.requestFailed }
            }
        }
    }

    func logout() {
        logoutUC.execute()
    }
}


