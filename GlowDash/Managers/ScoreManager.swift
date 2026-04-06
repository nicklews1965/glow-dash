import Foundation

/// Tracks the current score and persists high score via UserDefaults.
@MainActor
final class ScoreManager {

    static let shared = ScoreManager()

    private let defaults = UserDefaults.standard

    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    private(set) var totalGamesPlayed: Int = 0

    /// True if the current run set a new high score.
    private(set) var isNewHighScore: Bool = false

    private init() {
        highScore = defaults.integer(forKey: GameConstants.highScoreKey)
        totalGamesPlayed = defaults.integer(forKey: GameConstants.totalGamesKey)
    }

    func resetForNewGame() {
        currentScore = 0
        isNewHighScore = false
    }

    func incrementScore() {
        currentScore += 1
        if currentScore > highScore {
            highScore = currentScore
            isNewHighScore = true
        }
    }

    func saveHighScore() {
        defaults.set(highScore, forKey: GameConstants.highScoreKey)
        totalGamesPlayed += 1
        defaults.set(totalGamesPlayed, forKey: GameConstants.totalGamesKey)
    }

    /// The current palette index based on score.
    var currentPaletteIndex: Int {
        currentScore / GameConstants.colorShiftInterval
    }
}
