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
        }
    }
}


