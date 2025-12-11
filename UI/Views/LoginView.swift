import SwiftUI

struct LoginView: View {
    @State private var authViewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _authViewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(Strings.Login.title)
                .font(Typography.title)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                TextField(Strings.Login.identifierPlaceholder, text: $authViewModel.identifier)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(AppColors.beige)
                    .cornerRadius(8)
                    .foregroundColor(AppColors.textPrimary)
                    .accessibilityLabel(Text(Strings.A11y.identifierField))

                Button {
                    Task { await authViewModel.requestMagicLink() }
                } label: {
                    Text(Strings.Login.requestLink)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(authViewModel.isRequesting || authViewModel.cooldownSecondsRemaining > 0)
                .opacity(authViewModel.isRequesting || authViewModel.cooldownSecondsRemaining > 0 ? 0.5 : 1.0)
            }

            if authViewModel.cooldownSecondsRemaining > 0 {
                Text(String(format: Strings.Login.cooldownMessage, authViewModel.cooldownSecondsRemaining))
                    .font(.footnote)
                    .foregroundColor(AppColors.textPrimary.opacity(0.6))
                    .multilineTextAlignment(.center)
            } else {
                Text(Strings.Login.linkSentHint)
                    .font(.footnote)
                    .foregroundColor(AppColors.textPrimary.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
        .background(AppColors.sand.ignoresSafeArea())
        .alert(Strings.Errors.signInErrorTitle, isPresented: $authViewModel.isShowingErrorAlert) {
            if let url = authViewModel.errorAlertLinkURL {
                Button(Strings.Login.openSupportPage) {
                    #if canImport(UIKit)
                    UIApplication.shared.open(url)
                    #endif
                }
            }
            Button(Strings.Common.ok, role: .cancel) {}
        } message: {
            Text(authViewModel.errorAlertMessage)
        }
    }
}
