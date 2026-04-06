import GameplayKit
import SpriteKit

/// The player character — a neon geometric bird with wing animation and particle trail.
final class PlayerEntity: GKEntity {

    private let spriteComponent: SpriteComponent
    private var trailEmitter: SKEmitterNode?
    private var flapAnimationAction: SKAction?
    private var skinShape: SkinManager.Skin.Shape

    /// The player's SKSpriteNode (convenience accessor).
    var node: SKSpriteNode {
        spriteComponent.node as! SKSpriteNode
    }

    init(color: UIColor, shape: SkinManager.Skin.Shape = .chevron) {
        self.skinShape = shape
        // Generate animation frames
        let frames = SKTexture.neonPlayerFrames(size: GameConstants.playerSize, color: color, shape: shape)
        let spriteSize = CGSize(
            width: GameConstants.playerSize.width + 24,
            height: GameConstants.playerSize.height + 24
        )

        let sprite = SKSpriteNode(texture: frames[0], size: spriteSize)
        sprite.zPosition = GameConstants.playerZ
        sprite.name = "player"

        spriteComponent = SpriteComponent(node: sprite)

        // Build repeating flap animation
        flapAnimationAction = SKAction.repeatForever(
            SKAction.animate(with: frames, timePerFrame: GameConstants.flapAnimationFPS)
        )

        super.init()

        addComponent(spriteComponent)

        let physicsConfig = PhysicsComponent.Config(
            categoryBitMask: GameConstants.playerCategory,
            contactTestBitMask: GameConstants.obstacleCategory | GameConstants.groundCategory | GameConstants.scoreCategory | GameConstants.ceilingCategory,
            collisionBitMask: GameConstants.groundCategory | GameConstants.ceilingCategory,
            isDynamic: true,
            affectedByGravity: true,
            allowsRotation: false,
            linearDamping: 0,
            mass: 1.0,
            restitution: 0
        )
        addComponent(PhysicsComponent(config: physicsConfig))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not used") }

    // MARK: - Animation

    /// Start the wing flap animation loop.
    func startFlapAnimation() {
        guard let action = flapAnimationAction else { return }
        node.run(action, withKey: "flapAnimation")
    }

    /// Stop the wing animation (e.g. on death).
    func stopFlapAnimation() {
        node.removeAction(forKey: "flapAnimation")
    }

    // MARK: - Actions

    /// Apply an upward impulse (tap to flap).
    func flap() {
        guard let body = node.physicsBody else { return }
        // Reset vertical velocity for consistent jump height
        body.velocity = CGVector(dx: body.velocity.dx, dy: 0)
        body.applyImpulse(CGVector(dx: 0, dy: GameConstants.tapImpulse))

        // Quick "flap up" — reset animation to the upstroke frame
        node.removeAction(forKey: "flapAnimation")
        if let action = flapAnimationAction {
            node.run(action, withKey: "flapAnimation")
        }
    }

    /// Smoothly rotate the player based on vertical velocity.
    func updateRotation(deltaTime: TimeInterval) {
        guard let body = node.physicsBody else { return }
        let velocityFraction = body.velocity.dy / GameConstants.maxUpwardVelocity
        let targetAngle: CGFloat
        if velocityFraction > 0 {
            targetAngle = GameConstants.flapUpRotation * velocityFraction.clamped(to: 0...1)
        } else {
            targetAngle = GameConstants.flapDownRotation * (-velocityFraction).clamped(to: 0...1)
        }
        let angleDiff = targetAngle - node.zRotation
        node.zRotation += angleDiff * GameConstants.rotationSpeed * CGFloat(deltaTime)
    }

    /// Clamp upward velocity so the player can't rocket off screen.
    func clampVelocity() {
        guard let body = node.physicsBody else { return }
        if body.velocity.dy > GameConstants.maxUpwardVelocity {
            body.velocity.dy = GameConstants.maxUpwardVelocity
        }
    }

    // MARK: - Particle Trail

    /// Attach a neon trail emitter. Call once after adding the player to the scene.
    func attachTrail(to scene: SKScene, color: UIColor) {
        let emitter = SKEmitterNode.neonTrail(color: color)
        emitter.targetNode = scene
        emitter.position = CGPoint(x: -GameConstants.playerSize.width / 2, y: 0)
        emitter.zPosition = GameConstants.particleZ
        node.addChild(emitter)
        trailEmitter = emitter
    }

    /// Update the trail color during Neon Pulse shifts.
    func updateTrailColor(_ color: UIColor) {
        trailEmitter?.particleColor = color
    }

    /// Update the player textures to a new color (for Neon Pulse).
    func updateTextures(color: UIColor) {
        let frames = SKTexture.neonPlayerFrames(size: GameConstants.playerSize, color: color, shape: skinShape)
        flapAnimationAction = SKAction.repeatForever(
            SKAction.animate(with: frames, timePerFrame: GameConstants.flapAnimationFPS)
        )
        // Restart animation with new frames
        node.removeAction(forKey: "flapAnimation")
        if let action = flapAnimationAction {
            node.run(action, withKey: "flapAnimation")
        }
        updateTrailColor(color)
    }
}
