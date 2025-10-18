import SwiftUI

struct LoginView: View {
    @State private var vm: AuthViewModel

    init(viewModel: AuthViewModel) {
        _vm = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(Strings.Login.title)
                .font(.title)
                .bold()
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                TextField(Strings.Login.identifierPlaceholder, text: $vm.identifier)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.plain)
                    .accessibilityLabel(Text(Strings.A11y.identifierField))

                HStack(spacing: 12) {
                    TextField(Strings.Login.codePlaceholder, text: $vm.code)
                        .textFieldStyle(.plain)
                        .accessibilityLabel(Text(Strings.A11y.codeField))

                    Button(Strings.Login.requestCode) {
                        Task { await vm.requestCode() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(vm.isRequesting)
                }
            }

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(Text(Strings.A11y.errorLabel))
            }

            Button(Strings.Login.verifyAndContinue) {
                Task { await vm.verifyCode() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isVerifying)

            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.95))
    }
}


