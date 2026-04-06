import GameplayKit
import SpriteKit

/// A pair of neon obstacles (top + bottom) with a scoring gap between them.
final class ObstacleEntity: GKEntity {

    /// Parent container node that holds both obstacles and the score zone.
    let containerNode: SKNode

    init(sceneSize: CGSize, gapSize: CGFloat, gapCenterY: CGFloat, speed: CGFloat, color: UIColor, moving: Bool = false) {
        containerNode = SKNode()
        containerNode.name = "obstacleContainer"
        containerNode.zPosition = GameConstants.obstacleZ

        // Start just off the right edge
        containerNode.position = CGPoint(x: sceneSize.width + GameConstants.obstacleWidth, y: 0)

        let obstacleW = GameConstants.obstacleWidth
        let cornerR = GameConstants.obstacleCornerRadius

        // --- Bottom obstacle ---
        let bottomHeight = gapCenterY - gapSize / 2
        if bottomHeight > 0 {
            let bottomTexture = SKTexture.neonRect(
                size: CGSize(width: obstacleW, height: bottomHeight),
                color: color, cornerRadius: cornerR
            )
            let bottomSprite = SKSpriteNode(texture: bottomTexture, size: CGSize(
                width: obstacleW + 32, height: bottomHeight + 32
            ))
            bottomSprite.position = CGPoint(x: 0, y: bottomHeight / 2)
            bottomSprite.name = "obstacle"

            let bottomBody = SKPhysicsBody(rectangleOf: CGSize(width: obstacleW, height: bottomHeight))
            bottomBody.isDynamic = false
            bottomBody.categoryBitMask = GameConstants.obstacleCategory
            bottomBody.contactTestBitMask = GameConstants.playerCategory
            bottomBody.collisionBitMask = 0
            bottomSprite.physicsBody = bottomBody

            containerNode.addChild(bottomSprite)
        }

        // --- Top obstacle ---
        let topY = gapCenterY + gapSize / 2
        let topHeight = sceneSize.height - topY
        if topHeight > 0 {
            let topTexture = SKTexture.neonRect(
                size: CGSize(width: obstacleW, height: topHeight),
                color: color, cornerRadius: cornerR
            )
            let topSprite = SKSpriteNode(texture: topTexture, size: CGSize(
                width: obstacleW + 32, height: topHeight + 32
            ))
            topSprite.position = CGPoint(x: 0, y: topY + topHeight / 2)
            topSprite.name = "obstacle"

            let topBody = SKPhysicsBody(rectangleOf: CGSize(width: obstacleW, height: topHeight))
            topBody.isDynamic = false
            topBody.categoryBitMask = GameConstants.obstacleCategory
            topBody.contactTestBitMask = GameConstants.playerCategory
            topBody.collisionBitMask = 0
            topSprite.physicsBody = topBody

            containerNode.addChild(topSprite)
        }

        // --- Invisible score zone in the gap ---
        let scoreZone = SKNode()
        scoreZone.position = CGPoint(x: 0, y: gapCenterY)
        scoreZone.name = "scoreZone"

        let scoreBody = SKPhysicsBody(rectangleOf: CGSize(width: 2, height: gapSize))
        scoreBody.isDynamic = false
        scoreBody.categoryBitMask = GameConstants.scoreCategory
        scoreBody.contactTestBitMask = GameConstants.playerCategory
        scoreBody.collisionBitMask = 0
        scoreZone.physicsBody = scoreBody

        containerNode.addChild(scoreZone)

        // Create sprite component pointing to container
        let spriteComp = SpriteComponent(node: containerNode)
        let moveComp = MovementComponent(speed: -speed)  // negative = scroll left

        super.init()

        addComponent(spriteComp)
        addComponent(moveComp)
        addComponent(ScoreComponent())

        // Spawn scale-in animation
        containerNode.setScale(0.85)
        containerNode.run(SKAction.scale(to: 1.0, duration: GameConstants.obstacleSpawnAnimDuration))

        // Moving obstacle: vertical oscillation for advanced difficulty
        if moving {
            let amp = GameConstants.movingObstacleAmplitude
            let period = GameConstants.movingObstaclePeriod
            let moveUp = SKAction.moveBy(x: 0, y: amp, duration: period / 2)
            moveUp.timingMode = .easeInEaseOut
            let moveDown = SKAction.moveBy(x: 0, y: -amp, duration: period / 2)
            moveDown.timingMode = .easeInEaseOut
            containerNode.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not used") }

    /// Whether the obstacle has fully scrolled off the left edge.
    func isOffScreen() -> Bool {
        containerNode.position.x < -(GameConstants.obstacleWidth + 40)
    }

    /// Clean up nodes when removing the obstacle.
    func removeFromScene() {
        containerNode.removeAllChildren()
        containerNode.removeFromParent()
    }
}
