import SwiftUI

struct LoginView: View {
    @State private var authViewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _authViewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
                .cornerRadius(20)
                .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
                .accessibilityHidden(true)

            Text(Strings.Login.title)
                .font(Typography.displayMedium)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 24) {
                FormTextField(
                    label: Strings.Login.identifierPlaceholder,
                    text: $authViewModel.identifier,
                    keyboardType: .emailAddress,
                    autocapitalization: .never,
                    autocorrection: false,
                    accessibilityLabel: Strings.A11y.identifierField
                )

                Button {
                    Task { await authViewModel.requestMagicLink() }
                } label: {
                    Text(Strings.Login.requestLink)
                }
                .buttonStyle(PillButtonStyle())
                .disabled(authViewModel.isRequesting || authViewModel.cooldownSecondsRemaining > 0)
                .opacity(authViewModel.isRequesting || authViewModel.cooldownSecondsRemaining > 0 ? 0.5 : 1.0)
            }
            .padding(.bottom, Spacing.sm)

            if authViewModel.cooldownSecondsRemaining > 0 {
                Text(String(format: Strings.Login.cooldownMessage, authViewModel.cooldownSecondsRemaining))
                    .font(.footnote)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(Strings.Login.linkSentHint)
                    .font(.footnote)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
        .background(AppColors.pageBackground.ignoresSafeArea())
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
