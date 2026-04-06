import Foundation

/// Manages game state transitions.
@MainActor
final class GameManager {

    enum State {
        case menu
        case playing
        case gameOver
        case paused
    }

    static let shared = GameManager()

    private(set) var state: State = .menu
    private(set) var deathCountThisSession: Int = 0

    private init() {}

    func startGame() {
        state = .playing
    }

    func endGame() {
        state = .gameOver
        deathCountThisSession += 1
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .playing
    }

    func returnToMenu() {
        state = .menu
    }

    func resetSession() {
        deathCountThisSession = 0
    }

    /// Whether it's appropriate to show an interstitial ad (every 3rd death, not on first).
    var shouldShowInterstitial: Bool {
        deathCountThisSession > 1 && deathCountThisSession % 3 == 0
    }
}
