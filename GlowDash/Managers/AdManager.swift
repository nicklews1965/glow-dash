import GoogleMobileAds
import AppTrackingTransparency
import UserMessagingPlatform
import UIKit

/// Manages all ad loading, display, and consent flows.
/// The game works fully without ads — all ad operations fail gracefully.
@MainActor
final class AdManager: NSObject, ObservableObject {

    static let shared = AdManager()

    // MARK: - Published State (for SwiftUI banner visibility)

    @Published var showBanner: Bool = false
    @Published var isBannerLoaded: Bool = false

    // MARK: - Ad Objects

    private var rewardedAd: GADRewardedAd?
    private var interstitialAd: GADInterstitialAd?
    private(set) var bannerView: GADBannerView?

    // MARK: - State

    private(set) var isInitialized: Bool = false
    private(set) var canRequestAds: Bool = false
    private var continuesUsedThisGame: Int = 0

    // MARK: - Callbacks

    private var rewardedCompletion: ((Bool) -> Void)?
    private var interstitialCompletion: (() -> Void)?

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    /// Call once on app launch. Handles consent → ATT → SDK init → ad preloading.
    func configure() {
        requestConsentAndInitialize()
    }

    /// Reset per-game state (call at start of each game).
    func resetForNewGame() {
        continuesUsedThisGame = 0
    }

    /// Whether the player can still use a rewarded continue this game.
    var canContinue: Bool {
        continuesUsedThisGame < GameConstants.maxContinuesPerGame && rewardedAd != nil
    }

    // MARK: - Consent & ATT Flow

    private func requestConsentAndInitialize() {
        // Step 1: Request UMP consent info update
        let params = UMPRequestParameters()
        params.tagForUnderAgeOfConsent = false

        // For testing consent flow, uncomment:
        // let debugSettings = UMPDebugSettings()
        // debugSettings.testDeviceIdentifiers = ["YOUR-TEST-DEVICE-ID"]
        // debugSettings.geography = .EEA
        // params.debugSettings = debugSettings

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: params) { [weak self] error in
            guard let self else { return }

            if let error {
                print("[AdManager] Consent info error: \(error.localizedDescription)")
                // Continue anyway — ads will be non-personalized
                self.requestATTAndStartSDK()
                return
            }

            // Step 2: Show consent form if required
            UMPConsentForm.loadAndPresentIfRequired(from: self.rootViewController) { [weak self] error in
                if let error {
                    print("[AdManager] Consent form error: \(error.localizedDescription)")
                }
                self?.requestATTAndStartSDK()
            }
        }
    }

    private func requestATTAndStartSDK() {
        // Step 3: Request App Tracking Transparency authorization
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                Task { @MainActor in
                    self?.startMobileAdsSDK()
                }
            }
        } else {
            startMobileAdsSDK()
        }
    }

    private func startMobileAdsSDK() {
        guard !isInitialized else { return }

        // Check if we can request ads (consent was given or not required)
        canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds

        GADMobileAds.sharedInstance().start { [weak self] _ in
            guard let self else { return }
            self.isInitialized = true
            print("[AdManager] Mobile Ads SDK initialized. canRequestAds: \(self.canRequestAds)")

            // Start preloading ads
            self.preloadRewardedAd()
            self.preloadInterstitialAd()
            self.setupBannerView()
        }
    }

    // MARK: - Root View Controller

    private var rootViewController: UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return nil
        }
        // Walk the presentation chain to find the topmost VC
        var topVC = root
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }

    // MARK: - Rewarded Ads

    private func preloadRewardedAd() {
        guard isInitialized else { return }

        GADRewardedAd.load(withAdUnitID: GameConstants.rewardedAdUnitID,
                           request: GADRequest()) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                print("[AdManager] Rewarded ad failed to load: \(error.localizedDescription)")
                // Retry after delay
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(30))
                    self.preloadRewardedAd()
                }
                return
            }
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            print("[AdManager] Rewarded ad loaded")
        }
    }

    /// Show a rewarded ad for "continue" or "double score".
    /// Completion returns true if the reward was earned, false otherwise.
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd, let vc = rootViewController else {
            completion(false)
            return
        }

        rewardedCompletion = completion

        ad.present(fromRootViewController: vc) { [weak self] in
            // Reward earned
            self?.continuesUsedThisGame += 1
            self?.rewardedCompletion?(true)
            self?.rewardedCompletion = nil
        }
    }

    // MARK: - Interstitial Ads

    private func preloadInterstitialAd() {
        guard isInitialized else { return }

        GADInterstitialAd.load(withAdUnitID: GameConstants.interstitialAdUnitID,
                               request: GADRequest()) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                print("[AdManager] Interstitial failed to load: \(error.localizedDescription)")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(30))
                    self.preloadInterstitialAd()
                }
                return
            }
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            print("[AdManager] Interstitial loaded")
        }
    }

    /// Show interstitial if it's the right time (every Nth death, not first).
    /// Completion is called when the ad is dismissed (or immediately if no ad).
    func showInterstitialIfNeeded(completion: @escaping () -> Void) {
        let deathCount = GameManager.shared.deathCountThisSession

        // Don't show on first death, show every Nth death after that
        guard deathCount > 1,
              deathCount % GameConstants.interstitialFrequency == 0,
              let ad = interstitialAd,
              let vc = rootViewController else {
            completion()
            return
        }

        interstitialCompletion = completion
        ad.present(fromRootViewController: vc)
    }

    // MARK: - Banner Ads

    private func setupBannerView() {
        guard isInitialized else { return }

        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = GameConstants.bannerAdUnitID
        banner.rootViewController = rootViewController
        banner.delegate = self
        banner.load(GADRequest())

        bannerView = banner
    }

    /// Reload banner ad (call when banner should refresh).
    func reloadBanner() {
        bannerView?.load(GADRequest())
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdManager: GADFullScreenContentDelegate {

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdManager] Full-screen ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            // If rewarded ad failed, notify completion
            if ad is GADRewardedAd {
                self.rewardedCompletion?(false)
                self.rewardedCompletion = nil
                self.preloadRewardedAd()
            }
            // If interstitial failed, call completion
            if ad is GADInterstitialAd {
                self.interstitialCompletion?()
                self.interstitialCompletion = nil
                self.preloadInterstitialAd()
            }
        }
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            // Preload next ad after dismissal
            if ad is GADRewardedAd {
                self.preloadRewardedAd()
            }
            if ad is GADInterstitialAd {
                self.interstitialCompletion?()
                self.interstitialCompletion = nil
                self.preloadInterstitialAd()
            }
        }
    }
}

// MARK: - GADBannerViewDelegate

extension AdManager: GADBannerViewDelegate {

    nonisolated func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        Task { @MainActor in
            self.isBannerLoaded = true
            print("[AdManager] Banner loaded")
        }
    }

    nonisolated func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            self.isBannerLoaded = false
            print("[AdManager] Banner failed: \(error.localizedDescription)")
        }
    }
}
