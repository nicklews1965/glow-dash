import SpriteKit

/// Game over screen with Liquid Glass score panel, medals, and retry/menu buttons.
final class GameOverScene: SKScene {

    private let scoreManager = ScoreManager.shared
    private let neonColor: UIColor = .neonCyan
    private var touchEnabled = false

    override func didMove(to view: SKView) {
        backgroundColor = .glowBackground
        AdManager.shared.showBanner = true
        setupBackground()
        setupGlassScorePanel()
        setupButtons()

        // Delay touch to prevent accidental tap-through
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in self?.touchEnabled = true },
        ]))
    }

    // MARK: - Background

    private func setupBackground() {
        for _ in 0..<25 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.08...0.3)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.zPosition = GameConstants.backgroundFarZ + 1
            addChild(star)
        }
    }

    // MARK: - Glass Score Panel

    private func setupGlassScorePanel() {
        let centerX = size.width / 2
        let panelW = size.width * 0.8
        let panelH: CGFloat = 260

        // Glass panel
        let panel = SKSpriteNode.glassPanel(
            size: CGSize(width: panelW, height: panelH),
            tintColor: scoreManager.isNewHighScore ? .neonYellow : neonColor
        )
        panel.position = CGPoint(x: centerX, y: size.height * 0.58)
        panel.zPosition = GameConstants.uiZ - 1

        // Entrance animation
        panel.alpha = 0
        panel.setScale(0.8)
        panel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.25),
        ]))
        addChild(panel)

        let panelTop = size.height * 0.58 + panelH / 2

        // "GAME OVER" title above panel
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "GAME OVER"
        title.fontSize = 38
        title.fontColor = .neonMagenta
        title.position = CGPoint(x: centerX, y: panelTop + 25)
        title.zPosition = GameConstants.uiZ
        title.horizontalAlignmentMode = .center
        title.alpha = 0
        title.setScale(0.4)
        title.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
        ]))
        addChild(title)

        // New high score badge
        if scoreManager.isNewHighScore {
            let badge = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            badge.text = "NEW BEST!"
            badge.fontSize = 20
            badge.fontColor = .neonYellow
            badge.position = CGPoint(x: centerX, y: panelTop - 30)
            badge.zPosition = GameConstants.uiZ
            badge.horizontalAlignmentMode = .center
            badge.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.35),
                SKAction.scale(to: 1.0, duration: 0.35),
            ])))
            addChild(badge)

            // Celebration particles
            let sparkle = SKEmitterNode.neonBurst(color: .neonYellow)
            sparkle.position = CGPoint(x: centerX, y: size.height * 0.58)
            sparkle.zPosition = GameConstants.particleZ
            sparkle.numParticlesToEmit = 25
            sparkle.particleSpeed = 50
            addChild(sparkle)
        }

        // "SCORE" header
        let scoreHeader = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreHeader.text = "SCORE"
        scoreHeader.fontSize = 14
        scoreHeader.fontColor = UIColor.white.withAlphaComponent(0.45)
        let scoreHeaderY = scoreManager.isNewHighScore ? panelTop - 60 : panelTop - 35
        scoreHeader.position = CGPoint(x: centerX, y: scoreHeaderY)
        scoreHeader.zPosition = GameConstants.uiZ
        scoreHeader.horizontalAlignmentMode = .center
        addChild(scoreHeader)

        // Score value with count-up animation
        let scoreValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreValue.text = "0"
        scoreValue.fontSize = 58
        scoreValue.fontColor = .white
        scoreValue.position = CGPoint(x: centerX, y: scoreHeaderY - 55)
        scoreValue.zPosition = GameConstants.uiZ
        scoreValue.horizontalAlignmentMode = .center
        addChild(scoreValue)

        let target = scoreManager.currentScore
        if target > 0 {
            let steps = min(target, 25)
            let stepDuration = 0.35 / Double(steps)
            var actions: [SKAction] = []
            for i in 1...steps {
                let val = Int(Double(target) * Double(i) / Double(steps))
                actions.append(SKAction.run { scoreValue.text = "\(val)" })
                actions.append(SKAction.wait(forDuration: stepDuration))
            }
            scoreValue.run(SKAction.sequence(actions))
        }

        // Medal based on score
        let medal = medalForScore(scoreManager.currentScore)
        if let medalText = medal {
            let medalLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            medalLabel.text = medalText.0
            medalLabel.fontSize = 14
            medalLabel.fontColor = medalText.1
            medalLabel.position = CGPoint(x: centerX, y: scoreHeaderY - 80)
            medalLabel.zPosition = GameConstants.uiZ
            medalLabel.horizontalAlignmentMode = .center
            addChild(medalLabel)
        }

        // Neon separator
        let sep = SKShapeNode(rectOf: CGSize(width: panelW * 0.6, height: 1))
        sep.fillColor = neonColor.withAlphaComponent(0.2)
        sep.strokeColor = .clear
        sep.glowWidth = 3
        sep.position = CGPoint(x: centerX, y: scoreHeaderY - 100)
        sep.zPosition = GameConstants.uiZ
        addChild(sep)

        // High score
        let panelBottom = size.height * 0.58 - panelH / 2
        let hsLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        hsLabel.text = "BEST: \(scoreManager.highScore)"
        hsLabel.fontSize = 18
        hsLabel.fontColor = neonColor.withAlphaComponent(0.7)
        hsLabel.position = CGPoint(x: centerX, y: panelBottom + 25)
        hsLabel.zPosition = GameConstants.uiZ
        hsLabel.horizontalAlignmentMode = .center
        addChild(hsLabel)
    }

    // MARK: - Buttons

    private func setupButtons() {
        let centerX = size.width / 2
        let btnW: CGFloat = 150
        let btnH: CGFloat = 48

        // Retry button (primary)
        let retryBtnTexture = SKTexture.neonButton(size: CGSize(width: btnW, height: btnH), color: neonColor)
        let retryBtn = SKSpriteNode(texture: retryBtnTexture, size: CGSize(width: btnW, height: btnH))
        retryBtn.position = CGPoint(x: centerX, y: size.height * 0.28)
        retryBtn.zPosition = GameConstants.uiZ
        retryBtn.name = "retryButton"
        addChild(retryBtn)

        let retryLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        retryLabel.text = "RETRY"
        retryLabel.fontSize = 19
        retryLabel.fontColor = neonColor
        retryLabel.verticalAlignmentMode = .center
        retryLabel.horizontalAlignmentMode = .center
        retryLabel.position = .zero
        retryLabel.zPosition = 1
        retryLabel.name = "retryLabel"
        retryBtn.addChild(retryLabel)

        // Pulse the retry button
        retryBtn.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6),
        ])))

        // Share and Menu buttons side by side
        let shareBtn = SKSpriteNode(
            texture: SKTexture.neonButton(size: CGSize(width: 50, height: 42), color: .neonGreen, cornerRadius: 10),
            size: CGSize(width: 50, height: 42)
        )
        shareBtn.position = CGPoint(x: centerX + 95, y: size.height * 0.28)
        shareBtn.zPosition = GameConstants.uiZ
        shareBtn.name = "shareButton"
        addChild(shareBtn)

        let shareIcon = SKLabelNode(fontNamed: "AvenirNext-Medium")
        shareIcon.text = "\u{1F4E4}"  // Share icon
        shareIcon.fontSize = 18
        shareIcon.verticalAlignmentMode = .center
        shareIcon.horizontalAlignmentMode = .center
        shareIcon.name = "shareLabel"
        shareBtn.addChild(shareIcon)

        // Menu button
        let menuLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        menuLabel.text = "MENU"
        menuLabel.fontSize = 16
        menuLabel.fontColor = UIColor.white.withAlphaComponent(0.4)
        menuLabel.position = CGPoint(x: centerX, y: size.height * 0.21)
        menuLabel.zPosition = GameConstants.uiZ
        menuLabel.horizontalAlignmentMode = .center
        menuLabel.name = "menuButton"
        addChild(menuLabel)

        // Skin unlock notification
        let newSkins = SkinManager.shared.checkUnlocks(
            highScore: scoreManager.highScore,
            gamesPlayed: scoreManager.totalGamesPlayed,
            dailyChallengeComplete: DailyChallengeManager.shared.isCompleted
        )
        if let firstNew = newSkins.first,
           let skin = SkinManager.shared.allSkins.first(where: { $0.id == firstNew }) {
            let unlockLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            unlockLabel.text = "NEW SKIN UNLOCKED: \(skin.name.uppercased())!"
            unlockLabel.fontSize = 13
            unlockLabel.fontColor = .neonGreen
            unlockLabel.position = CGPoint(x: centerX, y: size.height * 0.15)
            unlockLabel.zPosition = GameConstants.uiZ
            unlockLabel.horizontalAlignmentMode = .center
            unlockLabel.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.4),
                SKAction.fadeAlpha(to: 1.0, duration: 0.4),
            ])))
            addChild(unlockLabel)
        }
    }

    // MARK: - Helpers

    private func medalForScore(_ score: Int) -> (String, UIColor)? {
        switch score {
        case 50...:  return ("GOLD", .neonYellow)
        case 25..<50: return ("SILVER", UIColor(white: 0.85, alpha: 1.0))
        case 10..<25: return ("BRONZE", UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0))
        default: return nil
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touchEnabled, let touch = touches.first else { return }

        AudioManager.shared.playTapHaptic()

        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        if tapped.contains(where: { $0.name == "menuButton" }) {
            let menuScene = MenuScene(size: size)
            menuScene.scaleMode = .resizeFill
            view?.presentScene(menuScene, transition: SKTransition.fade(withDuration: 0.3))
        } else if tapped.contains(where: { $0.name == "shareButton" || $0.name == "shareLabel" }) {
            shareScore()
        } else if tapped.contains(where: { $0.name == "retryButton" || $0.name == "retryLabel" }) {
            AdManager.shared.showBanner = false
            let gameScene = GameScene(size: size)
            gameScene.scaleMode = .resizeFill
            view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.3))
        }
    }

    // MARK: - Social Sharing

    private func shareScore() {
        guard let skView = view else { return }

        // Capture a screenshot of the current scene
        let renderer = UIGraphicsImageRenderer(size: skView.bounds.size)
        let screenshot = renderer.image { _ in
            skView.drawHierarchy(in: skView.bounds, afterScreenUpdates: true)
        }

        let shareText = "I scored \(scoreManager.currentScore) in LitFlap! Can you beat me? \(GameConstants.shareHashtag)"

        let activityVC = UIActivityViewController(
            activityItems: [shareText, screenshot],
            applicationActivities: nil
        )

        // Find root view controller to present from
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        // iPad requires popover source
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = skView
            popover.sourceRect = CGRect(x: skView.bounds.midX, y: skView.bounds.midY, width: 0, height: 0)
        }

        topVC.present(activityVC, animated: true)
    }
}
