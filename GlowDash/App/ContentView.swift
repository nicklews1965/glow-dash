import SpriteKit
import SwiftUI

struct ContentView: View {

    @ObservedObject private var adManager = AdManager.shared

    private let scene: SKScene = {
        let scene = MenuScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            // Banner ad at bottom (only on menu/game-over screens)
            if adManager.showBanner && adManager.isBannerLoaded {
                AdBannerView()
                    .frame(height: GameConstants.bannerAdHeight)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut(duration: 0.2), value: adManager.showBanner)
            }
        }
    }
}
