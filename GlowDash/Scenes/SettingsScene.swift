import SpriteKit

/// Settings screen with sound and haptic toggles, presented from the menu.
final class SettingsScene: SKScene {

    private let neonColor: UIColor = .neonCyan
    private let audioManager = AudioManager.shared

    private var soundToggle: SKSpriteNode!
    private var hapticToggle: SKSpriteNode!
    private var soundLabel: SKLabelNode!
    private var hapticLabel: SKLabelNode!

    private let toggleSize = CGSize(width: 56, height: 30)

    override func didMove(to view: SKView) {
        backgroundColor = .glowBackground
        setupBackground()
        setupPanel()
        setupBackButton()
    }

    // MARK: - Setup

    private func setupBackground() {
        for _ in 0..<25 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.08...0.35)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.zPosition = GameConstants.backgroundFarZ + 1
            addChild(star)
        }
    }

    private func setupPanel() {
        let centerX = size.width / 2
        let panelWidth = size.width * 0.82
        let panelHeight: CGFloat = 260

        // Glass panel background
        let panel = SKSpriteNode.glassPanel(
            size: CGSize(width: panelWidth, height: panelHeight),
            tintColor: neonColor
        )
        panel.position = CGPoint(x: centerX, y: size.height * 0.55)
        panel.zPosition = GameConstants.uiZ - 1
        addChild(panel)

        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "SETTINGS"
        title.fontSize = 32
        title.fontColor = neonColor
        title.position = CGPoint(x: centerX, y: size.height * 0.55 + panelHeight / 2 + 30)
        title.zPosition = GameConstants.uiZ
        title.horizontalAlignmentMode = .center
        addChild(title)

        // --- Sound row ---
        let soundY = size.height * 0.55 + 40

        soundLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        soundLabel.text = "Sound"
        soundLabel.fontSize = 20
        soundLabel.fontColor = .white
        soundLabel.position = CGPoint(x: centerX - panelWidth * 0.25, y: soundY - 7)
        soundLabel.zPosition = GameConstants.uiZ
        soundLabel.horizontalAlignmentMode = .left
        addChild(soundLabel)

        let soundStatusLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        soundStatusLabel.text = audioManager.isSoundMuted ? "OFF" : "ON"
        soundStatusLabel.fontSize = 14
        soundStatusLabel.fontColor = UIColor.white.withAlphaComponent(0.4)
        soundStatusLabel.position = CGPoint(x: centerX - panelWidth * 0.25, y: soundY - 24)
        soundStatusLabel.zPosition = GameConstants.uiZ
        soundStatusLabel.horizontalAlignmentMode = .left
        soundStatusLabel.name = "soundStatus"
        addChild(soundStatusLabel)

        soundToggle = createToggle(isOn: !audioManager.isSoundMuted, position: CGPoint(x: centerX + panelWidth * 0.25, y: soundY))
        soundToggle.name = "soundToggle"
        addChild(soundToggle)

        // Divider line
        let divider = SKShapeNode(rectOf: CGSize(width: panelWidth - 40, height: 0.5))
        divider.fillColor = UIColor.white.withAlphaComponent(0.1)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: centerX, y: soundY - 45)
        divider.zPosition = GameConstants.uiZ
        addChild(divider)

        // --- Haptic row ---
        let hapticY = soundY - 90

        hapticLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        hapticLabel.text = "Haptics"
        hapticLabel.fontSize = 20
        hapticLabel.fontColor = .white
        hapticLabel.position = CGPoint(x: centerX - panelWidth * 0.25, y: hapticY - 7)
        hapticLabel.zPosition = GameConstants.uiZ
        hapticLabel.horizontalAlignmentMode = .left
        addChild(hapticLabel)

        let hapticStatusLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        hapticStatusLabel.text = audioManager.isHapticMuted ? "OFF" : "ON"
        hapticStatusLabel.fontSize = 14
        hapticStatusLabel.fontColor = UIColor.white.withAlphaComponent(0.4)
        hapticStatusLabel.position = CGPoint(x: centerX - panelWidth * 0.25, y: hapticY - 24)
        hapticStatusLabel.zPosition = GameConstants.uiZ
        hapticStatusLabel.horizontalAlignmentMode = .left
        hapticStatusLabel.name = "hapticStatus"
        addChild(hapticStatusLabel)

        hapticToggle = createToggle(isOn: !audioManager.isHapticMuted, position: CGPoint(x: centerX + panelWidth * 0.25, y: hapticY))
        hapticToggle.name = "hapticToggle"
        addChild(hapticToggle)

        // Version info at bottom of panel
        let versionLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        versionLabel.text = "Glow Dash v1.0"
        versionLabel.fontSize = 11
        versionLabel.fontColor = UIColor.white.withAlphaComponent(0.2)
        versionLabel.position = CGPoint(x: centerX, y: size.height * 0.55 - panelHeight / 2 + 15)
        versionLabel.zPosition = GameConstants.uiZ
        versionLabel.horizontalAlignmentMode = .center
        addChild(versionLabel)
    }

    private func setupBackButton() {
        let centerX = size.width / 2
        let btnSize = CGSize(width: 140, height: 46)
        let btnTexture = SKTexture.neonButton(size: btnSize, color: neonColor)

        let btn = SKSpriteNode(texture: btnTexture, size: btnSize)
        btn.position = CGPoint(x: centerX, y: size.height * 0.25)
        btn.zPosition = GameConstants.uiZ
        btn.name = "backButton"
        addChild(btn)

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "BACK"
        label.fontSize = 18
        label.fontColor = neonColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        label.name = "backButtonLabel"
        btn.addChild(label)
    }

    // MARK: - Helpers

    private func createToggle(isOn: Bool, position: CGPoint) -> SKSpriteNode {
        let texture = SKTexture.toggleButton(size: toggleSize, isOn: isOn, color: neonColor)
        let toggle = SKSpriteNode(texture: texture, size: toggleSize)
        toggle.position = position
        toggle.zPosition = GameConstants.uiZ
        return toggle
    }

    private func refreshToggle(_ toggle: SKSpriteNode, isOn: Bool) {
        let texture = SKTexture.toggleButton(size: toggleSize, isOn: isOn, color: neonColor)
        toggle.texture = texture
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        // Sound toggle
        if tapped.contains(where: { $0.name == "soundToggle" }) {
            audioManager.toggleSound()
            refreshToggle(soundToggle, isOn: !audioManager.isSoundMuted)
            if let status = childNode(withName: "soundStatus") as? SKLabelNode {
                status.text = audioManager.isSoundMuted ? "OFF" : "ON"
            }
            audioManager.playTapHaptic()
            return
        }

        // Haptic toggle
        if tapped.contains(where: { $0.name == "hapticToggle" }) {
            audioManager.toggleHaptics()
            refreshToggle(hapticToggle, isOn: !audioManager.isHapticMuted)
            if let status = childNode(withName: "hapticStatus") as? SKLabelNode {
                status.text = audioManager.isHapticMuted ? "OFF" : "ON"
            }
            audioManager.playTapHaptic()
            return
        }

        // Back button
        if tapped.contains(where: { $0.name == "backButton" || $0.name == "backButtonLabel" }) {
            audioManager.playTapHaptic()
            let menuScene = MenuScene(size: size)
            menuScene.scaleMode = .resizeFill
            view?.presentScene(menuScene, transition: SKTransition.push(with: .right, duration: 0.3))
            return
        }
    }
}
