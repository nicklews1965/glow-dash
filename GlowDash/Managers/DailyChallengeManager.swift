import Foundation

/// Manages daily challenge generation, tracking, and completion.
@MainActor
final class DailyChallengeManager {

    static let shared = DailyChallengeManager()

    // MARK: - Challenge Types

    enum ChallengeType: Int, CaseIterable {
        case singleRunScore   // "Score X in a single run"
        case totalGames       // "Play N games today"
        case totalScore       // "Score a total of X points today"
    }

    struct Challenge {
        let type: ChallengeType
        let target: Int
        let description: String
    }

    // MARK: - State

    private let defaults = UserDefaults.standard
    private(set) var todayChallenge: Challenge
    private(set) var isCompleted: Bool

    // Daily stats
    private(set) var dailyGamesPlayed: Int
    private(set) var dailyTotalScore: Int
    private(set) var dailyHighScore: Int

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private init() {
        // Check if we need to reset for a new day
        let savedDate = defaults.string(forKey: GameConstants.dailyChallengeDate) ?? ""
        let today = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: Date())
        }()

        if savedDate == today {
            // Same day — load existing challenge and progress
            dailyGamesPlayed = defaults.integer(forKey: GameConstants.dailyGamesPlayedKey)
            dailyTotalScore = defaults.integer(forKey: GameConstants.dailyTotalScoreKey)
            dailyHighScore = defaults.integer(forKey: GameConstants.dailyHighScoreKey)
            isCompleted = defaults.bool(forKey: GameConstants.dailyChallengeComplete)

            let savedType = defaults.integer(forKey: GameConstants.dailyChallengeKey)
            let type = ChallengeType(rawValue: savedType) ?? .singleRunScore
            todayChallenge = DailyChallengeManager.generateChallenge(type: type, seed: today)
        } else {
            // New day — generate fresh challenge, reset stats
            dailyGamesPlayed = 0
            dailyTotalScore = 0
            dailyHighScore = 0
            isCompleted = false

            // Deterministic challenge based on date string hash
            let hash = abs(today.hashValue)
            let typeIndex = hash % ChallengeType.allCases.count
            let type = ChallengeType.allCases[typeIndex]
            todayChallenge = DailyChallengeManager.generateChallenge(type: type, seed: today)

            // Save
            defaults.set(today, forKey: GameConstants.dailyChallengeDate)
            defaults.set(type.rawValue, forKey: GameConstants.dailyChallengeKey)
            defaults.set(0, forKey: GameConstants.dailyGamesPlayedKey)
            defaults.set(0, forKey: GameConstants.dailyTotalScoreKey)
            defaults.set(0, forKey: GameConstants.dailyHighScoreKey)
            defaults.set(false, forKey: GameConstants.dailyChallengeComplete)
        }
    }

    // MARK: - Challenge Generation

    private static func generateChallenge(type: ChallengeType, seed: String) -> Challenge {
        let hash = abs(seed.hashValue)

        switch type {
        case .singleRunScore:
            let targets = [15, 20, 25, 30, 40]
            let target = targets[hash % targets.count]
            return Challenge(type: type, target: target, description: "Score \(target) in a single run")
        case .totalGames:
            let targets = [3, 5, 7, 10]
            let target = targets[hash % targets.count]
            return Challenge(type: type, target: target, description: "Play \(target) games today")
        case .totalScore:
            let targets = [30, 50, 75, 100]
            let target = targets[hash % targets.count]
            return Challenge(type: type, target: target, description: "Score \(target) total points today")
        }
    }

    // MARK: - Tracking

    /// Call after each game ends. Returns true if the challenge was just completed.
    @discardableResult
    func recordGame(score: Int) -> Bool {
        guard !isCompleted else { return false }

        dailyGamesPlayed += 1
        dailyTotalScore += score
        dailyHighScore = max(dailyHighScore, score)

        defaults.set(dailyGamesPlayed, forKey: GameConstants.dailyGamesPlayedKey)
        defaults.set(dailyTotalScore, forKey: GameConstants.dailyTotalScoreKey)
        defaults.set(dailyHighScore, forKey: GameConstants.dailyHighScoreKey)

        // Check completion
        let completed: Bool
        switch todayChallenge.type {
        case .singleRunScore:
            completed = score >= todayChallenge.target
        case .totalGames:
            completed = dailyGamesPlayed >= todayChallenge.target
        case .totalScore:
            completed = dailyTotalScore >= todayChallenge.target
        }

        if completed {
            isCompleted = true
            defaults.set(true, forKey: GameConstants.dailyChallengeComplete)
            return true
        }

        return false
    }

    // MARK: - Progress

    /// Returns current progress as (current, target).
    var progress: (current: Int, target: Int) {
        let current: Int
        switch todayChallenge.type {
        case .singleRunScore: current = dailyHighScore
        case .totalGames:     current = dailyGamesPlayed
        case .totalScore:     current = dailyTotalScore
        }
        return (current, todayChallenge.target)
    }

    /// Progress as a formatted string.
    var progressText: String {
        let p = progress
        return "\(min(p.current, p.target))/\(p.target)"
    }
}
