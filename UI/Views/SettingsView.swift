import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var selectedLanguageCode: String = ""
    @State private var showLanguagePicker = false

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            PageHeader(Strings.Settings.title)
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Language Selection Dropdown
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(Strings.Settings.languagePickerTitle)
                            .font(Typography.body.weight(.semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        Button {
                            showLanguagePicker = true
                        } label: {
                            HStack(spacing: Spacing.md) {
                                // Flag
                                Text(flagEmoji(for: selectedLanguageCode))
                                    .font(.system(size: 28))
                                
                                // Language name
                                Text(languageDisplayName(for: selectedLanguageCode))
                                    .font(Typography.body)
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Chevron down
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppColors.textPrimary.opacity(0.5))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.md)
                            .background(AppColors.darkBeige)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    .padding(.top, Spacing.sm)
                    
                    Spacer(minLength: Spacing.xl)
                    
                    // Logout Button
                    Button {
                        viewModel.logout()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text(Strings.Settings.logout)
                        }
                        .font(Typography.body.weight(.medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppColors.darkBeige)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, Spacing.md)
                    .accessibilityLabel(Text(Strings.A11y.logout))

                    // Delete Account Link (navigates to confirmation page)
                    NavigationLink {
                        DeleteAccountConfirmationView(viewModel: viewModel)
                    } label: {
                            Text(Strings.Settings.deleteAccount)
                            .font(Typography.body)
                        .foregroundColor(.red)
                            .underline()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, Spacing.xl * 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.md)
                    .accessibilityLabel(Text(Strings.A11y.deleteAccount))
                }
                .padding(.bottom, Spacing.lg)
            }
        }
        .background(AppColors.sand.ignoresSafeArea())
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet(
                availableLanguages: viewModel.availableLanguages,
                selectedLanguage: $selectedLanguageCode,
                onSelect: { code in
                    showLanguagePicker = false
                    Task {
                        await viewModel.updateLanguage(to: code)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
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
        .onChange(of: viewModel.selectedLanguageCode) { _, newValue in
            if let newValue = newValue, viewModel.availableLanguages.contains(newValue) {
                selectedLanguageCode = newValue
            }
        }
        .alert(viewModel.errorAlertTitle, isPresented: $viewModel.isShowingErrorAlert) {
            Button(Strings.Common.ok, role: .cancel) {}
        } message: {
            Text(viewModel.errorAlertMessage)
        }
    }

    private func languageDisplayName(for code: String) -> String {
        let languageNames: [String: String] = [
            "en": "English",
            "es": "Español",
            "fr": "Français",
            "de": "Deutsch",
            "it": "Italiano",
            "pt": "Português",
            "ru": "Русский",
            "zh": "中文",
            "ja": "日本語",
            "ko": "한국어",
            "ar": "العربية",
            "hi": "हिन्दी",
            "tr": "Türkçe",
            "nl": "Nederlands",
            "pl": "Polski"
        ]
        return languageNames[code] ?? code.uppercased()
    }
    
    private func flagEmoji(for languageCode: String) -> String {
        let countryMapping: [String: String] = [
            "en": "🇬🇧",
            "es": "🇪🇸",
            "fr": "🇫🇷",
            "de": "🇩🇪",
            "it": "🇮🇹",
            "pt": "🇵🇹",
            "ru": "🇷🇺",
            "zh": "🇨🇳",
            "ja": "🇯🇵",
            "ko": "🇰🇷",
            "ar": "🇸🇦",
            "hi": "🇮🇳",
            "tr": "🇹🇷",
            "nl": "🇳🇱",
            "pl": "🇵🇱"
        ]
        return countryMapping[languageCode] ?? "🌐"
    }
}

// MARK: - Delete Account Confirmation

struct DeleteAccountConfirmationView: View {
    @State private var viewModel: SettingsViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.sand.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                PageHeader(Strings.Settings.deleteAccountTitle)

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text(Strings.Settings.deleteAccountMessage)
                            .font(Typography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: Spacing.md) {
                            Button {
                                Task {
                                    await viewModel.requestAccountDeletion()
                                }
                            } label: {
                                Text(Strings.Settings.deleteAccountConfirm)
                            }
                            .buttonStyle(DestructiveButtonStyle())
                            .disabled(viewModel.isDeletingAccount)

                            Button {
                                dismiss()
                            } label: {
                                Text(Strings.Common.cancel)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding(.top, Spacing.lg)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
    }
}

// MARK: - Language Picker Sheet

struct LanguagePickerSheet: View {
    let availableLanguages: [String]
    @Binding var selectedLanguage: String
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    ForEach(availableLanguages, id: \.self) { code in
                        Button {
                            selectedLanguage = code
                            onSelect(code)
                        } label: {
                            HStack(spacing: Spacing.md) {
                                // Flag
                                Text(flagEmoji(for: code))
                                    .font(.system(size: 28))
                                
                                // Language name
                                Text(languageDisplayName(for: code))
                                    .font(Typography.body)
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Checkmark if selected
                                if selectedLanguage == code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.darkBlue)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.md)
                            .background(
                                selectedLanguage == code
                                    ? AppColors.darkBeige.opacity(0.8)
                                    : AppColors.darkBeige
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedLanguage == code
                                            ? AppColors.darkBlue.opacity(0.5)
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .background(AppColors.sand.ignoresSafeArea())
            .navigationTitle(Strings.Settings.languagePickerTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func languageDisplayName(for code: String) -> String {
        let languageNames: [String: String] = [
            "en": "English",
            "es": "Español",
            "fr": "Français",
            "de": "Deutsch",
            "it": "Italiano",
            "pt": "Português",
            "ru": "Русский",
            "zh": "中文",
            "ja": "日本語",
            "ko": "한국어",
            "ar": "العربية",
            "hi": "हिन्दी",
            "tr": "Türkçe",
            "nl": "Nederlands",
            "pl": "Polski"
        ]
        return languageNames[code] ?? code.uppercased()
    }
    
    private func flagEmoji(for languageCode: String) -> String {
        let countryMapping: [String: String] = [
            "en": "🇬🇧",
            "es": "🇪🇸",
            "fr": "🇫🇷",
            "de": "🇩🇪",
            "it": "🇮🇹",
            "pt": "🇵🇹",
            "ru": "🇷🇺",
            "zh": "🇨🇳",
            "ja": "🇯🇵",
            "ko": "🇰🇷",
            "ar": "🇸🇦",
            "hi": "🇮🇳",
            "tr": "🇹🇷",
            "nl": "🇳🇱",
            "pl": "🇵🇱"
        ]
        return countryMapping[languageCode] ?? "🌐"
    }
}
