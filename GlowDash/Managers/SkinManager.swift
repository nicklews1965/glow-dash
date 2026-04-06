import UIKit

/// Defines available character skins, tracks unlocks, and manages selection.
@MainActor
final class SkinManager {

    static let shared = SkinManager()

    // MARK: - Skin Definition

    struct Skin: Identifiable {
        let id: String
        let name: String
        let color: UIColor
        let shape: Shape
        let unlockDescription: String
        /// Unlock condition: nil = unlocked by default
        let unlockCondition: UnlockCondition?

        enum Shape: String {
            case chevron    // Default bird
            case orb        // Circle
            case diamond    // Diamond
            case bolt       // Lightning bolt
        }

        enum UnlockCondition {
            case score(Int)           // Single-run score
            case gamesPlayed(Int)     // Total games played
            case dailyChallenge       // Complete any daily challenge
        }
    }

    // MARK: - All Skins

    let allSkins: [Skin] = [
        Skin(id: "cyan_chevron", name: "Neon Cyan", color: .neonCyan,
             shape: .chevron, unlockDescription: "Default", unlockCondition: nil),
        Skin(id: "magenta_chevron", name: "Hot Magenta", color: .neonMagenta,
             shape: .chevron, unlockDescription: "Score 15 in one run", unlockCondition: .score(15)),
        Skin(id: "yellow_orb", name: "Solar Orb", color: .neonYellow,
             shape: .orb, unlockDescription: "Score 25 in one run", unlockCondition: .score(25)),
        Skin(id: "green_diamond", name: "Toxic Diamond", color: .neonGreen,
             shape: .diamond, unlockDescription: "Score 35 in one run", unlockCondition: .score(35)),
        Skin(id: "orange_bolt", name: "Blaze Bolt", color: UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0),
             shape: .bolt, unlockDescription: "Score 50 in one run", unlockCondition: .score(50)),
        Skin(id: "pink_chevron", name: "Electric Pink", color: UIColor(red: 1.0, green: 0.0, blue: 0.4, alpha: 1.0),
             shape: .chevron, unlockDescription: "Play 25 games", unlockCondition: .gamesPlayed(25)),
        Skin(id: "white_orb", name: "Arctic Orb", color: .white,
             shape: .orb, unlockDescription: "Play 50 games", unlockCondition: .gamesPlayed(50)),
        Skin(id: "purple_diamond", name: "Royal Diamond", color: UIColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1.0),
             shape: .diamond, unlockDescription: "Score 75 in one run", unlockCondition: .score(75)),
        Skin(id: "gold_bolt", name: "Golden Bolt", color: UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0),
             shape: .bolt, unlockDescription: "Score 100 in one run", unlockCondition: .score(100)),
        Skin(id: "rainbow_chevron", name: "Prismatic", color: .neonCyan,
             shape: .chevron, unlockDescription: "Complete a daily challenge", unlockCondition: .dailyChallenge),
    ]

    // MARK: - State

    private let defaults = UserDefaults.standard
    private(set) var unlockedSkinIDs: Set<String>
    private(set) var selectedSkinID: String

    private init() {
        let saved = defaults.stringArray(forKey: GameConstants.unlockedSkinsKey) ?? ["cyan_chevron"]
        unlockedSkinIDs = Set(saved)
        selectedSkinID = defaults.string(forKey: GameConstants.selectedSkinKey) ?? "cyan_chevron"
    }

    // MARK: - Selection

    var selectedSkin: Skin {
        allSkins.first { $0.id == selectedSkinID } ?? allSkins[0]
    }

    func selectSkin(_ id: String) {
        guard unlockedSkinIDs.contains(id) else { return }
        selectedSkinID = id
        defaults.set(id, forKey: GameConstants.selectedSkinKey)
    }

    func isSkinUnlocked(_ id: String) -> Bool {
        unlockedSkinIDs.contains(id)
    }

    // MARK: - Unlocking

    /// Check and unlock skins based on current stats. Returns newly unlocked skin IDs.
    @discardableResult
    func checkUnlocks(highScore: Int, gamesPlayed: Int, dailyChallengeComplete: Bool) -> [String] {
        var newlyUnlocked: [String] = []

        for skin in allSkins {
            guard !unlockedSkinIDs.contains(skin.id) else { continue }
            guard let condition = skin.unlockCondition else { continue }

            let shouldUnlock: Bool
            switch condition {
            case .score(let threshold):
                shouldUnlock = highScore >= threshold
            case .gamesPlayed(let threshold):
                shouldUnlock = gamesPlayed >= threshold
            case .dailyChallenge:
                shouldUnlock = dailyChallengeComplete
            }

            if shouldUnlock {
                unlockedSkinIDs.insert(skin.id)
                newlyUnlocked.append(skin.id)
            }
        }

        if !newlyUnlocked.isEmpty {
            defaults.set(Array(unlockedSkinIDs), forKey: GameConstants.unlockedSkinsKey)
        }

        return newlyUnlocked
    }

    /// Total skins unlocked / total skins.
    var progressText: String {
        "\(unlockedSkinIDs.count)/\(allSkins.count)"
    }
}
