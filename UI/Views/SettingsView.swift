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
            .accessibilityIdentifier("settings.languagePicker")

            Spacer()
            Button(Strings.Settings.logout) {
                tokenManager.clearTokens()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .foregroundColor(.red)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.6), lineWidth: 1)
            )
            .accessibilityLabel(Text(Strings.A11y.logout))
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.95))
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


