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
                    // Restrict to HTTPS universal links in production and expected host
                    guard url.scheme?.lowercased() == "https" else { return }
                    guard let host = url.host?.lowercased(), environment.universalLinkAllowedHosts.contains(host) else { return }
                    if url.path.lowercased() == environment.magicLinkPath.lowercased() {
                        NotificationCenter.default.post(name: .didOpenMagicTokenURL, object: url)
                    }
                }
        }
    }
}

extension Notification.Name {
    static let didOpenMagicTokenURL = Notification.Name("didOpenMagicTokenURL")
}


