import SpriteKit
import GameplayKit

/// The main gameplay scene — core game loop with full Phase 2 polish.
final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Entities

    private var playerEntity: PlayerEntity!
    private var backgroundEntity: BackgroundEntity!
    private var obstacleEntities: [ObstacleEntity] = []

    // MARK: - Component Systems

    private let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)

    // MARK: - Managers

    private let gameManager = GameManager.shared
    private let scoreManager = ScoreManager.shared
    private let audioManager = AudioManager.shared
    private let adManager = AdManager.shared
    private let skinManager = SkinManager.shared
    private let gameCenterManager = GameCenterManager.shared
    private let dailyChallengeManager = DailyChallengeManager.shared

    // MARK: - Timing

    private var lastUpdateTime: TimeInterval = 0
    private var obstacleSpawnTimer: TimeInterval = 0

    // MARK: - UI Nodes

    private var scoreLabel: SKLabelNode!
    private var scoreShadow: SKLabelNode!
    private var flashOverlay: SKSpriteNode!
    private var pauseOverlay: SKNode?

    // MARK: - State

    private var currentColorIndex: Int = 0
    private var isGameActive: Bool = false
    private var isPaused: Bool = false
    private var isShowingDeathOverlay: Bool = false

    // MARK: - Computed Properties

    private var currentSpeed: CGFloat {
        let bonus = CGFloat(scoreManager.currentScore / GameConstants.speedIncreaseInterval) * GameConstants.speedIncreaseAmount
        return min(GameConstants.obstacleBaseSpeed + bonus, GameConstants.maxSpeed)
    }

    private var currentGapSize: CGFloat {
        let reduction = CGFloat(scoreManager.currentScore / GameConstants.gapShrinkInterval) * GameConstants.gapShrinkAmount
        return max(GameConstants.gapSize - reduction, GameConstants.minimumGapSize)
    }

    private var currentNeonColor: UIColor {
        .neonColor(at: scoreManager.currentPaletteIndex)
    }

    /// Whether new obstacles should oscillate vertically.
    private var shouldSpawnMovingObstacles: Bool {
        scoreManager.currentScore >= GameConstants.movingObstacleThreshold
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .glowBackground
        scoreManager.resetForNewGame()
        adManager.resetForNewGame()
        adManager.showBanner = false

        setupPhysicsWorld()
        setupBackground()
        setupPlayer()
        setupUI()
        setupFlashOverlay()

        gameManager.startGame()
        isGameActive = true

        // Start wing flap animation
        playerEntity.startFlapAnimation()

        // Register for app lifecycle notifications (pause handling)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.pauseGame()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: GameConstants.gravity)
        physicsWorld.contactDelegate = self
    }

    private func setupBackground() {
        backgroundEntity = BackgroundEntity(sceneSize: size, color: currentNeonColor)
        addChild(backgroundEntity.rootNode)
    }

    private func setupPlayer() {
        let color = currentNeonColor
        let skin = skinManager.selectedSkin
        playerEntity = PlayerEntity(color: color, shape: skin.shape)

        let playerNode = playerEntity.node
        playerNode.position = CGPoint(
            x: size.width * GameConstants.playerXPositionFraction,
            y: size.height * 0.55
        )
        addChild(playerNode)
        playerEntity.attachTrail(to: self, color: color)
    }

    private func setupUI() {
        // Score label
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "0"
        scoreLabel.fontSize = 52
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        scoreLabel.zPosition = GameConstants.uiZ
        scoreLabel.horizontalAlignmentMode = .center

        // Shadow behind score
        scoreShadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreShadow.text = "0"
        scoreShadow.fontSize = 52
        scoreShadow.fontColor = UIColor.black.withAlphaComponent(0.4)
        scoreShadow.position = CGPoint(x: 2, y: -2)
        scoreShadow.zPosition = -1
        scoreShadow.horizontalAlignmentMode = .center
        scoreLabel.addChild(scoreShadow)

        addChild(scoreLabel)
    }

    private func setupFlashOverlay() {
        flashOverlay = SKSpriteNode(color: .white, size: size)
        flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flashOverlay.zPosition = GameConstants.uiZ + 10
        flashOverlay.alpha = 0
        addChild(flashOverlay)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Handle tap on pause overlay to resume
        if isPaused {
            resumeGame()
            return
        }

        // Handle taps on continue overlay
        if isShowingDeathOverlay, let touch = touches.first {
            let location = touch.location(in: self)
            let tapped = nodes(at: location)

            if tapped.contains(where: { $0.name == "watchAdButton" || $0.name == "watchAdLabel" }) {
                handleContinue()
            } else if tapped.contains(where: { $0.name == "skipContinueButton" }) {
                handleSkipContinue()
            }
            return
        }

        guard isGameActive else { return }

        playerEntity.flap()
        audioManager.playFlap()
        audioManager.playTapHaptic()
    }

    // MARK: - Pause / Resume

    private func pauseGame() {
        guard isGameActive, !isPaused else { return }
        isPaused = true
        isGameActive = false
        physicsWorld.speed = 0
        gameManager.pause()
        showPauseOverlay()
    }

    private func resumeGame() {
        guard isPaused else { return }
        isPaused = false
        hidePauseOverlay()

        // Reset lastUpdateTime so we don't get a huge delta spike
        lastUpdateTime = 0

        physicsWorld.speed = 1
        gameManager.resume()
        isGameActive = true
    }

    private func showPauseOverlay() {
        let overlay = SKNode()
        overlay.zPosition = GameConstants.uiZ + 20
        overlay.name = "pauseOverlay"

        // Dim background
        let dim = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.5), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        // Glass panel
        let panelSize = CGSize(width: size.width * 0.65, height: 180)
        let panel = SKSpriteNode.glassPanel(size: panelSize, tintColor: currentNeonColor)
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(panel)

        // "PAUSED" label
        let pauseLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        pauseLabel.text = "PAUSED"
        pauseLabel.fontSize = 36
        pauseLabel.fontColor = currentNeonColor
        pauseLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        pauseLabel.horizontalAlignmentMode = .center
        overlay.addChild(pauseLabel)

        // "Tap to resume" prompt
        let resumeLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        resumeLabel.text = "TAP TO RESUME"
        resumeLabel.fontSize = 16
        resumeLabel.fontColor = UIColor.white.withAlphaComponent(0.6)
        resumeLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 25)
        resumeLabel.horizontalAlignmentMode = .center

        resumeLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.5),
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
        ])))
        overlay.addChild(resumeLabel)

        // Fade in
        overlay.alpha = 0
        overlay.run(SKAction.fadeIn(withDuration: 0.15))

        addChild(overlay)
        pauseOverlay = overlay
    }

    private func hidePauseOverlay() {
        pauseOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent(),
        ]))
        pauseOverlay = nil
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        let deltaTime: TimeInterval
        if lastUpdateTime == 0 {
            deltaTime = 0
        } else {
            deltaTime = min(currentTime - lastUpdateTime, 1.0 / 30.0)  // Cap delta to prevent physics jumps
        }
        lastUpdateTime = currentTime

        guard isGameActive else { return }

        // Update ECS movement system
        movementSystem.update(deltaTime: deltaTime)

        // Update player
        playerEntity.updateRotation(deltaTime: deltaTime)
        playerEntity.clampVelocity()

        // Update parallax background
        backgroundEntity.update(speed: currentSpeed, deltaTime: deltaTime)

        // Spawn obstacles
        obstacleSpawnTimer += deltaTime
        if obstacleSpawnTimer >= GameConstants.obstacleSpawnInterval {
            spawnObstacle()
            obstacleSpawnTimer = 0
        }

        // Clean up off-screen obstacles
        removeOffScreenObstacles()

        // Check Neon Pulse color shift
        checkColorShift()
    }

    // MARK: - Obstacle Spawning

    private func spawnObstacle() {
        let playableMinY = GameConstants.groundHeight + currentGapSize / 2 + 40
        let playableMaxY = size.height - currentGapSize / 2 - 40

        guard playableMaxY > playableMinY else { return }

        let gapCenterY = CGFloat.random(in: playableMinY...playableMaxY)

        // After threshold, ~40% chance obstacle moves vertically
        let isMoving = shouldSpawnMovingObstacles && Int.random(in: 0..<5) < 2

        let obstacle = ObstacleEntity(
            sceneSize: size,
            gapSize: currentGapSize,
            gapCenterY: gapCenterY,
            speed: currentSpeed,
            color: currentNeonColor,
            moving: isMoving
        )

        obstacleEntities.append(obstacle)
        addChild(obstacle.containerNode)

        if let moveComp = obstacle.component(ofType: MovementComponent.self) {
            movementSystem.addComponent(moveComp)
        }
    }

    private func removeOffScreenObstacles() {
        obstacleEntities.removeAll { obstacle in
            if obstacle.isOffScreen() {
                if let moveComp = obstacle.component(ofType: MovementComponent.self) {
                    movementSystem.removeComponent(moveComp)
                }
                obstacle.removeFromScene()
                return true
            }
            return false
        }
    }

    // MARK: - Neon Pulse Color Shift

    private func checkColorShift() {
        let newIndex = scoreManager.currentPaletteIndex
        if newIndex != currentColorIndex {
            currentColorIndex = newIndex
            performColorShift()
        }
    }

    private func performColorShift() {
        let newColor = currentNeonColor

        // Flash overlay
        flashOverlay.color = newColor
        flashOverlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 0.08),
            SKAction.fadeAlpha(to: 0, duration: 0.35),
        ]))

        // Pulse wave line sweeping across the screen
        let wave = SKShapeNode(rectOf: CGSize(width: 3, height: size.height))
        wave.fillColor = newColor.withAlphaComponent(0.6)
        wave.strokeColor = newColor
        wave.lineWidth = 1
        wave.glowWidth = 8
        wave.position = CGPoint(x: -10, y: size.height / 2)
        wave.zPosition = GameConstants.uiZ + 5
        addChild(wave)

        wave.run(SKAction.sequence([
            SKAction.moveTo(x: size.width + 10, duration: 0.4),
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent(),
        ]))

        // Update entities
        playerEntity.updateTextures(color: newColor)
        backgroundEntity.updateColor(newColor)
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        guard isGameActive else { return }

        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let combined = maskA | maskB

        // Score zone contact
        if combined == (GameConstants.playerCategory | GameConstants.scoreCategory) {
            handleScoreContact(contact)
            return
        }

        // Obstacle or ground hit
        if (combined & GameConstants.obstacleCategory) != 0 || (combined & GameConstants.groundCategory) != 0 {
            if (combined & GameConstants.playerCategory) != 0 {
                handleDeathContact()
            }
        }
    }

    private func handleScoreContact(_ contact: SKPhysicsContact) {
        // Remove score zone so it triggers only once
        let scoreNode: SKNode?
        if contact.bodyA.categoryBitMask == GameConstants.scoreCategory {
            scoreNode = contact.bodyA.node
        } else {
            scoreNode = contact.bodyB.node
        }
        scoreNode?.removeFromParent()

        scoreManager.incrementScore()
        audioManager.playScore()
        audioManager.playScoreHaptic()

        // Update label
        let scoreText = "\(scoreManager.currentScore)"
        scoreLabel.text = scoreText
        scoreShadow.text = scoreText

        // Pop animation on score label
        scoreLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.06),
            SKAction.scale(to: 1.0, duration: 0.1),
        ]))

        // Floating "+1" popup
        spawnScorePopup()

        // Score sparkle at player position
        let sparkle = SKEmitterNode.scoreSparkle(color: currentNeonColor)
        sparkle.position = playerEntity.node.position
        sparkle.zPosition = GameConstants.particleZ + 1
        addChild(sparkle)
        sparkle.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent(),
        ]))
    }

    private func spawnScorePopup() {
        let popup = SKLabelNode(fontNamed: "AvenirNext-Bold")
        popup.text = "+1"
        popup.fontSize = 24
        popup.fontColor = currentNeonColor
        popup.position = CGPoint(
            x: playerEntity.node.position.x + 30,
            y: playerEntity.node.position.y + 10
        )
        popup.zPosition = GameConstants.uiZ + 1
        popup.horizontalAlignmentMode = .center
        addChild(popup)

        popup.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: GameConstants.scorePopupRiseDistance, duration: GameConstants.scorePopupDuration),
                SKAction.fadeOut(withDuration: GameConstants.scorePopupDuration),
                SKAction.scale(to: 0.5, duration: GameConstants.scorePopupDuration),
            ]),
            SKAction.removeFromParent(),
        ]))
    }

    // MARK: - Death

    private func handleDeathContact() {
        isGameActive = false
        gameManager.endGame()
        scoreManager.saveHighScore()

        // Report to GameCenter, daily challenge, and skin unlocks
        gameCenterManager.submitScore(scoreManager.currentScore)
        gameCenterManager.checkAchievements(
            currentScore: scoreManager.currentScore,
            totalGames: scoreManager.totalGamesPlayed,
            dailyChallengeComplete: dailyChallengeManager.isCompleted
        )
        dailyChallengeManager.recordGame(score: scoreManager.currentScore)
        skinManager.checkUnlocks(
            highScore: scoreManager.highScore,
            gamesPlayed: scoreManager.totalGamesPlayed,
            dailyChallengeComplete: dailyChallengeManager.isCompleted
        )

        audioManager.playHit()
        audioManager.playHitHaptic()

        if scoreManager.isNewHighScore {
            audioManager.playHighScoreHaptic()
        }

        // Stop player animation
        playerEntity.stopFlapAnimation()

        // Freeze physics
        physicsWorld.speed = 0

        // Death burst particles
        let burst = SKEmitterNode.neonBurst(color: currentNeonColor)
        burst.position = playerEntity.node.position
        burst.zPosition = GameConstants.particleZ + 2
        addChild(burst)

        // Screen shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 8, y: 6, duration: 0.025),
            SKAction.moveBy(x: -16, y: -8, duration: 0.025),
            SKAction.moveBy(x: 12, y: 6, duration: 0.025),
            SKAction.moveBy(x: -6, y: -4, duration: 0.025),
            SKAction.moveBy(x: 2, y: 0, duration: 0.025),
        ])

        // White flash
        flashOverlay.color = .white
        flashOverlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.04),
            SKAction.fadeAlpha(to: 0, duration: 0.25),
        ]))

        // Fade player out
        playerEntity.node.run(SKAction.fadeAlpha(to: 0.3, duration: 0.3))

        run(SKAction.sequence([
            shake,
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.afterDeathEffects()
            },
        ]))
    }

    /// After death effects finish, decide: show interstitial, continue overlay, or go to game over.
    private func afterDeathEffects() {
        // Step 1: Show interstitial if it's time
        adManager.showInterstitialIfNeeded { [weak self] in
            guard let self else { return }
            // Step 2: Show continue overlay if rewarded ad is available
            if self.adManager.canContinue {
                self.showContinueOverlay()
            } else {
                self.transitionToGameOver()
            }
        }
    }

    // MARK: - Continue Overlay (Rewarded Ad)

    private func showContinueOverlay() {
        isShowingDeathOverlay = true

        let overlay = SKNode()
        overlay.zPosition = GameConstants.uiZ + 20
        overlay.name = "continueOverlay"

        // Dim background
        let dim = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.45), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        // Glass panel
        let panelSize = CGSize(width: size.width * 0.78, height: 220)
        let panel = SKSpriteNode.glassPanel(size: panelSize, tintColor: currentNeonColor)
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        overlay.addChild(panel)

        // "Continue?" label
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = "CONTINUE?"
        titleLabel.fontSize = 30
        titleLabel.fontColor = currentNeonColor
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        titleLabel.horizontalAlignmentMode = .center
        overlay.addChild(titleLabel)

        // "Watch a short video" subtitle
        let subLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        subLabel.text = "Watch a short video to keep playing"
        subLabel.fontSize = 14
        subLabel.fontColor = UIColor.white.withAlphaComponent(0.6)
        subLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        subLabel.horizontalAlignmentMode = .center
        overlay.addChild(subLabel)

        // Score preview
        let scorePreview = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        scorePreview.text = "Current Score: \(scoreManager.currentScore)"
        scorePreview.fontSize = 16
        scorePreview.fontColor = .white
        scorePreview.position = CGPoint(x: size.width / 2, y: size.height / 2 + 25)
        scorePreview.horizontalAlignmentMode = .center
        overlay.addChild(scorePreview)

        // "Watch Ad" button
        let watchBtnSize = CGSize(width: 160, height: 48)
        let watchBtnTexture = SKTexture.neonButton(size: watchBtnSize, color: .neonGreen)
        let watchBtn = SKSpriteNode(texture: watchBtnTexture, size: watchBtnSize)
        watchBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 25)
        watchBtn.name = "watchAdButton"
        overlay.addChild(watchBtn)

        let watchLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        watchLabel.text = "WATCH AD"
        watchLabel.fontSize = 17
        watchLabel.fontColor = .neonGreen
        watchLabel.verticalAlignmentMode = .center
        watchLabel.horizontalAlignmentMode = .center
        watchLabel.name = "watchAdLabel"
        watchBtn.addChild(watchLabel)

        // Pulse the watch button
        watchBtn.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5),
        ])))

        // "Skip" button
        let skipLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        skipLabel.text = "NO THANKS"
        skipLabel.fontSize = 15
        skipLabel.fontColor = UIColor.white.withAlphaComponent(0.4)
        skipLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 70)
        skipLabel.horizontalAlignmentMode = .center
        skipLabel.name = "skipContinueButton"
        overlay.addChild(skipLabel)

        // Fade in
        overlay.alpha = 0
        overlay.run(SKAction.fadeIn(withDuration: 0.2))

        addChild(overlay)
    }

    private func handleContinue() {
        // Remove continue overlay
        childNode(withName: "continueOverlay")?.removeFromParent()
        isShowingDeathOverlay = false

        // Show rewarded ad
        adManager.showRewardedAd { [weak self] earned in
            guard let self else { return }
            if earned {
                self.performContinue()
            } else {
                self.transitionToGameOver()
            }
        }
    }

    private func performContinue() {
        // Reset player position and resume
        let playerNode = playerEntity.node
        playerNode.alpha = 1.0
        playerNode.position = CGPoint(
            x: size.width * GameConstants.playerXPositionFraction,
            y: size.height * 0.55
        )
        playerNode.physicsBody?.velocity = .zero
        playerNode.zRotation = 0

        // Remove nearby obstacles to give the player breathing room
        for obstacle in obstacleEntities where obstacle.containerNode.position.x < size.width * 0.6 {
            if let moveComp = obstacle.component(ofType: MovementComponent.self) {
                movementSystem.removeComponent(moveComp)
            }
            obstacle.removeFromScene()
        }
        obstacleEntities.removeAll { $0.containerNode.parent == nil }

        // Resume
        physicsWorld.speed = 1
        lastUpdateTime = 0
        obstacleSpawnTimer = 0
        gameManager.startGame()
        isGameActive = true
        playerEntity.startFlapAnimation()
    }

    private func handleSkipContinue() {
        childNode(withName: "continueOverlay")?.removeFromParent()
        isShowingDeathOverlay = false
        transitionToGameOver()
    }

    private func transitionToGameOver() {
        adManager.showBanner = true
        let gameOverScene = GameOverScene(size: size)
        gameOverScene.scaleMode = scaleMode
        view?.presentScene(gameOverScene, transition: SKTransition.fade(withDuration: 0.4))
    }
}
