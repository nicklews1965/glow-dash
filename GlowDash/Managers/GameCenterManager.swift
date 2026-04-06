import GameKit

/// Manages GameCenter authentication, leaderboard submissions, and achievements.
@MainActor
final class GameCenterManager {

    static let shared = GameCenterManager()

    private(set) var isAuthenticated: Bool = false

    private init() {}

    // MARK: - Authentication

    /// Authenticate the local player. Call on app launch.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let error {
                    print("[GameCenter] Auth error: \(error.localizedDescription)")
                    self?.isAuthenticated = false
                    return
                }

                if let vc = viewController {
                    // Present the GameCenter sign-in view controller
                    self?.presentViewController(vc)
                    return
                }

                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                print("[GameCenter] Authenticated: \(GKLocalPlayer.local.isAuthenticated)")
            }
        }
    }

    // MARK: - Leaderboard

    /// Submit a score to the leaderboard.
    func submitScore(_ score: Int) {
        guard isAuthenticated else { return }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [GameConstants.leaderboardID]
        ) { error in
            if let error {
                print("[GameCenter] Score submit error: \(error.localizedDescription)")
            } else {
                print("[GameCenter] Score \(score) submitted")
            }
        }
    }

    /// Show the GameCenter leaderboard UI.
    func showLeaderboard() {
        guard isAuthenticated else { return }

        let gcVC = GKGameCenterViewController(leaderboardID: GameConstants.leaderboardID,
                                               playerScope: .global,
                                               timeScope: .allTime)
        gcVC.gameCenterDelegate = GameCenterDelegateHandler.shared
        presentViewController(gcVC)
    }

    // MARK: - Achievements

    /// Report an achievement as 100% complete.
    func reportAchievement(_ id: String) {
        guard isAuthenticated else { return }

        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = 100
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { error in
            if let error {
                print("[GameCenter] Achievement error: \(error.localizedDescription)")
            } else {
                print("[GameCenter] Achievement reported: \(id)")
            }
        }
    }

    /// Check and report achievements based on current score and total games.
    func checkAchievements(currentScore: Int, totalGames: Int, dailyChallengeComplete: Bool) {
        if currentScore >= 10  { reportAchievement(GameConstants.achievementScore10) }
        if currentScore >= 25  { reportAchievement(GameConstants.achievementScore25) }
        if currentScore >= 50  { reportAchievement(GameConstants.achievementScore50) }
        if currentScore >= 100 { reportAchievement(GameConstants.achievementScore100) }
        if totalGames >= 10    { reportAchievement(GameConstants.achievementPlay10) }
        if totalGames >= 50    { reportAchievement(GameConstants.achievementPlay50) }
        if totalGames >= 100   { reportAchievement(GameConstants.achievementPlay100) }
        if dailyChallengeComplete { reportAchievement(GameConstants.achievementDaily) }
    }

    /// Show the GameCenter achievements UI.
    func showAchievements() {
        guard isAuthenticated else { return }

        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = GameCenterDelegateHandler.shared
        presentViewController(gcVC)
    }

    // MARK: - Helpers

    private func presentViewController(_ vc: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(vc, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate

/// Handles GameCenter view controller dismissal.
final class GameCenterDelegateHandler: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDelegateHandler()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
