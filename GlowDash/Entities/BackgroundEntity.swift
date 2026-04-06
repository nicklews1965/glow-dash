import GameplayKit
import SpriteKit

/// Manages a 3-layer parallax scrolling background and the ground.
///
/// Layers (back to front):
/// 1. **Far** — City silhouette (slowest scroll)
/// 2. **Mid** — Floating neon shapes (medium scroll)
/// 3. **Near / Ground** — Neon grid floor (fastest scroll)
final class BackgroundEntity: GKEntity {

    let rootNode: SKNode

    private var farLayers: [SKSpriteNode] = []
    private var midShapes: [SKShapeNode] = []
    private var groundLayers: [SKSpriteNode] = []

    private let sceneSize: CGSize

    init(sceneSize: CGSize, color: UIColor) {
        self.sceneSize = sceneSize
        rootNode = SKNode()
        rootNode.name = "background"

        super.init()

        setupSky()
        setupStars()
        setupCitySilhouette(color: color)
        setupMidLayer(color: color)
        setupGround(color: color)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not used") }

    // MARK: - Layer Setup

    private func setupSky() {
        // Deep dark gradient background (static)
        let bg = SKSpriteNode(color: .glowBackground, size: sceneSize)
        bg.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        bg.zPosition = GameConstants.backgroundFarZ - 1
        rootNode.addChild(bg)

        // Subtle vertical gradient overlay for depth
        let gradientSize = sceneSize
        let renderer = UIGraphicsImageRenderer(size: gradientSize)
        let gradientImage = renderer.image { ctx in
            let colors = [
                UIColor(red: 0.02, green: 0.01, blue: 0.08, alpha: 1.0).cgColor,
                UIColor(red: 0.06, green: 0.03, blue: 0.18, alpha: 1.0).cgColor,
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: gradientSize.height),
                options: []
            )
        }
        let gradientNode = SKSpriteNode(texture: SKTexture(image: gradientImage), size: sceneSize)
        gradientNode.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        gradientNode.zPosition = GameConstants.backgroundFarZ
        rootNode.addChild(gradientNode)
    }

