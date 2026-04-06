import CoreGraphics
import Foundation

enum GameConstants {

    // MARK: - Physics

    /// SpriteKit world gravity (negative = downward)
    static let gravity: CGFloat = -18.0
    /// Upward impulse applied per tap (with player mass = 1.0)
    static let tapImpulse: CGFloat = 7.0
    /// Maximum upward velocity to prevent flying off screen
    static let maxUpwardVelocity: CGFloat = 600.0

    // MARK: - Obstacles

    /// Base horizontal scroll speed (points per second)
    static let obstacleBaseSpeed: CGFloat = 180.0
    /// Seconds between obstacle spawns
    static let obstacleSpawnInterval: TimeInterval = 1.8
    /// Starting gap size between top and bottom obstacles (points)
    static let gapSize: CGFloat = 220.0
    /// Absolute minimum gap size — never smaller than this
    static let minimumGapSize: CGFloat = 130.0
    /// Gap shrinks by this amount at each shrink interval
    static let gapShrinkAmount: CGFloat = 4.0
    /// Gap shrinks every N points
    static let gapShrinkInterval: Int = 15
    /// Obstacle width (points)
    static let obstacleWidth: CGFloat = 60.0
    /// Corner radius for obstacle neon rectangles
    static let obstacleCornerRadius: CGFloat = 6.0

    // MARK: - Difficulty Scaling

    /// Speed increases every N points
    static let speedIncreaseInterval: Int = 10
    /// Speed increase per interval (points per second)
    static let speedIncreaseAmount: CGFloat = 12.0
    /// Maximum obstacle speed cap
    static let maxSpeed: CGFloat = 320.0

    // MARK: - Player

    /// Player hitbox / visual size
    static let playerSize: CGSize = CGSize(width: 36, height: 28)
    /// Player X position as fraction of screen width
    static let playerXPositionFraction: CGFloat = 0.28
    /// Upward rotation angle when tapping (radians)
    static let flapUpRotation: CGFloat = 0.45
    /// Downward rotation angle when falling (radians)
    static let flapDownRotation: CGFloat = -1.2
    /// How fast the player rotates toward the target angle
    static let rotationSpeed: CGFloat = 4.0

    // MARK: - Physics Categories (bitmasks)

    static let playerCategory:   UInt32 = 0x1 << 0
    static let obstacleCategory: UInt32 = 0x1 << 1
    static let groundCategory:   UInt32 = 0x1 << 2
    static let scoreCategory:    UInt32 = 0x1 << 3
    static let ceilingCategory:  UInt32 = 0x1 << 4

    // MARK: - Z Positions (draw order)

    static let backgroundFarZ:  CGFloat = -30
    static let backgroundMidZ:  CGFloat = -20
    static let backgroundNearZ: CGFloat = -10
    static let groundZ:         CGFloat = 1
    static let obstacleZ:       CGFloat = 2
    static let playerZ:         CGFloat = 3
    static let particleZ:       CGFloat = 4
    static let uiZ:             CGFloat = 100

    // MARK: - Visual / Neon Theme

