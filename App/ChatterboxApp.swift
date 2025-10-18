import SwiftUI
import Observation

@main
struct ChatterboxApp: App {
    @State private var tokenManager = TokenManager()
    private let environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            CompositionRootView()
                .environment(tokenManager)
                .environment(environment)
                .onOpenURL { url in
                    // Restrict to HTTPS universal links in production
                    guard url.scheme?.lowercased() == "https" else { return }
                    let path = url.path.lowercased()
                    if path == "/auth/magic" {
                        NotificationCenter.default.post(name: .didOpenMagicTokenURL, object: url)
                    }
                }
        }
    }
}

extension Notification.Name {
    static let didOpenMagicTokenURL = Notification.Name("didOpenMagicTokenURL")
}


