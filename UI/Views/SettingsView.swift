import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var selectedLanguageCode: String = ""

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            if let email = viewModel.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textPrimary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Picker(Strings.Settings.languagePickerTitle, selection: $selectedLanguageCode) {
                ForEach(viewModel.availableLanguages, id: \.self) { code in
                    Text(languageDisplayName(for: code))
                        .tag(code)
                }
            }
            .pickerStyle(.menu)
            .tint(AppColors.textPrimary)
            .accessibilityIdentifier("settings.languagePicker")

            Spacer()
            Button {
                viewModel.logout()
            } label: {
                Text(Strings.Settings.logout)
            }
            .buttonStyle(DestructiveButtonStyle())
            .accessibilityLabel(Text(Strings.A11y.logout))
            Spacer()
        }
        .padding()
        .background(AppColors.sand.ignoresSafeArea())
        .task {
            await viewModel.load()
            // Ensure the picker selection always maps to a valid tag.
            if let selected = viewModel.selectedLanguageCode,
               viewModel.availableLanguages.contains(selected) {
                selectedLanguageCode = selected
            } else if let first = viewModel.availableLanguages.first {
                selectedLanguageCode = first
            } else {
                selectedLanguageCode = ""
            }
        }
        .onChange(of: selectedLanguageCode) { _, newValue in
            // Ignore transient values that don't correspond to a real option.
            guard viewModel.availableLanguages.contains(newValue) else { return }
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

    private func languageDisplayName(for code: String) -> String {
        let locale = Locale.current
        let name = locale.localizedString(forLanguageCode: code) ?? code.uppercased()
        return "\(name) (\(code.uppercased()))"
    }
}