    private func setupStars() {
        for _ in 0..<50 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.0))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.15...0.6)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...sceneSize.width),
                y: CGFloat.random(in: sceneSize.height * 0.35...sceneSize.height)
            )
            star.zPosition = GameConstants.backgroundFarZ + 1

            // Gentle twinkle
            let baseAlpha = star.alpha
            let fadeOut = SKAction.fadeAlpha(to: baseAlpha * 0.3, duration: Double.random(in: 1.5...4.0))
            let fadeIn = SKAction.fadeAlpha(to: baseAlpha, duration: Double.random(in: 1.5...4.0))
            star.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))

            rootNode.addChild(star)
        }
    }

    private func setupCitySilhouette(color: UIColor) {
        let cityHeight = sceneSize.height * 0.4
        let cityTexture = SKTexture.neonCitySilhouette(
            size: CGSize(width: sceneSize.width, height: cityHeight),
            color: color
        )

        // Two tiles for seamless scrolling
        for i in 0..<2 {
            let city = SKSpriteNode(texture: cityTexture, size: CGSize(width: sceneSize.width, height: cityHeight))
            city.anchorPoint = CGPoint(x: 0, y: 0)
            city.position = CGPoint(
                x: CGFloat(i) * sceneSize.width,
                y: GameConstants.groundHeight
            )
            city.zPosition = GameConstants.backgroundFarZ + 2
            city.name = "cityFar"
            rootNode.addChild(city)
            farLayers.append(city)
        }
    }

    private func setupMidLayer(color: UIColor) {
        // Floating neon geometric shapes at mid-depth
        let count = GameConstants.midLayerShapeCount
        for _ in 0..<count {
            let size = CGFloat.random(in: GameConstants.midLayerMinSize...GameConstants.midLayerMaxSize)

            let shape: SKShapeNode
            if Bool.random() {
                shape = SKShapeNode(circleOfRadius: size)
            } else {
                shape = SKShapeNode(rectOf: CGSize(width: size * 1.5, height: size), cornerRadius: 2)
            }

            shape.fillColor = color.withAlphaComponent(CGFloat.random(in: 0.03...0.08))
            shape.strokeColor = color.withAlphaComponent(CGFloat.random(in: 0.06...0.15))
            shape.lineWidth = 0.5
            shape.glowWidth = 2.0

            shape.position = CGPoint(
                x: CGFloat.random(in: 0...sceneSize.width),
                y: CGFloat.random(in: GameConstants.groundHeight + 40...sceneSize.height - 40)
            )
            shape.zPosition = GameConstants.backgroundMidZ

            // Gentle floating animation
            let drift = SKAction.moveBy(
                x: 0,
                y: CGFloat.random(in: -10...10),
                duration: Double.random(in: 3.0...6.0)
            )
            drift.timingMode = .easeInEaseOut
            shape.run(SKAction.repeatForever(SKAction.sequence([drift, drift.reversed()])))

            rootNode.addChild(shape)
            midShapes.append(shape)
        }
    }

    private func setupGround(color: UIColor) {
        let groundH = GameConstants.groundHeight
        let groundTexture = SKTexture.neonGround(
            size: CGSize(width: sceneSize.width, height: groundH),
            color: color
        )

        for i in 0..<2 {
            let ground = SKSpriteNode(texture: groundTexture, size: CGSize(width: sceneSize.width, height: groundH))
            ground.anchorPoint = CGPoint(x: 0, y: 0)
            ground.position = CGPoint(x: CGFloat(i) * sceneSize.width, y: 0)
            ground.zPosition = GameConstants.groundZ
            ground.name = "ground"
            rootNode.addChild(ground)
            groundLayers.append(ground)
        }

        // Ground physics body
        let groundBody = SKNode()
        groundBody.position = CGPoint(x: sceneSize.width / 2, y: groundH)
        let body = SKPhysicsBody(rectangleOf: CGSize(width: sceneSize.width * 3, height: 2))
        body.isDynamic = false
        body.categoryBitMask = GameConstants.groundCategory
        body.contactTestBitMask = GameConstants.playerCategory
        body.collisionBitMask = GameConstants.playerCategory
        groundBody.physicsBody = body
        rootNode.addChild(groundBody)

        // Ceiling boundary
        let ceiling = SKNode()
        ceiling.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height + 20)
        let ceilingBody = SKPhysicsBody(rectangleOf: CGSize(width: sceneSize.width * 3, height: 2))
        ceilingBody.isDynamic = false
        ceilingBody.categoryBitMask = GameConstants.ceilingCategory
        ceilingBody.contactTestBitMask = 0
        ceilingBody.collisionBitMask = GameConstants.playerCategory
        ceiling.physicsBody = ceilingBody
        rootNode.addChild(ceiling)
    }

    // MARK: - Per-Frame Updates

    /// Scroll all parallax layers. Call each frame.
    func update(speed: CGFloat, deltaTime: TimeInterval) {
        scrollFarLayer(speed: speed, deltaTime: deltaTime)
        scrollMidLayer(speed: speed, deltaTime: deltaTime)
        scrollGround(speed: speed, deltaTime: deltaTime)
    }

    private func scrollFarLayer(speed: CGFloat, deltaTime: TimeInterval) {
        let dx = -speed * GameConstants.parallaxFarSpeed * CGFloat(deltaTime)
        for layer in farLayers {
            layer.position.x += dx
            if layer.position.x <= -sceneSize.width {
                layer.position.x += sceneSize.width * 2
            }
        }
    }

    private func scrollMidLayer(speed: CGFloat, deltaTime: TimeInterval) {
        let dx = -speed * GameConstants.parallaxMidSpeed * CGFloat(deltaTime)
        for shape in midShapes {
            shape.position.x += dx
            // Wrap around when off left edge
            if shape.position.x < -20 {
                shape.position.x = sceneSize.width + 20
                shape.position.y = CGFloat.random(in: GameConstants.groundHeight + 40...sceneSize.height - 40)
            }
        }
    }

    private func scrollGround(speed: CGFloat, deltaTime: TimeInterval) {
        let dx = -speed * GameConstants.parallaxNearSpeed * CGFloat(deltaTime)
        for ground in groundLayers {
            ground.position.x += dx
            if ground.position.x <= -sceneSize.width {
                ground.position.x += sceneSize.width * 2
            }
        }
    }

    // MARK: - Color Update (Neon Pulse)

    /// Update all background layer tints to match a new neon color.
    func updateColor(_ color: UIColor) {
        // Update mid-layer shapes
        for shape in midShapes {
            shape.fillColor = color.withAlphaComponent(shape.fillColor.cgColor.alpha)
            shape.strokeColor = color.withAlphaComponent(shape.strokeColor.cgColor.alpha)
        }
    }
}
