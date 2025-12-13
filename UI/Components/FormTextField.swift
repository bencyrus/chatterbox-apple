import SwiftUI

/// A reusable form text field with consistent styling.
///
/// Usage:
/// ```swift
/// @State private var email = ""
/// 
/// FormTextField(
///     label: "Email",
///     text: $email,
///     keyboardType: .emailAddress,
///     autocapitalization: .never
/// )
/// ```
struct FormTextField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrection: Bool = true
    var accessibilityLabel: String?
    
    var body: some View {
        TextField(label, text: $text)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(!autocorrection)
            .keyboardType(keyboardType)
            .textFieldStyle(.plain)
            .padding(Spacing.md)
            .background(AppColors.inputBackground)
            .cornerRadius(12)
            .foregroundColor(AppColors.textPrimary)
            .accessibilityLabel(Text(accessibilityLabel ?? label))
    }
}

