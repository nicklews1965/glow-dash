import GoogleMobileAds
import SwiftUI

/// UIViewRepresentable wrapper for GADBannerView in SwiftUI.
struct AdBannerView: UIViewRepresentable {

    func makeUIView(context: Context) -> GADBannerView {
        let banner = AdManager.shared.bannerView ?? GADBannerView(adSize: GADAdSizeBanner)
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // Banner updates are managed by AdManager
    }
}
