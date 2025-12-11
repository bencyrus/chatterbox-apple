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
    var errorAlertLinkURL: URL? = nil
    var cooldownSecondsRemaining: Int = 0
    private var cooldownTask: Task<Void, Never>? = nil
    private var cooldownExpiryDate: Date? = nil

    private static let cooldownExpiryDefaultsKey = "AuthViewModel.magicLinkCooldownExpiry"

    private let logoutUC: LogoutUseCase
    private let requestMagicLinkUC: RequestMagicLinkUseCase
    private let configProvider: ConfigProviding

    init(
        logout: LogoutUseCase,
        requestMagicLink: RequestMagicLinkUseCase,
        configProvider: ConfigProviding
    ) {
        self.logoutUC = logout
        self.requestMagicLinkUC = requestMagicLink
        self.configProvider = configProvider

        restoreCooldownIfNeeded()
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
            let isImmediateLogin = try await requestMagicLinkUC.execute(identifier: identifier)
            if !isImmediateLogin {
                // Normal flow: start cooldown only for non-reviewer accounts
                startCooldown(seconds: configProvider.snapshot.magicLinkCooldownSeconds)
            }
            // If isImmediateLogin is true, session is already updated and user will be logged in
        } catch {
            if let authError = error as? AuthError {
                switch authError {
                case .invalidMagicLink:
                    presentSignInError(message: Strings.Errors.requestFailed)
                case .accountDeleted(let message):
                    // Surface the server-provided message so support URL can be configured via secrets.
                    presentSignInError(message: message)
                }
            } else {
                presentSignInError(message: Strings.Errors.requestFailed)
            }
        }
    }

    @MainActor
    private func presentSignInError(message: String) {
        self.errorMessage = message
        self.errorAlertTitle = Strings.Errors.signInErrorTitle
        self.errorAlertMessage = message
        self.errorAlertLinkURL = Self.extractFirstURL(from: message)
        self.isShowingErrorAlert = true
    }

    private static func extractFirstURL(from text: String) -> URL? {
        guard let range = text.range(of: "https://") else {
            return nil
        }
        let substringFromURL = text[range.lowerBound...]
        // Split on whitespace or newline to get the URL token.
        let components = substringFromURL.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        guard let first = components.first else {
            return nil
        }
        return URL(string: String(first))
    }

    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()

        guard seconds > 0 else {
            cooldownSecondsRemaining = 0
            cooldownExpiryDate = nil
            UserDefaults.standard.removeObject(forKey: Self.cooldownExpiryDefaultsKey)
            return
        }

        let expiry = Date().addingTimeInterval(TimeInterval(seconds))
        cooldownExpiryDate = expiry
        UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: Self.cooldownExpiryDefaultsKey)

        // Set initial value immediately so UI updates without waiting 1s.
        cooldownSecondsRemaining = max(0, Int(ceil(expiry.timeIntervalSinceNow)))

        let task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                let remaining = max(0, Int(ceil(expiry.timeIntervalSinceNow)))

                await MainActor.run {
                    self.cooldownSecondsRemaining = remaining
                }

                if remaining == 0 {
                    await MainActor.run {
                        self.cooldownExpiryDate = nil
                        UserDefaults.standard.removeObject(forKey: Self.cooldownExpiryDefaultsKey)
                    }
                    break
                }
            }
        }
        cooldownTask = task
    }

    /// Restores an in‑progress cooldown based on the last stored expiry time.
    private func restoreCooldownIfNeeded() {
        guard let timestamp = UserDefaults.standard.object(forKey: Self.cooldownExpiryDefaultsKey) as? TimeInterval else {
            return
        }

        let expiry = Date(timeIntervalSince1970: timestamp)
        let remaining = Int(ceil(expiry.timeIntervalSinceNow))

        if remaining > 0 {
            startCooldown(seconds: remaining)
        } else {
            cooldownSecondsRemaining = 0
            cooldownExpiryDate = nil
            UserDefaults.standard.removeObject(forKey: Self.cooldownExpiryDefaultsKey)
        }
    }

    deinit {
        cooldownTask?.cancel()
    }

    func logout() {
        logoutUC.execute()
    }
}


