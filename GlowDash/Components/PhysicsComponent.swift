import GameplayKit
import SpriteKit

/// Configures the physics body on an entity's sprite node.
final class PhysicsComponent: GKComponent {

    struct Config {
        var categoryBitMask: UInt32
        var contactTestBitMask: UInt32 = 0
        var collisionBitMask: UInt32 = 0
        var isDynamic: Bool = true
        var affectedByGravity: Bool = true
        var allowsRotation: Bool = false
        var linearDamping: CGFloat = 0
        var mass: CGFloat = 1.0
        var restitution: CGFloat = 0
    }

    let config: Config

    init(config: Config) {
        self.config = config
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not used") }

    override func didAddToEntity() {
        guard let node = entity?.component(ofType: SpriteComponent.self)?.node as? SKSpriteNode else { return }
        applyPhysics(to: node)
    }

    private func applyPhysics(to node: SKSpriteNode) {
        let body = SKPhysicsBody(
            rectangleOf: CGSize(width: node.size.width * 0.8, height: node.size.height * 0.75)
        )
        body.categoryBitMask = config.categoryBitMask
        body.contactTestBitMask = config.contactTestBitMask
        body.collisionBitMask = config.collisionBitMask
        body.isDynamic = config.isDynamic
        body.affectedByGravity = config.affectedByGravity
        body.allowsRotation = config.allowsRotation
        body.linearDamping = config.linearDamping
        body.mass = config.mass
        body.restitution = config.restitution
        node.physicsBody = body
    }
}
