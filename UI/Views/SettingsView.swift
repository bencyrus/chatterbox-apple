import SwiftUI

struct SettingsView: View {
    @Environment(TokenManager.self) private var tokenManager

    var body: some View {
        VStack(spacing: 24) {
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
    }
}


