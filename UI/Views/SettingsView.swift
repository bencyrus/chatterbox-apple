import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var selectedLanguageCode: String = ""
    @Environment(TokenManager.self) private var tokenManager

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Picker(Strings.Settings.languagePickerTitle, selection: $selectedLanguageCode) {
                ForEach(viewModel.availableLanguages, id: \.self) { code in
                    Text(code.uppercased())
                        .tag(code)
                }
            }
            .pickerStyle(.menu)
            .tint(AppColors.textPrimary)
            .accessibilityIdentifier("settings.languagePicker")

            Spacer()
            Button {
                tokenManager.clearTokens()
            } label: {
                Text(Strings.Settings.logout)
                    .font(.body)
                    .fontWeight(.medium)
            .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
            )
            }
            .accessibilityLabel(Text(Strings.A11y.logout))
            Spacer()
        }
        .padding()
        .background(AppColors.sand.ignoresSafeArea())
        .task {
            await viewModel.load()
            selectedLanguageCode = viewModel.selectedLanguageCode ?? ""
        }
        .onChange(of: selectedLanguageCode) { _, newValue in
            Task {
                await viewModel.updateLanguage(to: newValue)
            }
        }
        .alert(viewModel.errorAlertTitle, isPresented: $viewModel.isShowingErrorAlert) {
            Button(Strings.Common.ok, role: .cancel) {}
        } message: {
            Text(viewModel.errorAlertMessage)
        }
    }
}
