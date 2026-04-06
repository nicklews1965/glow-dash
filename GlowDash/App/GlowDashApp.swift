import SwiftUI

@main
struct GlowDashApp: App {

    init() {
        // Initialize GameCenter authentication
        GameCenterManager.shared.authenticate()
        // Initialize ad consent + ATT + SDK
        AdManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .persistentSystemOverlays(.hidden)
                .preferredColorScheme(.dark)
        }
    }
}
