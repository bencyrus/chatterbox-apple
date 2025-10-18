import Foundation
import Observation

@Observable
final class AuthViewModel {
    var identifier: String = ""
    var code: String = ""
    var isRequesting: Bool = false
    var isVerifying: Bool = false
    var errorMessage: String = ""

    private let requestCodeUC: RequestOTPCodeUseCase
    private let verifyCodeUC: VerifyOTPCodeUseCase
    private let logoutUC: LogoutUseCase

    init(requestCode: RequestOTPCodeUseCase, verifyCode: VerifyOTPCodeUseCase, logout: LogoutUseCase) {
        self.requestCodeUC = requestCode
        self.verifyCodeUC = verifyCode
        self.logoutUC = logout
    }

    @MainActor
    func requestCode() async {
        errorMessage = ""
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = Strings.Errors.missingIdentifier
            return
        }
        isRequesting = true
        defer { isRequesting = false }
        do {
            try await requestCodeUC.execute(identifier: identifier)
        } catch {
            errorMessage = Strings.Errors.requestFailed
        }
    }

    @MainActor
    func verifyCode() async {
        errorMessage = ""
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = Strings.Errors.missingIdentifier
            return
        }
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = Strings.Errors.missingCode
            return
        }
        isVerifying = true
        defer { isVerifying = false }
        do {
            try await verifyCodeUC.execute(identifier: identifier, code: code)
        } catch {
            errorMessage = Strings.Errors.invalidCode
        }
    }

    func logout() {
        logoutUC.execute()
    }
}


