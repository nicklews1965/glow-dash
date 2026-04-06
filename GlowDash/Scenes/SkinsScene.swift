import SpriteKit

/// Skin selection screen — grid of unlockable character skins.
final class SkinsScene: SKScene {

    private let neonColor: UIColor = .neonCyan
    private let skinManager = SkinManager.shared
    private let columns = 3
    private let tileSize = CGSize(width: 90, height: 110)

    override func didMove(to view: SKView) {
        backgroundColor = .glowBackground
        setupBackground()
        setupTitle()
        setupGrid()
        setupBackButton()
    }

    // MARK: - Setup

    private func setupBackground() {
        for _ in 0..<20 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.08...0.3)
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            star.zPosition = GameConstants.backgroundFarZ + 1
            addChild(star)
        }
    }

    private func setupTitle() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "SKINS"
        title.fontSize = 32
        title.fontColor = neonColor
        title.position = CGPoint(x: size.width / 2, y: size.height - 80)
        title.zPosition = GameConstants.uiZ
        title.horizontalAlignmentMode = .center
        addChild(title)

        let progress = SKLabelNode(fontNamed: "AvenirNext-Regular")
        progress.text = "Unlocked: \(skinManager.progressText)"
        progress.fontSize = 14
        progress.fontColor = UIColor.white.withAlphaComponent(0.4)
        progress.position = CGPoint(x: size.width / 2, y: size.height - 105)
        progress.zPosition = GameConstants.uiZ
        progress.horizontalAlignmentMode = .center
        addChild(progress)
    }

    private func setupGrid() {
        let skins = skinManager.allSkins
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(columns) * tileSize.width + CGFloat(columns - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + tileSize.width / 2
        let startY = size.height - 160

        for (index, skin) in skins.enumerated() {
            let col = index % columns
            let row = index / columns

            let x = startX + CGFloat(col) * (tileSize.width + spacing)
            let y = startY - CGFloat(row) * (tileSize.height + spacing)

            let tile = createSkinTile(skin: skin, position: CGPoint(x: x, y: y))
            addChild(tile)
        }
    }

    private func createSkinTile(skin: SkinManager.Skin, position: CGPoint) -> SKNode {
        let tile = SKNode()
        tile.position = position
        tile.name = "skin_\(skin.id)"

        let isUnlocked = skinManager.isSkinUnlocked(skin.id)
        let isSelected = skinManager.selectedSkinID == skin.id

        // Background tile
        let bgColor = isSelected ? neonColor : .white
        let bgTexture = SKTexture.glassPanel(size: tileSize, cornerRadius: 12, tintColor: bgColor)
        let bg = SKSpriteNode(texture: bgTexture, size: tileSize)
        bg.alpha = isSelected ? 1.0 : 0.7
        bg.name = "skin_\(skin.id)"
        tile.addChild(bg)

        if isUnlocked {
            // Show bird preview
            let previewTexture = SKTexture.neonPlayerSkin(size: CGSize(width: 28, height: 22), color: skin.color, shape: skin.shape)
            let preview = SKSpriteNode(texture: previewTexture, size: CGSize(width: 52, height: 46))
            preview.position = CGPoint(x: 0, y: 12)
            preview.name = "skin_\(skin.id)"
            tile.addChild(preview)

            // Name
            let nameLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            nameLabel.text = skin.name
            nameLabel.fontSize = 10
            nameLabel.fontColor = isSelected ? neonColor : .white
            nameLabel.position = CGPoint(x: 0, y: -28)
            nameLabel.horizontalAlignmentMode = .center
            nameLabel.name = "skin_\(skin.id)"
            tile.addChild(nameLabel)

            // Selected indicator
            if isSelected {
                let checkLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
                checkLabel.text = "EQUIPPED"
                checkLabel.fontSize = 8
                checkLabel.fontColor = neonColor
                checkLabel.position = CGPoint(x: 0, y: -42)
                checkLabel.horizontalAlignmentMode = .center
                tile.addChild(checkLabel)
            }
        } else {
            // Locked state
            let lockLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            lockLabel.text = "LOCKED"
            lockLabel.fontSize = 11
            lockLabel.fontColor = UIColor.white.withAlphaComponent(0.3)
            lockLabel.position = CGPoint(x: 0, y: 8)
            lockLabel.horizontalAlignmentMode = .center
            lockLabel.name = "skin_\(skin.id)"
            tile.addChild(lockLabel)

            // Unlock requirement
            let reqLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            reqLabel.text = skin.unlockDescription
            reqLabel.fontSize = 8
            reqLabel.fontColor = UIColor.white.withAlphaComponent(0.25)
            reqLabel.position = CGPoint(x: 0, y: -12)
            reqLabel.horizontalAlignmentMode = .center
            reqLabel.preferredMaxLayoutWidth = tileSize.width - 10
            reqLabel.numberOfLines = 2
            reqLabel.name = "skin_\(skin.id)"
            tile.addChild(reqLabel)
        }

        return tile
    }

    private func setupBackButton() {
        let btnSize = CGSize(width: 140, height: 46)
        let btnTexture = SKTexture.neonButton(size: btnSize, color: neonColor)
        let btn = SKSpriteNode(texture: btnTexture, size: btnSize)
        btn.position = CGPoint(x: size.width / 2, y: 80)
        btn.zPosition = GameConstants.uiZ
        btn.name = "backButton"
        addChild(btn)

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "BACK"
        label.fontSize = 18
        label.fontColor = neonColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "backLabel"
        btn.addChild(label)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        AudioManager.shared.playTapHaptic()

        // Back button
        if tapped.contains(where: { $0.name == "backButton" || $0.name == "backLabel" }) {
            let menuScene = MenuScene(size: size)
            menuScene.scaleMode = .resizeFill
            view?.presentScene(menuScene, transition: SKTransition.push(with: .right, duration: 0.3))
            return
        }

        // Skin selection
        for node in tapped {
            guard let name = node.name, name.hasPrefix("skin_") else { continue }
            let skinID = String(name.dropFirst(5))
            if skinManager.isSkinUnlocked(skinID) {
                skinManager.selectSkin(skinID)
                // Refresh the scene
                let newScene = SkinsScene(size: size)
                newScene.scaleMode = .resizeFill
                view?.presentScene(newScene)
            }
            return
        }
    }
}
