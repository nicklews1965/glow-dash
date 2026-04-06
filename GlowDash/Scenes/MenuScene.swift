import SpriteKit

/// Start screen with Liquid Glass styling — tap to play, settings gear.
final class MenuScene: SKScene {

    private var playerPreview: SKSpriteNode!
    private let neonColor: UIColor = .neonCyan
    private var cityLayers: [SKSpriteNode] = []

    override func didMove(to view: SKView) {
        backgroundColor = .glowBackground
        AdManager.shared.showBanner = true
        setupBackground()
        setupCityScroll()
        setupGround()
        setupGlassPanel()
        setupPlayerPreview()
        setupSettingsButton()
        setupSkinsButton()
        setupDailyChallenge()
        setupLeaderboardButton()
    }

    // MARK: - Background

    private func setupBackground() {
        for _ in 0..<45 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.0))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.1...0.5)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.3...size.height)
            )
            star.zPosition = GameConstants.backgroundFarZ + 1

            let baseAlpha = star.alpha
            star.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: baseAlpha * 0.2, duration: Double.random(in: 1.5...3.5)),
                SKAction.fadeAlpha(to: baseAlpha, duration: Double.random(in: 1.5...3.5)),
            ])))
            addChild(star)
        }
    }

    private func setupCityScroll() {
        let cityH = size.height * 0.35
        let cityTexture = SKTexture.neonCitySilhouette(
            size: CGSize(width: size.width, height: cityH),
            color: neonColor
        )

        for i in 0..<2 {
            let city = SKSpriteNode(texture: cityTexture, size: CGSize(width: size.width, height: cityH))
            city.anchorPoint = CGPoint(x: 0, y: 0)
            city.position = CGPoint(x: CGFloat(i) * size.width, y: GameConstants.groundHeight)
            city.zPosition = GameConstants.backgroundFarZ + 2
            addChild(city)
            cityLayers.append(city)
        }

        let scrollSpeed: CGFloat = 15.0
        run(SKAction.customAction(withDuration: .greatestFiniteMagnitude) { [weak self] _, _ in
            guard let self else { return }
            let dx = -scrollSpeed * CGFloat(1.0 / 60.0)
            for layer in cityLayers {
                layer.position.x += dx
                if layer.position.x <= -size.width {
                    layer.position.x += size.width * 2
                }
            }
        })
    }

    private func setupGround() {
        let groundH = GameConstants.groundHeight
        let groundTexture = SKTexture.neonGround(
            size: CGSize(width: size.width, height: groundH),
            color: neonColor
        )
        let ground = SKSpriteNode(texture: groundTexture, size: CGSize(width: size.width, height: groundH))
        ground.anchorPoint = CGPoint(x: 0, y: 0)
        ground.position = .zero
        ground.zPosition = GameConstants.groundZ
        addChild(ground)
    }

    // MARK: - Glass Panel (main content card)

    private func setupGlassPanel() {
        let centerX = size.width / 2
        let panelW = size.width * 0.85
        let panelH: CGFloat = 320

        // Glass card
        let panel = SKSpriteNode.glassPanel(
            size: CGSize(width: panelW, height: panelH),
            tintColor: neonColor
        )
        panel.position = CGPoint(x: centerX, y: size.height * 0.55)
        panel.zPosition = GameConstants.uiZ - 1
        addChild(panel)

        let panelTop = size.height * 0.55 + panelH / 2

        // Title inside panel
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "GLOW DASH"
        title.fontSize = 44
        title.fontColor = neonColor
        title.position = CGPoint(x: centerX, y: panelTop - 60)
        title.zPosition = GameConstants.uiZ
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Pulse animation on title
        let pulseUp = SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.fadeAlpha(to: 0.55, duration: 1.0)
        pulseDown.timingMode = .easeInEaseOut
        title.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])))

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = "NEON PULSE EDITION"
        subtitle.fontSize = 13
        subtitle.fontColor = neonColor.withAlphaComponent(0.4)
        subtitle.position = CGPoint(x: centerX, y: panelTop - 82)
        subtitle.zPosition = GameConstants.uiZ
        subtitle.horizontalAlignmentMode = .center
        addChild(subtitle)

        // Tap to play prompt
        let tapLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tapLabel.text = "TAP TO PLAY"
        tapLabel.fontSize = 22
        tapLabel.fontColor = .white
        let panelBottom = size.height * 0.55 - panelH / 2
        tapLabel.position = CGPoint(x: centerX, y: panelBottom + 55)
        tapLabel.zPosition = GameConstants.uiZ
        tapLabel.horizontalAlignmentMode = .center
        tapLabel.name = "tapPrompt"

        tapLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.5),
            SKAction.fadeAlpha(to: 0.25, duration: 0.5),
        ])))
        addChild(tapLabel)

        // High score & games played
        let hs = ScoreManager.shared.highScore
        if hs > 0 {
            let hsLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            hsLabel.text = "BEST: \(hs)"
            hsLabel.fontSize = 17
            hsLabel.fontColor = UIColor.white.withAlphaComponent(0.5)
            hsLabel.position = CGPoint(x: centerX, y: panelBottom + 30)
            hsLabel.zPosition = GameConstants.uiZ
            hsLabel.horizontalAlignmentMode = .center
            addChild(hsLabel)
        }

        let totalGames = ScoreManager.shared.totalGamesPlayed
        if totalGames > 0 {
            let gamesLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            gamesLabel.text = "\(totalGames) games played"
            gamesLabel.fontSize = 12
            gamesLabel.fontColor = UIColor.white.withAlphaComponent(0.25)
            gamesLabel.position = CGPoint(x: centerX, y: panelBottom + 12)
            gamesLabel.zPosition = GameConstants.uiZ
            gamesLabel.horizontalAlignmentMode = .center
            addChild(gamesLabel)
        }
    }

    // MARK: - Player Preview

    private func setupPlayerPreview() {
        let frames = SKTexture.neonPlayerFrames(size: GameConstants.playerSize, color: neonColor)
        let spriteSize = CGSize(
            width: (GameConstants.playerSize.width + 24) * 1.8,
            height: (GameConstants.playerSize.height + 24) * 1.8
        )
        playerPreview = SKSpriteNode(texture: frames[0], size: spriteSize)
        playerPreview.position = CGPoint(x: size.width / 2, y: size.height * 0.53)
        playerPreview.zPosition = GameConstants.uiZ + 1

        // Wing flap
        playerPreview.run(SKAction.repeatForever(
            SKAction.animate(with: frames, timePerFrame: 0.12)
        ))

        // Float bob
        let floatUp = SKAction.moveBy(x: 0, y: 12, duration: 0.85)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -12, duration: 0.85)
        floatDown.timingMode = .easeInEaseOut
        playerPreview.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])))

        addChild(playerPreview)

        // Trail
        let trail = SKEmitterNode.neonTrail(color: neonColor)
        trail.particleBirthRate = 35
        trail.targetNode = self
        trail.position = CGPoint(x: -GameConstants.playerSize.width, y: 0)
        trail.zPosition = -1
        playerPreview.addChild(trail)
    }

    // MARK: - Settings Button

    private func setupSettingsButton() {
        // Small gear icon in top-right (using a neon button)
        let btnSize = CGSize(width: 44, height: 44)
        let btnTexture = SKTexture.neonButton(size: btnSize, color: neonColor, cornerRadius: 12)
        let btn = SKSpriteNode(texture: btnTexture, size: btnSize)

        // Position in top-right with safe area consideration
        btn.position = CGPoint(x: size.width - 40, y: size.height - 60)
        btn.zPosition = GameConstants.uiZ + 2
        btn.name = "settingsButton"
        addChild(btn)

        // Gear icon (simple text — Phase 5 can use an actual icon asset)
        let gearLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        gearLabel.text = "\u{2699}"  // Gear unicode
        gearLabel.fontSize = 22
        gearLabel.fontColor = neonColor
        gearLabel.verticalAlignmentMode = .center
        gearLabel.horizontalAlignmentMode = .center
        gearLabel.position = CGPoint(x: 0, y: -1)
        gearLabel.zPosition = 1
        gearLabel.name = "settingsLabel"
        btn.addChild(gearLabel)
    }

    // MARK: - Skins Button

    private func setupSkinsButton() {
        let btnSize = CGSize(width: 44, height: 44)
        let btnTexture = SKTexture.neonButton(size: btnSize, color: neonColor, cornerRadius: 12)
        let btn = SKSpriteNode(texture: btnTexture, size: btnSize)
        btn.position = CGPoint(x: 40, y: size.height - 60)
        btn.zPosition = GameConstants.uiZ + 2
        btn.name = "skinsButton"
        addChild(btn)

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = "\u{1F3A8}"  // Palette emoji
        label.fontSize = 20
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -1)
        label.zPosition = 1
        label.name = "skinsLabel"
        btn.addChild(label)
    }

    // MARK: - Leaderboard Button

    private func setupLeaderboardButton() {
        guard GameCenterManager.shared.isAuthenticated else { return }

        let btnSize = CGSize(width: 44, height: 44)
        let btnTexture = SKTexture.neonButton(size: btnSize, color: neonColor, cornerRadius: 12)
        let btn = SKSpriteNode(texture: btnTexture, size: btnSize)
        btn.position = CGPoint(x: size.width - 40, y: size.height - 115)
        btn.zPosition = GameConstants.uiZ + 2
        btn.name = "leaderboardButton"
        addChild(btn)

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = "\u{1F3C6}"  // Trophy emoji
        label.fontSize = 20
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -1)
        label.zPosition = 1
        label.name = "leaderboardLabel"
        btn.addChild(label)
    }

    // MARK: - Daily Challenge

    private func setupDailyChallenge() {
        let challenge = DailyChallengeManager.shared

        let panelW = size.width * 0.75
        let panelH: CGFloat = 50
        let panelTexture = SKTexture.glassPanel(size: CGSize(width: panelW, height: panelH), cornerRadius: 12, tintColor: neonColor)
        let panel = SKSpriteNode(texture: panelTexture, size: CGSize(width: panelW, height: panelH))
        panel.position = CGPoint(x: size.width / 2, y: size.height * 0.14)
        panel.zPosition = GameConstants.uiZ
        addChild(panel)

        let icon = challenge.isCompleted ? "\u{2705}" : "\u{1F3AF}"  // Check or target
        let statusText = challenge.isCompleted ? "COMPLETE!" : "\(challenge.progressText)"

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "\(icon) \(challenge.todayChallenge.description)  \(statusText)"
        label.fontSize = 11
        label.fontColor = challenge.isCompleted ? .neonGreen : UIColor.white.withAlphaComponent(0.6)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.14 - 4)
        label.zPosition = GameConstants.uiZ + 1
        label.horizontalAlignmentMode = .center
        addChild(label)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        AudioManager.shared.playTapHaptic()

        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        // Settings button
        if tapped.contains(where: { $0.name == "settingsButton" || $0.name == "settingsLabel" }) {
            let settingsScene = SettingsScene(size: size)
            settingsScene.scaleMode = .resizeFill
            view?.presentScene(settingsScene, transition: SKTransition.push(with: .left, duration: 0.3))
            return
        }

        // Skins button
        if tapped.contains(where: { $0.name == "skinsButton" || $0.name == "skinsLabel" }) {
            let skinsScene = SkinsScene(size: size)
            skinsScene.scaleMode = .resizeFill
            view?.presentScene(skinsScene, transition: SKTransition.push(with: .left, duration: 0.3))
            return
        }

        // Leaderboard button
        if tapped.contains(where: { $0.name == "leaderboardButton" || $0.name == "leaderboardLabel" }) {
            GameCenterManager.shared.showLeaderboard()
            return
        }

        // Anything else → start game
        AdManager.shared.showBanner = false
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.3))
    }
}