    /// Color palette that cycles during Neon Pulse events
    static let neonPalette: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
        (0.00, 1.00, 1.00),  // Cyan
        (1.00, 0.00, 1.00),  // Magenta
        (1.00, 1.00, 0.00),  // Yellow
        (0.00, 1.00, 0.40),  // Green
        (1.00, 0.40, 0.00),  // Orange
        (1.00, 0.00, 0.40),  // Hot Pink
    ]

    /// Points between each palette shift
    static let colorShiftInterval: Int = 15

    /// Background dark color (RGB)
    static let backgroundDarkColor: (r: CGFloat, g: CGFloat, b: CGFloat) = (0.04, 0.02, 0.12)

    /// Ground visual height (points)
    static let groundHeight: CGFloat = 60.0

    /// Parallax speed multipliers for background layers
    static let parallaxFarSpeed: CGFloat = 0.15
    static let parallaxMidSpeed: CGFloat = 0.4
    static let parallaxNearSpeed: CGFloat = 0.7

    // MARK: - Particle Trail

    static let trailBirthRate: CGFloat = 80
    static let trailLifetime: CGFloat = 0.4
    static let trailParticleSize: CGFloat = 5.0
    static let trailSpeed: CGFloat = 30.0

    // MARK: - Scoring

    static let highScoreKey = "GlowDash_HighScore"
    static let totalGamesKey = "GlowDash_TotalGames"

    // MARK: - Player Animation

    /// Frames per second for wing flap animation
    static let flapAnimationFPS: TimeInterval = 0.08
    /// Number of wing animation frames
    static let flapFrameCount: Int = 4
    /// Wing raise angle for animation frames (radians from neutral)
    static let wingRaiseAngle: CGFloat = 0.35

    // MARK: - Parallax City Silhouette

    /// Number of building columns in the far city layer
    static let cityBuildingCount: Int = 14
    /// Minimum building height as fraction of screen height
    static let cityMinHeightFraction: CGFloat = 0.08
    /// Maximum building height as fraction of screen height
    static let cityMaxHeightFraction: CGFloat = 0.30
    /// Building width range (points)
    static let cityBuildingMinWidth: CGFloat = 25.0
    static let cityBuildingMaxWidth: CGFloat = 55.0

    // MARK: - Mid-layer Floating Elements

    /// Number of floating neon shapes in mid parallax layer
    static let midLayerShapeCount: Int = 8
    /// Size range for floating shapes
    static let midLayerMinSize: CGFloat = 3.0
    static let midLayerMaxSize: CGFloat = 10.0

    // MARK: - Score Popup

    /// Duration for floating "+1" text
    static let scorePopupDuration: TimeInterval = 0.6
    /// How far the "+1" floats upward (points)
    static let scorePopupRiseDistance: CGFloat = 40.0

    // MARK: - Sound Synthesis

    /// Audio sample rate
    static let audioSampleRate: Double = 44100.0
    /// Flap sound: frequency sweep from → to (Hz)
    static let flapSoundFreqStart: Double = 900.0
    static let flapSoundFreqEnd: Double = 1400.0
    static let flapSoundDuration: Double = 0.06
    /// Score ding: two-tone frequencies (Hz)
    static let scoreSoundFreq1: Double = 523.25  // C5
    static let scoreSoundFreq2: Double = 659.25  // E5
    static let scoreSoundDuration: Double = 0.12
    /// Hit sound: low thud frequency (Hz)
    static let hitSoundFreq: Double = 150.0
    static let hitSoundDuration: Double = 0.18
    /// Master volume for synthesized sounds (0.0–1.0)
    static let soundVolume: Float = 0.35

    // MARK: - Obstacle Entrance Animation

    /// Duration for obstacle scale-in on spawn
    static let obstacleSpawnAnimDuration: TimeInterval = 0.2

    // MARK: - Moving Obstacles (advanced difficulty)

    /// Score threshold after which some obstacles move vertically
    static let movingObstacleThreshold: Int = 30
    /// Vertical oscillation amplitude for moving obstacles (points)
    static let movingObstacleAmplitude: CGFloat = 35.0
    /// Vertical oscillation period (seconds per full cycle)
    static let movingObstaclePeriod: TimeInterval = 2.0

    // MARK: - User Settings Keys

    static let soundMutedKey = "GlowDash_SoundMuted"
    static let hapticMutedKey = "GlowDash_HapticMuted"

    // MARK: - Glass Panel UI

    /// Corner radius for glass panels
    static let glassPanelCornerRadius: CGFloat = 22.0
    /// Glass panel background alpha
    static let glassPanelAlpha: CGFloat = 0.55
    /// Glass panel highlight alpha (top gradient)
    static let glassHighlightAlpha: CGFloat = 0.12
    /// Glass panel border alpha
    static let glassBorderAlpha: CGFloat = 0.2

    // MARK: - Neon Button

    /// Button corner radius
    static let buttonCornerRadius: CGFloat = 14.0
    /// Button padding (horizontal)
    static let buttonPaddingH: CGFloat = 32.0
    /// Button padding (vertical)
    static let buttonPaddingV: CGFloat = 14.0

    // MARK: - Ads (Google AdMob)
    // IMPORTANT: These are Google's official TEST ad unit IDs.
    // Replace with your real AdMob ad unit IDs before submitting to the App Store.

    /// AdMob App ID — replace with your real app ID from AdMob dashboard
    static let adMobAppID = "ca-app-pub-3940256099942544~1458002511"  // TEST APP ID

    /// Banner ad unit ID (test)
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    /// Interstitial ad unit ID (test)
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    /// Rewarded video ad unit ID (test)
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// Show interstitial every N deaths (not on first death)
    static let interstitialFrequency: Int = 3
    /// Maximum continues per game from rewarded ads
    static let maxContinuesPerGame: Int = 1

    /// Banner ad height (standard)
    static let bannerAdHeight: CGFloat = 50

    // MARK: - GameCenter

    /// Leaderboard ID — set this to match your App Store Connect config
    static let leaderboardID = "com.developer.glowdash.highscores"

    // MARK: - Achievements (IDs must match App Store Connect)

    static let achievementScore10   = "com.developer.glowdash.score10"
    static let achievementScore25   = "com.developer.glowdash.score25"
    static let achievementScore50   = "com.developer.glowdash.score50"
    static let achievementScore100  = "com.developer.glowdash.score100"
    static let achievementPlay10    = "com.developer.glowdash.play10"
    static let achievementPlay50    = "com.developer.glowdash.play50"
    static let achievementPlay100   = "com.developer.glowdash.play100"
    static let achievementDaily     = "com.developer.glowdash.dailychallenge"

    // MARK: - Skins

    static let unlockedSkinsKey = "GlowDash_UnlockedSkins"
    static let selectedSkinKey  = "GlowDash_SelectedSkin"

    // MARK: - Daily Challenge

    static let dailyChallengeKey      = "GlowDash_DailyChallenge"
    static let dailyChallengeDate     = "GlowDash_DailyChallengeDate"
    static let dailyGamesPlayedKey    = "GlowDash_DailyGamesPlayed"
    static let dailyTotalScoreKey     = "GlowDash_DailyTotalScore"
    static let dailyHighScoreKey      = "GlowDash_DailyHighScore"
    static let dailyChallengeComplete = "GlowDash_DailyChallengeComplete"

    // MARK: - Social Share

    static let shareHashtag = "#GlowDash"
    static let appStoreURL  = "https://apps.apple.com/app/idYOUR_APP_ID"  // Replace with real URL
}
