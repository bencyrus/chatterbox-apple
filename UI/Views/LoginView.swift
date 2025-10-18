import SwiftUI

struct LoginView: View {
    @State private var authViewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _authViewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(Strings.Login.title)
                .font(.title)
                .bold()
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                TextField(Strings.Login.identifierPlaceholder, text: $authViewModel.identifier)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.plain)
                    .accessibilityLabel(Text(Strings.A11y.identifierField))

                Button(Strings.Login.requestLink) {
                    Task { await authViewModel.requestMagicLink() }
                }
                .buttonStyle(.bordered)
                .disabled(authViewModel.isRequesting)
            }

            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(Text(Strings.A11y.errorLabel))
            }

            Text(Strings.Login.linkSentHint)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.95))
    }
}


