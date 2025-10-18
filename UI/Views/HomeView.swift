import SwiftUI

struct HomeView: View {
    @Environment(TokenManager.self) private var tokenManager

    var body: some View {
        VStack(spacing: 16) {
            Text(Strings.Home.latestJWT)
                .font(.headline)
            ScrollView {
                Text(tokenManager.accessToken ?? Strings.Home.noToken)
                    .font(.footnote.monospaced())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(Color.black.opacity(0.95))
    }
}


